import SwiftUI

// MARK: - Vue principale
struct LabasniForgotPasswordView: View {
    @StateObject private var viewModel = ForgotPasswordViewModel()
    @Environment(\.dismiss) private var dismiss
    @State private var navigateToLogin = false

    var body: some View {
        ZStack {
            LinearGradient(colors: [Color.e8aabe.opacity(0.30), .white],
                           startPoint: .top, endPoint: .bottom)
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
    }

    private var header: some View {
        HStack {
            Button(action: { dismiss() }) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.ca3c66)
            }
            Spacer()
        }
        .padding(.horizontal, 22)
        .padding(.top, 12)
    }

    private var illustration: some View {
        ZStack {
            Circle()
                .fill(Color._4aa3a2.opacity(0.25))
                .frame(width: 96, height: 96)
                .shadow(color: .black.opacity(0.12), radius: 14, x: 0, y: 8)

            Image(systemName: "lock.rotation.open")
                .font(.system(size: 34, weight: .bold))
                .foregroundStyle(Color._4aa3a2)
        }
        .padding(.top, 6)
    }

    private var description: some View {
        VStack(spacing: 8) {
            Text("Forgot password?")
                .font(.system(size: 26, weight: .heavy))
                .foregroundColor(.ca3c66)

            Text("Enter your email. We will send you an SMS code to the phone number associated with your account.")
                .multilineTextAlignment(.center)
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(._4aa3a2)
                .padding(.horizontal, 24)
        }
    }

    private var emailField: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Email address")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(._4aa3a2)
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
                    ProgressView().progressViewStyle(.circular)
                } else {
                    Text("Receive code via SMS")
                        .font(.system(size: 17, weight: .semibold))
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
        }
        .buttonStyle(PillButtonStyle(background: .ca3c66, foreground: .white))
        .padding(.horizontal, 22)
        .padding(.top, 2)
        .disabled(viewModel.isLoading)
    }

    private var secondaryButton: some View {
        Button(action: { dismiss() }) {
            Text("Back to Login")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(._4aa3a2)
        }
        .padding(.top, 4)
    }
}

// MARK: - Composants réutilisés
private struct IconField: View {
    let systemName: String
    let placeholder: String
    @Binding var text: String

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: systemName)
                .foregroundColor(._4aa3a2.opacity(0.9))
                .font(.system(size: 18, weight: .semibold))
                .frame(width: 24)
            TextField(placeholder, text: $text)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled(true)
                .keyboardType(.emailAddress)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 14)
        .background(
            RoundedRectangle(cornerRadius: 22)
                .fill(Color.white)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 22)
                .stroke(Color.ca3c66.opacity(0.8), lineWidth: 1.5)
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
            .foregroundColor(.ca3c66)
            .padding(.horizontal, 22)
    }
}

// MARK: - Previews
struct LabasniForgotPasswordView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            LabasniForgotPasswordView()
                .previewDevice(PreviewDevice(rawValue: "iPhone 15 Pro"))
                .environment(\.colorScheme, .light)

            LabasniForgotPasswordView()
                .previewDevice(PreviewDevice(rawValue: "iPhone SE (3rd generation)"))
                .environment(\.colorScheme, .dark)

            LabasniForgotPasswordView()
                .environment(\.sizeCategory, .accessibilityExtraExtraExtraLarge)
        }
    }
}
