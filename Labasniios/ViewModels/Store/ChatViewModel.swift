//
//  ChatViewModel.swift
//  Labasniios
//
//  ViewModel pour la liste des conversations de chat
//
//  Ce fichier gère la logique métier de la liste des conversations :
//  - Chargement des conversations depuis le serveur
//  - Synchronisation en temps réel via WebSocket
//  - Mise à jour automatique lors de nouveaux messages
//  - Tri des conversations par date de dernière mise à jour
//
//  Architecture : MVVM avec ObservableObject (Combine)
//  Dépendances : Foundation, Combine, ChatService, ChatSocketManager
//

import Foundation
import Combine

/**
 * ViewModel pour la liste des conversations de chat
 * 
 * Cette classe gère toute la logique métier de la liste des conversations
 * de chat dans le contexte du marketplace. Elle est marquée @MainActor pour
 * garantir que toutes les opérations se déroulent sur le thread principal.
 * 
 * Fonctionnalités :
 * - Chargement des conversations depuis ChatService
 * - Synchronisation en temps réel via ChatSocketManager (WebSocket)
 * - Mise à jour automatique de la liste lors de nouveaux messages
 * - Tri des conversations par date de dernière mise à jour
 * - Gestion des états de chargement et erreurs
 * 
 * Les conversations sont automatiquement mises à jour en temps réel grâce
 * au WebSocket, permettant aux utilisateurs de voir les nouveaux messages
 * instantanément sans avoir besoin de rafraîchir manuellement.
 * 
 * @see ObservableObject pour la réactivité avec SwiftUI
 * @see @MainActor pour l'exécution sur le thread principal
 * @see ChatService pour les opérations backend
 * @see ChatSocketManager pour la synchronisation en temps réel
 */
@MainActor
class ChatViewModel: ObservableObject {
    @Published var conversations: [ChatConversationResponse] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var unreadCount: Int = 0
    
    private var cancellables = Set<AnyCancellable>()
    private var currentUserId: String?
    
    init() {
        subscribeToRealtimeUpdates()
    }
    
    func loadConversations(showLoader: Bool = true) async {
        if showLoader { isLoading = true }
        errorMessage = nil
        
        // Get current user ID
        if let token = TokenManager.shared.getToken() {
            currentUserId = JWTDecoder.extractUserId(from: token)
        }
        
        do {
            let convs = try await ChatService.shared.fetchMyConversations()
            conversations = convs.sorted { $0.updatedAt > $1.updatedAt }
            updateUnreadCount()
        } catch {
            errorMessage = "Impossible de charger les messages"
            print("Erreur chargement conversations:", error)
        }
        
        if showLoader { isLoading = false }
    }
    
    private func updateUnreadCount() {
        guard let userId = currentUserId else {
            unreadCount = 0
            return
        }
        
        var count = 0
        let normalizedUserId = userId.trimmingCharacters(in: .whitespaces).lowercased()
        
        for conversation in conversations {
            if hasUnreadMessages(conversation: conversation, userId: normalizedUserId) {
                count += 1
            }
        }
        
        unreadCount = count
    }
    
    private func hasUnreadMessages(conversation: ChatConversationResponse, userId: String) -> Bool {
        guard let lastMessage = conversation.messages.last else { return false }
        let senderIdNormalized = lastMessage.senderId.id.trimmingCharacters(in: .whitespaces).lowercased()
        return senderIdNormalized != userId
    }
    
    func markConversationAsRead(conversationId: String) {
        // Mark conversation as read locally
        if conversations.firstIndex(where: { $0.id == conversationId }) != nil {
            // Update local state - in a real app, you'd also call an API
            updateUnreadCount()
        }
    }
    
    private func subscribeToRealtimeUpdates() {
        ChatSocketManager.shared.connect()
        
        ChatSocketManager.shared.messagePublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] message in
                guard let self = self else { return }
                Task {
                    await self.processIncoming(message)
                }
            }
            .store(in: &cancellables)
    }
    
    private func processIncoming(_ message: ChatMessage) async {
        if let index = conversations.firstIndex(where: { $0.id == message.conversationId }) {
            var conversation = conversations[index]
            
            guard !conversation.messages.contains(where: { $0.id == message.id }) else { return }
            
            conversation.messages.append(message)
            conversation.messages.sort { $0.createdAt < $1.createdAt }
            conversation.updatedAt = max(conversation.updatedAt, message.createdAt)
            conversations[index] = conversation
            conversations.sort { $0.updatedAt > $1.updatedAt }
            updateUnreadCount()
        } else {
            await loadConversations(showLoader: false)
        }
    }
}
