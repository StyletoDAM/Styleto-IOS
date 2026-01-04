import SwiftUI

struct AvatarView: View {
    
    @EnvironmentObject var viewModel: AvatarViewModel
    @State private var showExperimentalDialog = true
    @State private var hasAcceptedExperimental = false
    
    var body: some View {
        ZStack {
            if viewModel.isCameraActive && hasAcceptedExperimental {
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
        .sheet(isPresented: $showExperimentalDialog) {
            ExperimentalModeDialog {
                hasAcceptedExperimental = true
                showExperimentalDialog = false
                if !viewModel.isCameraActive {
                    viewModel.startCamera()
                }
            }
        }
        .onAppear {
            // Only start camera if user has accepted experimental mode
            if hasAcceptedExperimental && !viewModel.isCameraActive {
                viewModel.startCamera()
            }
        }
        .onDisappear {
            viewModel.stopCamera()
        }
    }
}
