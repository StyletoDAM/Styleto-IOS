import SwiftUI

struct AddToStoreSheet: View {
    @ObservedObject var viewModel: StoreViewModel
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationStack {
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

                // MARK: - Clothes List
                if viewModel.myClothes.isEmpty {
                    emptyState
                } else {
                    clothesList
                }

                // MARK: - Price Input
                priceInput

                Spacer()
            }
            .padding()
            .background(Color.themeBackground.ignoresSafeArea())
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(.themeSecondary)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        // Appel sans closure
                        viewModel.addToStore()
                    }
                    .bold()
                    .foregroundColor(.white)
                    .frame(width: 80, height: 36)
                    .background(
                        viewModel.selectedClothe != nil && !viewModel.priceInput.isEmpty && !viewModel.isAdding
                        ? Color.themePrimary
                        : Color.gray.opacity(0.3)
                    )
                    .clipShape(Capsule())
                    .disabled(viewModel.selectedClothe == nil || viewModel.priceInput.isEmpty || viewModel.isAdding)
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
            // Observer showAddToStore pour fermer automatiquement
            .onChange(of: viewModel.showAddToStore) { _, newValue in
                if !newValue {
                    dismiss()
                }
            }
        }
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
        ScrollView {
            LazyVStack(spacing: 12) {
                ForEach(viewModel.myClothes) { clothe in
                    let isAlreadyInStore = viewModel.storeItems.contains { storeItem in
                        if case .clotheId(let id) = storeItem.clothesId {
                            return id == clothe.id
                        }
                        if case .clothe(let c) = storeItem.clothesId {
                            return c.id == clothe.id
                        }
                        return false
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
                            }
                        }
                    }
                    .disabled(isAlreadyInStore)
                }
            }
        }
        .frame(maxHeight: 400)
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

                Text("DT")
                    .font(.title2.bold())
                    .foregroundColor(.themePrimary)
                    .padding(.trailing)
            }
        }
    }
}
