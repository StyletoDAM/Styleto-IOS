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
        
        // Connecter le socket et rejoindre la conversation
        ChatSocketManager.shared.connect()
        
        // ⭐ IMPORTANT : Rejoindre la room de la conversation
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            ChatSocketManager.shared.joinConversation(self.conversation.id)
        }
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
                print("📨 Sender ID:", newMessage.senderId.id)
                print("📨 Mon ID:", self.currentUserId ?? "nil")
                
                // Vérifier que le message appartient à cette conversation
                guard newMessage.conversationId == self.conversation.id else {
                    print("⚠️ Message pour une autre conversation, ignoré")
                    return
                }
                
                // ⭐ REMPLACER le message optimiste s'il existe
                if let tempIndex = self.messages.firstIndex(where: { $0.id.hasPrefix("temp-") }) {
                    print("🔄 Remplacement du message optimiste par le vrai")
                    self.messages.remove(at: tempIndex)
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
                
                // ⭐ Rejoindre la conversation dès que connecté
                if connected, let conversationId = self?.conversation.id {
                    ChatSocketManager.shared.joinConversation(conversationId)
                }
            }
            .store(in: &cancellables)
    }
    
    func sendMessage() async {
        let text = messageText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }
        
        print("📤 Envoi du message:", text)
        
        messageText = ""
        isSending = true
        
        // ⭐ PAS de message optimiste - on attend le serveur
        // Ça évite les doublons et garantit la cohérence
        
        // Envoi via socket
        if ChatSocketManager.shared.isConnected {
            print("✅ Envoi via socket...")
            ChatSocketManager.shared.sendMessage(text, in: conversation.id)
        } else {
            print("❌ Socket non connecté, envoi via REST API...")
            // Fallback REST API si socket déconnecté
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
}
