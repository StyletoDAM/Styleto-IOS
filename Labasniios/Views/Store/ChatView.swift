// ChatView.swift
import SwiftUI

struct ChatView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var showingChatDetail = false
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // MARK: - Search Bar FULL WIDTH (edge-to-edge)
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.gray.opacity(0.8))
                        .padding(.leading, 16)
                    
                    Text("Search conversations...")
                        .foregroundColor(.gray.opacity(0.8))
                        .font(.subheadline)
                    
                    Spacer()
                }
                .padding(.vertical, 14)
                .background(Color.themeAqua.opacity(0.25))
                .cornerRadius(16)
                .padding(.horizontal, 16)   // Marge gauche/droite classique
                .padding(.top, 10)
                .padding(.bottom, 14)
                
                // MARK: - Conversations List
                ScrollView {
                    VStack(spacing: 12) {
                        ChatRow(
                            name: "Sarah Belhadj",
                            message: "Gorgeous outfit!",
                            time: "10:30",
                            badge: 2,
                            isOnline: true
                        )
                        .onTapGesture { showingChatDetail = true }
                        
                        ChatRow(
                            name: "Amira Trabelsi",
                            message: "Have you seen the new dresses?",
                            time: "09:15",
                            badge: nil,
                            isOnline: true
                        )
                        .onTapGesture { showingChatDetail = true }
                        
                        ChatRow(
                            name: "Leila Gharbi",
                            message: "Thanks for the advice!",
                            time: "Yesterday",
                            badge: nil,
                            isOnline: false
                        )
                        .onTapGesture { showingChatDetail = true }
                        
                        ChatRow(
                            name: "Yasmine Ben Ali",
                            message: "I love your avatar! How did you...",
                            time: "Yesterday",
                            badge: 5,
                            isOnline: false
                        )
                        .onTapGesture { showingChatDetail = true }
                        
                        ChatRow(
                            name: "Mariem Kacem",
                            message: "See you this weekend?",
                            time: "Monday",
                            badge: nil,
                            isOnline: false
                        )
                        .onTapGesture { showingChatDetail = true }
                        
                        ChatRow(
                            name: "Asma Bouazizi",
                            message: "Great idea for tonight!",
                            time: "Sunday",
                            badge: 1,
                            isOnline: true
                        )
                        .onTapGesture { showingChatDetail = true }
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 20)
                }
            }
            .background(Color.themeBackground.ignoresSafeArea())
            .navigationTitle("Messages")
            .navigationBarTitleDisplayMode(.inline)
            .foregroundColor(.themePrimary)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "chevron.left")
                            .fontWeight(.bold)
                            .foregroundColor(.themePrimary)
                    }
                }
            }
            .fullScreenCover(isPresented: $showingChatDetail) {
                ChatDetailView()
            }
        }
    }
}

// MARK: - Conversation Row
struct ChatRow: View {
    let name: String
    let message: String
    let time: String
    let badge: Int?
    let isOnline: Bool
    
    var body: some View {
        HStack(spacing: 14) {
            ZStack(alignment: .bottomTrailing) {
                Circle()
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 56, height: 56)
                    .overlay(
                        Text(name.prefix(1))
                            .font(.title2.bold())
                            .foregroundColor(.white)
                    )
                
                if isOnline {
                    Circle()
                        .fill(Color.green)
                        .frame(width: 14, height: 14)
                        .overlay(Circle().stroke(Color.themeBackground, lineWidth: 3))
                }
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(name)
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(.themePrimary)
                
                Text(message)
                    .font(.system(size: 15))
                    .foregroundColor(.gray)
                    .lineLimit(1)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                Text(time)
                    .font(.caption)
                    .foregroundColor(.gray)
                
                if let badge = badge {
                    Text("\(badge)")
                        .font(.caption.bold())
                        .foregroundColor(.white)
                        .frame(width: 20, height: 20)
                        .background(Color.themePrimary)
                        .clipShape(Circle())
                }
            }
        }
        .padding()
        .background(Color.themeCard)
        .cornerRadius(20)
        .shadow(color: .black.opacity(0.04), radius: 6)
    }
}

#Preview {
    ChatView()
}
