//
//  ExperimentalModeDialog.swift
//  Labasniios
//
//  Dialog to inform users about experimental Virtual Try-On feature
//

import SwiftUI

struct ExperimentalModeDialog: View {
    @Environment(\.dismiss) private var dismiss
    let onConfirm: () -> Void
    
    @State private var scale: CGFloat = 0.9
    
    var body: some View {
        ZStack {
            // Background overlay
            Color.black.opacity(0.4)
                .ignoresSafeArea()
                .onTapGesture {
                    dismiss()
                }
            
            // Dialog card
            VStack(spacing: 24) {
                // Icon with animation
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color.themePrimary.opacity(0.25),
                                    Color.themeTeal.opacity(0.15)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 120, height: 120)
                    
                    Image(systemName: "sparkles")
                        .font(.system(size: 64, weight: .semibold))
                        .foregroundColor(.themePrimary)
                }
                
                // Title
                Text("Experimental Mode")
                    .font(.system(size: 26, weight: .bold))
                    .foregroundColor(.themeText)
                    .multilineTextAlignment(.center)
                
                // Information message
                VStack(spacing: 16) {
                    Text("This feature is still in experimentation")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.themeText)
                        .multilineTextAlignment(.center)
                    
                    Text("Are you sure you want to test it?")
                        .font(.system(size: 16))
                        .foregroundColor(.themeText)
                        .multilineTextAlignment(.center)
                    
                    Text("Virtual Try-On uses artificial intelligence to overlay your clothes in real time. This innovative feature may still have imperfections.")
                        .font(.system(size: 14))
                        .foregroundColor(.themeSecondaryText)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 8)
                    
                    // BETA badge
                    HStack(spacing: 8) {
                        Image(systemName: "sparkles")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundColor(.themePrimary)
                        
                        Text("BETA")
                            .font(.system(size: 13, weight: .bold))
                            .tracking(2)
                            .foregroundColor(.themePrimary)
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                    .background(
                        Capsule()
                            .fill(
                                LinearGradient(
                                    colors: [
                                        Color.themePrimary.opacity(0.2),
                                        Color.themeTeal.opacity(0.2)
                                    ],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .overlay(
                                Capsule()
                                    .strokeBorder(
                                        LinearGradient(
                                            colors: [
                                                Color.themePrimary.opacity(0.5),
                                                Color.themeTeal.opacity(0.5)
                                            ],
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        ),
                                        lineWidth: 1.5
                                    )
                            )
                    )
                }
                
                // Buttons
                VStack(spacing: 12) {
                    // "Try Now" button
                    Button {
                        onConfirm()
                        dismiss()
                    } label: {
                        Text("Try Now")
                            .font(.system(size: 17, weight: .bold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 56)
                            .background(Color.themePrimary)
                            .cornerRadius(16)
                    }
                    
                    // "Cancel" button
                    Button {
                        dismiss()
                    } label: {
                        Text("Cancel")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.themeSecondaryText)
                            .frame(maxWidth: .infinity)
                    }
                }
            }
            .padding(28)
            .background(
                RoundedRectangle(cornerRadius: 32)
                    .fill(Color.themeCard)
                    .shadow(color: .black.opacity(0.3), radius: 24)
            )
            .padding(.horizontal, 20)
            .scaleEffect(scale)
            .onAppear {
                withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                    scale = 1.0
                }
            }
        }
    }
}

