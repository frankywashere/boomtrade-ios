import SwiftUI

struct LoginView: View {
    @StateObject private var api = TradingAPI.shared
    @State private var selectedPort = 7497  // Default to paper trading
    @State private var showingError = false
    @State private var errorMessage = ""
    @Binding var showingLogin: Bool
    
    var body: some View {
        VStack(spacing: 30) {
            VStack(spacing: 10) {
                Image(systemName: "chart.line.uptrend.xyaxis.circle.fill")
                    .font(.system(size: 80))
                    .foregroundColor(.blue)
                
                Text("BoomTrade")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                Text("Connect to TWS/IB Gateway")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            .padding(.top, 50)
            
            // Connection Type Selection
            VStack(spacing: 15) {
                Text("Select Trading Mode")
                    .font(.headline)
                
                Picker("Trading Mode", selection: $selectedPort) {
                    Text("Paper Trading").tag(7497)
                    Text("Live Trading").tag(7496)
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding(.horizontal, 30)
                
                Text("Port: \(selectedPort)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            if api.isConnecting {
                VStack(spacing: 15) {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle())
                        .scaleEffect(1.2)
                    
                    Text(api.connectionMessage)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding()
            } else {
                Button(action: connect) {
                    HStack {
                        Image(systemName: "link.circle.fill")
                        Text("Connect to TWS")
                            .fontWeight(.semibold)
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .cornerRadius(10)
                }
                .padding(.horizontal, 30)
            }
            
            Spacer()
            
            // Setup Instructions
            VStack(alignment: .leading, spacing: 10) {
                Text("Setup Instructions:")
                    .font(.headline)
                    .padding(.bottom, 5)
                
                VStack(alignment: .leading, spacing: 8) {
                    Label("Login to TWS or IB Gateway", systemImage: "1.circle.fill")
                    Label("Enable API connections in settings", systemImage: "2.circle.fill")
                    Label("Set socket port to \(selectedPort)", systemImage: "3.circle.fill")
                    Label("Add 127.0.0.1 to trusted IPs", systemImage: "4.circle.fill")
                    Label("Click Connect above", systemImage: "5.circle.fill")
                }
                .font(.caption)
                .foregroundColor(.secondary)
            }
            .padding()
            .background(Color.gray.opacity(0.1))
            .cornerRadius(10)
            .padding(.horizontal, 20)
            .padding(.bottom, 30)
        }
        .alert("Connection Error", isPresented: $showingError) {
            Button("OK") { }
        } message: {
            Text(errorMessage)
        }
        .onChange(of: api.isConnected) { _, connected in
            if connected {
                showingLogin = false
            }
        }
    }
    
    private func connect() {
        print("🔵 CONNECTION ATTEMPT")
        print("Port: \(selectedPort)")
        print("URL: \(api.baseURL)")
        
        Task {
            do {
                print("🔵 Calling connectToTWS...")
                try await api.connectToTWS(port: selectedPort)
                print("✅ Connected successfully")
            } catch {
                print("❌ Connection error: \(error)")
                errorMessage = error.localizedDescription
                showingError = true
            }
        }
    }
}