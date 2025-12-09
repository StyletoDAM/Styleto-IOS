import SwiftUI

struct ChatDetailView: View {
    let conversation: ChatConversationResponse
    
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel: ChatDetailViewModel
    @FocusState private var keyboardFocused: Bool
    
    init(conversation: ChatConversationResponse) {
        self.conversation = conversation
        _viewModel = StateObject(wrappedValue: ChatDetailViewModel(conversation: conversation))
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Bannière de statut de connexion (optionnelle)
                if !viewModel.isConnected {
                    connectionStatusBanner
                }
                
                // ⭐ Indicateur de chargement des messages
                if viewModel.isLoadingMessages {
                    VStack {
                        Spacer()
                        ProgressView("Chargement des messages...")
                            .padding()
                        Spacer()
                    }
                } else if viewModel.messages.isEmpty {
                    // ⭐ Aucun message
                    VStack(spacing: 16) {
                        Image(systemName: "message")
                            .font(.system(size: 50))
                            .foregroundColor(.gray.opacity(0.5))
                        Text("Aucun message pour le moment")
                            .foregroundColor(.gray)
                        Text("Envoyez le premier message !")
                            .font(.caption)
                            .foregroundColor(.gray.opacity(0.8))
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    messagesList
                }
                
                inputBar
            }
            .background(Color.themeBackground.ignoresSafeArea())
            .navigationTitle(partnerName)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { toolbarContent }
        }
    }
    
    // Bannière de statut (masquée quand connecté)
    private var connectionStatusBanner: some View {
        HStack(spacing: 8) {
            ProgressView()
                .scaleEffect(0.8)
            Text("Connexion...")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 6)
        .background(Color.orange.opacity(0.1))
    }

    // MARK: - Sous-vues séparées
    private var messagesList: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: 20) {
                    ForEach(viewModel.messages) { message in
                        messageRow(message)
                    }
                    Color.clear.frame(height: 1).id("bottom")
                }
                .padding(.horizontal)
                .padding(.top, 10)
                .padding(.bottom, 100)
            }
            .onTapGesture {
                keyboardFocused = false  // Ferme le clavier
            }
            .onAppear { scrollToBottom(proxy: proxy) }
            .onChange(of: viewModel.messages.count) { _ in
                scrollToBottom(proxy: proxy)
            }
        }
    }

    @ViewBuilder
    private func messageRow(_ message: ChatMessage) -> some View {
        if message.senderId.id == viewModel.currentUserId {
            OutgoingMessage(
                text: message.content,
                time: message.createdAt.formatTime(),
                extractedInfo: message.extractedInfo
            )
        } else {
            IncomingMessage(
                text: message.content,
                time: message.createdAt.formatTime(),
                avatarLetter: message.senderId.fullName.prefix(1).uppercased(),
                profilePictureURL: message.senderId.profilePicture,
                extractedInfo: message.extractedInfo
            )
        }
    }

    private var inputBar: some View {
        HStack(spacing: 14) {
            
            TextField("Write a message...", text: $viewModel.messageText, axis: .vertical)
                .focused($keyboardFocused)  // Ajoute cette ligne
                .padding(14)
                .background(Color.themeCard)
                .cornerRadius(24)
                .lineLimit(1...6)
            
            Button {
                Task { await viewModel.sendMessage() }
            } label: {
                Image(systemName: viewModel.isSending ? "timer" : "paperplane.fill")
                    .font(.title2)
                    .foregroundColor(.white)
                    .frame(width: 44, height: 44)
                    .background(viewModel.isSending ? Color.gray : Color.themePrimary)
                    .clipShape(Circle())
                    .shadow(color: .themePrimary.opacity(0.4), radius: 8)
                    .rotationEffect(.degrees(viewModel.isSending ? 360 : 0))
                    .animation(viewModel.isSending ? .linear(duration: 1).repeatForever(autoreverses: false) : .default, value: viewModel.isSending)
            }
            .disabled(viewModel.messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || viewModel.isSending)
        }
        .padding(.horizontal)
        .padding(.vertical, 12)
        .background(Color.themeBackground)
    }

    private var toolbarContent: some ToolbarContent {
        Group {
            ToolbarItem(placement: .navigationBarLeading) {
                Button { dismiss() } label: {
                    Image(systemName: "chevron.left")
                        .fontWeight(.bold)
                        .foregroundColor(.themePrimary)
                }
            }
            
            ToolbarItem(placement: .principal) {
                HStack(spacing: 10) {
                    ZStack(alignment: .bottomTrailing) {
                        if let url = partner.profilePicture, let imageURL = URL(string: url) {
                            AsyncImage(url: imageURL) { image in
                                image.resizable().scaledToFill()
                            } placeholder: {
                                Circle()
                                    .fill(Color.gray.opacity(0.3))
                                    .overlay(Text(partnerName.prefix(1)).font(.title3.bold()).foregroundColor(.white))
                            }
                            .frame(width: 36, height: 36)
                            .clipShape(Circle())
                        } else {
                            Circle()
                                .fill(Color.gray.opacity(0.3))
                                .frame(width: 36, height: 36)
                                .overlay(Text(partnerName.prefix(1)).font(.title3.bold()).foregroundColor(.white))
                        }
                        
                        
                    }
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text(partnerName)
                            .font(.headline)
                            .foregroundColor(.themePrimary)
                        
                    }
                }
            }
            

        }
    }
    
    private var partner: ChatParticipant {
        let currentUserId = JWTDecoder.extractUserId(from: TokenManager.shared.getToken() ?? "")
        return conversation.participants.first { $0.id != currentUserId } ?? conversation.participants[0]
    }
    
    private var partnerName: String { partner.fullName }
    
    private func scrollToBottom(proxy: ScrollViewProxy) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            withAnimation {
                proxy.scrollTo("bottom", anchor: .bottom)
            }
        }
    }
}

// MARK: - Messages (identiques à avant)
struct IncomingMessage: View {
    let text: String
    let time: String
    let avatarLetter: String
    let profilePictureURL: String?
    let extractedInfo: ExtractedInfo?
    
    var body: some View {
        HStack(alignment: .bottom, spacing: 8) {
            if let urlString = profilePictureURL, let url = URL(string: urlString) {
                AsyncImage(url: url) { image in
                    image.resizable().scaledToFill()
                } placeholder: {
                    Circle()
                        .fill(Color.gray.opacity(0.3))
                        .overlay(Text(avatarLetter).font(.title3.bold()).foregroundColor(.white))
                }
                .frame(width: 36, height: 36)
                .clipShape(Circle())
            } else {
                Circle()
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 36, height: 36)
                    .overlay(Text(avatarLetter).font(.title3.bold()).foregroundColor(.white))
            }
            
            VStack(alignment: .leading, spacing: 6) {
                Text(text) // ✨ Le texte est déjà masqué par le backend
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

struct OutgoingMessage: View {
    let text: String
    let time: String
    let extractedInfo: ExtractedInfo?
    
    var body: some View {
        HStack(alignment: .bottom, spacing: 8) {
            Spacer()
            VStack(alignment: .trailing, spacing: 6) {
                Text(text) // ✨ Le texte est déjà masqué par le backend
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

// MARK: - Extensions
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

extension Date {
    func formatTime() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        formatter.locale = Locale(identifier: "fr_FR")
        return formatter.string(from: self)
    }
}

