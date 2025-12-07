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
    @Published var errorMessage: String?  // ✅ Pour afficher erreurs
    
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
    private let throttleInterval: TimeInterval = 0.3  // ✅ 3-4 FPS (plus lent = plus stable)
    
    // Queue
    private var pendingFrame: UIImage?
    private var processingTimer: Timer?
    
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
        processedImage = nil  // ✅ Reset l'image
        
        print("🛑 Caméra arrêtée")
    }
    
    private func setupCamera() {
        cameraSession.sessionPreset = .medium  // 640x480 pour perfs
        
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
        
        if cameraSession.canAddOutput(output) {
            cameraSession.addOutput(output)
        }
        videoOutput = output
        
        cameraSession.commitConfiguration()
        print("✅ Caméra configurée")
    }
    
    // Capture frames (background thread)
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        guard selectedClothe != nil else { return }
        
        guard let imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
        
        let ciImage = CIImage(cvPixelBuffer: imageBuffer)
        let context = CIContext()
        guard let cgImage = context.createCGImage(ciImage, from: ciImage.extent) else { return }
        
        var image = UIImage(cgImage: cgImage, scale: 1.0, orientation: .leftMirrored)
        
        // Compression aggressive pour réduire la latence
        if let compressed = image.jpegData(compressionQuality: 0.4) {
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
    
    // ✅ CORRIGÉ: Payload conforme au backend Python
    private func sendFrameToServer(frame: UIImage, clothe: Clothe) {
        guard let base64 = frame.jpegData(compressionQuality: 0.4)?.base64EncodedString() else {
            print("❌ Impossible d'encoder l'image")
            return
        }
        
        isProcessing = true
        errorMessage = nil
        
        // ✅ STRUCTURE CORRECTE (conforme à ProcessFrameRequest du Python)
        let payload: [String: Any] = [
            "frame": base64,
            "clothes": [
                [
                    "imageURL": clothe.imageURL,
                    "processedImageURL": clothe.processedImageURL ?? clothe.imageURL,  // Fallback important
                    "category": clothe.category ?? "top"
                ]
            ]
        ]
        
        socket?.emit("process_frame", payload)
        print("📤 Frame envoyée (\(base64.count / 1024)KB) - Vêtement: \(clothe.category ?? "unknown")")
    }
    
    private func setupSocket() {
        guard let url = URL(string: APIConstants.baseURL.absoluteString),
              let token = TokenManager.shared.getToken() else {
            print("❌ Impossible de configurer le socket (URL ou token manquant)")
            return
        }
        
        socketManager = SocketManager(socketURL: url, config: [
            .log(false),
            .connectParams(["token": token]),
            .reconnects(true),
            .reconnectWait(3),
            .reconnectAttempts(3)
        ])
        
        socket = socketManager?.socket(forNamespace: "/vto")
        
        // Connexion
        socket?.on(clientEvent: .connect) { [weak self] _, _ in
            Task { @MainActor in
                print("✅ WebSocket VTO connecté")
                self?.errorMessage = nil
            }
        }
        
        // Frame traitée (SUCCESS)
        socket?.on("frame_processed") { [weak self] data, _ in
            guard let self = self else { return }
            
            Task { @MainActor in
                self.isProcessing = false
                
                guard let dict = data[0] as? [String: Any],
                      let base64 = dict["frame"] as? String,
                      let imageData = Data(base64Encoded: base64),
                      let image = UIImage(data: imageData) else {
                    print("❌ Frame traitée invalide")
                    self.errorMessage = "Données invalides reçues"
                    return
                }
                
                self.processedImage = image
                print("✅ Frame traitée reçue (\(imageData.count / 1024)KB)")
            }
        }
        
        // Erreur traitement
        socket?.on("frame_error") { [weak self] data, _ in
            Task { @MainActor in
                self?.isProcessing = false
                
                if let dict = data[0] as? [String: Any],
                   let error = dict["error"] as? String {
                    print("❌ Erreur: \(error)")
                    self?.errorMessage = error
                } else {
                    print("❌ Erreur inconnue: \(data)")
                    self?.errorMessage = "Erreur de traitement"
                }
            }
        }
        
        // Erreur générale
        socket?.on(clientEvent: .error) { data, _ in
            print("❌ Socket error: \(data)")
        }
        
        // Déconnexion
        socket?.on(clientEvent: .disconnect) { data, _ in
            print("⚠️ Socket déconnecté: \(data)")
        }
        
        socket?.connect()
        print("🔌 Connexion au WebSocket VTO...")
    }
    
    private func fetchClothes() {
        clothesService.fetchMyClothes { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .success(let clothes):
                    self?.clothes = clothes
                    print("✅ \(clothes.count) vêtements chargés")
                    
                    // Debug: Afficher les URLs
                    for clothe in clothes {
                        print("  - \(clothe.category ?? "unknown"): \(clothe.imageURL)")
                        if let processed = clothe.processedImageURL {
                            print("    Processed: \(processed)")
                        }
                    }
                    
                case .failure(let error):
                    print("❌ Erreur chargement vêtements: \(error)")
                    self?.errorMessage = "Impossible de charger les vêtements"
                }
            }
        }
    }
}
