
import SwiftUI

struct DiscoverItemDetailSheet: View {
    let storeItem: Store
    @Environment(\.dismiss) var dismiss
    
    // À connecter plus tard avec ton système de panier et chat
    private func addToCart() {
        print("Ajouté au panier : \(storeItem.clothe?.category ?? "") – \(storeItem.price) DT")
        // viewModel.addToCart(storeItem)
        dismiss()
    }
    
    private func openChatWithSeller() {
        print("Ouvrir le chat avec le vendeur de cet article")
        // Navigation vers le chat avec le owner du storeItem
        dismiss()
    }
    
    var body: some View {
        NavigationView {
            Form {
                // MARK: - Image + Infos principales
                Section {
                    HStack(spacing: 16) {
                        AsyncImage(url: URL(string: storeItem.clothe?.imageURL ?? "")) { image in
                            image
                                .resizable()
                                .scaledToFill()
                        } placeholder: {
                            Rectangle()
                                .fill(Color.themeSoftPink.opacity(0.3))
                                .overlay(
                                    Image(systemName: "tshirt")
                                        .font(.title)
                                        .foregroundColor(.themeTeal.opacity(0.6))
                                )
                        }
                        .frame(width: 80, height: 80)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)

                        VStack(alignment: .leading, spacing: 6) {
                            Text(storeItem.clothe?.category?.capitalized ?? "Item")
                                .font(.headline)
                                .foregroundColor(.themeTeal)

                            HStack {
                                Image(systemName: "tag.fill")
                                    .font(.caption)
                                    .foregroundColor(.themePrimary)
                                Text("\(Int(storeItem.price)) DT")
                                    .font(.subheadline.bold())
                                    .foregroundColor(.themePrimary)
                            }

                            // Statut : Disponible ou Vendu
                            HStack(spacing: 4) {
                                Image(systemName: storeItem.isAvailable ? "circle.fill" : "checkmark.circle.fill")
                                    .font(.caption2)
                                    .foregroundColor(storeItem.isAvailable ? .green : .gray)
                                Text(storeItem.isAvailable ? "Available" : "Sold")
                                    .font(.caption.bold())
                                    .foregroundColor(storeItem.isAvailable ? .green : .gray)
                            }
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(
                                Capsule()
                                    .fill(storeItem.isAvailable ? Color.green.opacity(0.1) : Color.gray.opacity(0.1))
                            )
                        }
                        Spacer()
                    }
                    .padding(.vertical, 8)
                }
                .listRowBackground(Color.themeCard)
                .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))

                
                .listRowBackground(Color.themeSoftPink.opacity(0.15))

                // MARK: - Actions (Add to Cart + Chat)
                Section {
                    // Bouton Add to Cart
                    Button {
                        addToCart()
                    } label: {
                        HStack {
                            Image(systemName: "cart.fill")
                                .foregroundColor(.white)
                            Text("Add to Cart")
                                .font(.subheadline.bold())
                                .foregroundColor(.white)
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(
                            LinearGradient(
                                colors: [.themePrimary, .themeSecondary],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                            .cornerRadius(12)
                        )
                    }
                    .disabled(!storeItem.isAvailable)
                    .listRowBackground(Color.clear)

                    // Bouton Chat with Seller
                    Button {
                        openChatWithSeller()
                    } label: {
                        HStack {
                            Image(systemName: "message.fill")
                                .foregroundColor(.white)
                            Text("Chat with Seller")
                                .font(.subheadline.bold())
                                .foregroundColor(.white)
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(
                            LinearGradient(
                                colors: [Color.themeTeal, Color.themeAqua],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                            .cornerRadius(12)
                        )
                    }
                    .disabled(!storeItem.isAvailable)
                    .listRowBackground(Color.clear)
                }
                .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
            }
            .navigationTitle("Item Details")
            .navigationBarTitleDisplayMode(.inline)
            .background(
                Color.themeSoftPink.opacity(UITraitCollection.current.userInterfaceStyle == .dark ? 0.1 : 0.25)
                    .ignoresSafeArea()
            )
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") {
                        dismiss()
                    }
                    .foregroundColor(.themePrimary)
                    .font(.subheadline.bold())
                }
            }
        }
    }
}

