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
    private let columns: [GridItem] = [
        GridItem(.flexible(), spacing: 16),
        GridItem(.flexible(), spacing: 16)
    ]
    
    private let categories = ["All", "Tshirt", "Pants", "Dress", "Shoes", "Accessory"]
    
    var body: some View {
        ZStack {
            // Scrollable Content
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    header
                    //userInfoDebug // POUR TESTER
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
        // Remplace ton ancien fullScreenCover par ÇA :
        .fullScreenCover(isPresented: $isUploading) {
            AIAnalysisLoadingView(
                image: capturedImage,
                onAnalysisComplete: { resultText in
                    // Quand l'analyse est finie → on ouvre le vrai popup
                    detectionText = resultText
                    detectedImage = capturedImage
                    showDetectionResult = true
                    isUploading = false
                }
            )
        }
        .fullScreenCover(isPresented: $showDetectionResult) {
            DetectionResultView(
                image: detectedImage,
                resultText: detectionText,
                isShowing: $showDetectionResult,
                isUploading: $isUploading,
                imageURL: detectedImageURL          // ← METS imageURL EN DERNIER
            )
        }
        .alert("Erreur", isPresented: .constant(!detectionText.isEmpty && detectionText.contains("Erreur"))) {
            Button("OK") { }
        } message: {
            Text(detectionText)
        }
    }
    private func uploadAndDetect(image: UIImage) {
        guard let imageData = image.jpegData(compressionQuality: 0.85) else { return }
        
        isUploading = true
        showDetectionResult = true
        detectedImage = image
        detectionText = "Analyse en cours..."

        let url = URL(string: "\(APIConstants.baseURL.absoluteString)/detect")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        
        let boundary = "Boundary-\(UUID().uuidString)"
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        
        var body = Data()
        
        // --- Partie fichier ---
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"photo\"; filename=\"photo.jpg\"\r\n".data(using: .utf8)!)
        body.append("Content-Type: image/jpeg\r\n\r\n".data(using: .utf8)!)
        body.append(imageData)
        body.append("\r\n".data(using: .utf8)!)
        
        // --- Fin ---
        body.append("--\(boundary)--\r\n".data(using: .utf8)!)
        
        request.httpBody = body
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                isUploading = false
                
                if let error = error {
                    detectionText = "Network error: \(error.localizedDescription)"
                    return
                }
                
                guard let data = data,
                      let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                      let detectionResult = json["detection_result"] as? String else {
                    detectionText = "Server error"
                    return
                }
                
                // ON MET À JOUR LE TEXTE BRUT
                // On garde le JSON complet + on extrait juste le texte à afficher
                if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let fullText = json["detection_result"] as? String,
                   let imageUrl = json["image_url"] as? String {

                    detectionText = fullText        // ← Seulement le texte à afficher
                    detectedImageURL = imageUrl     // ← On garde l'URL Cloudinary !
                } else {
                    detectionText = "Erreur de réponse du serveur"
                    detectedImageURL = nil
                }
                // ON FERME LE POP-UP ET ON LE RÉ-OUVRE POUR FORCER LE PARSING
                showDetectionResult = false
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    showDetectionResult = true
                }
            }
        }.resume()
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
    
    // MARK: - User Info Debug (POUR TESTER)
    private var userInfoDebug: some View {
        VStack(alignment: .leading, spacing: 8) {
            if let user = appPreferences.currentUser {
                HStack {
                    Text("👤 User:")
                        .font(.system(size: 14, weight: .medium))
                    Text(user.fullName)
                        .font(.system(size: 14))
                }
                
                HStack {
                    Text("⚧ Gender:")
                        .font(.system(size: 14, weight: .medium))
                    Text(user.gender == .male ? "Male 👨 (Couleurs inversées)" : "Female 👩 (Couleurs normales)")
                        .font(.system(size: 14))
                        .foregroundColor(user.gender == .male ? .themeAqua : .themePrimary)
                }
                
                HStack {
                    Text("🎨 Theme:")
                        .font(.system(size: 14, weight: .medium))
                    Circle()
                        .fill(Color.themePrimary)
                        .frame(width: 20, height: 20)
                    Circle()
                        .fill(Color.themeSecondary)
                        .frame(width: 20, height: 20)
                    Circle()
                        .fill(Color.themeSoftPink)
                        .frame(width: 20, height: 20)
                    Circle()
                        .fill(Color.themeAqua)
                        .frame(width: 20, height: 20)
                    Circle()
                        .fill(Color.themeTeal)
                        .frame(width: 20, height: 20)
                }
            } else {
                Text("Aucun utilisateur connecté")
                    .font(.system(size: 14))
                    .foregroundColor(.gray)
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.themeCard)
                .shadow(color: .black.opacity(0.05), radius: 4)
        )
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
                        ClothingCard(clothe: clothe, viewModel: viewModel)
                    }
                }
            }
        }
        .padding(.bottom, 22)
    }
    
    // MARK: - Floating Add Button
    private var floatingAddButton: some View {
        Button(action: {
            showCamera = true
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
        // 1. Animation immédiate
        withAnimation(.easeOut(duration: 0.25)) {
            isDeleting = true
        }
        
        // 2. Suppression
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
extension Notification.Name {
    static let refreshDressing = Notification.Name("refreshDressing")
}
