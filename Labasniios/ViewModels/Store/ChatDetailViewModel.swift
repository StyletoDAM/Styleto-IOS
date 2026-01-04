//
//  ChatDetailViewModel.swift
//  Labasniios
//
//  ViewModel pour l'écran de détail d'une conversation de chat
//
//  Ce fichier gère la logique métier de l'écran de détail d'une conversation :
//  - Chargement et affichage des messages
//  - Envoi de nouveaux messages
//  - Synchronisation en temps réel via WebSocket
//  - Identification de l'utilisateur actuel (pour l'affichage des bulles)
//
//  Architecture : MVVM avec ObservableObject (Combine)
//  Dépendances : Foundation, Combine, SwiftUI, ChatService, ChatSocketManager
//

import Foundation
import Combine
import SwiftUI

/**
 * ViewModel pour l'écran de détail d'une conversation de chat
 * 
 * Cette classe gère toute la logique métier de l'écran de détail d'une
 * conversation de chat. Elle est marquée @MainActor pour garantir que toutes
 * les opérations se déroulent sur le thread principal.
 * 
 * Fonctionnalités :
 * - Chargement et affichage des messages de la conversation
 * - Envoi de nouveaux messages via ChatService
 * - Synchronisation en temps réel via ChatSocketManager (WebSocket)
 * - Identification de l'utilisateur actuel depuis le JWT (champ 'sub')
 * - Mise à jour automatique de la liste lors de nouveaux messages
 * - Gestion des états de chargement et erreurs
 * 
 * L'identification de l'utilisateur actuel est cruciale pour déterminer
 * si un message doit être affiché à gauche (expéditeur) ou à droite
 * (utilisateur actuel). L'ID est extrait depuis le JWT pour garantir
 * la cohérence avec le backend.
 * 
 * @see ObservableObject pour la réactivité avec SwiftUI
 * @see @MainActor pour l'exécution sur le thread principal
 * @see ChatService pour les opérations backend
 * @see ChatSocketManager pour la synchronisation en temps réel
 * @see JWTDecoder pour l'extraction de l'ID utilisateur
 */
@MainActor
class ChatDetailViewModel: ObservableObject {
    @Published var messages: [ChatMessage] = []
    @Published var messageText = ""
    @Published var isSending = false
    @Published var isConnected = false
    @Published var isLoadingMessages = false
    
    let conversation: ChatConversationResponse
    let currentUserId: String?
    
    private var cancellables = Set<AnyCancellable>()
    
    init(conversation: ChatConversationResponse) {
        self.conversation = conversation
        
        // ✨ SOLUTION : Utiliser UNIQUEMENT le JWT (qui contient 'sub' = _id MongoDB)
        // C'est exactement ce que le backend utilise pour identifier l'utilisateur
        guard let token = TokenManager.shared.getToken() else {
            print("❌ [ChatDetailViewModel] Aucun token disponible")
            self.currentUserId = nil
            return
        }
        
        // Extraire l'ID depuis le JWT (champ 'sub')
        self.currentUserId = JWTDecoder.extractUserId(from: token)
        
        print("═══════════════════════════════════════════════════════════")
        print("📱 [ChatDetailViewModel] Initialisation")
        print("   📦 Conversation ID: \(conversation.id)")
        print("   📦 Messages dans la conversation: \(conversation.messages.count)")
        print("   🔑 Current User ID (from JWT 'sub'): '\(currentUserId ?? "nil")'")
        
        if let currentUserId = currentUserId {
            let normalized = JWTDecoder.normalizeId(currentUserId)
            print("   🔑 Current User ID (normalized): '\(normalized)'")
        }
        
        // Debug participants
        print("   👥 Participants de la conversation:")
        for (index, participant) in conversation.participants.enumerated() {
            let normalizedParticipantId = JWTDecoder.normalizeId(participant.id)
            let normalizedUserId = JWTDecoder.normalizeId(currentUserId)
            let isCurrentUser = normalizedParticipantId == normalizedUserId && 
                               !normalizedParticipantId.isEmpty && 
                               !normalizedUserId.isEmpty
            print("      [\(index)] ID: '\(participant.id)'")
            print("            Normalized: '\(normalizedParticipantId)'")
            print("            Name: '\(participant.fullName)'")
            print("            Is Current User: \(isCurrentUser ? "✅ OUI" : "❌ NON")")
        }
        print("═══════════════════════════════════════════════════════════")
        
        // Charger les messages initiaux
        loadInitialMessages()
        
        // S'abonner aux nouveaux messages en temps réel
        setupRealtimeUpdates()
        
        // Connecter le socket et rejoindre la conversation
        ChatSocketManager.shared.connect()
        
        // Rejoindre la room après connexion
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            ChatSocketManager.shared.joinConversation(self.conversation.id)
        }
    }
    
    // MARK: - Initial Messages Loading
    
    private func loadInitialMessages() {
        if !conversation.messages.isEmpty {
            self.messages = conversation.messages.sorted { $0.createdAt < $1.createdAt }
            print("✅ [\(self.messages.count)] messages chargés depuis la conversation")
            
            // Debug : afficher l'alignement de chaque message
            debugMessageAlignment()
        } else {
            Task {
                await fetchMessages()
            }
        }
    }
    
    func fetchMessages() async {
        isLoadingMessages = true
        
        do {
            let fetchedMessages = try await ChatService.shared.fetchMessages(conversationId: conversation.id)
            
            await MainActor.run {
                self.messages = fetchedMessages.sorted { $0.createdAt < $1.createdAt }
                print("✅ [\(self.messages.count)] messages récupérés depuis l'API")
                self.isLoadingMessages = false
                
                // Debug : afficher l'alignement de chaque message
                debugMessageAlignment()
            }
        } catch {
            print("❌ Erreur chargement messages:", error)
            await MainActor.run {
                self.isLoadingMessages = false
            }
        }
    }
    
    // MARK: - Realtime Updates
    
    private func setupRealtimeUpdates() {
        // Écouter les nouveaux messages
        ChatSocketManager.shared.messagePublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] newMessage in
                guard let self = self else { return }
                
                print("═══════════════════════════════════════════════════════════")
                print("📨 [ChatDetailViewModel] Nouveau message reçu via socket:")
                print("   - Content: '\(newMessage.content)'")
                print("   - Sender ID (raw): '\(newMessage.senderId.id)'")
                print("   - Sender ID (normalized): '\(JWTDecoder.normalizeId(newMessage.senderId.id))'")
                print("   - Sender Name: '\(newMessage.senderId.fullName)'")
                print("   - Conversation ID: '\(newMessage.conversationId)'")
                print("   - Ma conversation: '\(self.conversation.id)'")
                print("   - Current User ID (raw): '\(self.currentUserId ?? "nil")'")
                
                if let currentUserId = self.currentUserId {
                    let normalizedSenderId = JWTDecoder.normalizeId(newMessage.senderId.id)
                    let normalizedUserId = JWTDecoder.normalizeId(currentUserId)
                    print("   - Current User ID (normalized): '\(normalizedUserId)'")
                    print("   - Match: \(normalizedSenderId == normalizedUserId && !normalizedSenderId.isEmpty ? "✅ OUI (message envoyé par moi)" : "❌ NON (message reçu)")")
                }
                print("═══════════════════════════════════════════════════════════")
                
                // Vérifier que le message appartient à cette conversation
                guard newMessage.conversationId == self.conversation.id else {
                    print("⚠️ Message pour une autre conversation, ignoré")
                    return
                }
                
                // Éviter les doublons
                guard !self.messages.contains(where: { $0.id == newMessage.id }) else {
                    print("⚠️ Message déjà présent (doublon évité)")
                    return
                }
                
                // Ajouter le message avec animation
                withAnimation(.easeInOut(duration: 0.3)) {
                    self.messages.append(newMessage)
                    self.messages.sort { $0.createdAt < $1.createdAt }
                }
                
                print("✅ Message ajouté ! Total: \(self.messages.count)")
            }
            .store(in: &cancellables)
        
        // Écouter le statut de connexion
        ChatSocketManager.shared.$isConnected
            .receive(on: DispatchQueue.main)
            .sink { [weak self] connected in
                self?.isConnected = connected
                print("🔌 Statut connexion socket:", connected ? "✅ Connecté" : "❌ Déconnecté")
                
                // Rejoindre la conversation dès que connecté
                if connected, let conversationId = self?.conversation.id {
                    ChatSocketManager.shared.joinConversation(conversationId)
                }
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Send Message
    
    func sendMessage() async {
        let text = messageText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }
        
        print("═══════════════════════════════════════════════════════════")
        print("📤 [ChatDetailViewModel] Envoi du message:")
        print("   - Content: '\(text)'")
        print("   - Sender ID: '\(currentUserId ?? "nil")'")
        print("   - Conversation ID: '\(conversation.id)'")
        print("═══════════════════════════════════════════════════════════")
        
        messageText = ""
        isSending = true
        
        // Envoi via socket
        if ChatSocketManager.shared.isConnected {
            print("✅ Envoi via socket...")
            ChatSocketManager.shared.sendMessage(text, in: conversation.id)
        } else {
            print("❌ Socket non connecté, envoi via REST API...")
            await sendViaAPI(text)
        }
        
        isSending = false
    }
    
    // Fallback si socket déconnecté
    private func sendViaAPI(_ text: String) async {
        guard let url = URL(string: "\(APIConstants.baseURL)/chat/messages"),
              let token = TokenManager.shared.getToken() else {
            print("❌ URL ou token invalide")
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body: [String: Any] = [
            "conversationId": conversation.id,
            "content": text
        ]
        
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)
        
        do {
            let (_, response) = try await URLSession.shared.data(for: request)
            if let httpResponse = response as? HTTPURLResponse {
                print("📡 REST API response:", httpResponse.statusCode)
            }
        } catch {
            print("❌ Erreur REST API:", error)
        }
    }
    
    // MARK: - Debug Helper
    
    /// Affiche l'alignement prévu pour chaque message (debug)
    private func debugMessageAlignment() {
        guard let currentUserId = currentUserId else { return }
        let normalizedUserId = JWTDecoder.normalizeId(currentUserId)
        
        print("═══════════════════════════════════════════════════════════")
        print("🔍 [ChatDetailViewModel] Debug alignement des messages:")
        print("   Current User ID (normalized): '\(normalizedUserId)'")
        print("")
        
        for (index, message) in messages.enumerated() {
            let normalizedSenderId = JWTDecoder.normalizeId(message.senderId.id)
            let isOwnMessage = normalizedSenderId == normalizedUserId && 
                              !normalizedSenderId.isEmpty && 
                              !normalizedUserId.isEmpty
            
            print("   [\(index)] '\(message.content.prefix(30))...'")
            print("       Sender ID (normalized): '\(normalizedSenderId)'")
            print("       Alignment: \(isOwnMessage ? "➡️ DROITE (Outgoing)" : "⬅️ GAUCHE (Incoming)")")
        }
        print("═══════════════════════════════════════════════════════════")
    }
}
