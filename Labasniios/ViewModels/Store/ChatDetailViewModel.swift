// ViewModels/Store/ChatDetailViewModel.swift
import Foundation
import Combine
import SwiftUI

@MainActor
class ChatDetailViewModel: ObservableObject {
    @Published var messages: [ChatMessage] = []
    @Published var messageText = ""
    @Published var isSending = false
    @Published var isConnected = false
    
    let conversation: ChatConversationResponse
    let currentUserId: String?
    
    private var cancellables = Set<AnyCancellable>()
    
    init(conversation: ChatConversationResponse) {
        self.conversation = conversation
        self.currentUserId = JWTDecoder.extractUserId(from: TokenManager.shared.getToken() ?? "")
        
        // Charger les messages initiaux
        self.messages = conversation.messages.sorted { $0.createdAt < $1.createdAt }
        
        print("📱 ChatDetailViewModel init avec", messages.count, "messages")
        
        // S'abonner aux nouveaux messages en temps réel
        setupRealtimeUpdates()
        
        // Connecter le socket
        ChatSocketManager.shared.connect()
    }
    
    private func setupRealtimeUpdates() {
        // Écouter les nouveaux messages
        ChatSocketManager.shared.messagePublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] newMessage in
                guard let self = self else { return }
                
                print("📨 Nouveau message reçu:", newMessage.content)
                print("📨 Pour conversation:", newMessage.conversationId)
                print("📨 Ma conversation:", self.conversation.id)
                
                // Vérifier que le message appartient à cette conversation
                guard newMessage.conversationId == self.conversation.id else {
                    print("⚠️ Message pour une autre conversation, ignoré")
                    return
                }
                
                // Éviter les doublons
                guard !self.messages.contains(where: { $0.id == newMessage.id }) else {
                    print("⚠️ Message déjà présent, ignoré")
                    return
                }
                
                // Ajouter le message avec animation
                withAnimation(.easeInOut(duration: 0.3)) {
                    self.messages.append(newMessage)
                    self.messages.sort { $0.createdAt < $1.createdAt }
                }
                
                print("✅ Message ajouté ! Total:", self.messages.count)
            }
            .store(in: &cancellables)
        
        // Écouter le statut de connexion
        ChatSocketManager.shared.$isConnected
            .receive(on: DispatchQueue.main)
            .sink { [weak self] connected in
                self?.isConnected = connected
                print("🔌 Statut connexion:", connected ? "Connecté" : "Déconnecté")
            }
            .store(in: &cancellables)
    }
    
    func sendMessage() async {
        let text = messageText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }
        
        print("📤 Envoi du message:", text)
        
        messageText = ""
        isSending = true
        
        // Message optimiste (affichage immédiat)
        let tempId = "temp-\(UUID().uuidString)"
        let optimisticMessage = ChatMessage(
            id: tempId,
            conversationId: conversation.id,
            senderId: ChatParticipant(
                id: currentUserId ?? "me",
                fullName: "Moi",
                profilePicture: nil
            ),
            content: text,
            createdAt: Date()
        )
        
        withAnimation {
            messages.append(optimisticMessage)
        }
        
        // ⭐ UNIQUEMENT envoi socket
        if ChatSocketManager.shared.isConnected {
            print("✅ Envoi via socket...")
            ChatSocketManager.shared.sendMessage(text, in: conversation.id)
        } else {
            print("❌ Socket non connecté !")
        }
        
        isSending = false
    }
}
