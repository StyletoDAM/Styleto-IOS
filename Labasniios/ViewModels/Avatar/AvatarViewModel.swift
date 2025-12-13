import Foundation
import UIKit
import AVFoundation
import Combine
import SocketIO

@MainActor
class AvatarViewModel: NSObject, ObservableObject, AVCaptureVideoDataOutputSampleBufferDelegate {
    @Published var clothes: [Clothe] = []
    @Published var selectedClothe: Clothe?
    @Published var isCameraActive = false
    @Published var processedImage: UIImage?
    @Published var isProcessing = false
    @Published var errorMessage: String?
    @Published var fps: Int = 0  // ✅ Afficher FPS réel
    
    private var cancellables = Set<AnyCancellable>()
    private let clothesService = ClothesService.shared
    
    // Caméra
    let cameraSession = AVCaptureSession()
    private var cameraInput: AVCaptureDeviceInput?
    private var videoOutput: AVCaptureVideoDataOutput?
    
    // WebSocket
    private var socketManager: SocketManager?
    private var socket: SocketIOClient?
    private var lastSendTime: Date = .distantPast
    private let throttleInterval: TimeInterval = 0.25  // ✅ 4 FPS (était 0.3)
    
    // Queue
    private var pendingFrame: UIImage?
    private var processingTimer: Timer?
    
    // ✅ NOUVEAU : Compression adaptative
    private var currentQuality: CGFloat = 0.4
    private var lastProcessingTime: TimeInterval = 0
    
    override init() {
        super.init()
        setupCamera()
        fetchClothes()
        setupSocket()
    }
    
    func startCamera() {
        guard !cameraSession.isRunning else { return }
        DispatchQueue.global(qos: .background).async {
            self.cameraSession.startRunning()
        }
        isCameraActive = true
        startProcessingLoop()
        
        print("🎥 Caméra démarrée")
    }
    
    func stopCamera() {
        cameraSession.stopRunning()
        isCameraActive = false
        socket?.disconnect()
        stopProcessingLoop()
        processedImage = nil
        
        print("🛑 Caméra arrêtée")
    }
    
    private func setupCamera() {
        // ✅ OPTIMISATION : Résolution plus faible (640x480 au lieu de 1280x720)
        cameraSession.sessionPreset = .vga640x480
        
        guard let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front),
              let input = try? AVCaptureDeviceInput(device: device) else {
            print("❌ Impossible d'accéder à la caméra")
            return
        }
        
        cameraInput = input
        cameraSession.beginConfiguration()
        
        if cameraSession.canAddInput(input) {
            cameraSession.addInput(input)
        }
        
        let output = AVCaptureVideoDataOutput()
        output.setSampleBufferDelegate(self, queue: DispatchQueue(label: "videoQueue"))
        output.videoSettings = [kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA]
        
        // ✅ OPTIMISATION : Désactiver buffers en attente
        output.alwaysDiscardsLateVideoFrames = true
        
        if cameraSession.canAddOutput(output) {
            cameraSession.addOutput(output)
        }
        videoOutput = output
        
        cameraSession.commitConfiguration()
        print("✅ Caméra configurée (640x480, quality adaptative)")
    }
    
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        guard selectedClothe != nil else { return }
        guard !isProcessing else { return }  // ✅ Skip si déjà en traitement
        
        guard let imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
        
        let ciImage = CIImage(cvPixelBuffer: imageBuffer)
        let context = CIContext()
        guard let cgImage = context.createCGImage(ciImage, from: ciImage.extent) else { return }
        
        var image = UIImage(cgImage: cgImage, scale: 1.0, orientation: .leftMirrored)
        
        // ✅ OPTIMISATION : Redimensionner avant compression
        let maxWidth: CGFloat = 480  // Réduit de 640
        if image.size.width > maxWidth {
            let ratio = maxWidth / image.size.width
            let newSize = CGSize(width: maxWidth, height: image.size.height * ratio)
            UIGraphicsBeginImageContext(newSize)
            image.draw(in: CGRect(origin: .zero, size: newSize))
            image = UIGraphicsGetImageFromCurrentImageContext() ?? image
            UIGraphicsEndImageContext()
        }
        
        // ✅ OPTIMISATION : Compression adaptative selon latence
        if let compressed = image.jpegData(compressionQuality: currentQuality) {
            image = UIImage(data: compressed) ?? image
        }
        
        pendingFrame = image
    }
    
    private func startProcessingLoop() {
        processingTimer = Timer.scheduledTimer(withTimeInterval: throttleInterval, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            
            Task { @MainActor in
                guard !self.isProcessing,
                      let frame = self.pendingFrame,
                      let selected = self.selectedClothe else { return }
                
                self.sendFrameToServer(frame: frame, clothe: selected)
            }
        }
    }
    
    private func stopProcessingLoop() {
        processingTimer?.invalidate()
        processingTimer = nil
        pendingFrame = nil
    }
    
    private func sendFrameToServer(frame: UIImage, clothe: Clothe) {
        guard let base64 = frame.jpegData(compressionQuality: currentQuality)?.base64EncodedString() else {
            print("❌ Impossible d'encoder l'image")
            return
        }
        
        let startTime = Date()
        isProcessing = true
        errorMessage = nil
        
        let payload: [String: Any] = [
            "frame": base64,
            "clothes": [
                [
                    "imageURL": clothe.imageURL,
                    "processedImageURL": clothe.processedImageURL ?? clothe.imageURL,
                    "category": clothe.category ?? "top"
                ]
            ]
        ]
        
        socket?.emit("process_frame", payload)
        
        let sizeKB = base64.count / 1024
        print("📤 Frame envoyée (\(sizeKB)KB, Q:\(Int(currentQuality * 100))%) - \(clothe.category ?? "unknown")")
        
        // ✅ Timeout de 5 secondes
        DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) { [weak self] in
            guard let self = self else { return }
            if self.isProcessing {
                self.isProcessing = false
                self.errorMessage = "Timeout (>5s)"
                print("⏱️ Timeout détecté")
            }
        }
    }
    
    private func setupSocket() {
        guard let url = URL(string: APIConstants.baseURL.absoluteString),
              let token = TokenManager.shared.getToken() else {
            print("❌ Impossible de configurer le socket")
            return
        }
        
        socketManager = SocketManager(socketURL: url, config: [
            .log(false),
            .connectParams(["token": token]),
            .reconnects(true),
            .reconnectWait(2),
            .reconnectAttempts(5),
            .compress  // ✅ Compression WebSocket
        ])
        
        socket = socketManager?.socket(forNamespace: "/vto")
        
        socket?.on(clientEvent: .connect) { [weak self] _, _ in
            Task { @MainActor in
                print("✅ WebSocket VTO connecté")
                self?.errorMessage = nil
            }
        }
        
        socket?.on("frame_processed") { [weak self] data, _ in
            guard let self = self else { return }
            
            Task { @MainActor in
                let processingTime = Date().timeIntervalSince(Date())
                self.isProcessing = false
                
                guard let dict = data[0] as? [String: Any],
                      let base64 = dict["frame"] as? String,
                      let imageData = Data(base64Encoded: base64),
                      let image = UIImage(data: imageData) else {
                    print("❌ Frame invalide")
                    self.errorMessage = "Données invalides"
                    return
                }
                
                self.processedImage = image
                
                // ✅ Calculer FPS réel
                if let serverTime = dict["processingTime"] as? Double {
                    self.lastProcessingTime = serverTime / 1000.0
                    self.fps = Int(1000.0 / serverTime)
                    
                    // ✅ Ajuster qualité selon latence
                    self.adjustQuality(latency: serverTime)
                    
                    print("✅ Frame OK (\(Int(serverTime))ms, \(self.fps) FPS)")
                }
            }
        }
        
        socket?.on("frame_error") { [weak self] data, _ in
            Task { @MainActor in
                self?.isProcessing = false
                
                if let dict = data[0] as? [String: Any],
                   let error = dict["error"] as? String {
                    print("❌ Erreur: \(error)")
                    self?.errorMessage = error
                } else {
                    self?.errorMessage = "Erreur de traitement"
                }
            }
        }
        
        socket?.on(clientEvent: .error) { data, _ in
            print("❌ Socket error: \(data)")
        }
        
        socket?.on(clientEvent: .disconnect) { data, _ in
            print("⚠️ Socket déconnecté: \(data)")
        }
        
        socket?.connect()
        print("🔌 Connexion WebSocket VTO...")
    }
    
    // ✅ NOUVEAU : Ajustement qualité automatique
    private func adjustQuality(latency: Double) {
        if latency > 1500 {
            // Très lent : baisser qualité
            currentQuality = max(0.2, currentQuality - 0.05)
            print("⚠️ Latence élevée (\(Int(latency))ms) → Qualité: \(Int(currentQuality * 100))%")
        } else if latency < 500 && currentQuality < 0.5 {
            // Rapide : augmenter qualité
            currentQuality = min(0.5, currentQuality + 0.05)
            print("✅ Latence basse (\(Int(latency))ms) → Qualité: \(Int(currentQuality * 100))%")
        }
    }
    
    private func fetchClothes() {
        clothesService.fetchMyClothes { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .success(let clothes):
                    self?.clothes = clothes
                    print("✅ \(clothes.count) vêtements chargés")
                    
                case .failure(let error):
                    print("❌ Erreur: \(error)")
                    self?.errorMessage = "Impossible de charger"
                }
            }
        }
    }
}
