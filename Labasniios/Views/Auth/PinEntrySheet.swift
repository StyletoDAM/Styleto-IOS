//
//  PinEntrySheet.swift
//  Labasniios
//
//  Created by Salma Mahjoub on 7/11/2025.
//

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
                    .foregroundColor(.ca3c66)

                VStack(spacing: 8) {
                    Text("A 6-digit code has been sent to")
                        .font(.subheadline)
                        .foregroundColor(._4aa3a2)

                    Text(email)
                        .font(.subheadline).bold()
                        .foregroundColor(.ca3c66)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.e8aabe.opacity(0.2))
                        .cornerRadius(8)
                }
            }

            TextField("000000", text: $pinCode)
                .font(.system(size: 28, weight: .bold, design: .monospaced))
                .multilineTextAlignment(.center)
                .keyboardType(.numberPad)
                .onChange(of: pinCode) { newValue in
                    pinCode = String(newValue.filter { $0.isNumber }.prefix(6))
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
                        Text("Verify code")
                            .font(.headline)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding()
            }
            .buttonStyle(PillButtonStyle(background: .ca3c66, foreground: .white))
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
                .foregroundColor(canResend ? .ca3c66 : .gray)
                .disabled(!canResend)
            }

            Button("Cancel", action: onCancel)
                .foregroundColor(._4aa3a2)
                .font(.subheadline)
        }
        .padding()
        .presentationDetents([.medium])
        .presentationDragIndicator(.visible)
    }
}

#Preview {
    PinEntrySheet(
        email: "mahjoub2003@gmail.com",
        pinCode: .constant(""),
        errorMessage: nil,
        isLoading: false,
        resendSecondsRemaining: 30,
        canResend: false,
        onVerify: {},
        onCancel: {},
        onResend: {}
    )
}
