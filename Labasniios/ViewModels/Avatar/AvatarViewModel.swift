// ViewModels/AvatarViewModel.swift
import Foundation
import AVFoundation
import Combine

@MainActor
class AvatarViewModel: ObservableObject {
    @Published var clothes: [Clothe] = []
    @Published var selectedClothe: Clothe?
    @Published var isCameraActive = false
    
    private var cancellables = Set<AnyCancellable>()
    private let clothesService = ClothesService.shared
    
    // Caméra
    let cameraSession = AVCaptureSession()
    private var cameraInput: AVCaptureDeviceInput?
    
    init() {
        setupCamera()
        fetchClothes()
    }
    
    func startCamera() {
        guard !cameraSession.isRunning else { return }
        DispatchQueue.global(qos: .background).async {
            self.cameraSession.startRunning()
        }
        isCameraActive = true
    }
    
    func stopCamera() {
        cameraSession.stopRunning()
        isCameraActive = false
    }
    
    private func setupCamera() {
        guard let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front),
              let input = try? AVCaptureDeviceInput(device: device) else { return }
        
        cameraInput = input
        cameraSession.beginConfiguration()
        if cameraSession.canAddInput(input) {
            cameraSession.addInput(input)
        }
        cameraSession.commitConfiguration()
    }
    
    private func fetchClothes() {
        clothesService.fetchMyClothes { [weak self] result in
            DispatchQueue.main.async {
                if case .success(let clothes) = result {
                    self?.clothes = clothes
                }
            }
        }
    }
}
