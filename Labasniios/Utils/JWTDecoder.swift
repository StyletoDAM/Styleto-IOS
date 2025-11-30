import Foundation

struct JWTDecoder {
    static func decode(jwtToken: String) -> [String: Any]? {
        let parts = jwtToken.split(separator: ".")
        guard parts.count > 1 else { return nil }
        
        var payload = String(parts[1])
        payload = payload
            .replacingOccurrences(of: "-", with: "+")
            .replacingOccurrences(of: "_", with: "/")
        
        let padding = payload.count % 4
        if padding != 0 {
            payload += String(repeating: "=", count: 4 - padding)
        }
        
        guard let data = Data(base64Encoded: payload),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            return nil
        }
        
        return json
    }
    
    static func extractUserId(from token: String) -> String? {
        guard let payload = decode(jwtToken: token) else { return nil }
        return payload["sub"] as? String ??
               payload["userId"] as? String ??
               payload["_id"] as? String
    }
}
