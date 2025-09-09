import SwiftUI

struct OptionsView: View {
    @StateObject private var api = TradingAPI.shared
    @State private var symbol = ""
    @State private var selectedExpiry = ""
    @State private var availableExpiries: [String] = []
    @State private var optionChain: OptionChain?
    @State private var selectedContract: OptionContract?
    @State private var isCall = true
    @State private var isLoadingChain = false
    @State private var showingOrderSheet = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Symbol and Expiry Selection
                VStack(spacing: 15) {
                    HStack {
                        TextField("Symbol (e.g., AAPL)", text: $symbol)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .autocapitalization(.allCharacters)
                            .disableAutocorrection(true)
                        
                        Button(action: loadExpiries) {
                            if isLoadingChain {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle())
                                    .scaleEffect(0.8)
                            } else {
                                Text("Search")
                                    .fontWeight(.medium)
                            }
                        }
                        .disabled(symbol.isEmpty || isLoadingChain)
                    }
                    
                    if !availableExpiries.isEmpty {
                        Picker("Expiry", selection: $selectedExpiry) {
                            Text("Select Expiry").tag("")
                            ForEach(availableExpiries, id: \.self) { expiry in
                                Text(formatExpiry(expiry)).tag(expiry)
                            }
                        }
                        .pickerStyle(MenuPickerStyle())
                        .padding(.horizontal)
                        .padding(.vertical, 8)
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(8)
                        .onChange(of: selectedExpiry) { _ in
                            if !selectedExpiry.isEmpty {
                                loadOptionChain()
                            }
                        }
                    }
                    
                    // Call/Put Toggle
                    if optionChain != nil {
                        Picker("Type", selection: $isCall) {
                            Text("Calls").tag(true)
                            Text("Puts").tag(false)
                        }
                        .pickerStyle(SegmentedPickerStyle())
                    }
                }
                .padding()
                .background(Color(UIColor.systemBackground))
                
                Divider()
                
                // Option Chain Display
                if let chain = optionChain {
                    ScrollView {
                        VStack(spacing: 0) {
                            // Header
                            HStack {
                                Text("Strike")
                                    .frame(width: 70, alignment: .leading)
                                Text("Bid")
                                    .frame(width: 60, alignment: .trailing)
                                Text("Ask")
                                    .frame(width: 60, alignment: .trailing)
                                Text("Last")
                                    .frame(width: 60, alignment: .trailing)
                                Text("Volume")
                                    .frame(width: 70, alignment: .trailing)
                                Text("OI")
                                    .frame(width: 60, alignment: .trailing)
                            }
                            .font(.caption)
                            .fontWeight(.semibold)
                            .padding(.horizontal)
                            .padding(.vertical, 8)
                            .background(Color.gray.opacity(0.1))
                            
                            // Option Contracts
                            ForEach(isCall ? chain.calls : chain.puts) { contract in
                                Button(action: { selectContract(contract) }) {
                                    HStack {
                                        Text("$\(contract.strike, specifier: "%.2f")")
                                            .frame(width: 70, alignment: .leading)
                                            .fontWeight(.medium)
                                        
                                        Text("$\(contract.bid, specifier: "%.2f")")
                                            .frame(width: 60, alignment: .trailing)
                                            .foregroundColor(.green)
                                        
                                        Text("$\(contract.ask, specifier: "%.2f")")
                                            .frame(width: 60, alignment: .trailing)
                                            .foregroundColor(.red)
                                        
                                        Text("$\(contract.last, specifier: "%.2f")")
                                            .frame(width: 60, alignment: .trailing)
                                        
                                        Text("\(contract.volume)")
                                            .frame(width: 70, alignment: .trailing)
                                            .font(.caption2)
                                        
                                        Text("\(contract.openInterest)")
                                            .frame(width: 60, alignment: .trailing)
                                            .font(.caption2)
                                    }
                                    .font(.system(size: 13, design: .monospaced))
                                    .padding(.horizontal)
                                    .padding(.vertical, 10)
                                    .background(
                                        selectedContract?.strike == contract.strike ?
                                        Color.blue.opacity(0.1) : Color.clear
                                    )
                                }
                                .buttonStyle(PlainButtonStyle())
                                
                                Divider()
                            }
                        }
                    }
                } else if isLoadingChain {
                    Spacer()
                    ProgressView("Loading option chain...")
                        .progressViewStyle(CircularProgressViewStyle())
                    Spacer()
                } else {
                    Spacer()
                    VStack(spacing: 20) {
                        Image(systemName: "list.bullet.rectangle")
                            .font(.system(size: 60))
                            .foregroundColor(.gray)
                        Text("Enter a symbol to view option chains")
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                }
            }
            .navigationTitle("Options Trading")
            .sheet(isPresented: $showingOrderSheet) {
                if let contract = selectedContract {
                    OptionOrderView(
                        symbol: symbol,
                        expiry: selectedExpiry,
                        contract: contract,
                        isCall: isCall,
                        isPresented: $showingOrderSheet
                    )
                }
            }
        }
    }
    
    private func loadExpiries() {
        isLoadingChain = true
        Task {
            do {
                let chains = try await api.searchOptions(symbol: symbol)
                await MainActor.run {
                    // Extract unique expiries from chains
                    availableExpiries = chains.map { $0.expiry }.sorted()
                    isLoadingChain = false
                }
            } catch {
                await MainActor.run {
                    isLoadingChain = false
                    print("Failed to load expiries: \(error)")
                }
            }
        }
    }
    
    private func loadOptionChain() {
        isLoadingChain = true
        Task {
            do {
                let chain = try await api.getOptionChain(symbol: symbol, expiry: selectedExpiry)
                await MainActor.run {
                    optionChain = chain
                    isLoadingChain = false
                }
            } catch {
                await MainActor.run {
                    isLoadingChain = false
                    print("Failed to load option chain: \(error)")
                }
            }
        }
    }
    
    private func selectContract(_ contract: OptionContract) {
        selectedContract = contract
        showingOrderSheet = true
    }
    
    private func formatExpiry(_ expiry: String) -> String {
        // Convert YYYYMMDD to readable format
        guard expiry.count == 8 else { return expiry }
        
        let year = String(expiry.prefix(4))
        let month = String(expiry.dropFirst(4).prefix(2))
        let day = String(expiry.suffix(2))
        
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        
        if let date = formatter.date(from: "\(year)-\(month)-\(day)") {
            formatter.dateFormat = "MMM d, yyyy"
            return formatter.string(from: date)
        }
        
        return expiry
    }
}

// Option Order Sheet
struct OptionOrderView: View {
    let symbol: String
    let expiry: String
    let contract: OptionContract
    let isCall: Bool
    @Binding var isPresented: Bool
    
    @StateObject private var api = TradingAPI.shared
    @State private var quantity = "1"
    @State private var orderType = "LMT"
    @State private var limitPrice = ""
    @State private var isBuyOrder = true
    @State private var showingResult = false
    @State private var orderResult = ""
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Contract Details")) {
                    HStack {
                        Text("Symbol:")
                        Spacer()
                        Text("\(symbol) \(formatExpiry(expiry)) \(contract.strike) \(isCall ? "C" : "P")")
                            .fontWeight(.medium)
                    }
                    
                    HStack {
                        Text("Strike:")
                        Spacer()
                        Text("$\(contract.strike, specifier: "%.2f")")
                    }
                    
                    HStack {
                        Text("Bid/Ask:")
                        Spacer()
                        Text("$\(contract.bid, specifier: "%.2f") / $\(contract.ask, specifier: "%.2f")")
                    }
                    
                    if let iv = contract.impliedVolatility as? Double {
                        HStack {
                            Text("IV:")
                            Spacer()
                            Text("\(iv * 100, specifier: "%.1f")%")
                        }
                    }
                }
                
                Section(header: Text("Order Details")) {
                    Picker("Action", selection: $isBuyOrder) {
                        Text("Buy to Open").tag(true)
                        Text("Sell to Close").tag(false)
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    
                    HStack {
                        Text("Quantity:")
                        TextField("Contracts", text: $quantity)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing)
                    }
                    
                    HStack {
                        Text("Limit Price:")
                        TextField("$0.00", text: $limitPrice)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                    }
                    .onAppear {
                        limitPrice = isBuyOrder ? 
                            String(format: "%.2f", contract.ask) : 
                            String(format: "%.2f", contract.bid)
                    }
                }
                
                Section {
                    Button(action: placeOrder) {
                        HStack {
                            Spacer()
                            Image(systemName: isBuyOrder ? "arrow.up.circle.fill" : "arrow.down.circle.fill")
                            Text("Place \(isBuyOrder ? "Buy" : "Sell") Order")
                                .fontWeight(.semibold)
                            Spacer()
                        }
                        .foregroundColor(.white)
                    }
                    .listRowBackground(isBuyOrder ? Color.green : Color.red)
                }
            }
            .navigationTitle("Option Order")
            .navigationBarItems(
                leading: Button("Cancel") { isPresented = false }
            )
            .alert("Order Result", isPresented: $showingResult) {
                Button("OK") { 
                    if orderResult.contains("successfully") {
                        isPresented = false
                    }
                }
            } message: {
                Text(orderResult)
            }
        }
    }
    
    private func placeOrder() {
        guard let qty = Int(quantity),
              let price = Double(limitPrice) else {
            orderResult = "Invalid quantity or price"
            showingResult = true
            return
        }
        
        let order = OptionOrder(
            symbol: symbol,
            expiry: expiry,
            strike: contract.strike,
            right: isCall ? "C" : "P",
            quantity: qty,
            orderType: "LMT",
            side: isBuyOrder ? "BUY" : "SELL",
            limitPrice: price
        )
        
        Task {
            do {
                let response = try await api.placeOptionOrder(order)
                await MainActor.run {
                    orderResult = "Order placed successfully!\nOrder ID: \(response.orderId)"
                    showingResult = true
                }
            } catch {
                await MainActor.run {
                    orderResult = "Failed to place order: \(error.localizedDescription)"
                    showingResult = true
                }
            }
        }
    }
    
    private func formatExpiry(_ expiry: String) -> String {
        guard expiry.count == 8 else { return expiry }
        
        let month = String(expiry.dropFirst(4).prefix(2))
        let day = String(expiry.suffix(2))
        
        return "\(month)/\(day)"
    }
}