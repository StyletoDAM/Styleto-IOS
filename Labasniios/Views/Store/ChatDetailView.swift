// ChatDetailView.swift
import SwiftUI

struct ChatDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var messageText = ""
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                ScrollView {
                    VStack(spacing: 20) {
                        // Messages reçus (bulles roses - à gauche)
                        IncomingMessage(
                            text: "Magnifique tenue !",
                            time: "10:10"
                        )
                        
                        OutgoingMessage(
                            text: "Oui j’ai essayé aussi ! L’analyse automatique de la photo est impressionnante",
                            time: "10:12"
                        )
                        
                        IncomingMessage(
                            text: "Complètement d’accord ! Tu vas au store ce weekend ?",
                            time: "10:15"
                        )
                        
                        OutgoingMessage(
                            text: "Oui absolument ! Il y a de nouvelles collections",
                            time: "10:20"
                        )
                        
                        IncomingMessage(
                            text: "Super ! On se voit là-bas alors",
                            time: "10:25"
                        )
                        
                        OutgoingMessage(
                            text: "Parfait ! À samedi !",
                            time: "10:30"
                        )
                    }
                    .padding(.horizontal)
                    .padding(.top, 10)
                    .padding(.bottom, 100)
                }
                
                // MARK: - Barre d'envoi
                HStack(spacing: 14) {
                    Image(systemName: "paperclip")
                        .font(.title2)
                        .foregroundColor(.themePrimary.opacity(0.8))
                    
                    TextField("Écrivez un message...", text: $messageText, axis: .vertical)
                        .padding(14)
                        .background(Color.themeCard)
                        .cornerRadius(24)
                        .lineLimit(1...6)
                    
                    Button {
                        // Envoyer
                    } label: {
                        Image(systemName: "paperplane.fill")
                            .font(.title2)
                            .foregroundColor(.white)
                            .frame(width: 44, height: 44)
                            .background(Color.themePrimary)
                            .clipShape(Circle())
                            .shadow(color: .themePrimary.opacity(0.4), radius: 8)
                    }
                }
                .padding(.horizontal)
                .padding(.vertical, 12)
                .background(Color.themeBackground)
            }
            .background(Color.themeBackground.ignoresSafeArea())
            .navigationTitle("Sarah Belhadj")
            .navigationBarTitleDisplayMode(.inline)
            .foregroundColor(.themePrimary)
            .toolbar {
                // Bouton retour
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "chevron.left")
                            .fontWeight(.bold)
                            .foregroundColor(.themePrimary)
                    }
                }
                
                // Titre avec avatar + statut
                ToolbarItem(placement: .principal) {
                    HStack(spacing: 10) {
                        ZStack(alignment: .bottomTrailing) {
                            Circle()
                                .fill(Color.gray.opacity(0.3))
                                .frame(width: 36, height: 36)
                                .overlay(
                                    Text("S")
                                        .font(.title3.bold())
                                        .foregroundColor(.white)
                                )
                            
                            Circle()
                                .fill(Color.green)
                                .frame(width: 12, height: 12)
                                .overlay(Circle().stroke(Color.themeBackground, lineWidth: 2))
                        }
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Sarah Belhadj")
                                .font(.headline)
                                .foregroundColor(.themePrimary)
                            
                            Text("En ligne")
                                .font(.caption)
                                .foregroundColor(.green)
                        }
                    }
                }
            }
        }
    }
}

// MARK: - Message reçu (bulle rose à gauche)
struct IncomingMessage: View {
    let text: String
    let time: String
    
    var body: some View {
        HStack(alignment: .bottom, spacing: 8) {
            // Avatar à gauche
            Circle()
                .fill(Color.gray.opacity(0.3))
                .frame(width: 36, height: 36)
                .overlay(Text("S").font(.title3.bold()).foregroundColor(.white))
            
            VStack(alignment: .leading, spacing: 6) {
                Text(text)
                    .foregroundColor(.white)
                    .padding(14)
                    .background(Color.themePrimary)
                    .cornerRadius(20)
                    .cornerRadius(4, corners: [.topLeft])
                
                Text(time)
                    .font(.caption2)
                    .foregroundColor(.gray.opacity(0.8))
            }
            
            Spacer()
        }
    }
}

// MARK: - Message envoyé (bulle claire à droite)
struct OutgoingMessage: View {
    let text: String
    let time: String
    
    var body: some View {
        HStack(alignment: .bottom, spacing: 8) {
            Spacer()
            
            VStack(alignment: .trailing, spacing: 6) {
                Text(text)
                    .foregroundColor(.primary)
                    .padding(14)
                    .background(Color.themeCard)
                    .cornerRadius(20)
                    .cornerRadius(4, corners: [.topRight])
                
                Text(time)
                    .font(.caption2)
                    .foregroundColor(.gray.opacity(0.8))
            }
        }
    }
}

// Extension pour coins arrondis spécifiques
extension View {
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape(RoundedCorner(radius: radius, corners: corners))
    }
}

struct RoundedCorner: Shape {
    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners
    
    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: corners,
            cornerRadii: CGSize(width: radius, height: radius)
        )
        return Path(path.cgPath)
    }
}

#Preview {
    ChatDetailView()
}
