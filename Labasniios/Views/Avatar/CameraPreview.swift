import SwiftUI
import AVFoundation

class CameraPreviewUIView: UIView {
    var session: AVCaptureSession
    private var previewLayer: AVCaptureVideoPreviewLayer!
    
    init(session: AVCaptureSession) {
        self.session = session
        super.init(frame: .zero)
        
        previewLayer = AVCaptureVideoPreviewLayer(session: session)
        previewLayer.videoGravity = .resizeAspectFill
        layer.addSublayer(previewLayer)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        previewLayer.frame = bounds
    }
}

struct CameraPreview: UIViewRepresentable {
    let session: AVCaptureSession
    
    func makeUIView(context: Context) -> CameraPreviewUIView {
        CameraPreviewUIView(session: session)
    }
    
    func updateUIView(_ uiView: CameraPreviewUIView, context: Context) {
    }
}
