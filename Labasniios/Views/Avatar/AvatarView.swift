import SwiftUI

struct AvatarView: View {
    
    @EnvironmentObject var viewModel: AvatarViewModel
    var body: some View {
        ZStack {
            if viewModel.isCameraActive {
                CameraOverlayView(viewModel: viewModel)
            } else {
                
                VStack(spacing: 30) {
                    Image(systemName: "camera.fill")
                        .font(.system(size: 80))
                        .foregroundColor(.themePrimary.opacity(0.6))
                    
                    Text("Real Time Try-On")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(.themeTeal)
                    
                    Text("Press the central button to start")
                        .font(.subheadline)
                        .foregroundColor(.themeSecondaryText)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color.themeBackground.ignoresSafeArea())
            }
        }
        .onAppear {
            if !viewModel.isCameraActive {
                viewModel.startCamera()
            }
        }
        .onDisappear {
            viewModel.stopCamera()
        }
    }
}
