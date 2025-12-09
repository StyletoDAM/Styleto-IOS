import Foundation
import SwiftUI

struct PinEntrySheet: View {
    let email: String
    @Binding var pinCode: String
    let errorMessage: String?
    let isLoading: Bool
    let resendSecondsRemaining: Int
    let canResend: Bool
    let onVerify: () -> Void
    let onCancel: () -> Void
    let onResend: (() -> Void)?
    
    init(
        email: String,
        pinCode: Binding<String>,
        errorMessage: String?,
        isLoading: Bool,
        resendSecondsRemaining: Int = 0,
        canResend: Bool = true,
        onVerify: @escaping () -> Void,
        onCancel: @escaping () -> Void,
        onResend: (() -> Void)? = nil
    ) {
        self.email = email
        self._pinCode = pinCode
        self.errorMessage = errorMessage
        self.isLoading = isLoading
        self.resendSecondsRemaining = resendSecondsRemaining
        self.canResend = canResend
        self.onVerify = onVerify
        self.onCancel = onCancel
        self.onResend = onResend
    }
    
    var body: some View {
        VStack(spacing: 24) {
            Capsule()
                .fill(Color.gray.opacity(0.3))
                .frame(width: 50, height: 4)
                .padding(.top, 8)
            
            VStack(spacing: 16) {
                Text("Verification Required")
                    .font(.title2).bold()
                    .foregroundColor(.themePrimary)  // ✅ Dynamique
                
                VStack(spacing: 8) {
                    Text("A 6-digit code has been sent to")
                        .font(.subheadline)
                        .foregroundColor(.themeText)  // ✅ Dynamique
                    
                    Text(email)
                        .font(.subheadline).bold()
                        .foregroundColor(.themePrimary)  // ✅ Dynamique
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.themeSoftPink.opacity(0.2))  // ✅ Dynamique
                        .cornerRadius(8)
                }
            }
            
            TextField("000000", text: $pinCode)
                .font(.system(size: 28, weight: .bold, design: .monospaced))
                .multilineTextAlignment(.center)
                .keyboardType(.numberPad)
                .foregroundColor(.themeText)  // ✅ Dynamique
                .onChange(of: pinCode) { newValue in
                    pinCode = String(newValue.filter { $0.isNumber }.prefix(6))
                }
                .frame(maxWidth: 220)
                .padding()
                .background(RoundedRectangle(cornerRadius: 16).fill(Color.themeCard))  // ✅ Dynamique
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.themePrimary.opacity(0.7), lineWidth: 1.8)  // ✅ Dynamique
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
                        ProgressView()
                            .progressViewStyle(.circular)
                            .tint(.white)
                    } else {
                        Text("Verify code")
                            .font(.headline)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding()
            }
            .buttonStyle(PillButtonStyle(background: .themePrimary, foreground: .white))  // ✅ Dynamique
            .disabled(pinCode.count != 6 || isLoading)
            
            if let onResend {
                Button {
                    onResend()
                } label: {
                    Text(canResend ? "Resend code" : "Resend code (\(resendSecondsRemaining)s)")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                }
                .buttonStyle(.plain)
                .foregroundColor(canResend ? .themePrimary : .gray)  // ✅ Dynamique
                .disabled(!canResend)
            }
            
            Button("Cancel", action: onCancel)
                .foregroundColor(.themeSecondary)  // ✅ Dynamique
                .font(.subheadline)
        }
        .padding()
        .background(Color.themeBackground)  // ✅ Dynamique
        .presentationDetents([.medium])
        .presentationDragIndicator(.visible)
    }
}
