import Foundation
import Combine

@MainActor
class ChatViewModel: ObservableObject {
    @Published var conversations: [ChatConversationResponse] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    func loadConversations() async {
        isLoading = true
        errorMessage = nil
        
        do {
            let convs = try await ChatService.shared.fetchMyConversations()
            // Trier par date du dernier message
            self.conversations = convs.sorted { $0.updatedAt > $1.updatedAt }
        } catch {
            errorMessage = "Impossible de charger les messages"
            print("Erreur chargement conversations:", error)
        }
        
        isLoading = false
    }
}
