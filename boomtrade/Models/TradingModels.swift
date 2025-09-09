import Foundation

// MARK: - Authentication
struct Credentials: Codable {
    let username: String
    let password: String
    let account: String?
}

struct GatewayStatus: Codable {
    let status: String
    let message: String
}

// MARK: - Account
struct Account: Codable {
    let id: String
    let accountType: String
    let currency: String
}

// MARK: - Orders
struct StockOrder: Codable {
    let symbol: String
    let quantity: Int
    let orderType: String  // MKT, LMT, STP, TRAIL, etc.
    let side: String  // BUY, SELL
    let limitPrice: Double?
    let stopPrice: Double?
    let timeInForce: String  // DAY, GTC, IOC, FOK
    
    enum CodingKeys: String, CodingKey {
        case symbol, quantity
        case orderType = "order_type"
        case side
        case limitPrice = "limit_price"
        case stopPrice = "stop_price"
        case timeInForce = "time_in_force"
    }
}

struct OptionOrder: Codable {
    let symbol: String  // Underlying
    let expiry: String  // YYYYMMDD
    let strike: Double
    let right: String  // C or P
    let quantity: Int
    let orderType: String
    let side: String
    let limitPrice: Double?
    
    enum CodingKeys: String, CodingKey {
        case symbol, expiry, strike, right, quantity
        case orderType = "order_type"
        case side
        case limitPrice = "limit_price"
    }
}

// MARK: - Market Data
struct MarketData: Codable {
    let symbol: String
    let last: Double
    let bid: Double
    let ask: Double
    let volume: Int
    let open: Double
    let high: Double
    let low: Double
    let close: Double
}

// MARK: - Options
struct OptionChain: Codable {
    let symbol: String
    let expiry: String
    let calls: [OptionContract]
    let puts: [OptionContract]
}

struct OptionContract: Codable, Identifiable {
    let id = UUID()
    let strike: Double
    let bid: Double
    let ask: Double
    let last: Double
    let volume: Int
    let openInterest: Int
    let impliedVolatility: Double
    let delta: Double?
    let gamma: Double?
    let theta: Double?
    let vega: Double?
    
    enum CodingKeys: String, CodingKey {
        case strike, bid, ask, last, volume
        case openInterest = "open_interest"
        case impliedVolatility = "implied_volatility"
        case delta, gamma, theta, vega
    }
}

// MARK: - Positions
struct Position: Codable, Identifiable {
    let id = UUID()
    let symbol: String
    let quantity: Int
    let averagePrice: Double
    let currentPrice: Double
    let unrealizedPnL: Double
    let realizedPnL: Double
    
    var totalValue: Double {
        return Double(quantity) * currentPrice
    }
    
    var percentChange: Double {
        return ((currentPrice - averagePrice) / averagePrice) * 100
    }
    
    enum CodingKeys: String, CodingKey {
        case symbol, quantity
        case averagePrice = "average_price"
        case currentPrice = "current_price"
        case unrealizedPnL = "unrealized_pnl"
        case realizedPnL = "realized_pnl"
    }
}

// MARK: - Order Types
enum OrderType: String, CaseIterable {
    case market = "MKT"
    case limit = "LMT"
    case stop = "STP"
    case stopLimit = "STP_LMT"
    case trailing = "TRAIL"
    case marketIfTouched = "MIT"
    case limitIfTouched = "LIT"
    
    var displayName: String {
        switch self {
        case .market: return "Market"
        case .limit: return "Limit"
        case .stop: return "Stop"
        case .stopLimit: return "Stop Limit"
        case .trailing: return "Trailing Stop"
        case .marketIfTouched: return "Market if Touched"
        case .limitIfTouched: return "Limit if Touched"
        }
    }
}

enum TimeInForce: String, CaseIterable {
    case day = "DAY"
    case goodTillCanceled = "GTC"
    case immediateOrCancel = "IOC"
    case fillOrKill = "FOK"
    
    var displayName: String {
        switch self {
        case .day: return "Day"
        case .goodTillCanceled: return "Good Till Canceled"
        case .immediateOrCancel: return "Immediate or Cancel"
        case .fillOrKill: return "Fill or Kill"
        }
    }
}