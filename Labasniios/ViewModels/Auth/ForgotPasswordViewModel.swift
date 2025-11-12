import Foundation

@MainActor
final class ForgotPasswordViewModel: ObservableObject {
    @Published var email: String = ""
    @Published var otpCode: String = ""
    @Published var newPassword: String = ""
    @Published var confirmPassword: String = ""

    @Published private(set) var isLoading: Bool = false
    @Published private(set) var errorMessage: String?
    @Published private(set) var successMessage: String?
    @Published private(set) var maskedPhoneNumber: String?
    @Published private(set) var resendSecondsRemaining: Int = 0
    @Published var showOtpSheet: Bool = false
    @Published var showResetSheet: Bool = false

    private let authService: AuthService

    private var resetToken: String?
    nonisolated(unsafe) private var resendTimer: Timer?

    init(authService: AuthService = AuthService.shared) { // singleton
        self.authService = authService
    }

    deinit {
        stopResendTimer()
    }

    var canResendCode: Bool {
        resendSecondsRemaining == 0 && !isLoading
    }

    func requestOtp() async {
        clearFlashMessages()

        guard isValidEmail(email) else {
            errorMessage = "Invalid email address."
            return
        }

        isLoading = true
        defer { isLoading = false }

        do {
            let response = try await authService.requestForgotPassword(email: trimmed(email.lowercased()))
            // Ici, si ton API renvoie un numéro masqué, sinon ignore
            maskedPhoneNumber = response.maskedPhoneNumber
            successMessage = response.message
            showOtpSheet = true
            otpCode = ""
            startResendCountdown()
        } catch let network as NetworkError {
            errorMessage = network.errorDescription
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func resendOtp() async {
        guard canResendCode else { return }
        await requestOtp()
    }

    func verifyOtp() async {
        clearFlashMessages()

        guard otpCode.count == 6 else {
            errorMessage = "The code must be 6 digits."
            return
        }

        isLoading = true
        defer { isLoading = false }

        do {
            let response = try await authService.verifyOtp(
                email: trimmed(email.lowercased()),
                code: otpCode
            )
            resetToken = response.resetToken
            successMessage = response.message
            showOtpSheet = false
            showResetSheet = true
            stopResendTimer()
            resetResendCountdown()
        } catch let network as NetworkError {
            errorMessage = network.errorDescription
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func resetPassword() async {
        clearFlashMessages()

        guard let resetToken else {
            errorMessage = "Please verify the code before setting a new password."
            return
        }

        guard isStrongPassword(newPassword) else {
            errorMessage = "Password must be at least 6 characters, include an uppercase letter and a special character."
            return
        }

        guard newPassword == confirmPassword else {
            errorMessage = "Passwords do not match."
            return
        }

        isLoading = true
        defer { isLoading = false }

        do {
            let response = try await authService.resetPassword(resetToken: resetToken, newPassword: newPassword)
            successMessage = response.message
            showResetSheet = false
            clearSensitive()
            AppPreferences.shared.isLoggedIn = false
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                NotificationCenter.default.post(name: .didRequestNavigateToLogin, object: nil)
            }
        } catch let network as NetworkError {
            errorMessage = network.errorDescription
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func clearFlashMessages() {
        errorMessage = nil
        successMessage = nil
    }

    private func startResendCountdown(duration: Int = 60) {
        stopResendTimer()
        resendSecondsRemaining = duration
        guard duration > 0 else { return }

        resendTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] timer in
            guard let self else {
                timer.invalidate()
                return
            }
            Task { @MainActor [weak self] in
                guard let self else { return }
                if self.resendSecondsRemaining > 0 {
                    self.resendSecondsRemaining -= 1
                } else {
                    timer.invalidate()
                }
            }
        }
    }

    nonisolated func stopResendTimer() {
        resendTimer?.invalidate()
        resendTimer = nil
    }

    private func resetResendCountdown() {
        resendSecondsRemaining = 0
    }

    private func clearSensitive() {
        otpCode = ""
        newPassword = ""
        confirmPassword = ""
        resetToken = nil
    }

    private func trimmed(_ value: String) -> String {
        value.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func isValidEmail(_ value: String) -> Bool {
        let pattern = #"^[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$"#
        return value.range(of: pattern, options: .regularExpression) != nil
    }

    private func isStrongPassword(_ value: String) -> Bool {
        let hasMinLength = value.count >= 6
        let hasUppercase = value.range(of: "[A-Z]", options: .regularExpression) != nil
        let hasSpecial = value.range(of: "[!@#$%^&*()_+\\-={}\\[\\]|\\\\:\";'<>?,./]", options: .regularExpression) != nil
        return hasMinLength && hasUppercase && hasSpecial
    }
}
