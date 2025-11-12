import SwiftUI

struct ResetPasswordSheet: View {
    @Binding var newPassword: String
    @Binding var confirmPassword: String
    let isLoading: Bool
    let errorMessage: String?
    let onConfirm: () -> Void
    let onCancel: () -> Void

    @State private var isPasswordHidden: Bool = true
    @State private var isConfirmationHidden: Bool = true

    var body: some View {
        VStack(spacing: 18) {
            Capsule()
                .fill(Color.gray.opacity(0.3))
                .frame(width: 50, height: 4)
                .padding(.top, 8)

            Text("New password")
                .font(.title2).bold()
                .foregroundColor(.ca3c66)

            VStack(alignment: .leading, spacing: 14) {
                SecureInputField(
                    title: "Password",
                    text: $newPassword,
                    isHidden: $isPasswordHidden
                )

                SecureInputField(
                    title: "Confirm password",
                    text: $confirmPassword,
                    isHidden: $isConfirmationHidden
                )

                Text("Minimum 6 characters, at least one uppercase letter and one special character.")
                    .font(.footnote)
                    .foregroundColor(._4aa3a2)
            }

            if let error = errorMessage {
                Text(error)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.red)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }

            Button {
                onConfirm()
            } label: {
                Group {
                    if isLoading {
                        ProgressView().progressViewStyle(.circular)
                    } else {
                        Text("Reset Password")
                            .font(.headline)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding()
            }
            .buttonStyle(PillButtonStyle(background: .ca3c66, foreground: .white))
            .disabled(isLoading)

            Button("Cancel", action: onCancel)
                .foregroundColor(._4aa3a2)
                .font(.subheadline)
        }
        .padding()
        .presentationDetents([.medium])
        .presentationDragIndicator(.visible)
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
                .foregroundColor(._4aa3a2)

            HStack {
                if isHidden {
                    SecureField("••••••••", text: $text)
                } else {
                    TextField("••••••••", text: $text)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled(true)
                }

                Button {
                    isHidden.toggle()
                } label: {
                    Image(systemName: isHidden ? "eye.slash" : "eye")
                        .foregroundColor(.ca3c66)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .background(RoundedRectangle(cornerRadius: 18).fill(Color.white))
            .overlay(
                RoundedRectangle(cornerRadius: 18)
                    .stroke(Color.ca3c66.opacity(0.8), lineWidth: 1.2)
            )
            .shadow(color: .black.opacity(0.05), radius: 6, x: 0, y: 4)
        }
    }
}

#Preview {
    ResetPasswordSheet(
        newPassword: .constant(""),
        confirmPassword: .constant(""),
        isLoading: false,
        errorMessage: nil,
        onConfirm: {},
        onCancel: {}
    )
}

