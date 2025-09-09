import Foundation
import Combine

class TradingAPI: ObservableObject {
    static let shared = TradingAPI()
    
    // Always use Render URL for now
    let baseURL = "https://boomtrade-backend.onrender.com"  // Your Render URL
    
    @Published var isGatewayReady = false
    @Published var isAuthenticating = false
    @Published var authenticationMessage = ""
    
    private var cancellables = Set<AnyCancellable>()
    private let session = URLSession.shared
    private let decoder = JSONDecoder()
    private let encoder = JSONEncoder()
    
    // MARK: - Gateway Management
    
    func startGateway(username: String, password: String, account: String? = nil) async throws {
        print("📡 TradingAPI.startGateway called")
        print("📡 Base URL: \(baseURL)")
        
        await MainActor.run {
            isAuthenticating = true
            authenticationMessage = "Starting IBKR Gateway..."
        }
        
        let credentials = Credentials(username: username, password: password, account: account)
        let url = URL(string: "\(baseURL)/gateway/start")!
        print("📡 Request URL: \(url)")
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try encoder.encode(credentials)
        request.timeoutInterval = 120  // 2 minutes for gateway startup
        
        do {
            print("📡 Sending request to backend...")
            let (data, response) = try await session.data(for: request)
            
            if let httpResponse = response as? HTTPURLResponse {
                print("📡 Response status code: \(httpResponse.statusCode)")
            }
            
            let status = try decoder.decode(GatewayStatus.self, from: data)
            print("📡 Gateway status: \(status)")
            
            if status.status == "ready" {
                await MainActor.run {
                    isGatewayReady = true
                    authenticationMessage = "Connected to IBKR"
                }
            } else {
                throw APIError.gatewayTimeout
            }
        } catch {
            await MainActor.run {
                isAuthenticating = false
                authenticationMessage = "Failed to connect: \(error.localizedDescription)"
            }
            throw error
        }
        
        await MainActor.run {
            isAuthenticating = false
        }
    }
    
    // MARK: - Account
    
    func getAccount() async throws -> Account {
        guard isGatewayReady else { throw APIError.gatewayNotReady }
        
        let url = URL(string: "\(baseURL)/account")!
        let (data, _) = try await session.data(from: url)
        return try decoder.decode(Account.self, from: data)
    }
    
    // MARK: - Positions
    
    func getPositions() async throws -> [Position] {
        guard isGatewayReady else { throw APIError.gatewayNotReady }
        
        let url = URL(string: "\(baseURL)/positions")!
        let (data, _) = try await session.data(from: url)
        return try decoder.decode([Position].self, from: data)
    }
    
    // MARK: - Market Data
    
    func getMarketData(symbol: String) async throws -> MarketData {
        guard isGatewayReady else { throw APIError.gatewayNotReady }
        
        let url = URL(string: "\(baseURL)/marketdata/\(symbol)")!
        let (data, _) = try await session.data(from: url)
        return try decoder.decode(MarketData.self, from: data)
    }
    
    // MARK: - Options
    
    func searchOptions(symbol: String) async throws -> [OptionChain] {
        guard isGatewayReady else { throw APIError.gatewayNotReady }
        
        let url = URL(string: "\(baseURL)/options/search/\(symbol)")!
        let (data, _) = try await session.data(from: url)
        return try decoder.decode([OptionChain].self, from: data)
    }
    
    func getOptionChain(symbol: String, expiry: String) async throws -> OptionChain {
        guard isGatewayReady else { throw APIError.gatewayNotReady }
        
        let url = URL(string: "\(baseURL)/options/chain/\(symbol)/\(expiry)")!
        let (data, _) = try await session.data(from: url)
        return try decoder.decode(OptionChain.self, from: data)
    }
    
    // MARK: - Orders
    
    func placeStockOrder(_ order: StockOrder) async throws -> OrderResponse {
        guard isGatewayReady else { throw APIError.gatewayNotReady }
        
        let url = URL(string: "\(baseURL)/order/stock")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try encoder.encode(order)
        
        let (data, _) = try await session.data(for: request)
        return try decoder.decode(OrderResponse.self, from: data)
    }
    
    func placeOptionOrder(_ order: OptionOrder) async throws -> OrderResponse {
        guard isGatewayReady else { throw APIError.gatewayNotReady }
        
        let url = URL(string: "\(baseURL)/order/option")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try encoder.encode(order)
        
        let (data, _) = try await session.data(for: request)
        return try decoder.decode(OrderResponse.self, from: data)
    }
}

// MARK: - Error Handling

enum APIError: LocalizedError {
    case gatewayNotReady
    case gatewayTimeout
    case invalidResponse
    case networkError(String)
    
    var errorDescription: String? {
        switch self {
        case .gatewayNotReady:
            return "Gateway is not ready. Please authenticate first."
        case .gatewayTimeout:
            return "Gateway startup timeout. Please try again."
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
    let message: String?
}