import SwiftUI

struct OtpEntrySheet: View {
    let maskedPhone: String
    @Binding var code: String
    let errorMessage: String?
    let isLoading: Bool
    let resendSecondsRemaining: Int
    let canResend: Bool
    let onVerify: () -> Void
    let onResend: () -> Void
    let onCancel: () -> Void

    var body: some View {
        VStack(spacing: 24) {
            Capsule()
                .fill(Color.gray.opacity(0.3))
                .frame(width: 50, height: 4)
                .padding(.top, 8)

            VStack(spacing: 12) {
                Text("Vérifiez votre identité")
                    .font(.title2).bold()
                    .foregroundColor(.ca3c66)

                Text("Un code à 6 chiffres a été envoyé au numéro \(maskedPhone).")
                    .font(.subheadline)
                    .foregroundColor(._4aa3a2)
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal, 12)

            TextField("000000", text: $code)
                .font(.system(size: 28, weight: .bold, design: .monospaced))
                .multilineTextAlignment(.center)
                .keyboardType(.numberPad)
                .onChange(of: code) { newValue in
                    code = String(newValue.filter { $0.isNumber }.prefix(6))
                }
                .frame(maxWidth: 220)
                .padding()
                .background(RoundedRectangle(cornerRadius: 16).fill(Color.white))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.ca3c66.opacity(0.7), lineWidth: 1.8)
                )
                .shadow(color: .black.opacity(0.06), radius: 6, x: 0, y: 4)

            if let error = errorMessage {
                Text(error)
                    .font(.caption).bold()
                    .foregroundColor(.red)
                    .padding(.horizontal)
            }

            Button {
                onVerify()
            } label: {
                Group {
                    if isLoading {
                        ProgressView().progressViewStyle(.circular)
                    } else {
                        Text("Valider le code")
                            .font(.headline)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding()
            }
            .buttonStyle(PillButtonStyle(background: .ca3c66, foreground: .white))
            .disabled(code.count != 6 || isLoading)

            Button {
                onResend()
            } label: {
                Text(canResend ? "Renvoyer le code SMS" : "Renvoyer le code (\(resendSecondsRemaining)s)")
                    .font(.subheadline)
                    .fontWeight(.semibold)
            }
            .buttonStyle(.plain)
            .foregroundColor(canResend ? .ca3c66 : .gray)
            .disabled(!canResend)

            Button("Annuler", action: onCancel)
                .foregroundColor(._4aa3a2)
                .font(.subheadline)
        }
        .padding()
        .presentationDetents([.medium])
        .presentationDragIndicator(.visible)
    }
}

#Preview {
    OtpEntrySheet(
        maskedPhone: "+216 ** *** 123",
        code: .constant(""),
        errorMessage: nil,
        isLoading: false,
        resendSecondsRemaining: 45,
        canResend: false,
        onVerify: {},
        onResend: {},
        onCancel: {}
    )
}

