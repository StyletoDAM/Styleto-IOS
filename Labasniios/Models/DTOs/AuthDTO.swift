import Foundation

// MARK: - Signin / Signup
struct SigninResponse: Codable {
    let user: User
    let accessToken: String
    let refreshToken: String // ✨ NOUVEAU : Refresh token pour renouveler l'access token
}

struct SignupResponse: Codable {
    let message: String
    let tempToken: String
}

// MARK: - Forgot Password Flow
struct ForgotPasswordResponse: Codable {
    let message: String
    let maskedPhoneNumber: String?
    let expiresAt: Date?
}

// MARK: - Verify Otp
struct VerifyOtpResponse: Codable {
    let message: String
    let resetToken: String
}

// MARK: - Reset Password
struct ResetPasswordResponse: Codable {
    let message: String
}

// MARK: - Verify Email
struct VerifyEmailResponse: Codable {
    let message: String
    let user: UserResponse
}

struct UserResponse: Codable {
    let id: String
    let fullName: String
    let email: String
    let gender: String
}
