import SwiftUI
import Foundation

// MARK: - Palette (hex)
extension Color {
    static let ca3c66 = Color(hex: "#CA3C66") // primaire (bouton)
    static let db6a8f = Color(hex: "#DB6A8F")
    static let e8aabe = Color(hex: "#E8AABE") // haut du dégradé
    static let a7e0e0 = Color(hex: "#A7E0E0") // bas du dégradé / bouton secondaire
    static let _4aa3a2 = Color(hex: "#4AA3A2") // badge/accents
}

// Utilitaire hex → Color
extension Color {
    init(hex: String, opacity: Double = 1.0) {
        var s = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        s = s.replacingOccurrences(of: "#", with: "")
        var rgb: UInt64 = 0; Scanner(string: s).scanHexInt64(&rgb)
        self.init(.sRGB,
                  red: Double((rgb >> 16) & 0xFF)/255,
                  green: Double((rgb >> 8) & 0xFF)/255,
                  blue: Double(rgb & 0xFF)/255,
                  opacity: opacity)
    }
}

// MARK: - Vue principale
struct LabasniIntroView: View {
    var body: some View {
        NavigationStack {
            ZStack {
                LinearGradient(colors: [.e8aabe, .a7e0e0],
                               startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea()
                
                VStack(spacing: 28) {
                    Spacer(minLength: 40)
                    
                    Image("logocercle")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 180, height: 180)
                        .shadow(color: .black.opacity(0.18), radius: 20, x: 0, y: 10)
                    
                    VStack(spacing: 6) {
                        Text("Styleto")
                            .font(.system(size: 34, weight: .bold))
                            .foregroundColor(.white.opacity(0.96))
                            .shadow(color: .black.opacity(0.08), radius: 4, x: 0, y: 2)
                        
                        Text("Your Smart Stylist")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.white.opacity(0.85))
                    }
                    .padding(.top, 4)
                    
                    Spacer()
                    
                    VStack(spacing: 16) {
                        NavigationLink {
                            LabasniLoginView()
                        } label: {
                            Text("Log In")
                                .font(.system(size: 17, weight: .semibold))
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                        }
                        .buttonStyle(PillButtonStyle(
                            background: .ca3c66,
                            foreground: .white
                        ))
                        
                        NavigationLink {
                            LabasniSignupView()
                        } label: {
                            Text("Sign Up")
                                .font(.system(size: 17, weight: .semibold))
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                        }
                        .buttonStyle(PillButtonStyle(
                            background: .a7e0e0.opacity(0.9),
                            foreground: Color.black.opacity(0.55),
                            border: Color.white.opacity(0.35)
                        ))
                    }
                    .padding(.horizontal, 28)
                    
                    Spacer(minLength: 24)
                }
                .padding(.bottom, 8)
            }
            .navigationBarBackButtonHidden(true)
            .toolbar(.hidden, for: .navigationBar)
        }
    }
}

// MARK: - Styles
struct PillButtonStyle: ButtonStyle {
    var background: Color
    var foreground: Color
    var border: Color? = nil
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundColor(foreground)
            .background(Capsule().fill(background))
            .overlay(Capsule().stroke(border ?? .clear, lineWidth: border == nil ? 0 : 1))
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
            .shadow(color: .black.opacity(0.12), radius: 10, x: 0, y: 6)
            .animation(.easeOut(duration: 0.15), value: configuration.isPressed)
    }
}

