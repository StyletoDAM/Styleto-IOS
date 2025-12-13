import SwiftUI
 
struct AddToStoreSheet: View {
    @ObservedObject var viewModel: StoreViewModel
    @Environment(\.dismiss) var dismiss
    @State private var showUpgradeDialog = false
    @State private var showProDetails = false
    @FocusState private var focusedField: Field?
    
    enum Field {
        case price
        case size
    }
 
    var body: some View {
        NavigationStack {
            ScrollView { // ✅ AJOUT: ScrollView principal
                VStack(spacing: 24) {
                    // MARK: - Header
                    VStack(spacing: 8) {
                        Text("Add to Store")
                            .font(.title2.bold())
                            .foregroundColor(.themePrimary)
     
                        Text("Select an item and set a price")
                            .font(.subheadline)
                            .foregroundColor(.themeSecondaryText)
                    }
                    .padding(.top, 8)
     
                    // ✨ NOUVEAU : Afficher l'image de l'article sélectionné en haut
                    if let selectedClothe = viewModel.selectedClothe {
                        selectedClothePreview
                    } else if viewModel.myClothes.isEmpty {
                        emptyState
                    } else {
                        clothesList
                    }
     
                    // MARK: - Price + Size (seulement si un vêtement est sélectionné)
                    if viewModel.selectedClothe != nil {
                        priceInput
                        sizeInputSection
                    }
                }
                .padding()
            }
            .background(Color.themeBackground.ignoresSafeArea())
            // ✅ SOLUTION: Utiliser un geste simultané pour fermer le clavier
            .simultaneousGesture(
                TapGesture().onEnded {
                    focusedField = nil
                }
            )
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        print("❌ [AddToStoreSheet] Cancel button tapped")
                        dismiss()
                    }
                    .foregroundColor(.themeSecondary)
                }
                ToolbarItem(placement: .confirmationAction) {
                    let isDisabled = viewModel.selectedClothe == nil ||
                                     viewModel.priceInput.isEmpty ||
                                     viewModel.isAdding ||
                                     (viewModel.isShoes ? viewModel.sizeInput.isEmpty : false)
                    
                    Button("Add") {
                        print("✅ [AddToStoreSheet] Add button tapped")
                        viewModel.addToStore()
                    }
                    .bold()
                    .foregroundColor(isDisabled ? .gray : .white)
                    .frame(width: 80, height: 36)
                    .disabled(isDisabled)
                    .background(
                        isDisabled
                            ? Color.gray.opacity(0.3)
                            : Color.themePrimary
                    )
                    .clipShape(Capsule())
                }
            }
            // ✅ AJOUT: Toolbar avec bouton "Done" sur le clavier
            .toolbar {
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("Done") {
                        focusedField = nil
                    }
                    .foregroundColor(.themePrimary)
                    .bold()
                }
            }
            .overlay {
                if viewModel.isAdding {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .themePrimary))
                        .padding()
                        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
                        .shadow(radius: 10)
                }
            }
            .onAppear {
                print("✅ [AddToStoreSheet] Sheet appeared - myClothes count: \(viewModel.myClothes.count)")
                if viewModel.myClothes.isEmpty {
                    Task {
                        await viewModel.loadMyClothes()
                    }
                }
            }
            
            // Observer showUpgradeToPro depuis ViewModel
            .onChange(of: viewModel.showUpgradeToPro) { oldValue, newValue in
                print("🔄 [AddToStoreSheet] showUpgradeToPro changed: \(oldValue) -> \(newValue)")
                if newValue {
                    showUpgradeDialog = true
                    viewModel.showUpgradeToPro = false
                }
            }
            // Upgrade Dialog
            .overlay {
                if showUpgradeDialog {
                    ZStack {
                        Color.black.opacity(0.4)
                            .ignoresSafeArea()
                            .onTapGesture {
                                showUpgradeDialog = false
                            }
                        
                        UpgradeToProDialog(
                            onDismiss: {
                                showUpgradeDialog = false
                            },
                            onUpgrade: {
                                showUpgradeDialog = false
                                showProDetails = true
                            }
                        )
                    }
                }
            }
            // Pro Pack Details Sheet
            .sheet(isPresented: $showProDetails) {
                SubscriptionDetailView(plan: .pro) {
                    showProDetails = false
                    dismiss()
                    viewModel.loadMyStore()
                }
            }
        }
    }
    
    private var selectedClothePreview: some View {
        VStack(spacing: 16) {
            // Image grande et centrée
            AsyncImage(url: URL(string: viewModel.selectedClothe?.imageURL ?? "")) { phase in
                switch phase {
                case .success(let image):
                    image
                        .resizable()
                        .scaledToFill()
                        .frame(width: 200, height: 200)
                        .clipShape(RoundedRectangle(cornerRadius: 24))
                        .shadow(color: .black.opacity(0.15), radius: 12, x: 0, y: 6)
                case .empty:
                    RoundedRectangle(cornerRadius: 24)
                        .fill(Color.themeSoftPink.opacity(0.2))
                        .frame(width: 200, height: 200)
                        .overlay(
                            ProgressView()
                                .tint(.themePrimary)
                        )
                case .failure:
                    RoundedRectangle(cornerRadius: 24)
                        .fill(Color.themeSoftPink.opacity(0.2))
                        .frame(width: 200, height: 200)
                        .overlay(
                            Image(systemName: "photo")
                                .font(.system(size: 48))
                                .foregroundColor(.gray)
                        )
                @unknown default:
                    EmptyView()
                }
            }
            
            // Infos de l'article
            VStack(spacing: 8) {
                Text(viewModel.selectedClothe?.category?.capitalized ?? "Item")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.themePrimary)
                
                HStack(spacing: 16) {
                    if let color = viewModel.selectedClothe?.color {
                        Label(color.capitalized, systemImage: "paintpalette.fill")
                            .font(.subheadline)
                            .foregroundColor(.themeSecondaryText)
                    }
                    
                    if let style = viewModel.selectedClothe?.style {
                        Label(style.capitalized, systemImage: "star.fill")
                            .font(.subheadline)
                            .foregroundColor(.themeSecondaryText)
                    }
                }
            }
            
            // Bouton pour changer d'article
            Button {
                withAnimation {
                    viewModel.selectedClothe = nil
                    viewModel.priceInput = ""
                    viewModel.sizeInput = ""
                    viewModel.selectedSize = "M"
                }
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "arrow.left.circle.fill")
                    Text("Choose another item")
                }
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(.themePrimary)
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(
                    Capsule()
                        .stroke(Color.themePrimary.opacity(0.3), lineWidth: 1.5)
                )
            }
            .padding(.top, 8)
        }
        .padding(.vertical)
    }
 
    // MARK: - Empty State
    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "tshirt")
                .font(.system(size: 48))
                .foregroundColor(.themeSecondary.opacity(0.5))
 
            Text("No clothes available")
                .font(.headline)
                .foregroundColor(.themeSecondaryText)
 
            Text("Add clothes from your wardrobe first.")
                .font(.subheadline)
                .foregroundColor(.themeSecondaryText.opacity(0.8))
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(32)
        .background(Color.themeCard, in: RoundedRectangle(cornerRadius: 20))
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(Color.themeSecondary.opacity(0.2), lineWidth: 1)
        )
    }
 
    // MARK: - Clothes List
    private var clothesList: some View {
        LazyVStack(spacing: 16) {
            ForEach(viewModel.myClothes) { clothe in
                let isAlreadyInStore = viewModel.storeItems.contains { storeItem in
                    storeItem.clothesId == clothe.id
                }
                let isSelected = viewModel.selectedClothe?.id == clothe.id
 
                HStack {
                    // Image
                    AsyncImage(url: URL(string: clothe.imageURL)) { phase in
                        switch phase {
                        case .success(let image):
                            image
                                .resizable()
                                .scaledToFit()
                                .frame(width: 70, height: 70)
                                .clipShape(RoundedRectangle(cornerRadius: 14))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 14)
                                        .stroke(isSelected ? Color.themePrimary : Color.clear, lineWidth: 3)
                                )
                                .shadow(radius: isSelected ? 6 : 0)
                                .scaleEffect(isSelected ? 1.05 : 1.0)
                                .animation(.spring(response: 0.3), value: isSelected)
                        case .empty:
                            ProgressView()
                                .frame(width: 70, height: 70)
                        case .failure:
                            Image(systemName: "photo")
                                .font(.system(size: 28))
                                .foregroundColor(.gray)
                                .frame(width: 70, height: 70)
                                .background(Color.themeCard)
                                .clipShape(RoundedRectangle(cornerRadius: 14))
                        @unknown default:
                            EmptyView()
                        }
                    }
 
                    // Info
                    VStack(alignment: .leading, spacing: 4) {
                        Text(clothe.category ?? "Unknown")
                            .font(.headline)
                            .foregroundColor(isAlreadyInStore ? .secondary : .themeText)
 
                        Text(clothe.color ?? "")
                            .font(.subheadline)
                            .foregroundColor(.themeSecondaryText)
                    }
 
                    Spacer()
 
                    // Status
                    if isAlreadyInStore {
                        Text("For sale")
                            .font(.caption.bold())
                            .foregroundColor(.white)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Color.gray.opacity(0.6))
                            .clipShape(Capsule())
                    } else if isSelected {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.title2)
                            .foregroundColor(.themePrimary)
                            .scaleEffect(isSelected ? 1.2 : 1.0)
                            .animation(.spring(), value: isSelected)
                    }
                }
                .padding()
                .background(Color.themeCard)
                .clipShape(RoundedRectangle(cornerRadius: 18))
                .overlay(
                    RoundedRectangle(cornerRadius: 18)
                        .stroke(isSelected ? Color.themePrimary : Color.clear, lineWidth: 2)
                )
                .shadow(color: isSelected ? Color.themePrimary.opacity(0.3) : Color.clear, radius: 8)
                .opacity(isAlreadyInStore ? 0.5 : 1.0)
                .onTapGesture {
                    if !isAlreadyInStore {
                        withAnimation(.spring()) {
                            viewModel.selectedClothe = clothe
 
                            // Détection automatique chaussures
                            let category = (clothe.category ?? "").lowercased()
                            viewModel.isShoes = category.contains("shoe") ||
                                               category.contains("sneaker") ||
                                               category.contains("basket") ||
                                               category.contains("boot") ||
                                               category.contains("chaussure")
 
                            // Reset taille selon type
                            if viewModel.isShoes {
                                viewModel.sizeInput = ""
                            } else {
                                viewModel.selectedSize = "M"
                            }
                        }
                    }
                }
                .disabled(isAlreadyInStore)
            }
        }
    }
 
    // MARK: - Price Input
    private var priceInput: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Price")
                .font(.headline)
                .foregroundColor(.themeText)
 
            HStack {
                TextField("0.00", text: $viewModel.priceInput)
                    .keyboardType(.decimalPad)
                    .font(.title3.bold())
                    .padding()
                    .frame(height: 56)
                    .background(Color.themeCard)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color.themeSecondary.opacity(0.3), lineWidth: 1)
                    )
                    .focused($focusedField, equals: .price)
 
                Text("DT")
                    .font(.title2.bold())
                    .foregroundColor(.themePrimary)
                    .padding(.trailing)
            }
        }
    }
 
    // MARK: - Size Input (Dynamique)
    private var sizeInputSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Size / Shoe size")
                .font(.headline)
                .foregroundColor(.themeText)
 
            if viewModel.isShoes {
                // Champ libre pour chaussures
                TextField("Ex: 38, 42, 44...", text: $viewModel.sizeInput)
                    .keyboardType(.numberPad)
                    .padding()
                    .frame(height: 56)
                    .background(Color.themeCard)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(viewModel.sizeInput.isEmpty ? Color.red.opacity(0.5) : Color.themePrimary.opacity(0.5), lineWidth: 2)
                    )
                    .focused($focusedField, equals: .size)
            } else {
                // Picker vêtements
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 4), spacing: 12) {
                    ForEach(["XS", "S", "M", "L", "XL", "XXL", "XXXL"], id: \.self) { size in
                        Button {
                            withAnimation(.spring()) {
                                viewModel.selectedSize = size
                            }
                        } label: {
                            Text(size)
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(viewModel.selectedSize == size ? .white : .themeText)
                                .frame(width: 52, height: 52)
                                .background(
                                    viewModel.selectedSize == size
                                        ? Color.themePrimary
                                        : Color.themeCard
                                )
                                .clipShape(Circle())
                                .overlay(
                                    Circle()
                                        .stroke(Color.themePrimary, lineWidth: viewModel.selectedSize == size ? 0 : 2)
                                )
                        }
                    }
                }
                .padding(.horizontal)
            }
        }
    }
}
