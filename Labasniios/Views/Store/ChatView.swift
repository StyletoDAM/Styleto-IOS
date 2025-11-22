// Views/Store/ChatView.swift
import SwiftUI

struct ChatView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = ChatViewModel()
    @State private var selectedConversation: ChatConversationResponse?
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // MARK: - Search Bar
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
                .padding(.horizontal, 16)
                .padding(.top, 10)
                .padding(.bottom, 14)
                
                // MARK: - Conversations List
                if viewModel.isLoading {
                    ProgressView()
                        .padding()
                    Spacer()
                } else if viewModel.conversations.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "message")
                            .font(.system(size: 50))
                            .foregroundColor(.gray.opacity(0.5))
                        Text("Aucune conversation pour le moment")
                            .foregroundColor(.gray)
                    }
                    .padding()
                    Spacer()
                } else {
                    ScrollView {
                        VStack(spacing: 12) {
                            ForEach(viewModel.conversations) { conversation in
                                // On extrait l'userId du JWT sans toucher TokenManager
                                let currentUserId = TokenManager.shared.getToken().flatMap { JWTDecoder.extractUserId(from: $0) }
                                
                                // On prend l'autre personne dans la conversation
                                let partner = conversation.participants.first { $0.id != currentUserId }
                                           ?? conversation.participants.first!
                                
                                let lastMsg = conversation.lastMessage ?? conversation.messages.last
                                
                                ChatRow(
                                    name: partner.fullName,
                                    message: lastMsg?.content ?? "Commencer la conversation",
                                    time: lastMsg?.createdAt.relativeTime() ?? "Nouveau",
                                    badge: nil,
                                    isOnline: false,
                                    profilePictureURL: partner.profilePicture
                                )
                                .onTapGesture {
                                    selectedConversation = conversation
                                }
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.bottom, 20)
                    }
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
            .task {
                await viewModel.loadConversations()
            }
            .fullScreenCover(item: $selectedConversation) { conv in
                ChatDetailView(conversation: conv)            }
        }
    }
}

// Extension pour le temps relatif
extension Date {
    func relativeTime() -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: self, relativeTo: Date())
    }
}


// Dans ChatRow.swift
struct ChatRow: View {
    let name: String
    let message: String
    let time: String
    let badge: Int?
    let isOnline: Bool
    let profilePictureURL: String? // ← Nouveau
    
    var body: some View {
        HStack(spacing: 14) {
            ZStack(alignment: .bottomTrailing) {
                if let urlString = profilePictureURL,
                   let url = URL(string: urlString) {
                    AsyncImage(url: url) { image in
                        image
                            .resizable()
                            .scaledToFill()
                    } placeholder: {
                        Circle()
                            .fill(Color.gray.opacity(0.3))
                            .overlay(
                                Text(name.prefix(1))
                                    .font(.title2.bold())
                                    .foregroundColor(.white)
                            )
                    }
                    .frame(width: 56, height: 56)
                    .clipShape(Circle())
                } else {
                    Circle()
                        .fill(Color.gray.opacity(0.3))
                        .frame(width: 56, height: 56)
                        .overlay(
                            Text(name.prefix(1))
                                .font(.title2.bold())
                                .foregroundColor(.white)
                        )
                }
                
                if isOnline {
                    Circle()
                        .fill(Color.green)
                        .frame(width: 14, height: 14)
                        .overlay(Circle().stroke(Color.themeBackground, lineWidth: 3))
                }
            }
            
            // Le reste reste identique...
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
