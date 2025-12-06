//
//  VTOViewModel.swift
//  Labasniios
//
//  Created by Aziz on 6/12/2025.
//

import Foundation
import AVFoundation
import Combine
import UIKit

@MainActor
class VTOViewModel: NSObject, ObservableObject {
    // MARK: - Published Properties
    @Published var clothesByCategory: [String: [VTOClothe]] = [:]
    @Published var selectedClothingIds: Set<String> = []
    @Published var isLoading = true
    @Published var isStreaming = false
    @Published var errorMessage: String?
    
    // Stats
    @Published var fps: Int = 0
    @Published var processingTime: Int = 0
    @Published var isConnected = false
    
    // Frame actuelle (pour affichage)
    @Published var currentFrame: UIImage?
    
    // MARK: - Services
    private let clothesService = VTOClothesService.shared
    private let socketService = VTOSocketService.shared
    
    // MARK: - Camera
    private let captureSession = AVCaptureSession()
    private var videoOutput: AVCaptureVideoDataOutput?
    private let videoQueue = DispatchQueue(label: "com.labasni.vto.video")
    
    var cameraSession: AVCaptureSession {
        captureSession
    }
    
    // MARK: - Combine
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Init
    override init() {
        super.init()
        setupCamera()
        setupSubscriptions()
    }
    
    // MARK: - Setup
    
    private func setupCamera() {
        captureSession.sessionPreset = .vga640x480
        
        guard let camera = AVCaptureDevice.default(.builtInWideAngleCamera,
                                                   for: .video,
                                                   position: .front),
              let input = try? AVCaptureDeviceInput(device: camera) else {
            print("❌ VTO: Impossible d'initialiser la caméra")
            return
        }
        
        if captureSession.canAddInput(input) {
            captureSession.addInput(input)
        }
        
        let output = AVCaptureVideoDataOutput()
        output.setSampleBufferDelegate(self, queue: videoQueue)
        output.videoSettings = [
            kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA
        ]
        
        if captureSession.canAddOutput(output) {
            captureSession.addOutput(output)
        }
        
        videoOutput = output
    }
    
    private func setupSubscriptions() {
        // Écouter les frames traitées du socket
        socketService.processedFramePublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] image in
                self?.currentFrame = image
            }
            .store(in: &cancellables)
        
        // Écouter le statut de connexion
        socketService.$isConnected
            .receive(on: DispatchQueue.main)
            .assign(to: &$isConnected)
        
        // Écouter les stats
        socketService.$fps
            .receive(on: DispatchQueue.main)
            .assign(to: &$fps)
        
        socketService.$processingTime
            .receive(on: DispatchQueue.main)
            .assign(to: &$processingTime)
    }
    
    // MARK: - Load Clothes
    
    func loadClothes() async {
        isLoading = true
        errorMessage = nil
        
        do {
            let clothes = try await clothesService.fetchVTOReadyClothes()
            self.clothesByCategory = clothes
            self.isLoading = false
        } catch {
            self.errorMessage = "Erreur chargement: \(error.localizedDescription)"
            self.isLoading = false
        }
    }
    
    // MARK: - Streaming Control
    
    func startStreaming() {
        guard !selectedClothingIds.isEmpty else {
            errorMessage = "Sélectionnez au moins un vêtement"
            return
        }
        
        // Connecter le socket
        socketService.connect()
        
        // Démarrer la caméra
        DispatchQueue.global(qos: .userInitiated).async {
            self.captureSession.startRunning()
        }
        
        isStreaming = true
        errorMessage = nil
    }
    
    func stopStreaming() {
        captureSession.stopRunning()
        socketService.disconnect()
        isStreaming = false
        currentFrame = nil
    }
    
    // MARK: - Selection
    
    func toggleSelection(_ clothe: VTOClothe) {
        if selectedClothingIds.contains(clothe.id) {
            selectedClothingIds.remove(clothe.id)
        } else {
            selectedClothingIds.insert(clothe.id)
        }
    }
    
    func clearSelection() {
        selectedClothingIds.removeAll()
    }
}

// MARK: - AVCaptureVideoDataOutputSampleBufferDelegate
extension VTOViewModel: AVCaptureVideoDataOutputSampleBufferDelegate {
    nonisolated func captureOutput(
        _ output: AVCaptureOutput,
        didOutput sampleBuffer: CMSampleBuffer,
        from connection: AVCaptureConnection
    ) {
        guard let imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else {
            return
        }
        
        let ciImage = CIImage(cvPixelBuffer: imageBuffer)
        let context = CIContext()
        
        guard let cgImage = context.createCGImage(ciImage, from: ciImage.extent) else {
            return
        }
        
        let image = UIImage(cgImage: cgImage)
        
        Task { @MainActor in
            // Envoyer la frame au serveur si streaming actif
            if self.isStreaming && self.isConnected {
                self.socketService.processFrame(
                    image,
                    clothingIds: Array(self.selectedClothingIds)
                )
            } else {
                // Sinon, afficher la frame brute
                self.currentFrame = image
            }
        }
    }
}
