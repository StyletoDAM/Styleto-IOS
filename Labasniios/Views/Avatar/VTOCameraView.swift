//
//  VTOCameraView.swift
//  Labasniios
//
//  Created by Aziz on 6/12/2025.
//

import SwiftUI
import AVFoundation

struct VTOCameraView: View {
    @ObservedObject var viewModel: VTOViewModel
    
    var body: some View {
        ZStack {
            // Preview vidéo
            if let frame = viewModel.currentFrame {
                Image(uiImage: frame)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                CameraPreview(session: viewModel.cameraSession)
                    .ignoresSafeArea()
            }
            
            // Overlay UI
            VStack {
                // Header avec stats
                VTOHeaderView(
                    isConnected: viewModel.isConnected,
                    fps: viewModel.fps,
                    selectedCount: viewModel.selectedClothingIds.count
                )
                
                Spacer()
                
                // Sélecteur de vêtements
                VTOClothingSelector(
                    clothesByCategory: viewModel.clothesByCategory,
                    selectedIds: viewModel.selectedClothingIds,
                    onToggle: { viewModel.toggleSelection($0) }
                )
                .frame(height: 250)
                
                // Contrôles
                VTOControlsView(
                    isStreaming: viewModel.isStreaming,
                    onStart: { viewModel.startStreaming() },
                    onStop: { viewModel.stopStreaming() },
                    onClear: { viewModel.clearSelection() }
                )
                .padding(.bottom, 20)
            }
        }
        .task {
            await viewModel.loadClothes()
        }
    }
}

// MARK: - Header
struct VTOHeaderView: View {
    let isConnected: Bool
    let fps: Int
    let selectedCount: Int
    
    var body: some View {
        HStack {
            Circle()
                .fill(isConnected ? Color.green : Color.red)
                .frame(width: 12, height: 12)
            Text(isConnected ? "Connecté" : "Déconnecté")
                .foregroundColor(.white)
            
            Spacer()
            
            Text("\(fps) FPS")
                .foregroundColor(.white)
            
            Text("| \(selectedCount) vêtements")
                .foregroundColor(.white)
        }
        .padding()
        .background(Color.black.opacity(0.7))
    }
}

// MARK: - Controls
struct VTOControlsView: View {
    let isStreaming: Bool
    let onStart: () -> Void
    let onStop: () -> Void
    let onClear: () -> Void
    
    var body: some View {
        HStack(spacing: 20) {
            Button(action: isStreaming ? onStop : onStart) {
                Image(systemName: isStreaming ? "stop.circle.fill" : "play.circle.fill")
                    .font(.system(size: 60))
                    .foregroundColor(.white)
            }
            
            Button(action: onClear) {
                Image(systemName: "trash.circle.fill")
                    .font(.system(size: 50))
                    .foregroundColor(.red)
            }
        }
        .padding()
    }
}
