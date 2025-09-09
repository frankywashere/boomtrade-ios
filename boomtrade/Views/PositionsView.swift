import SwiftUI

struct PositionsView: View {
    @StateObject private var api = TradingAPI.shared
    @State private var positions: [Position] = []
    @State private var isLoading = false
    @State private var lastRefresh = Date()
    
    var totalValue: Double {
        positions.reduce(0) { $0 + $1.totalValue }
    }
    
    var totalPnL: Double {
        positions.reduce(0) { $0 + $1.unrealizedPnL }
    }
    
    var body: some View {
        NavigationView {
            VStack {
                if positions.isEmpty && !isLoading {
                    VStack(spacing: 20) {
                        Image(systemName: "briefcase")
                            .font(.system(size: 60))
                            .foregroundColor(.gray)
                        Text("No open positions")
                            .font(.title3)
                            .foregroundColor(.secondary)
                        
                        Button(action: refreshPositions) {
                            Label("Refresh", systemImage: "arrow.clockwise")
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    List {
                        // Portfolio Summary
                        Section {
                            VStack(spacing: 12) {
                                HStack {
                                    Text("Total Value")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    Spacer()
                                    Text("$\(totalValue, specifier: "%.2f")")
                                        .font(.title2)
                                        .fontWeight(.semibold)
                                }
                                
                                HStack {
                                    Text("Unrealized P&L")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    Spacer()
                                    Text("\(totalPnL >= 0 ? "+" : "")$\(totalPnL, specifier: "%.2f")")
                                        .font(.title3)
                                        .fontWeight(.medium)
                                        .foregroundColor(totalPnL >= 0 ? .green : .red)
                                }
                            }
                            .padding(.vertical, 8)
                        }
                        
                        // Positions
                        Section(header: Text("Open Positions")) {
                            ForEach(positions) { position in
                                PositionRow(position: position)
                            }
                        }
                    }
                    .refreshable {
                        await refreshPositionsAsync()
                    }
                }
                
                if isLoading {
                    ProgressView()
                        .padding()
                }
            }
            .navigationTitle("Positions")
            .navigationBarItems(
                trailing: Button(action: refreshPositions) {
                    Image(systemName: "arrow.clockwise")
                }
                .disabled(isLoading)
            )
            .onAppear {
                refreshPositions()
            }
        }
    }
    
    private func refreshPositions() {
        Task {
            await refreshPositionsAsync()
        }
    }
    
    private func refreshPositionsAsync() async {
        isLoading = true
        do {
            let fetchedPositions = try await api.getPositions()
            await MainActor.run {
                positions = fetchedPositions
                lastRefresh = Date()
                isLoading = false
            }
        } catch {
            await MainActor.run {
                isLoading = false
                print("Failed to load positions: \(error)")
            }
        }
    }
}

struct PositionRow: View {
    let position: Position
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(position.symbol)
                        .font(.headline)
                    Text("\(position.quantity) shares @ $\(position.averagePrice, specifier: "%.2f")")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text("$\(position.currentPrice, specifier: "%.2f")")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    HStack(spacing: 4) {
                        Image(systemName: position.percentChange >= 0 ? "arrow.up.right" : "arrow.down.right")
                            .font(.caption2)
                        Text("\(position.percentChange >= 0 ? "+" : "")\(position.percentChange, specifier: "%.2f")%")
                            .font(.caption)
                    }
                    .foregroundColor(position.percentChange >= 0 ? .green : .red)
                }
            }
            
            HStack {
                Text("P&L:")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text("\(position.unrealizedPnL >= 0 ? "+" : "")$\(position.unrealizedPnL, specifier: "%.2f")")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(position.unrealizedPnL >= 0 ? .green : .red)
                
                Spacer()
                
                Text("Value: $\(position.totalValue, specifier: "%.2f")")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}