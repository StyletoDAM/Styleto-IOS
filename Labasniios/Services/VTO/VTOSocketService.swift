//
//  VTOSocketService.swift
//  Labasniios
//
//  Created by Aziz on 6/12/2025.
//

import Foundation
import SocketIO
import Combine
import UIKit

@MainActor
final class VTOSocketService: ObservableObject {
    static let shared = VTOSocketService()
    
    private var manager: SocketManager!
    private var socket: SocketIOClient!
    
    @Published var isConnected = false
    @Published var connectionStatus = "Déconnecté"
    
    // Publisher pour les frames traitées
    private let processedFrameSubject = PassthroughSubject<UIImage, Never>()
    var processedFramePublisher: AnyPublisher<UIImage, Never> {
        processedFrameSubject.eraseToAnyPublisher()
    }
    
    // Statistiques
    @Published var fps: Int = 0
    @Published var processingTime: Int = 0
    
    private init() {}
    
    // MARK: - Setup
    func setupSocket() {
        guard let token = TokenManager.shared.getToken() else {
            print("❌ VTO: Pas de token disponible")
            return
        }
        
        // Extraire l'URL de base sans /api
        var baseURLString = APIConstants.baseURL.absoluteString
        if baseURLString.hasSuffix("/api") {
            baseURLString = String(baseURLString.dropLast(4))
        }
        
        guard let baseURL = URL(string: baseURLString) else {
            print("❌ VTO: URL invalide")
            return
        }
        
        print("🔧 VTO: Configuration socket avec URL:", baseURL.absoluteString)
        
        // Configuration du SocketManager
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
        
        // Connexion au namespace /vto
        socket = manager.socket(forNamespace: "/vto")
        
        setupListeners()
    }
    
    // MARK: - Listeners
    private func setupListeners() {
        // Connexion réussie
        socket.on(clientEvent: .connect) { [weak self] data, _ in
            Task { @MainActor in
                self?.isConnected = true
                self?.connectionStatus = "Connecté ✓"
                print("✅ VTO: Socket connecté")
            }
        }
        
        // Déconnexion
        socket.on(clientEvent: .disconnect) { [weak self] data, _ in
            Task { @MainActor in
                self?.isConnected = false
                self?.connectionStatus = "Déconnecté"
                print("🔌 VTO: Socket déconnecté")
            }
        }
        
        // Confirmation du serveur
        socket.on("connected") { data, _ in
            print("✅ VTO: Confirmation serveur reçue:", data)
        }
        
        // Frame traitée reçue
        socket.on("frame_processed") { [weak self] data, _ in
            self?.handleProcessedFrame(data)
        }
        
        // Erreur de traitement
        socket.on("frame_error") { data, _ in
            print("❌ VTO: Erreur traitement:", data)
        }
        
        // Pong (pour test ping)
        socket.on("pong") { data, _ in
            print("🏓 VTO: Pong reçu:", data)
        }
    }
    
    // MARK: - Handle Processed Frame
    private func handleProcessedFrame(_ data: [Any]) {
        guard let json = data.first as? [String: Any],
              let frameBase64 = json["frame"] as? String,
              let fps = json["fps"] as? Int,
              let processingTime = json["processingTime"] as? Int else {
            print("❌ VTO: Format de réponse invalide")
            return
        }
        
        // Mettre à jour les stats
        Task { @MainActor in
            self.fps = fps
            self.processingTime = processingTime
        }
        
        // Décoder l'image Base64
        guard let imageData = Data(base64Encoded: frameBase64),
              let image = UIImage(data: imageData) else {
            print("❌ VTO: Impossible de décoder l'image")
            return
        }
        
        // Émettre l'image traitée
        Task { @MainActor in
            self.processedFrameSubject.send(image)
        }
    }
    
    // MARK: - Public Methods
    
    /// Connecter au socket VTO
    func connect() {
        if manager == nil {
            setupSocket()
        }
        
        guard !socket.status.active else {
            print("⚠️ VTO: Socket déjà connecté")
            return
        }
        
        print("🔌 VTO: Connexion au socket...")
        socket.connect()
    }
    
    /// Déconnecter
    func disconnect() {
        socket?.disconnect()
        print("🔌 VTO: Déconnexion du socket")
    }
    
    /// Envoyer une frame pour traitement
    func processFrame(_ image: UIImage, clothingIds: [String]) {
        guard isConnected else {
            print("⚠️ VTO: Socket non connecté")
            return
        }
        
        // Redimensionner l'image (640x480 optimal)
        guard let resized = image.resized(to: CGSize(width: 640, height: 480)),
              let jpegData = resized.jpegData(compressionQuality: 0.7),
              let base64 = jpegData.base64EncodedString() as String? else {
            print("❌ VTO: Impossible de convertir l'image")
            return
        }
        
        let payload: [String: Any] = [
            "frame": base64,
            "clothingIds": clothingIds
        ]
        
        socket.emit("process_frame", payload)
    }
    
    /// Test de connexion (ping)
    func ping() {
        guard isConnected else { return }
        socket.emit("ping")
    }
}

// MARK: - UIImage Extension
extension UIImage {
    func resized(to size: CGSize) -> UIImage? {
        UIGraphicsBeginImageContextWithOptions(size, false, 1.0)
        defer { UIGraphicsEndImageContext() }
        draw(in: CGRect(origin: .zero, size: size))
        return UIGraphicsGetImageFromCurrentImageContext()
    }
}
