import SwiftUI

struct TradingView: View {
    @StateObject private var api = TradingAPI.shared
    @State private var symbol = ""
    @State private var quantity = "100"
    @State private var selectedOrderType = OrderType.market
    @State private var selectedTimeInForce = TimeInForce.day
    @State private var limitPrice = ""
    @State private var stopPrice = ""
    @State private var isBuyOrder = true
    @State private var showingOrderConfirmation = false
    @State private var orderResult = ""
    @State private var currentPrice: Double = 0
    @State private var isLoadingPrice = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Symbol Input
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Symbol")
                            .font(.headline)
                        
                        HStack {
                            TextField("Enter Symbol (e.g., AAPL)", text: $symbol)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .autocapitalization(.allCharacters)
                                .disableAutocorrection(true)
                            
                            Button(action: fetchPrice) {
                                if isLoadingPrice {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle())
                                        .scaleEffect(0.8)
                                } else {
                                    Image(systemName: "arrow.clockwise")
                                }
                            }
                            .disabled(symbol.isEmpty || isLoadingPrice)
                        }
                        
                        if currentPrice > 0 {
                            HStack {
                                Text("Current Price:")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Text("$\(currentPrice, specifier: "%.2f")")
                                    .font(.caption)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.green)
                            }
                        }
                    }
                    .padding(.horizontal)
                    
                    // Buy/Sell Toggle
                    Picker("Side", selection: $isBuyOrder) {
                        Text("Buy").tag(true)
                        Text("Sell").tag(false)
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    .padding(.horizontal)
                    
                    // Quantity
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Quantity")
                            .font(.headline)
                        
                        TextField("Number of Shares", text: $quantity)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .keyboardType(.numberPad)
                    }
                    .padding(.horizontal)
                    
                    // Order Type
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Order Type")
                            .font(.headline)
                        
                        Picker("Order Type", selection: $selectedOrderType) {
                            ForEach(OrderType.allCases, id: \.self) { type in
                                Text(type.displayName).tag(type)
                            }
                        }
                        .pickerStyle(MenuPickerStyle())
                        .padding()
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(8)
                    }
                    .padding(.horizontal)
                    
                    // Conditional Price Fields
                    if selectedOrderType == .limit || selectedOrderType == .stopLimit || selectedOrderType == .limitIfTouched {
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Limit Price")
                                .font(.headline)
                            
                            TextField("Enter Limit Price", text: $limitPrice)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .keyboardType(.decimalPad)
                        }
                        .padding(.horizontal)
                    }
                    
                    if selectedOrderType == .stop || selectedOrderType == .stopLimit || selectedOrderType == .trailing {
                        VStack(alignment: .leading, spacing: 10) {
                            Text(selectedOrderType == .trailing ? "Trail Amount" : "Stop Price")
                                .font(.headline)
                            
                            TextField(selectedOrderType == .trailing ? "Trail Amount ($)" : "Enter Stop Price", text: $stopPrice)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .keyboardType(.decimalPad)
                        }
                        .padding(.horizontal)
                    }
                    
                    // Time in Force
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Time in Force")
                            .font(.headline)
                        
                        Picker("Time in Force", selection: $selectedTimeInForce) {
                            ForEach(TimeInForce.allCases, id: \.self) { tif in
                                Text(tif.displayName).tag(tif)
                            }
                        }
                        .pickerStyle(SegmentedPickerStyle())
                    }
                    .padding(.horizontal)
                    
                    // Order Summary
                    VStack(spacing: 10) {
                        Text("Order Summary")
                            .font(.headline)
                        
                        VStack(alignment: .leading, spacing: 5) {
                            HStack {
                                Text("Action:")
                                    .foregroundColor(.secondary)
                                Text("\(isBuyOrder ? "Buy" : "Sell") \(quantity) shares of \(symbol.isEmpty ? "..." : symbol)")
                                    .fontWeight(.medium)
                            }
                            .font(.caption)
                            
                            HStack {
                                Text("Order Type:")
                                    .foregroundColor(.secondary)
                                Text(selectedOrderType.displayName)
                                    .fontWeight(.medium)
                            }
                            .font(.caption)
                            
                            if !limitPrice.isEmpty {
                                HStack {
                                    Text("Limit Price:")
                                        .foregroundColor(.secondary)
                                    Text("$\(limitPrice)")
                                        .fontWeight(.medium)
                                }
                                .font(.caption)
                            }
                            
                            if !stopPrice.isEmpty {
                                HStack {
                                    Text(selectedOrderType == .trailing ? "Trail:" : "Stop:")
                                        .foregroundColor(.secondary)
                                    Text("$\(stopPrice)")
                                        .fontWeight(.medium)
                                }
                                .font(.caption)
                            }
                        }
                        .padding()
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(8)
                    }
                    .padding(.horizontal)
                    
                    // Place Order Button
                    Button(action: placeOrder) {
                        HStack {
                            Image(systemName: isBuyOrder ? "arrow.up.circle.fill" : "arrow.down.circle.fill")
                            Text("Place \(isBuyOrder ? "Buy" : "Sell") Order")
                                .fontWeight(.semibold)
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(isBuyOrder ? Color.green : Color.red)
                        .cornerRadius(10)
                    }
                    .padding(.horizontal)
                    .disabled(symbol.isEmpty || quantity.isEmpty)
                    
                    Spacer(minLength: 50)
                }
                .padding(.vertical)
            }
            .navigationTitle("Trade Stocks")
            .alert("Order Result", isPresented: $showingOrderConfirmation) {
                Button("OK") { }
            } message: {
                Text(orderResult)
            }
        }
    }
    
    private func fetchPrice() {
        guard !symbol.isEmpty else { return }
        
        isLoadingPrice = true
        Task {
            do {
                let marketData = try await api.getMarketData(symbol: symbol)
                await MainActor.run {
                    currentPrice = marketData.last
                    isLoadingPrice = false
                }
            } catch {
                await MainActor.run {
                    isLoadingPrice = false
                    orderResult = "Failed to fetch price: \(error.localizedDescription)"
                    showingOrderConfirmation = true
                }
            }
        }
    }
    
    private func placeOrder() {
        guard let qty = Int(quantity) else {
            orderResult = "Invalid quantity"
            showingOrderConfirmation = true
            return
        }
        
        let order = StockOrder(
            symbol: symbol,
            quantity: qty,
            orderType: selectedOrderType.rawValue,
            side: isBuyOrder ? "BUY" : "SELL",
            limitPrice: limitPrice.isEmpty ? nil : Double(limitPrice),
            stopPrice: stopPrice.isEmpty ? nil : Double(stopPrice),
            timeInForce: selectedTimeInForce.rawValue
        )
        
        Task {
            do {
                let response = try await api.placeStockOrder(order)
                await MainActor.run {
                    orderResult = "Order placed successfully!\nOrder ID: \(response.orderId)\nStatus: \(response.status)"
                    showingOrderConfirmation = true
                    // Reset form
                    symbol = ""
                    quantity = "100"
                    limitPrice = ""
                    stopPrice = ""
                    currentPrice = 0
                }
            } catch {
                await MainActor.run {
                    orderResult = "Order failed: \(error.localizedDescription)"
                    showingOrderConfirmation = true
                }
            }
        }
    }
}