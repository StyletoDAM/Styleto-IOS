import Foundation
@testable import Labasniios

/// Protocol pour AuthService (facilite les tests)
@MainActor
protocol AuthServiceProtocol {
    func signin(email: String, password: String) async throws -> SigninResponse
}

/// Extension pour que AuthService respecte le protocol
extension AuthService: AuthServiceProtocol {}

/// Helper pour créer des User dans les tests
extension User {
    /// Crée un User pour les tests
    static func testUser(
        id: String = "test_user_id",
        fullName: String = "Test User",
        email: String = "test@example.com",
        gender: Gender = .female,
        preferences: [String] = [],
        phoneNumber: String? = nil,
        createdAt: Date? = nil,
        updatedAt: Date? = nil,
        authProvider: AuthProvider? = .local,
        googleId: String? = nil,
        appleId: String? = nil,
        profilePicture: String? = nil,
        balance: Double? = 0.0
    ) -> User {
        // Créer un JSON pour décoder
        var json: [String: Any] = [
            "id": id,
            "fullName": fullName,
            "email": email,
            "gender": gender.rawValue,
            "preferences": preferences
        ]
        
        if let phoneNumber = phoneNumber {
            json["phoneNumber"] = phoneNumber
        }
        if let createdAt = createdAt {
            let formatter = ISO8601DateFormatter()
            json["createdAt"] = formatter.string(from: createdAt)
        }
        if let updatedAt = updatedAt {
            let formatter = ISO8601DateFormatter()
            json["updatedAt"] = formatter.string(from: updatedAt)
        }
        if let authProvider = authProvider {
            json["authProvider"] = authProvider.rawValue
        }
        if let googleId = googleId {
            json["googleId"] = googleId
        }
        if let appleId = appleId {
            json["appleId"] = appleId
        }
        if let profilePicture = profilePicture {
            json["profilePicture"] = profilePicture
        }
        if let balance = balance {
            json["balance"] = balance
        }
        
        let jsonData = try! JSONSerialization.data(withJSONObject: json)
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try! decoder.decode(User.self, from: jsonData)
    }
}

/// Mock de AuthService pour les tests unitaires
@MainActor
class MockAuthService: NSObject, ObservableObject, AuthServiceProtocol {
    var shouldSucceed = true
    var mockUser: User?
    var mockAccessToken = "mock_access_token_123"
    var mockRefreshToken = "mock_refresh_token_123"
    var mockError: Error?
    
    func signin(email: String, password: String) async throws -> SigninResponse {
        // Simuler un délai réseau
        try await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconde
        
        if shouldSucceed {
            let user = mockUser ?? User.testUser(email: email)
            return SigninResponse(
                user: user,
                accessToken: mockAccessToken,
                refreshToken: mockRefreshToken
            )
        } else {
            throw mockError ?? NetworkError.serverMessage("Invalid credentials")
        }
    }
}

