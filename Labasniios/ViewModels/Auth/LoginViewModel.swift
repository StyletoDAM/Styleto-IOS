import Combine
import Foundation

@MainActor
final class LoginViewModel: ObservableObject {
    @Published var email: String = ""
    @Published var password: String = ""

    @Published private(set) var isLoading: Bool = false
    @Published private(set) var errorMessage: String?
    @Published private(set) var signedInUser: User?
    @Published private(set) var accessToken: String?

    private let authService: AuthService  

    init(authService: AuthService = AuthService.shared) { // utilise le singleton par défaut
        self.authService = authService
    }

    func signin() async {
        resetFeedback()

        guard validateFields() else { return }

        isLoading = true
        defer { isLoading = false }

        do {
            let response = try await authService.signin(
                email: email.lowercased().trimmingCharacters(in: .whitespacesAndNewlines),
                password: password
            )
            debugPrint("[LoginViewModel] Signed in user: \(response.user.email)")
            signedInUser = response.user
            accessToken = response.accessToken
            TokenManager.shared.saveToken(response.accessToken)
            TokenManager.shared.saveRefreshToken(response.refreshToken) // ✨ NOUVEAU
        } catch let networkError as NetworkError {
            errorMessage = networkError.errorDescription ?? "An error occurred."
            debugPrint("[LoginViewModel] Network error: \(errorMessage ?? "")")
        } catch {
            errorMessage = error.localizedDescription
            debugPrint("[LoginViewModel] Unexpected error: \(error.localizedDescription)")
        }
    }

    func resetFeedback() {
        errorMessage = nil
        signedInUser = nil
        accessToken = nil
    }

    private func validateFields() -> Bool {
        guard isValidEmail(email) else {
            errorMessage = "Invalid email address."
            return false
        }

        guard password.count >= 6 else {
            errorMessage = "Password is too short."
            return false
        }

        return true
    }

    private func isValidEmail(_ value: String) -> Bool {
        let pattern = #"^[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$"#
        return value.range(of: pattern, options: .regularExpression) != nil
    }
}
