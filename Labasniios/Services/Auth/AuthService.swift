import Foundation
import AuthenticationServices
import SwiftUI
import UIKit
import GoogleSignIn
import GoogleSignInSwift

@MainActor
final class AuthService: NSObject, ObservableObject {
    
    static let shared = AuthService()
    
    private let session: URLSession
    private let encoder: JSONEncoder
    private let decoder: JSONDecoder
    
    // MARK: - Publishers pour la UI
    @Published var errorMessage: String?
    @Published var isLoading: Bool = false
    
    // Callbacks
    var onSuccess: ((SigninResponse) -> Void)?
    var onError: ((Error) -> Void)?
    
    private override init() {
        self.session = .shared
        self.encoder = JSONEncoder()
        self.encoder.keyEncodingStrategy = .useDefaultKeys
        self.decoder = JSONDecoder()
        self.decoder.keyDecodingStrategy = .convertFromSnakeCase
        self.decoder.dateDecodingStrategy = .iso8601
    }
    
    // MARK: - Signin / Signup
    func signin(email: String, password: String) async throws -> SigninResponse {
        let payload = ["email": email, "password": password]
        return try await performRequest(path: APIConstants.signinPath, payload: payload, responseType: SigninResponse.self)
    }
    
    func signup(fullName: String, email: String, password: String, gender: User.Gender, phoneNumber: String, preferences: [String]? = nil) async throws -> SignupResponse {
        var payload: [String: Any] = [
            "fullName": fullName,
            "email": email,
            "password": password,
            "gender": gender.rawValue,
            "phoneNumber": phoneNumber
        ]
        if let prefs = preferences { payload["preferences"] = prefs }
        return try await performRequest(path: APIConstants.signupPath, payload: payload, responseType: SignupResponse.self)
    }
    
    // MARK: - Apple Sign In
    func signInWithApple(credential: ASAuthorizationAppleIDCredential) async {
        isLoading = true
        defer { isLoading = false }
        let appleId = credential.user
        let fullName = [credential.fullName?.givenName, credential.fullName?.familyName].compactMap { $0 }.joined(separator: " ")
        let email = credential.email ?? ""
        do {
            let response = try await authenticateApple(appleId: appleId, fullName: fullName, email: email)
            onSuccess?(response)
        } catch {
            errorMessage = error.localizedDescription
            onError?(error)
        }
    }
    
    private func authenticateApple(appleId: String, fullName: String, email: String) async throws -> SigninResponse {
        let payload: [String: Any] = [
            "identityToken": appleId,
            "fullName": fullName,
            "email": email
        ]
        return try await performRequest(path: APIConstants.appleAuthPath, payload: payload, responseType: SigninResponse.self)
    }
    
    // MARK: - Google Sign In
    func signInWithGoogle(user: GIDGoogleUser) async {
        isLoading = true
        defer { isLoading = false }
        guard let profile = user.profile else { return }
        let googleId = user.userID ?? ""
        let fullName = profile.name
        let email = profile.email
        let profilePicture = profile.hasImage ? profile.imageURL(withDimension: 320)?.absoluteString : nil
        
        do {
            let response = try await authenticateGoogle(googleId: googleId, fullName: fullName, email: email, profilePicture: profilePicture)
            onSuccess?(response)
        } catch {
            errorMessage = error.localizedDescription
            onError?(error)
        }
    }
    
    private func authenticateGoogle(googleId: String, fullName: String, email: String, profilePicture: String?) async throws -> SigninResponse {
        let payload: [String: Any] = [
            "googleId": googleId,
            "fullName": fullName,
            "email": email,
            "profilePicture": profilePicture ?? ""
        ]
        return try await performRequest(path: APIConstants.googleAuthPath, payload: payload, responseType: SigninResponse.self)
    }
    
    // MARK: - Forgot Password / Verify OTP / Reset Password
    func requestForgotPassword(email: String) async throws -> ForgotPasswordResponse {
        let payload = ["email": email]
        return try await performRequest(path: APIConstants.forgotPasswordPath, payload: payload, responseType: ForgotPasswordResponse.self)
    }
    
    func verifyOtp(email: String, code: String) async throws -> VerifyOtpResponse {
        let payload = ["email": email, "code": code]
        return try await performRequest(path: APIConstants.verifyOtpPath, payload: payload, responseType: VerifyOtpResponse.self)
    }
    
    func resetPassword(resetToken: String, newPassword: String) async throws -> ResetPasswordResponse {
        let payload = ["resetToken": resetToken, "newPassword": newPassword]
        return try await performRequest(path: APIConstants.resetPasswordPath, payload: payload, responseType: ResetPasswordResponse.self)
    }
    
    // MARK: - Verify Email
    func verifyEmail(tempToken: String, code: String) async throws -> VerifyEmailResponse {
        let payload = ["tempToken": tempToken, "code": code]
        return try await performRequest(path: APIConstants.verifyEmailPath, payload: payload, responseType: VerifyEmailResponse.self)
    }
    
    // MARK: - Private Helper
    private func performRequest<T: Decodable>(path: String, payload: [String: Any], responseType: T.Type) async throws -> T {
        guard let url = URL(string: path, relativeTo: APIConstants.baseURL) else { throw NetworkError.invalidURL }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue(APIConstants.jsonContentType, forHTTPHeaderField: "Content-Type")
        request.addValue(APIConstants.jsonContentType, forHTTPHeaderField: "Accept")
        request.httpBody = try JSONSerialization.data(withJSONObject: payload)
        
        let (data, response) = try await session.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else { throw NetworkError.noData }
        
        switch httpResponse.statusCode {
        case 200..<300:
            return try decoder.decode(T.self, from: data)
        default:
            if let serverError = try? decoder.decode(ErrorResponse.self, from: data) {
                throw NetworkError.serverMessage(serverError.message)
            }
            throw NetworkError.requestFailed(httpResponse.statusCode)
        }
    }
    // MARK: - Apple Sign In Helper
    func authenticateWithApple(appleId: String, fullName: String, email: String, profilePicture: String?, gender: String?) async throws -> SigninResponse {
        // Appelle la méthode privée existante
        return try await authenticateApple(appleId: appleId, fullName: fullName, email: email)
    }
    
    // MARK: - Google Sign In Helper
    func authenticateWithGoogle(googleId: String, fullName: String, email: String, profilePicture: String?, gender: String?) async throws -> SigninResponse {
        // Appelle la méthode privée existante
        return try await authenticateGoogle(googleId: googleId, fullName: fullName, email: email, profilePicture: profilePicture)
    }
    
    // ✨ NOUVEAU : Refresh Token
    func refreshToken() async throws -> (accessToken: String, refreshToken: String) {
        guard let refreshToken = TokenManager.shared.getRefreshToken() else {
            throw NetworkError.serverMessage("Refresh token manquant.")
        }
        
        let payload = ["refreshToken": refreshToken]
        guard let url = URL(string: "/auth/refresh", relativeTo: APIConstants.baseURL) else {
            throw NetworkError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue(APIConstants.jsonContentType, forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONSerialization.data(withJSONObject: payload)
        
        let (data, response) = try await session.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw NetworkError.noData
        }
        
        switch httpResponse.statusCode {
        case 200..<300:
            struct RefreshResponse: Codable {
                let accessToken: String
                let refreshToken: String
            }
            let refreshResponse = try decoder.decode(RefreshResponse.self, from: data)
            TokenManager.shared.saveToken(refreshResponse.accessToken)
            TokenManager.shared.saveRefreshToken(refreshResponse.refreshToken)
            return (refreshResponse.accessToken, refreshResponse.refreshToken)
        default:
            // Refresh échoué, déconnecter l'utilisateur
            TokenManager.shared.clearToken()
            throw NetworkError.serverMessage("Token de rafraîchissement invalide.")
        }
    }
}

