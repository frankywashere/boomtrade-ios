import Foundation
import Combine

class TradingAPI: ObservableObject {
    static let shared = TradingAPI()
    
    // Local backend URL - runs on your Mac
    let baseURL = "http://127.0.0.1:8000"
    
    @Published var isConnected = false
    @Published var isConnecting = false
    @Published var connectionMessage = ""
    @Published var accountInfo: Account?
    @Published var serverVersion: Int?
    
    private var cancellables = Set<AnyCancellable>()
    private let session = URLSession.shared
    private let decoder = JSONDecoder()
    private let encoder = JSONEncoder()
    
    // MARK: - Connection Management
    
    func connectToTWS(port: Int = 7497) async throws {
        print("📡 Connecting to TWS on port \(port)")
        
        await MainActor.run {
            isConnecting = true
            connectionMessage = "Connecting to TWS..."
        }
        
        let config = ConnectionConfig(host: "127.0.0.1", port: port, clientId: 1)
        let url = URL(string: "\(baseURL)/connect")!
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try encoder.encode(config)
        request.timeoutInterval = 10
        
        do {
            let (data, response) = try await session.data(for: request)
            
            if let httpResponse = response as? HTTPURLResponse {
                print("📡 Response status code: \(httpResponse.statusCode)")
            }
            
            let status = try decoder.decode(ConnectionStatus.self, from: data)
            print("📡 Connection status: \(status)")
            
            if status.status == "connected" {
                await MainActor.run {
                    isConnected = true
                    serverVersion = status.serverVersion
                    connectionMessage = "Connected to TWS"
                }
                
                // Fetch account info
                try? await fetchAccountInfo()
            } else {
                throw APIError.connectionFailed("Failed to connect to TWS")
            }
        } catch {
            await MainActor.run {
                isConnecting = false
                connectionMessage = "Connection failed: \(error.localizedDescription)"
            }
            throw error
        }
        
        await MainActor.run {
            isConnecting = false
        }
    }
    
    func disconnect() async throws {
        let url = URL(string: "\(baseURL)/disconnect")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        
        _ = try await session.data(for: request)
        
        await MainActor.run {
            isConnected = false
            connectionMessage = "Disconnected"
            accountInfo = nil
        }
    }
    
    // MARK: - Account
    
    func fetchAccountInfo() async throws {
        guard isConnected else { throw APIError.notConnected }
        
        let url = URL(string: "\(baseURL)/account")!
        let (data, _) = try await session.data(from: url)
        let account = try decoder.decode(Account.self, from: data)
        
        await MainActor.run {
            self.accountInfo = account
        }
    }
    
    func getAccount() async throws -> Account {
        guard isConnected else { throw APIError.notConnected }
        
        let url = URL(string: "\(baseURL)/account")!
        let (data, _) = try await session.data(from: url)
        return try decoder.decode(Account.self, from: data)
    }
    
    // MARK: - Positions
    
    func getPositions() async throws -> [Position] {
        guard isConnected else { throw APIError.notConnected }
        
        let url = URL(string: "\(baseURL)/positions")!
        let (data, _) = try await session.data(from: url)
        return try decoder.decode([Position].self, from: data)
    }
    
    // MARK: - Market Data
    
    func getMarketData(symbol: String) async throws -> MarketData {
        guard isConnected else { throw APIError.notConnected }
        
        let url = URL(string: "\(baseURL)/market-data/\(symbol)")!
        let (data, _) = try await session.data(from: url)
        return try decoder.decode(MarketData.self, from: data)
    }
    
    // MARK: - Options
    
    func searchOptions(symbol: String) async throws -> [OptionChain] {
        guard isConnected else { throw APIError.notConnected }
        
        let url = URL(string: "\(baseURL)/options/search/\(symbol)")!
        let (data, _) = try await session.data(from: url)
        return try decoder.decode([OptionChain].self, from: data)
    }
    
    func getOptionChain(symbol: String, expiry: String) async throws -> OptionChain {
        guard isConnected else { throw APIError.notConnected }
        
        let url = URL(string: "\(baseURL)/options/chain/\(symbol)/\(expiry)")!
        let (data, _) = try await session.data(from: url)
        return try decoder.decode(OptionChain.self, from: data)
    }
    
    // MARK: - Orders
    
    func placeStockOrder(_ order: StockOrder) async throws -> OrderResponse {
        guard isConnected else { throw APIError.notConnected }
        
        let url = URL(string: "\(baseURL)/order/stock")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try encoder.encode(order)
        
        let (data, _) = try await session.data(for: request)
        return try decoder.decode(OrderResponse.self, from: data)
    }
    
    func placeOptionOrder(_ order: OptionOrder) async throws -> OrderResponse {
        guard isConnected else { throw APIError.notConnected }
        
        let url = URL(string: "\(baseURL)/order/option")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try encoder.encode(order)
        
        let (data, _) = try await session.data(for: request)
        return try decoder.decode(OrderResponse.self, from: data)
    }
    
    func getOpenOrders() async throws -> [OpenOrder] {
        guard isConnected else { throw APIError.notConnected }
        
        let url = URL(string: "\(baseURL)/orders")!
        let (data, _) = try await session.data(from: url)
        return try decoder.decode([OpenOrder].self, from: data)
    }
}

// MARK: - Models

struct ConnectionConfig: Codable {
    let host: String
    let port: Int
    let clientId: Int
    
    init(host: String = "127.0.0.1", port: Int = 7497, clientId: Int = 1) {
        self.host = host
        self.port = port
        self.clientId = clientId
    }
}

struct ConnectionStatus: Codable {
    let status: String
    let accounts: [String]?
    let serverVersion: Int?
    let connectionTime: String?
    let marketDataAvailable: Bool?
    
    private enum CodingKeys: String, CodingKey {
        case status, accounts
        case serverVersion = "server_version"
        case connectionTime = "connection_time"
        case marketDataAvailable = "market_data_available"
    }
}

struct OpenOrder: Codable {
    let orderId: String
    let symbol: String
    let action: String
    let quantity: Double
    let orderType: String
    let status: String?
    let limitPrice: Double?
    
    private enum CodingKeys: String, CodingKey {
        case orderId = "order_id"
        case symbol, action, quantity
        case orderType = "order_type"
        case status
        case limitPrice = "limit_price"
    }
}

// MARK: - Error Handling

enum APIError: LocalizedError {
    case notConnected
    case connectionFailed(String)
    case invalidResponse
    case networkError(String)
    
    var errorDescription: String? {
        switch self {
        case .notConnected:
            return "Not connected to TWS. Please connect first."
        case .connectionFailed(let message):
            return "Connection failed: \(message)"
        case .invalidResponse:
            return "Invalid response from server."
        case .networkError(let message):
            return "Network error: \(message)"
        }
    }
}

// MARK: - Order Response

struct OrderResponse: Codable {
    let orderId: String
    let status: String
    let contract: String?
    let action: String?
    let quantity: Int?
    
    private enum CodingKeys: String, CodingKey {
        case orderId = "order_id"
        case status, contract, action, quantity
    }
}