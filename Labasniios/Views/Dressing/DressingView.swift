import SwiftUI
import UIKit

struct DressingView: View {
    @StateObject private var viewModel = DressingViewModel()
    @ObservedObject private var themeManager = ThemeManager.shared
    @ObservedObject private var appPreferences = AppPreferences.shared
    @State private var showCamera = false
    @State private var capturedImage: UIImage?
    @State private var searchText = ""
    @State private var showDetectionResult = false
    @State private var detectedImage: UIImage?
    @State private var detectionText = ""
    @State private var isUploading = false
    @State private var detectedImageURL: String?
    @State private var showAIErrorAlert = false
    @State private var aiErrorMessage = ""
    @State private var showPhotoGuide = false
    @State private var selectedClothe: Clothe?
    
    private let columns: [GridItem] = [
        GridItem(.flexible(), spacing: 16),
        GridItem(.flexible(), spacing: 16)
    ]
    
    private let categories = ["All", "Top", "Bottom", "Dress", "Shoes", "Accessory", "Jacket"]
    
    var body: some View {
        ZStack {
            // Scrollable Content
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    header
                    searchAndFilter
                    categoryChips
                    clothesGrid
                }
                .padding(.horizontal, 16)
                .padding(.top, 12)
                .padding(.bottom, 80)
            }
            .background(Color.themeBackground.ignoresSafeArea())
            .refreshable { viewModel.fetchClothes() }
            
            // Bouton flottant EN BAS À DROITE
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    floatingAddButton
                        .padding(.trailing, 20)
                        .padding(.bottom, 20)
                }
            }
        }
        .navigationBarBackButtonHidden(true)
        .toolbar(.hidden, for: .navigationBar)
        .onAppear {
            themeManager.updateTheme()
            viewModel.fetchClothes()
            
            // Écoute le refresh global
            NotificationCenter.default.addObserver(
                forName: .refreshDressing,
                object: nil,
                queue: .main
            ) { _ in
                viewModel.fetchClothes()
            }
        }
        // MODAL CAMERA UNIQUEMENT
        .sheet(isPresented: $showCamera) {
            ImagePicker(sourceType: .camera) { image in
                capturedImage = image
                isUploading = true
                if let image = image {
                    uploadAndDetect(image: image)
                }
            }
        }
        // Loading Screen
        .fullScreenCover(isPresented: $isUploading) {
            AIAnalysisLoadingView(
                image: capturedImage,
                onAnalysisComplete: { resultText in
                    detectionText = resultText
                    detectedImage = capturedImage
                    showDetectionResult = true
                    isUploading = false
                }
            )
        }
        // Detection Result
        .fullScreenCover(isPresented: $showDetectionResult) {
            DetectionResultView(
                image: detectedImage,
                resultText: detectionText,
                isShowing: $showDetectionResult,
                isUploading: $isUploading,
                imageURL: detectedImageURL
            )
        }
        // Error Alert
        .alert("Detection Error", isPresented: $showAIErrorAlert) {
            Button("OK") {
                aiErrorMessage = ""
            }
        } message: {
            Text(aiErrorMessage)
        }
        // Photo Guide Overlay
        .overlay {
            if showPhotoGuide {
                PhotoGuidePopupView(
                    isShowing: $showPhotoGuide,
                    onContinue: {
                        showCamera = true
                    }
                )
                .transition(.opacity.combined(with: .scale))
                .animation(.spring(response: 0.4), value: showPhotoGuide)
            }
        }
        // Clothing Detail Sheet
        .sheet(item: $selectedClothe) { clothe in
            ClothingDetailSheet(clothe: clothe, viewModel: viewModel)
        }
    }
    
    // MARK: - Upload and Detect
    private func uploadAndDetect(image: UIImage) {
        guard let imageData = image.jpegData(compressionQuality: 0.85) else { return }
        
        isUploading = true
        detectionText = "Analyzing..."
        
        let url = URL(string: "\(APIConstants.baseURL.absoluteString)/detect")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        
        let boundary = "Boundary-\(UUID().uuidString)"
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        
        var body = Data()
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"photo\"; filename=\"photo.jpg\"\r\n".data(using: .utf8)!)
        body.append("Content-Type: image/jpeg\r\n\r\n".data(using: .utf8)!)
        body.append(imageData)
        body.append("\r\n--\(boundary)--\r\n".data(using: .utf8)!)
        request.httpBody = body
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                isUploading = false
                
                if let error = error {
                    self.showErrorAlert("Network error. Please try again.")
                    return
                }
                
                guard let data = data,
                      let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                      let detectionResult = json["detection_result"] as? String else {
                    self.showErrorAlert("AI analysis failed. Please try again.")
                    return
                }
                
                let imageUrl = json["image_url"] as? String
                let text = detectionResult.lowercased()
                
                let errorKeywords = [
                    "aucun vêtement", "aucun vetement", "no clothing", "no clothes",
                    "no item", "nothing detected", "cannot detect", "erreur", "error"
                ]
                
                if errorKeywords.contains(where: text.contains) {
                    self.showErrorAlert("Error: No clothing detected. Please take a clear photo of a single item on a plain background.")
                    return
                }
                
                self.detectionText = detectionResult
                self.detectedImageURL = imageUrl
                self.detectedImage = image
                self.showDetectionResult = true
            }
        }.resume()
    }

    private func showErrorAlert(_ message: String) {
        aiErrorMessage = message
        showAIErrorAlert = true
        showDetectionResult = false
    }
    
    // MARK: - Header
    private var header: some View {
        HStack {
            Text("My Dressing")
                .font(.system(size: 36, weight: .bold))
                .foregroundColor(.themePrimary)
            Spacer()
        }
        .padding(.top, 8)
    }
    
    // MARK: - Search & Filter
    private var searchAndFilter: some View {
        HStack(spacing: 12) {
            HStack(spacing: 10) {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.themeSecondary)
                
                TextField("Rechercher...", text: $searchText)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled(true)
                    .onChange(of: searchText) { newValue in
                        viewModel.searchText = newValue
                    }
            }
            .padding(14)
            .background(
                RoundedRectangle(cornerRadius: 18)
                    .stroke(Color.themeSecondary.opacity(0.6), lineWidth: 2)
                    .background(
                        RoundedRectangle(cornerRadius: 18)
                            .fill(Color.themeSoftPink.opacity(0.25))
                    )
            )
            
            Circle()
                .fill(Color.themeAqua)
                .frame(width: 48, height: 48)
                .overlay(
                    Image(systemName: "line.3.horizontal.decrease.circle")
                        .font(.system(size: 22, weight: .semibold))
                        .foregroundColor(.white)
                )
                .shadow(color: .black.opacity(0.1), radius: 6, x: 0, y: 4)
        }
    }
    
    // MARK: - Category Chips
    private var categoryChips: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(categories, id: \.self) { category in
                    CategoryChip(
                        label: category,
                        selected: viewModel.selectedCategory == category
                    )
                    .onTapGesture {
                        searchText = ""
                        viewModel.selectCategory(category)
                    }
                }
            }
            .padding(.vertical, 4)
        }
    }
    
    // MARK: - Clothes Grid
    private var clothesGrid: some View {
        Group {
            if viewModel.isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: 200)
            } else if viewModel.filteredClothes.isEmpty {
                Text("No clothes found")
                    .foregroundColor(.gray)
                    .frame(maxWidth: .infinity, maxHeight: 200)
            } else {
                LazyVGrid(columns: columns, spacing: 16) {
                    ForEach(viewModel.filteredClothes) { clothe in
                        ClothingCard(
                            clothe: clothe,
                            viewModel: viewModel,
                            selectedClothe: $selectedClothe
                        )
                    }
                }
            }
        }
        .padding(.bottom, 22)
    }
    
    // MARK: - Floating Add Button
    private var floatingAddButton: some View {
        Button(action: {
            showPhotoGuide = true
        }) {
            Image(systemName: "plus")
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(.white)
                .frame(width: 60, height: 60)
                .background(
                    Circle()
                        .fill(Color.themePrimary)
                        .shadow(color: .black.opacity(0.2), radius: 12, x: 0, y: 6)
                )
        }
    }
}

// MARK: - Category Chip
private struct CategoryChip: View {
    let label: String
    let selected: Bool
    
    var body: some View {
        Text(label)
            .font(.system(size: 15, weight: .semibold))
            .foregroundColor(selected ? .white : .themeTeal)
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(
                Capsule()
                    .fill(selected ? Color.themePrimary : Color.themeSoftPink.opacity(0.6))
            )
    }
}

// MARK: - Clothing Card
private struct ClothingCard: View {
    let clothe: Clothe
    @ObservedObject var viewModel: DressingViewModel
    @Binding var selectedClothe: Clothe?
    
    @State private var showDeleteAlert = false
    @State private var isDeleting = false
    
    private var fillColor: Color {
        CategoryColors.color(for: clothe.category ?? "")
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Image
            AsyncImage(url: URL(string: clothe.imageURL)) { image in
                image
                    .resizable()
                    .scaledToFill()
            } placeholder: {
                Rectangle()
                    .fill(fillColor.opacity(0.3))
                    .overlay(ProgressView().tint(.white))
            }
            .frame(height: 140)
            .clipped()
            
            // Infos + Trash
            HStack {
                VStack(alignment: .leading, spacing: 6) {
                    Text(clothe.category?.capitalized ?? "Unknown")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.themeTeal)
                        .lineLimit(1)
                    
                    if let season = clothe.season {
                        Text(season)
                            .font(.system(size: 13))
                            .foregroundColor(.themeTeal.opacity(0.7))
                    }
                }
                Spacer()
                
                // Trash Button
                Button {
                    showDeleteAlert = true
                } label: {
                    Image(systemName: "trash")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.themePrimary)
                        .frame(width: 32, height: 32)
                        .background(
                            Circle()
                                .fill(Color.themePrimary.opacity(0.15))
                        )
                        .overlay(
                            Circle()
                                .stroke(Color.themePrimary.opacity(0.3), lineWidth: 1)
                        )
                }
                .opacity(isDeleting ? 0.5 : 1.0)
                .disabled(isDeleting)
            }
            .padding(14)
            .background(Color.themeCard)
        }
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.themeCard)
        )
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .shadow(color: .black.opacity(0.08), radius: 8)
        .onTapGesture {
            selectedClothe = clothe
        }
        .alert("Delete this item?", isPresented: $showDeleteAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                deleteItem()
            }
        } message: {
            Text("This action cannot be undone.")
        }
        .opacity(isDeleting ? 0.0 : 1.0)
        .scaleEffect(isDeleting ? 0.95 : 1.0)
        .animation(.spring(response: 0.35), value: isDeleting)
    }
    
    private func deleteItem() {
        withAnimation(.easeOut(duration: 0.25)) {
            isDeleting = true
        }
        
        viewModel.deleteClothe(clothe) { success in
            DispatchQueue.main.async {
                if !success {
                    withAnimation {
                        isDeleting = false
                    }
                }
            }
        }
    }
}

// MARK: - ImagePicker
struct ImagePicker: UIViewControllerRepresentable {
    let sourceType: UIImagePickerController.SourceType
    let onImagePicked: (UIImage?) -> Void
    @Environment(\.dismiss) private var dismiss
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = sourceType
        picker.delegate = context.coordinator
        picker.allowsEditing = true
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: ImagePicker
        
        init(_ parent: ImagePicker) {
            self.parent = parent
        }
        
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            let image = info[.editedImage] as? UIImage ?? info[.originalImage] as? UIImage
            parent.onImagePicked(image)
            parent.dismiss()
        }
        
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.onImagePicked(nil)
            parent.dismiss()
        }
    }
}

// MARK: - Notification Extension
extension Notification.Name {
    static let refreshDressing = Notification.Name("refreshDressing")
}
