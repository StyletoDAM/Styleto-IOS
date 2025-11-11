import Foundation

// MARK: - Signin / Signup
struct SigninResponse: Codable {
    let user: User
    let accessToken: String
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

struct VerifyOtpResponse: Codable {
    let message: String
    let resetToken: String
}

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
