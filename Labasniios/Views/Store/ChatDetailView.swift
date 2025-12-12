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
                            .onAppear {
                                // Logs de debug quand le message apparaît
                                logMessageAlignment(message: message)
                            }
                            .id("\(message.id)-\(message.senderId.id)")
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
            .onChange(of: viewModel.messages.count) {
                scrollToBottom(proxy: proxy)
            }
        }
    }

    @ViewBuilder
    private func messageRow(_ message: ChatMessage) -> some View {
        // ANALYSE COMPLÈTE : Déterminer l'ID de l'utilisateur actuel (EXACTEMENT comme Android)
        // Android utilise directement userId passé en paramètre depuis TokenManager.getUserId()
        // Ce userId vient de response.user.userId qui est id ?: mongoId (donc peut être id OU _id)
        
        // 1. PRIORITÉ : userId stocké (comme Android utilise getUserId())
        let storedUserId = TokenManager.shared.getUserId()
        
        // 2. Depuis le JWT (fallback si userId non stocké) - extraire sub
        let jwtUserId = JWTDecoder.extractUserId(from: TokenManager.shared.getToken() ?? "")
        
        // 3. Depuis le ViewModel (fallback supplémentaire)
        let viewModelUserId = viewModel.currentUserId
        
        // 4. Depuis les participants de la conversation (dernier fallback)
        let participantUserId = findCurrentUserIdFromParticipants()
        
        // 5. Utiliser le premier disponible (priorité : stocké > JWT > ViewModel > participants)
        // ⚠️ CRITIQUE : Utiliser JWT en priorité car le backend utilise client.user?.sub (du JWT)
        let currentUserId = jwtUserId ?? storedUserId ?? viewModelUserId ?? participantUserId
        
        // Normaliser les IDs pour la comparaison (EXACTEMENT comme Android: trim + lowercase)
        let rawSenderId = message.senderId.id
        let normalizedSenderId = normalizeId(rawSenderId)
        let normalizedUserId = normalizeId(currentUserId)
        
        // Comparaison stricte (EXACTEMENT comme Android)
        // Android: normalizedSenderId == normalizedUserId && normalizedSenderId.isNotBlank() && normalizedUserId.isNotBlank()
        let isOwnMessage = !normalizedSenderId.isEmpty && 
                           !normalizedUserId.isEmpty &&
                           normalizedSenderId == normalizedUserId
        
        // Logs de debug (appelés depuis onAppear, pas dans le ViewBuilder)
        
        if isOwnMessage {
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
    
    // Fonction utilitaire pour normaliser et comparer les IDs (EXACTEMENT comme Android)
    // Android: id.trim().lowercase()
    // Gère les différents formats possibles (MongoDB ObjectId, UUID, etc.)
    private func normalizeId(_ id: String?) -> String {
        guard let id = id, !id.isEmpty else { return "" }
        // EXACTEMENT comme Android: trim + lowercase
        let trimmed = id.trimmingCharacters(in: .whitespacesAndNewlines)
        let lowercased = trimmed.lowercased()
        // Log pour debug
        if trimmed != id || lowercased != trimmed {
            print("   [normalizeId] '\(id)' -> '\(lowercased)' (trimmed: \(trimmed != id), lowercased: \(lowercased != trimmed))")
        }
        return lowercased
    }
    
    // Fonction de log pour le debug (appelée depuis onAppear)
    private func logMessageAlignment(message: ChatMessage) {
        // Extraire tous les userId possibles pour debug
        let storedUserId = TokenManager.shared.getUserId()
        let currentToken = TokenManager.shared.getToken() ?? ""
        let jwtUserIdFromToken = JWTDecoder.extractUserId(from: currentToken)
        let viewModelUserId = viewModel.currentUserId
        let participantUserId = findCurrentUserIdFromParticipants()
        
        // Utiliser la même logique que messageRow (priorité : JWT > stocké > ViewModel > participants)
        // ⚠️ CRITIQUE : Utiliser JWT en priorité car le backend utilise client.user?.sub (du JWT)
        let currentUserId = jwtUserIdFromToken ?? storedUserId ?? viewModelUserId ?? participantUserId
        
        // Normaliser les IDs pour la comparaison (EXACTEMENT comme Android)
        let rawSenderId = message.senderId.id
        let normalizedSenderId = normalizeId(rawSenderId)
        let normalizedUserId = normalizeId(currentUserId)
        
        // Comparaison stricte (EXACTEMENT comme Android)
        let isOwnMessage = !normalizedSenderId.isEmpty && 
                           !normalizedUserId.isEmpty &&
                           normalizedSenderId == normalizedUserId
        
        print("═══════════════════════════════════════════════════════════")
        print("🔍 [ChatDetailView.messageRow] ANALYSE MESSAGE COMPLÈTE:")
        print("   📨 Content: '\(message.content.prefix(30))...'")
        print("   ───────────────────────────────────────────────────────")
        print("   👤 SENDER INFO:")
        print("      - Sender ID (raw): '\(rawSenderId)' (length: \(rawSenderId.count))")
        print("      - Sender ID (normalized): '\(normalizedSenderId)' (length: \(normalizedSenderId.count))")
        print("      - Sender Name: '\(message.senderId.fullName)'")
        print("   ───────────────────────────────────────────────────────")
        print("   🔑 CURRENT USER INFO:")
        print("      - Stored User ID (from TokenManager): '\(storedUserId ?? "nil")' ⭐ PRIORITÉ")
        print("      - JWT User ID (from Token now): '\(jwtUserIdFromToken ?? "nil")'")
        print("      - ViewModel User ID: '\(viewModelUserId ?? "nil")'")
        print("      - Participant User ID: '\(participantUserId ?? "nil")'")
        print("      - Current User ID (used): '\(currentUserId ?? "nil")' (length: \(currentUserId?.count ?? 0))")
        print("      - Current User ID (normalized): '\(normalizedUserId)' (length: \(normalizedUserId.count))")
        print("   ───────────────────────────────────────────────────────")
        print("   ✅ COMPARAISON CRITIQUE:")
        print("      - senderId (normalized): '\(normalizedSenderId)'")
        print("      - userId (normalized):   '\(normalizedUserId)'")
        print("      - IDs match: \(normalizedSenderId == normalizedUserId ? "✅ OUI" : "❌ NON")")
        print("      - Is own message: \(isOwnMessage ? "✅ OUI → OUTGOING (droite)" : "❌ NON → INCOMING (gauche)")")
        if normalizedSenderId != normalizedUserId && !normalizedSenderId.isEmpty && !normalizedUserId.isEmpty {
            print("   ⚠️ DIFFÉRENCE DÉTECTÉE:")
            print("      Sender normalized: '\(normalizedSenderId)'")
            print("      User normalized:   '\(normalizedUserId)'")
            let minLength = min(normalizedSenderId.count, normalizedUserId.count)
            let maxLength = max(normalizedSenderId.count, normalizedUserId.count)
            print("      Lengths: sender=\(normalizedSenderId.count), user=\(normalizedUserId.count)")
            if minLength > 0 {
                let diffCount = zip(normalizedSenderId.prefix(minLength), normalizedUserId.prefix(minLength)).filter { $0 != $1 }.count
                print("      Diff chars (first \(minLength)): \(diffCount)")
                // Afficher les caractères différents
                if diffCount > 0 {
                    let senderPrefix = String(normalizedSenderId.prefix(minLength))
                    let userPrefix = String(normalizedUserId.prefix(minLength))
                    print("      Sender prefix: '\(senderPrefix)'")
                    print("      User prefix:   '\(userPrefix)'")
                }
            }
            if maxLength > minLength {
                print("      ⚠️ Longueurs différentes !")
            }
        }
        print("   ───────────────────────────────────────────────────────")
        print("   📋 PARTICIPANTS:")
        for (index, p) in conversation.participants.enumerated() {
            let normalizedPId = normalizeId(p.id)
            let isSenderMatch = normalizedPId == normalizedSenderId
            let isUserMatch = normalizedPId == normalizedUserId
            print("      [\(index)] ID: '\(p.id)' (normalized: '\(normalizedPId)') Name: '\(p.fullName)'")
            if isSenderMatch {
                print("         ✅ ← SENDER OF THIS MESSAGE")
            }
            if isUserMatch {
                print("         ✅ ← CURRENT USER")
            }
        }
        print("═══════════════════════════════════════════════════════════")
    }
    
    // Trouver l'ID de l'utilisateur actuel depuis les participants
    // En comparant avec l'ID stocké (comme Android)
    private func findCurrentUserIdFromParticipants() -> String? {
        // ✨ CORRIGÉ : Utiliser le userId stocké (comme Android) au lieu de l'extraire du JWT
        let storedUserId = TokenManager.shared.getUserId()
        let jwtUserId = JWTDecoder.extractUserId(from: TokenManager.shared.getToken() ?? "")
        let userIdToUse = storedUserId ?? jwtUserId
        
        guard let userIdToUse = userIdToUse else { 
            print("⚠️ [ChatDetailView] Pas de userId (ni stocké ni JWT) pour trouver dans participants")
            return nil 
        }
        
        let normalizedUserId = normalizeId(userIdToUse)
        print("🔍 [ChatDetailView] Recherche de l'utilisateur actuel dans participants:")
        print("   - Stored User ID: '\(storedUserId ?? "nil")'")
        print("   - JWT User ID: '\(jwtUserId ?? "nil")'")
        print("   - User ID to use: '\(userIdToUse)'")
        print("   - User ID (normalized): '\(normalizedUserId)'")
        
        // Chercher dans les participants celui qui correspond à notre ID
        for (index, participant) in conversation.participants.enumerated() {
            let normalizedParticipantId = normalizeId(participant.id)
            let isMatch = normalizedParticipantId == normalizedUserId
            print("   - Participant [\(index)]: '\(participant.id)' (normalized: '\(normalizedParticipantId)') \(isMatch ? "✅ MATCH!" : "❌")")
            
            if isMatch {
                print("✅ [ChatDetailView] Utilisateur actuel trouvé dans participants: '\(participant.id)'")
                return participant.id
            }
        }
        
        print("⚠️ [ChatDetailView] Aucun participant ne correspond, utilisation du userId directement")
        // Si aucun participant ne correspond, retourner le userId utilisé
        return userIdToUse
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

