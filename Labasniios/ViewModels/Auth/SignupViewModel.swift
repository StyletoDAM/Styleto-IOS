import Foundation

@MainActor
final class SignupViewModel: ObservableObject {
    @Published var fullName = ""
    @Published var email = ""
    @Published var password = ""
    @Published var phoneNumber = ""
    @Published var selectedGender: User.Gender?
    @Published var selectedDialCode: CountryDialCode = .default

    @Published private(set) var isLoading = false
    @Published private(set) var errorMessage: String?
    @Published private(set) var successMessage: String?
    @Published private(set) var needsAcceptance = false

    @Published var tempToken: String = ""
    @Published var showPinEntry = false
    @Published var pinCode = ""
    @Published var pinError: String?
    @Published private(set) var navigateToLogin = false
    @Published private(set) var resendSecondsRemaining: Int = 0

    private let authService: AuthService
    nonisolated(unsafe) private var resendTimer: Timer?

    init(authService: AuthService = AuthService.shared) {
        self.authService = authService
    }

    deinit {
        stopResendTimer()
    }

    func selectGender(_ gender: User.Gender) {
        selectedGender = gender
    }

    var dialCodes: [CountryDialCode] {
        CountryDialCode.presets
    }

    var isPasswordStrong: Bool {
        isStrongPassword(password)
    }

    var canResendCode: Bool {
        resendSecondsRemaining == 0 && !isLoading
    }

    var formattedPhoneNumber: String {
        let digits = sanitizedPhoneDigits()
        guard !digits.isEmpty else { return "" }
        return "\(selectedDialCode.dialCode)\(digits)"
    }

    func attemptSignup() {
        resetMessages()
        guard validateFields() else { return }
        needsAcceptance = true
    }

    func performSignupAfterAcceptance() async {
        resetMessages()
        needsAcceptance = false
        pinError = nil
        pinCode = ""

        guard !formattedPhoneNumber.isEmpty else {
            errorMessage = "Numéro de téléphone invalide."
            return
        }

        isLoading = true
        defer { isLoading = false }

        do {
            guard let gender = selectedGender else {
                throw ValidationError.missingGender
            }

            let response = try await authService.signup(
                fullName: trimmed(fullName),
                email: trimmed(email.lowercased()),
                password: password,
                gender: gender,
                phoneNumber: formattedPhoneNumber,
                preferences: nil
            )

            successMessage = response.message
            tempToken = response.tempToken
            showPinEntry = true
            startResendCountdown()
        } catch let validation as ValidationError {
            errorMessage = validation.message
        } catch let network as NetworkError {
            errorMessage = network.errorDescription
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func resendVerificationCode() async {
        guard canResendCode else { return }
        pinError = nil

        isLoading = true
        defer { isLoading = false }

        do {
            guard let gender = selectedGender else {
                throw ValidationError.missingGender
            }

            guard !formattedPhoneNumber.isEmpty else {
                throw ValidationError.invalidPhone
            }

            let response = try await authService.signup(
                fullName: trimmed(fullName),
                email: trimmed(email.lowercased()),
                password: password,
                gender: gender,
                phoneNumber: formattedPhoneNumber,
                preferences: nil
            )

            tempToken = response.tempToken
            successMessage = response.message
            startResendCountdown()
        } catch let validation as ValidationError {
            pinError = validation.message
        } catch let network as NetworkError {
            pinError = network.errorDescription
        } catch {
            pinError = error.localizedDescription
        }
    }

    func verifyPinCode() async {
        pinError = nil
        isLoading = true
        defer { isLoading = false }

        do {
            try await authService.verifyEmail(tempToken: tempToken, code: pinCode)
            showPinEntry = false
            stopResendTimer()
            resetResendCountdown()
            clearSensitiveFields()
            navigateToLogin = true
        } catch let network as NetworkError {
            pinError = network.errorDescription
        } catch {
            pinError = "Code invalide ou expiré."
        }
    }

    func resetFeedback() {
        errorMessage = nil
        successMessage = nil
        needsAcceptance = false
    }

    func pushBlockingError(_ message: String) {
        errorMessage = message
    }

    func resetMessages() {
        resetFeedback()
        pinError = nil
    }

    private func validateFields() -> Bool {
        guard !trimmed(fullName).isEmpty else {
            errorMessage = "Le nom complet est requis."
            return false
        }

        guard isValidEmail(email) else {
            errorMessage = "Adresse email invalide."
            return false
        }

        guard isStrongPassword(password) else {
            errorMessage = "Le mot de passe doit contenir au moins 6 caractères, une majuscule et un caractère spécial."
            return false
        }

        guard sanitizedPhoneDigits().count >= 6 else {
            errorMessage = "Le numéro de téléphone est requis (6 chiffres minimum)."
            return false
        }

        guard selectedGender != nil else {
            errorMessage = "Veuillez sélectionner un sexe."
            return false
        }

        return true
    }

    private func trimmed(_ value: String) -> String {
        value.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func sanitizedPhoneDigits() -> String {
        trimmed(phoneNumber).filter { $0.isNumber }
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

    private func startResendCountdown(duration: Int = 60) {
        stopResendTimer()
        resendSecondsRemaining = duration
        guard duration > 0 else { return }

        resendTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] timer in
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

    private func clearSensitiveFields() {
        password = ""
        phoneNumber = ""
    }

    private enum ValidationError: Error {
        case missingGender
        case invalidPhone

        var message: String {
            switch self {
            case .missingGender:
                return "Veuillez sélectionner un sexe."
            case .invalidPhone:
                return "Numéro de téléphone invalide."
            }
        }
    }
}

struct CountryDialCode: Identifiable, Hashable {
    let id: String
    let name: String
    let dialCode: String

    static let presets: [CountryDialCode] = [
        CountryDialCode(id: "tn", name: "Tunisie (+216)", dialCode: "+216"),
        CountryDialCode(id: "fr", name: "France (+33)", dialCode: "+33"),
        CountryDialCode(id: "ma", name: "Maroc (+212)", dialCode: "+212"),
        CountryDialCode(id: "dz", name: "Algérie (+213)", dialCode: "+213"),
    ]

    static let `default`: CountryDialCode =
        presets.first ?? CountryDialCode(id: "tn", name: "Tunisie (+216)", dialCode: "+216")
}
