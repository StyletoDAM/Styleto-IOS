import Foundation
import Combine

@MainActor
class ChatViewModel: ObservableObject {
    @Published var conversations: [ChatConversationResponse] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        subscribeToRealtimeUpdates()
    }
    
    func loadConversations(showLoader: Bool = true) async {
        if showLoader { isLoading = true }
        errorMessage = nil
        
        do {
            let convs = try await ChatService.shared.fetchMyConversations()
            conversations = convs.sorted { $0.updatedAt > $1.updatedAt }
        } catch {
            errorMessage = "Impossible de charger les messages"
            print("Erreur chargement conversations:", error)
        }
        
        if showLoader { isLoading = false }
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
        } else {
            await loadConversations(showLoader: false)
        }
    }
}
