import SwiftUI

// MARK: - Vue principale
struct LabasniForgotPasswordView: View {
    @StateObject private var viewModel = ForgotPasswordViewModel()
    @ObservedObject private var themeManager = ThemeManager.shared  // ✅ AJOUT
    @Environment(\.dismiss) private var dismiss
    @State private var navigateToLogin = false

    var body: some View {
        ZStack {
            // ✅ CORRECTION: Fond dynamique
            LinearGradient(
                colors: [Color.themeSoftPink.opacity(0.30), Color.themeBackground],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 22) {
                    header
                    illustration
                    description
                    emailField

                    if let error = viewModel.errorMessage {
                        ValidationMessage(error)
                    }

                    if let success = viewModel.successMessage {
                        SuccessMessage(success)
                    }

                    primaryButton
                    secondaryButton
                }
                .padding(.bottom, 32)
            }
        }
        .navigationBarBackButtonHidden(true)
        .toolbar(.hidden, for: .navigationBar)
        .background(
            NavigationLink(
                destination: LabasniLoginView(),
                isActive: $navigateToLogin
            ) { EmptyView() }
                .hidden()
        )
        .sheet(isPresented: $viewModel.showOtpSheet) {
            OtpEntrySheet(
                maskedPhone: viewModel.maskedPhoneNumber ?? "",
                code: $viewModel.otpCode,
                errorMessage: viewModel.errorMessage,
                isLoading: viewModel.isLoading,
                resendSecondsRemaining: viewModel.resendSecondsRemaining,
                canResend: viewModel.canResendCode,
                onVerify: {
                    Task { await viewModel.verifyOtp() }
                },
                onResend: {
                    Task { await viewModel.resendOtp() }
                },
                onCancel: {
                    viewModel.showOtpSheet = false
                    viewModel.otpCode = ""
                    viewModel.clearFlashMessages()
                    viewModel.stopResendTimer()
                }
            )
        }
        .sheet(isPresented: $viewModel.showResetSheet) {
            ResetPasswordSheet(
                newPassword: $viewModel.newPassword,
                confirmPassword: $viewModel.confirmPassword,
                isLoading: viewModel.isLoading,
                errorMessage: viewModel.errorMessage,
                onConfirm: {
                    Task { await viewModel.resetPassword() }
                },
                onCancel: {
                    viewModel.showResetSheet = false
                    viewModel.clearFlashMessages()
                }
            )
        }
        .onDisappear {
            viewModel.stopResendTimer()
            NotificationCenter.default.removeObserver(self)
        }
        .onReceive(NotificationCenter.default.publisher(for: .didRequestNavigateToLogin)) { _ in
            navigateToLogin = true
        }
        .onAppear {
            themeManager.updateTheme()  // ✅ IMPORTANT
        }
    }

    private var header: some View {
        HStack {
            Button(action: { dismiss() }) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.themePrimary)  // ✅ Dynamique
            }
            Spacer()
        }
        .padding(.horizontal, 22)
        .padding(.top, 12)
    }

    private var illustration: some View {
        ZStack {
            Circle()
                .fill(Color.themeSecondary.opacity(0.25))  // ✅ Dynamique
                .frame(width: 96, height: 96)
                .shadow(color: .black.opacity(0.12), radius: 14, x: 0, y: 8)

            Image(systemName: "lock.rotation.open")
                .font(.system(size: 34, weight: .bold))
                .foregroundStyle(Color.themeSecondary)  // ✅ Dynamique
        }
        .padding(.top, 6)
    }

    private var description: some View {
        VStack(spacing: 8) {
            Text("Forgot password?")
                .font(.system(size: 26, weight: .heavy))
                .foregroundColor(.themePrimary)  // ✅ Dynamique

            Text("Enter your email. We will send you an SMS code to the phone number associated with your account.")
                .multilineTextAlignment(.center)
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(.themeText)  // ✅ Dynamique
                .padding(.horizontal, 24)
        }
    }

    private var emailField: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Email address")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.themeText)  // ✅ Dynamique
                .padding(.top, 6)

            IconField(systemName: "envelope",
                      placeholder: "your@email.com",
                      text: $viewModel.email)
        }
        .padding(.horizontal, 22)
    }

    private var primaryButton: some View {
        Button {
            Task { await viewModel.requestOtp() }
        } label: {
            Group {
                if viewModel.isLoading {
                    ProgressView()
                        .progressViewStyle(.circular)
                        .tint(.white)
                } else {
                    Text("Receive code via SMS")
                        .font(.system(size: 17, weight: .semibold))
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
        }
        .buttonStyle(PillButtonStyle(background: .themePrimary, foreground: .white))  // ✅ Dynamique
        .padding(.horizontal, 22)
        .padding(.top, 2)
        .disabled(viewModel.isLoading)
    }

    private var secondaryButton: some View {
        Button(action: { dismiss() }) {
            Text("Back to Login")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.themeSecondary)  // ✅ Dynamique
        }
        .padding(.top, 4)
    }
}

// MARK: - Composants réutilisés (avec couleurs dynamiques)
private struct IconField: View {
    let systemName: String
    let placeholder: String
    @Binding var text: String

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: systemName)
                .foregroundColor(.themeSecondary)  // ✅ Dynamique
                .font(.system(size: 18, weight: .semibold))
                .frame(width: 24)
            TextField(placeholder, text: $text)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled(true)
                .keyboardType(.emailAddress)
                .foregroundColor(.themeText)  // ✅ Dynamique
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 14)
        .background(
            RoundedRectangle(cornerRadius: 22)
                .fill(Color.themeCard)  // ✅ Dynamique
        )
        .overlay(
            RoundedRectangle(cornerRadius: 22)
                .stroke(Color.themePrimary.opacity(0.6), lineWidth: 1.5)  // ✅ Dynamique
        )
        .shadow(color: .black.opacity(0.06), radius: 8, x: 0, y: 4)
    }
}

private struct SuccessMessage: View {
    var text: String

    init(_ text: String) {
        self.text = text
    }

    var body: some View {
        Text(text)
            .font(.system(size: 13, weight: .semibold))
            .foregroundColor(.green)
            .padding(.horizontal, 22)
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
            .foregroundColor(.themePrimary)  // ✅ Dynamique
            .padding(.horizontal, 22)
    }
}



private struct SecureInputField: View {
    let title: String
    @Binding var text: String
    @Binding var isHidden: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.callout)
                .fontWeight(.semibold)
                .foregroundColor(.themeText)  // ✅ Dynamique

            HStack {
                if isHidden {
                    SecureField("••••••••", text: $text)
                        .foregroundColor(.themeText)  // ✅ Dynamique
                } else {
                    TextField("••••••••", text: $text)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled(true)
                        .foregroundColor(.themeText)  // ✅ Dynamique
                }

                Button {
                    isHidden.toggle()
                } label: {
                    Image(systemName: isHidden ? "eye.slash" : "eye")
                        .foregroundColor(.themePrimary)  // ✅ Dynamique
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .background(RoundedRectangle(cornerRadius: 18).fill(Color.themeCard))  // ✅ Dynamique
            .overlay(
                RoundedRectangle(cornerRadius: 18)
                    .stroke(Color.themePrimary.opacity(0.6), lineWidth: 1.2)  // ✅ Dynamique
            )
            .shadow(color: .black.opacity(0.05), radius: 6, x: 0, y: 4)
        }
    }
}
