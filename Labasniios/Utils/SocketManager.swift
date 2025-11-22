import Foundation
import SocketIO
import Combine

@MainActor
final class ChatSocketManager: ObservableObject {
    static let shared = ChatSocketManager()
    
    private var manager: SocketManager!
    private var socket: SocketIOClient!
    
    @Published var isConnected = false
    @Published var connectionStatus = "Déconnecté"
    
    // Publishers pour le temps réel
    private let messageSubject = PassthroughSubject<ChatMessage, Never>()
    var messagePublisher: AnyPublisher<ChatMessage, Never> {
        messageSubject.eraseToAnyPublisher()
    }
    
    private init() {
        // Ne pas se connecter automatiquement
    }
    
    func setupSocket() {
        debugToken() // ← AJOUT

        guard let token = TokenManager.shared.getToken() else {
            print("❌ Pas de token disponible")
            return
        }
        
        // Extraire l'URL de base sans le /api
        var baseURLString = APIConstants.baseURL.absoluteString
        if baseURLString.hasSuffix("/api") {
            baseURLString = String(baseURLString.dropLast(4))
        }
        
        guard let baseURL = URL(string: baseURLString) else {
            print("❌ URL invalide:", baseURLString)
            return
        }
        
        print("🔧 Configuration socket avec URL:", baseURL.absoluteString)
        print("🔑 Token complet:", token)
        
        // Configuration du SocketManager avec token dans auth
        manager = SocketManager(
            socketURL: baseURL,
            config: [
                .log(true),
                .compress,
                .reconnects(true),
                .reconnectAttempts(-1),
                .reconnectWait(2),
                .forceWebsockets(true),
                .extraHeaders(["Authorization": "Bearer \(token)"]),
                .connectParams(["token": token])
            ]
        )
        
        // Connexion au namespace /chat
        socket = manager.socket(forNamespace: "/chat")
        
        setupListeners()
    }
    
    private func setupListeners() {
        // Événements de connexion
        socket.on(clientEvent: .connect) { [weak self] data, _ in
            guard let self = self else { return }
            Task { @MainActor in
                self.isConnected = true
                self.connectionStatus = "Connecté ✓"
                print("✅ SOCKET CONNECTÉ AU CHAT")
                print("📦 Data:", data)
            }
        }
        
        socket.on(clientEvent: .disconnect) { [weak self] data, _ in
            guard let self = self else { return }
            Task { @MainActor in
                self.isConnected = false
                self.connectionStatus = "Déconnecté"
                print("🔌 SOCKET DÉCONNECTÉ:", data)
            }
        }
        
        socket.on(clientEvent: .reconnect) { [weak self] data, _ in
            guard let self = self else { return }
            Task { @MainActor in
                self.isConnected = true
                self.connectionStatus = "Reconnecté ✓"
                print("🔄 RECONNECTÉ AU CHAT:", data)
            }
        }
        
        socket.on(clientEvent: .reconnectAttempt) { [weak self] data, _ in
            guard let self = self else { return }
            Task { @MainActor in
                self.connectionStatus = "Reconnexion..."
                print("🔁 Tentative de reconnexion:", data)
            }
        }
        
        socket.on(clientEvent: .error) { data, _ in
            print("❌ ERREUR SOCKET:", data)
        }
        
        // Événement de confirmation de connexion
        socket.on("connected") { data, _ in
            print("✅ Confirmation de connexion reçue:", data)
        }
        
        // Événement principal : nouveau message en temps réel
        socket.on("new-message") { [weak self] data, _ in
            print("📨 Événement new-message reçu:", data)
            self?.handleIncomingMessage(data)
        }
        
        // Debug : tous les événements
        socket.onAny { event in
            if event.event != "ping" && event.event != "pong" {
                print("🔔 EVENT:", event.event, "→", event.items ?? [])
            }
        }
    }
    
    private func handleIncomingMessage(_ data: [Any]) {
        guard let json = data.first as? [String: Any] else {
            print("❌ Format de message invalide:", data)
            return
        }
        
        print("📝 JSON reçu:", json)
        
        do {
            let messageData = try JSONSerialization.data(withJSONObject: json)
            let decoder = JSONDecoder()
            
            // Configuration du décodeur pour les dates
            let formatter = ISO8601DateFormatter()
            formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
            
            decoder.dateDecodingStrategy = .custom { decoder in
                let container = try decoder.singleValueContainer()
                if let dateString = try? container.decode(String.self) {
                    if let date = formatter.date(from: dateString) {
                        return date
                    }
                    formatter.formatOptions = [.withInternetDateTime]
                    if let date = formatter.date(from: dateString) {
                        return date
                    }
                }
                return Date()
            }
            
            let message = try decoder.decode(ChatMessage.self, from: messageData)
            print("✅ MESSAGE DÉCODÉ:", message.content, "de", message.senderId.fullName)
            
            // Émettre le message via le publisher
            Task { @MainActor in
                self.messageSubject.send(message)
            }
            
        } catch {
            print("❌ ÉCHEC DÉCODAGE MESSAGE:", error)
            if let decodingError = error as? DecodingError {
                switch decodingError {
                case .keyNotFound(let key, let context):
                    print("Clé manquante:", key.stringValue, "contexte:", context.debugDescription)
                case .typeMismatch(let type, let context):
                    print("Type incompatible:", type, "contexte:", context.debugDescription)
                case .valueNotFound(let type, let context):
                    print("Valeur manquante:", type, "contexte:", context.debugDescription)
                case .dataCorrupted(let context):
                    print("Données corrompues:", context.debugDescription)
                @unknown default:
                    print("Erreur de décodage inconnue")
                }
            }
        }
    }
    
    // MÉTHODES PUBLIQUES
    
    func connect() {
        if manager == nil {
            setupSocket()
        }
        
        guard !socket.status.active else {
            print("⚠️ Socket déjà connecté")
            return
        }
        
        print("🔌 Connexion au socket...")
        socket.connect()
    }
    
    func disconnect() {
        socket?.disconnect()
        print("🔌 Déconnexion du socket")
    }
    
    func sendMessage(_ content: String, in conversationId: String) {
        guard isConnected else {
            print("⚠️ Socket non connecté, impossible d'envoyer le message")
            return
        }
        
        let payload: [String: Any] = [
            "conversationId": conversationId,
            "content": content
        ]
        
        print("📤 Envoi message via socket:", content)
        socket.emit("send-message", payload)
    }
    
    func joinConversation(_ conversationId: String) {
        guard isConnected else {
            print("⚠️ Socket non connecté, impossible de join")
            return
        }
        
        let payload = ["conversationId": conversationId]
        socket.emit("join-conversation", payload)
        print("🔗 Join conversation:", conversationId)
    }
    
    func sendTypingIndicator(in conversationId: String, isTyping: Bool) {
        guard isConnected else { return }
        
        let payload: [String: Any] = [
            "conversationId": conversationId,
            "isTyping": isTyping
        ]
        socket.emit("typing", payload)
    }
    func debugToken() {
        guard let token = TokenManager.shared.getToken() else {
            print("❌ PAS DE TOKEN")
            return
        }
        
        print("🔍 TOKEN DEBUG:")
        print("Longueur:", token.count)
        print("Commence par 'eyJ'?", token.hasPrefix("eyJ"))
        print("Token complet:", token)
        
        // Décoder le payload JWT (la partie du milieu)
        let parts = token.split(separator: ".")
        if parts.count == 3 {
            let payloadPart = String(parts[1])
            // Ajouter le padding si nécessaire
            var base64 = payloadPart
                .replacingOccurrences(of: "-", with: "+")
                .replacingOccurrences(of: "_", with: "/")
            while base64.count % 4 != 0 {
                base64 += "="
            }
            
            if let data = Data(base64Encoded: base64),
               let json = try? JSONSerialization.jsonObject(with: data) {
                print("Payload décodé:", json)
            }
        }
    }
}
