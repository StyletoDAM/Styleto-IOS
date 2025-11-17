import SwiftUI
import UIKit

struct DressingView: View {
    @StateObject private var viewModel = DressingViewModel()
    @ObservedObject private var themeManager = ThemeManager.shared
    @State private var showCamera = false
    @State private var capturedImage: UIImage?
    @State private var searchText = ""
    
    
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
        .onAppear { viewModel.fetchClothes() }
        
        // MODAL CAMERA UNIQUEMENT
        .sheet(isPresented: $showCamera) {
            ImagePicker(sourceType: .camera) { image in
                capturedImage = image
                if let image = image {
                    print("IMAGE CAPTUREE:", image)
                    // TODO: Traiter l'image capturée
                }
            }
        }
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
    



// MARK: - ImagePicker (Version mise à jour avec Optional)
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
