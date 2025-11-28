// Models/DTOs/SubscriptionDTO.swift
import Foundation

enum SubscriptionPlan: String, Codable {
    case free = "FREE"
    case premium = "PREMIUM"
    case proSeller = "PRO_SELLER"
    
    var displayName: String {
        switch self {
        case .free: return "Free Pack"
        case .premium: return "Premium"
        case .proSeller: return "Pro Seller"
        }
    }
}

struct SubscriptionResponse: Codable {
    let plan: SubscriptionPlan
    let subscribedAt: Date
    let expiresAt: Date?
    let isActive: Bool
}

struct UsageStatsResponse: Codable {
    let plan: SubscriptionPlan
    let currentMonth: String
    
    let clothesDetection: UsageItem
    let outfitSuggestions: UsageItem
    let storeSelling: UsageItem
    
    let subscribedAt: Date
    let expiresAt: Date?
    let isActive: Bool
}

// Models/DTOs/SubscriptionDTO.swift  (remplace juste cette partie UsageItem)

struct UsageItem: Codable {
    let used: Int
    let limit: StringOrNumber    // accepte String OU Int
    let remaining: StringOrNumber // accepte String OU Int
    
    // Propriétés pratiques pour l'UI
    var isUnlimited: Bool {
        switch limit {
        case .string(let str): return str.lowercased() == "unlimited"
        case .number(let num): return num == -1
        }
    }
    
    var limitCount: Int? {
        switch limit {
        case .string: return nil
        case .number(let num): return num == -1 ? nil : num
        }
    }
    
    var remainingCount: Int? {
        switch remaining {
        case .string(let str): return Int(str)
        case .number(let num): return num
        }
    }
}

// MARK: - Type magique qui accepte String OU Int/Float
enum StringOrNumber: Codable {
    case string(String)
    case number(Int)
    
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        
        if let intValue = try? container.decode(Int.self) {
            self = .number(intValue)
            return
        }
        if let stringValue = try? container.decode(String.self) {
            self = .string(stringValue)
            return
        }
        throw DecodingError.typeMismatch(StringOrNumber.self, DecodingError.Context(
            codingPath: decoder.codingPath,
            debugDescription: "Expected String or Number"
        ))
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case .string(let value): try container.encode(value)
        case .number(let value): try container.encode(value)
        }
    }
}

// MARK: - Type qui accepte String OU Int
enum StringOrInt: Codable {
    case string(String)
    case int(Int)
    
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let intValue = try? container.decode(Int.self) {
            self = .int(intValue)
        } else if let stringValue = try? container.decode(String.self) {
            self = .string(stringValue)
        } else {
            throw DecodingError.typeMismatch(StringOrInt.self, DecodingError.Context(codingPath: decoder.codingPath, debugDescription: "Expected String or Int"))
        }
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case .string(let value): try container.encode(value)
        case .int(let value): try container.encode(value)
        }
    }
}

struct PurchaseSimulationRequest: Codable {
    let cardNumber: String
    let expiryDate: String
    let cvv: String
    let cardholderName: String
}

struct PurchaseSimulationResponse: Codable {
    let success: Bool
    let message: String
    let transaction: TransactionInfo?
    let subscription: SubscriptionResponse?
}

struct TransactionInfo: Codable {
    let id: String
    let amount: Int
    let currency: String
    let plan: SubscriptionPlan
    let date: String
    let cardLast4: String
}

struct QuotaCheckResult: Codable {
    let allowed: Bool
    let remaining: String?
    let limit: String?
    let plan: SubscriptionPlan
    let message: String?
}
