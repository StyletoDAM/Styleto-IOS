//
//  SocketManager.swift
//  Labasniios
//
//  Gestionnaire WebSocket pour le chat en temps réel
//
//  Ce fichier gère la connexion WebSocket pour le chat en temps réel
//  dans l'application Labasni. Il utilise Socket.IO pour établir une
//  connexion bidirectionnelle avec le serveur et recevoir les messages
//  instantanément sans polling.
//
//  Architecture : Singleton avec ObservableObject (Combine)
//  Dépendances : Foundation, SocketIO, Combine
//

import Foundation
import SocketIO
import Combine

/**
 * Gestionnaire WebSocket pour le chat en temps réel
 * 
 * Cette classe gère la connexion WebSocket pour le chat en temps réel
 * dans le contexte du marketplace. Elle est marquée @MainActor pour
 * garantir que toutes les opérations se déroulent sur le thread principal.
 * 
 * Fonctionnalités :
 * - Connexion/déconnexion au serveur WebSocket
 * - Réception de messages en temps réel
 * - Gestion automatique de la reconnexion
 * - Publication des messages via Combine Publishers
 * - Authentification via token JWT
 * 
 * Le WebSocket est utilisé pour recevoir les messages instantanément
 * sans avoir besoin de polling régulier, améliorant ainsi l'expérience
 * utilisateur et réduisant la charge serveur.
 * 
 * @see ObservableObject pour la réactivité avec SwiftUI
 * @see @MainActor pour l'exécution sur le thread principal
 * @see SocketIO pour la bibliothèque WebSocket
 */
@MainActor
final class ChatSocketManager: ObservableObject {
    static let shared = ChatSocketManager()
    
    private var manager: SocketManager!
    private var socket: SocketIOClient!
    private var configuredToken: String? // ✨ Stocker le token utilisé lors de la configuration
    
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
        debugToken()

        guard let token = TokenManager.shared.getToken() else {
            print("❌ [SocketManager] Pas de token disponible")
            return
        }
        
        // ✨ CRITIQUE : Extraire l'userId du JWT pour les logs
        let currentUserId = JWTDecoder.extractUserId(from: token)
        print("═══════════════════════════════════════════════════════════")
        print("🔌 [SocketManager] Connexion au socket...")
        print("   Token: \(token.prefix(20))...")
        print("   Current User ID (from JWT): '\(currentUserId ?? "nil")'")
        print("═══════════════════════════════════════════════════════════")
        
        // Extraire l'URL de base sans le /api
        var baseURLString = APIConstants.baseURL.absoluteString
        if baseURLString.hasSuffix("/api") {
            baseURLString = String(baseURLString.dropLast(4))
        }
        
        guard let baseURL = URL(string: baseURLString) else {
            print("❌ [SocketManager] URL invalide:", baseURLString)
            return
        }
        
        print("🔧 [SocketManager] Configuration socket avec URL:", baseURL.absoluteString)
        
        // Configuration du SocketManager avec token dans auth
        manager = SocketManager(
            socketURL: baseURL,
            config: [
                .log(false),
                .compress,
                .reconnects(true),
                .reconnectAttempts(-1),
                .reconnectWait(2),
                .forceWebsockets(true),
                .extraHeaders(["Authorization": "Bearer \(token)"]),
                .connectParams(["token": token]),
                .path("/socket.io/")
            ]
        )
        
        // ✨ CRITIQUE : Stocker le token utilisé pour la configuration
        configuredToken = token
        
        // Connexion au namespace /chat
        socket = manager.socket(forNamespace: "/chat")
        
        // ✨ CRITIQUE : Nettoyer les listeners AVANT de les reconfigurer
        // Supprimer tous les handlers existants
        socket.removeAllHandlers()
        
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
        print("═══════════════════════════════════════════════════════════")
        print("📨 [SocketManager] Nouveau message reçu via socket")
        print("   Data brut: \(data)")
        
        guard let messageDict = data.first as? [String: Any] else {
            print("❌ [SocketManager] Format de données invalide")
            print("═══════════════════════════════════════════════════════════")
            return
        }
        
        print("   📦 Message Dict: \(messageDict)")
        
        // ✨ CRITIQUE : Extraire les informations pour logs
        if let senderDict = messageDict["senderId"] as? [String: Any] {
            let senderId = (senderDict["_id"] as? String) ?? (senderDict["id"] as? String) ?? ""
            let senderName = senderDict["fullName"] as? String ?? "Unknown"
            
            // Récupérer l'ID de l'utilisateur actuel depuis le JWT
            let currentUserId = TokenManager.shared.getUserId() ?? JWTDecoder.extractUserId(from: TokenManager.shared.getToken() ?? "")
            let normalizedSenderId = JWTDecoder.normalizeId(senderId)
            let normalizedUserId = JWTDecoder.normalizeId(currentUserId ?? "")
            
            print("   👤 Sender Info:")
            print("      - ID (raw): '\(senderId)'")
            print("      - ID (normalized): '\(normalizedSenderId)'")
            print("      - Name: '\(senderName)'")
            print("   🔑 Current User Info:")
            print("      - ID (raw): '\(currentUserId ?? "nil")'")
            print("      - ID (normalized): '\(normalizedUserId)'")
            print("   ✅ Comparaison:")
            print("      - IDs match: \(normalizedSenderId == normalizedUserId && !normalizedSenderId.isEmpty)")
            print("      - Alignment: \(normalizedSenderId == normalizedUserId ? "➡️ DROITE (Outgoing)" : "⬅️ GAUCHE (Incoming)")")
        }
        
        do {
            // Convertir en Data pour décoder
            let messageData = try JSONSerialization.data(withJSONObject: messageDict)
            
            // Configuration du décodeur pour les dates
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .custom { decoder in
                let container = try decoder.singleValueContainer()
                if let dateString = try? container.decode(String.self) {
                    let formatter = ISO8601DateFormatter()
                    formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
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
            
            print("   ✅ Message décodé avec succès:")
            print("      - ID: '\(message.id)'")
            print("      - Content: '\(message.content)'")
            print("      - Sender ID: '\(message.senderId.id)'")
            print("      - Sender Name: '\(message.senderId.fullName)'")
            print("      - Conversation ID: '\(message.conversationId)'")
            print("═══════════════════════════════════════════════════════════")
            
            // Publier le message pour que les vues l'affichent
            Task { @MainActor in
                self.messageSubject.send(message)
            }
            
        } catch {
            print("❌ [SocketManager] Erreur de décodage:", error)
            if let decodingError = error as? DecodingError {
                switch decodingError {
                case .keyNotFound(let key, let context):
                    print("   Clé manquante: \(key.stringValue)")
                    print("   Context: \(context.debugDescription)")
                case .typeMismatch(let type, let context):
                    print("   Type mismatch: \(type)")
                    print("   Context: \(context.debugDescription)")
                case .valueNotFound(let type, let context):
                    print("   Valeur non trouvée: \(type)")
                    print("   Context: \(context.debugDescription)")
                case .dataCorrupted(let context):
                    print("   Données corrompues: \(context.debugDescription)")
                @unknown default:
                    print("   Erreur inconnue")
                }
            }
            print("═══════════════════════════════════════════════════════════")
        }
    }
    
    // MÉTHODES PUBLIQUES
    
    func connect() {
        // ✨ CRITIQUE : Vérifier si le token a changé
        // Si le token actuel est différent de celui utilisé pour configurer le socket, reconfigurer
        guard let currentToken = TokenManager.shared.getToken() else {
            print("❌ [SocketManager] Pas de token disponible pour la connexion")
            return
        }
        
        // Si le manager existe déjà, vérifier si le token a changé
        if manager != nil, let oldToken = configuredToken {
            if oldToken != currentToken {
                print("🔄 [SocketManager] Token a changé !")
                print("   - Ancien token (user): '\(JWTDecoder.extractUserId(from: oldToken) ?? "nil")'")
                print("   - Nouveau token (user): '\(JWTDecoder.extractUserId(from: currentToken) ?? "nil")'")
                print("   - Reconnexion avec le nouveau token...")
                disconnect()
                setupSocket()
            }
        } else {
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
        print("🔌 [SocketManager] Déconnexion...")
        socket?.removeAllHandlers()  // ✨ Nettoyer tous les listeners
        socket?.disconnect()
        isConnected = false
        configuredToken = nil // ✨ Réinitialiser le token stocké
    }
    
    func sendMessage(_ content: String, in conversationId: String) {
        guard isConnected else {
            print("⚠️ [SocketManager] Socket non connecté, impossible d'envoyer le message")
            return
        }
        
        // ✨ CRITIQUE : Récupérer l'ID de l'utilisateur actuel
        guard let currentUserId = TokenManager.shared.getUserId() ?? JWTDecoder.extractUserId(from: TokenManager.shared.getToken() ?? "") else {
            print("❌ [SocketManager] Pas d'ID utilisateur disponible")
            return
        }
        
        let normalizedUserId = JWTDecoder.normalizeId(currentUserId)
        
        print("═══════════════════════════════════════════════════════════")
        print("📤 [SocketManager] Envoi du message:")
        print("   Content: '\(content)'")
        print("   Conversation ID: '\(conversationId)'")
        print("   Sender ID (raw): '\(currentUserId)'")
        print("   Sender ID (normalized): '\(normalizedUserId)'")
        print("   ⚠️ IMPORTANT: Ce message DOIT s'afficher à DROITE (Outgoing)")
        print("═══════════════════════════════════════════════════════════")
        
        // ✨ CRITIQUE : Inclure le token actuel dans le payload pour que le backend puisse le re-vérifier
        guard let currentToken = TokenManager.shared.getToken() else {
            print("❌ [SocketManager] Pas de token disponible pour l'envoi")
            return
        }
        
        let payload: [String: Any] = [
            "conversationId": conversationId,
            "content": content,
            "token": currentToken  // ✨ NOUVEAU : Inclure le token actuel
        ]
        
        print("📤 [SocketManager] Envoi avec token actuel (user: '\(JWTDecoder.extractUserId(from: currentToken) ?? "nil")')")
        socket.emit("send-message", payload)
    }
    
    func joinConversation(_ conversationId: String) {
        guard isConnected else {
            print("⚠️ [SocketManager] Socket non connecté, impossible de join")
            return
        }
        
        print("═══════════════════════════════════════════════════════════")
        print("🚪 [SocketManager] Rejoindre conversation:")
        print("   Conversation ID: '\(conversationId)'")
        
        // Récupérer l'ID de l'utilisateur actuel pour logs
        let currentUserId = TokenManager.shared.getUserId() ?? JWTDecoder.extractUserId(from: TokenManager.shared.getToken() ?? "")
        print("   Current User ID: '\(currentUserId ?? "nil")'")
        print("═══════════════════════════════════════════════════════════")
        
        let payload = ["conversationId": conversationId]
        socket.emit("join-conversation", payload)
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
