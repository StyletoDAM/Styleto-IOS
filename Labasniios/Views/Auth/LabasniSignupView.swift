import SwiftUI
import UIKit

// MARK: - Vue principale
struct LabasniSignupView: View {
    private enum GenderOption: String, CaseIterable {
        case female = "Female", male = "Male"
    }
    
    @StateObject private var viewModel = SignupViewModel()
    @State private var selectedGender: GenderOption?
    @State private var showTermsSheet = false
    @State private var attemptedSubmit = false
    @State private var navigateToLogin = false
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        ZStack {
            // Fond doux rosé → blanc
            LinearGradient(colors: [Color.e8aabe.opacity(0.35), .white],
                           startPoint: .top, endPoint: .bottom)
            .ignoresSafeArea()
            
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 20) {
                    Spacer(minLength: 8)
                    
                    // Titre
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Create Account")
                            .font(.system(size: 28, weight: .heavy))
                            .foregroundColor(.ca3c66)
                        
                        Text("Join Styleto and discover your style")
                            .font(.system(size: 15, weight: .medium))
                            .foregroundColor(._4aa3a2)
                    }
                    .padding(.bottom, 8)
                    
                    // Formulaire
                    Group {
                        Label("Full Name", systemImage: "person")
                            .labelStyle(LeftAlignedLabelStyle(color: ._4aa3a2))
                        IconField(systemName: "person",
                                  placeholder: "Enter your name",
                                  text: $viewModel.fullName)
                        if shouldShowFullNameWarning {
                            ValidationMessage("Please enter your full name.")
                        }
                        
                        Label("Email", systemImage: "envelope")
                            .labelStyle(LeftAlignedLabelStyle(color: ._4aa3a2))

                        IconField(
                            systemName: "envelope",
                            placeholder: "your@email.com",
                            text: $viewModel.email,
                            keyboardType: .emailAddress,
                            textContentType: .emailAddress
                        )
                        if shouldShowEmailWarning {
                            ValidationMessage("Invalid email address.")
                        }
                        
                        Label("Phone Number", systemImage: "phone")
                            .labelStyle(LeftAlignedLabelStyle(color: ._4aa3a2))
                        PhoneInputField(
                            selectedDialCode: $viewModel.selectedDialCode,
                            number: $viewModel.phoneNumber,
                            options: viewModel.dialCodes
                        )
                        if shouldShowPhoneWarning {
                            ValidationMessage("Please enter a phone number.")
                        }
                        
                        Label("Password", systemImage: "lock")
                            .labelStyle(LeftAlignedLabelStyle(color: ._4aa3a2))
                        IconSecureField(systemName: "lock",
                                        placeholder: "••••••••",
                                        text: $viewModel.password)
                        PasswordHint(isValid: viewModel.isPasswordStrong, attempted: attemptedSubmit)
                    }
                    
                    // Sexe – chips
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Gender")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(._4aa3a2)
                        
                        HStack(spacing: 12) {
                            Spacer(minLength: 0)
                            ForEach(GenderOption.allCases, id: \.self) { option in
                                GenderChip(
                                    title: option.rawValue,
                                    selected: selectedGender == option
                                )
                                .onTapGesture {
                                    selectedGender = option
                                    if let backendGender = userGender(for: option) {
                                        viewModel.selectGender(backendGender)
                                    }
                                }
                            }
                            Spacer(minLength: 0)
                        }
                        if shouldShowGenderWarning {
                            ValidationMessage("Please select your gender.")
                        }
                    }
                    
                    // Conditions
                    if let error = viewModel.errorMessage {
                        ValidationMessage(error)
                    }
                    
                    // Bouton principal
                    Button {
                        attemptedSubmit = true
                        viewModel.resetMessages()
                        if hasBlockingValidationError {
                            viewModel.pushBlockingError("Please check the required fields.")
                            return
                        }
                        viewModel.attemptSignup()
                        if viewModel.needsAcceptance {
                            showTermsSheet = true
                        }
                    } label: {
                        Group {
                            if viewModel.isLoading {
                                ProgressView()
                                    .progressViewStyle(.circular)
                            } else {
                                Text("Create my account")
                                    .font(.system(size: 17, weight: .semibold))
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                    }
                    .buttonStyle(PillButtonStyle(background: .ca3c66, foreground: .white))
                    .disabled(viewModel.isLoading)
                    .padding(.top, 6)
                    
                    // Lien connexion
                    HStack {
                        Spacer()
                        NavigationLink {
                            LabasniLoginView()
                        } label: {
                            Text("Already have an account? Sign in")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(._4aa3a2)
                        }
                        .buttonStyle(.plain)
                        Spacer()
                    }
                    .padding(.top, 6)
                    
                    Spacer(minLength: 20)
                }
                .padding(.horizontal, 22)
                .padding(.bottom, 30)
            }
        }
        .contentShape(Rectangle())                    // Important : permet de capter le tap même sur les espaces vides
            .onTapGesture {
                // Ferme le clavier quand on tape n’importe où sur l'écran
                UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
            }
        .navigationBarBackButtonHidden(true)
        .toolbar(.hidden, for: .navigationBar)
        .background(
            NavigationLink(
                destination: LabasniLoginView(),
                isActive: $navigateToLogin
            ) {
                EmptyView()
            }
                .hidden()
        )
        .sheet(isPresented: $showTermsSheet) {
            TermsSheetView(
                onAccept: {
                    showTermsSheet = false
                    Task {
                        await viewModel.performSignupAfterAcceptance()
                    }
                },
                onDecline: {
                    showTermsSheet = false
                    viewModel.pushBlockingError("Terms not accepted.")
                }
            )
        }
        .sheet(isPresented: $viewModel.showPinEntry) {
            PinEntrySheet(
                email: viewModel.email,
                pinCode: $viewModel.pinCode,
                errorMessage: viewModel.pinError,
                isLoading: viewModel.isLoading,
                resendSecondsRemaining: viewModel.resendSecondsRemaining,
                canResend: viewModel.canResendCode,
                onVerify: {
                    Task { await viewModel.verifyPinCode() }
                },
                onCancel: {
                    viewModel.showPinEntry = false
                    viewModel.pinCode = ""
                    viewModel.pinError = nil
                    viewModel.stopResendTimer()
                },
                onResend: {
                    Task { await viewModel.resendVerificationCode() }
                }
            )
        }
        .onChange(of: viewModel.successMessage) { _ in }
        .onChange(of: viewModel.navigateToLogin) { shouldNavigate in
            if shouldNavigate {
                navigateToLogin = true
            }
        }
        .onAppear {
            viewModel.resetMessages()
            attemptedSubmit = false
        }
    }
    
    private func userGender(for option: GenderOption) -> User.Gender? {
        switch option {
        case .female:
            return .female
        case .male:
            return .male
        }
    }
    
    private var shouldShowFullNameWarning: Bool {
        attemptedSubmit && viewModel.fullName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    private var shouldShowEmailWarning: Bool {
        attemptedSubmit && !isValidEmail(viewModel.email)
    }
    
    private var shouldShowPhoneWarning: Bool {
        attemptedSubmit && viewModel.formattedPhoneNumber.isEmpty
    }
    
    private var shouldShowGenderWarning: Bool {
        attemptedSubmit && selectedGender == nil
    }
    
    private var hasBlockingValidationError: Bool {
        shouldShowFullNameWarning
        || shouldShowEmailWarning
        || !viewModel.isPasswordStrong
        || shouldShowPhoneWarning
        || shouldShowGenderWarning
    }
    
    private func isValidEmail(_ email: String) -> Bool {
        let pattern = #"^[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$"#
        return email.range(of: pattern, options: .regularExpression) != nil
    }
}

// MARK: - Composants

struct LeftAlignedLabelStyle: LabelStyle {
    var color: Color
    func makeBody(configuration: Configuration) -> some View {
        HStack(spacing: 8) {
            configuration.icon
                .foregroundColor(color)
            configuration.title
                .foregroundColor(color)
                .font(.system(size: 16, weight: .semibold))
        }
    }
}

private struct IconField: View {
    let systemName: String
    let placeholder: String
    @Binding var text: String
    var keyboardType: UIKeyboardType = .default
    var textContentType: UITextContentType? = nil
    
    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: systemName)
                .foregroundColor(._4aa3a2.opacity(0.9))
                .font(.system(size: 18, weight: .semibold))
                .frame(width: 24)
            TextField(placeholder, text: $text)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled(true)
                .keyboardType(keyboardType)
                .textContentType(textContentType)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 14)
        .background(RoundedRectangle(cornerRadius: 22).fill(Color.white))
        .overlay(RoundedRectangle(cornerRadius: 22)
            .stroke(Color.ca3c66.opacity(0.8), lineWidth: 1.5))
        .shadow(color: .black.opacity(0.06), radius: 8, x: 0, y: 4)
    }
}

private struct PhoneInputField: View {
    @Binding var selectedDialCode: CountryDialCode
    @Binding var number: String
    let options: [CountryDialCode]
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "phone")
                .foregroundColor(._4aa3a2.opacity(0.9))
                .font(.system(size: 18, weight: .semibold))
                .frame(width: 24)
            
            Menu {
                ForEach(options, id: \.id) { code in
                    Button {
                        selectedDialCode = code
                    } label: {
                        Text(code.name)
                    }
                }
            } label: {
                HStack(spacing: 4) {
                    Text(selectedDialCode.dialCode)
                        .font(.system(size: 16, weight: .semibold))
                    Image(systemName: "chevron.down")
                        .font(.system(size: 12, weight: .bold))
                }
                .foregroundColor(.ca3c66)
            }
            
            Divider()
                .frame(height: 24)
                .background(Color.ca3c66.opacity(0.3))
            
            TextField("12 345 678", text: $number)
                .keyboardType(.numberPad)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled(true)
                .onChange(of: number) { newValue in
                    let digitsOnly = newValue.filter { $0.isNumber }
                    
                    if digitsOnly.count > 8 {
                        number = String(digitsOnly.prefix(8))
                    } else {
                        number = digitsOnly
                    }
                }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 14)
        .background(RoundedRectangle(cornerRadius: 22).fill(Color.white))
        .overlay(
            RoundedRectangle(cornerRadius: 22)
                .stroke(Color.ca3c66.opacity(0.8), lineWidth: 1.5)
        )
        .shadow(color: .black.opacity(0.06), radius: 8, x: 0, y: 4)
    }
}

private struct IconSecureField: View {
    let systemName: String
    let placeholder: String
    @Binding var text: String
    @State private var isSecure: Bool
    
    init(systemName: String, placeholder: String, text: Binding<String>, initiallySecure: Bool = true) {
        self.systemName = systemName
        self.placeholder = placeholder
        _text = text
        _isSecure = State(initialValue: initiallySecure)
    }
    
    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: systemName)
                .foregroundColor(._4aa3a2.opacity(0.9))
                .font(.system(size: 18, weight: .semibold))
                .frame(width: 24)
            
            if isSecure {
                SecureField(placeholder, text: $text)
            } else {
                TextField(placeholder, text: $text)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled(true)
            }
            
            Spacer(minLength: 0)
            
            Button {
                isSecure.toggle()
            } label: {
                Image(systemName: isSecure ? "eye.slash" : "eye")
                    .foregroundColor(.ca3c66)
                    .font(.system(size: 16, weight: .semibold))
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 14)
        .background(RoundedRectangle(cornerRadius: 22).fill(Color.white))
        .overlay(RoundedRectangle(cornerRadius: 22)
            .stroke(Color.ca3c66.opacity(0.8), lineWidth: 1.5))
        .shadow(color: .black.opacity(0.06), radius: 8, x: 0, y: 4)
    }
}

/// Chip sexe : contour rose, fond blanc, état sélectionné avec léger remplissage rose
private struct GenderChip: View {
    var title: String
    var selected: Bool
    
    var body: some View {
        Text(title)
            .font(.system(size: 16, weight: .semibold))
            .foregroundColor(selected ? .ca3c66 : ._4aa3a2)
            .padding(.horizontal, 18)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 18)
                    .fill(selected ? Color.e8aabe.opacity(0.22) : .white)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 18)
                    .stroke(Color.ca3c66.opacity(0.8), lineWidth: 1.2)
            )
            .shadow(color: .black.opacity(selected ? 0.06 : 0.04), radius: 6, x: 0, y: 3)
    }
}

/// Checkbox style proche d’iOS mais carré pour coller à la maquette
struct CheckboxToggleStyle: ToggleStyle {
    var tint: Color = .accentColor
    func makeBody(configuration: Configuration) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Button {
                configuration.isOn.toggle()
            } label: {
                ZStack {
                    RoundedRectangle(cornerRadius: 5)
                        .stroke(tint, lineWidth: 1.5)
                        .frame(width: 22, height: 22)
                        .background(
                            RoundedRectangle(cornerRadius: 5)
                                .fill(configuration.isOn ? tint.opacity(0.15) : .clear)
                        )
                    if configuration.isOn {
                        Image(systemName: "checkmark")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundStyle(tint)
                    }
                }
            }
            .buttonStyle(.plain)
            
            configuration.label
        }
    }
}

private struct ValidationMessage: View {
    var text: String
    
    init(_ text: String) {
        self.text = text
    }
    
    var body: some View {
        Text(text)
            .font(.system(size: 13, weight: .semibold))
            .foregroundColor(.ca3c66)
    }
}

private struct PasswordHint: View {
    var isValid: Bool
    var attempted: Bool
    
    var body: some View {
        let color: Color = isValid || !attempted ? ._4aa3a2.opacity(0.7) : .ca3c66
        Text("Minimum 6 characters, one uppercase letter, and one special character.")
            .font(.system(size: 13, weight: .medium))
            .foregroundColor(color)
    }
}

private struct TermsSheetView: View {
    var onAccept: () -> Void
    var onDecline: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Capsule()
                .fill(Color.gray.opacity(0.3))
                .frame(width: 50, height: 4)
                .padding(.top, 8)
                .frame(maxWidth: .infinity)
            
            Text("Terms of Use")
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(.ca3c66)
            
            ScrollView {
                VStack(alignment: .leading, spacing: 12) {
                    Text("By creating a Styleto account, you agree to:")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.ca3c66)
                    
                    TermsBullet("The processing of your data to personalize your style recommendations.")
                    TermsBullet("The possible receipt of notifications related to your activity and our updates.")
                    TermsBullet("The secure use of your information in accordance with our privacy policy.")
                    
                }
                .foregroundColor(._4aa3a2)
                .font(.system(size: 14))
            }
            
            VStack(spacing: 12) {
                Button(action: onAccept) {
                    Text("Accept and create my account")
                        .font(.system(size: 16, weight: .semibold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                }
                .buttonStyle(PillButtonStyle(background: .ca3c66, foreground: .white))
                
                Button(action: onDecline) {
                    Text("Decline")
                        .font(.system(size: 16, weight: .semibold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                }
                .buttonStyle(PillButtonStyle(background: .a7e0e0.opacity(0.4), foreground: .ca3c66))
            }
            .padding(.bottom, 20)
        }
        .padding(.horizontal, 20)
        .presentationDetents([.medium, .large])
    }
}

private struct TermsBullet: View {
    var text: String
    
    init(_ text: String) {
        self.text = text
    }
    
    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            Circle()
                .fill(Color.ca3c66)
                .frame(width: 6, height: 6)
                .padding(.top, 6)
            Text(text)
        }
    }
}

