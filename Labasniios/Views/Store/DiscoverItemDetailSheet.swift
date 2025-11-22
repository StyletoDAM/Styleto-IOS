import SwiftUI

struct DiscoverItemDetailSheet: View {
    let storeItem: Store
    @Environment(\.dismiss) var dismiss
    
    private func addToCart() {
        CartManager.shared.addToCart(storeItem: storeItem)
        
        // Feedback haptique + toast
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
        
        // Tu peux afficher un petit toast si tu veux
        dismiss()
    }
    
    private func openChatWithSeller() {
        print("Ouvrir le chat avec le vendeur de cet article")
        dismiss()
    }
    
    
    var body: some View {
        NavigationView {
            Form {
                // MARK: - Image + Infos principales
                Section {
                    HStack(spacing: 16) {
                        // Image
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
                        
                        // Infos
                        VStack(alignment: .leading, spacing: 6) {
                            Text(storeItem.clothe?.category?.capitalized ?? "Article")
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
                            
                            // TAILLE – IDENTIQUE À EDITSTOREPOPUP
                            if let size = storeItem.size, !size.isEmpty {
                                HStack(spacing: 6) {
                                    Image(systemName: "ruler")
                                        .font(.caption)
                                        .foregroundColor(.themeSecondary)
                                    Text("Taille: \(size)")
                                        .font(.caption.bold())
                                        .foregroundColor(.themeSecondary)
                                }
                                .padding(.horizontal, 10)
                                .padding(.vertical, 4)
                                .background(Color.themeCard.opacity(0.8))
                                .clipShape(Capsule())
                                .overlay(
                                    Capsule()
                                        .stroke(Color.themePrimary.opacity(0.3), lineWidth: 1)
                                )
                            }
                            
                            // Statut
                            HStack(spacing: 4) {
                                Image(systemName: storeItem.isAvailable ? "circle.fill" : "checkmark.circle.fill")
                                    .font(.caption2)
                                    .foregroundColor(storeItem.isAvailable ? .green : .gray)
                                Text(storeItem.isAvailable ? "Disponible" : "Vendu")
                                    .font(.caption.bold())
                                .foregroundColor(storeItem.isAvailable ? .green : .gray)                            }
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
                
                // MARK: - Boutons d'action
                Section {
                    Button {
                        addToCart()
                    } label: {
                        Label("Ajouter au panier", systemImage: "cart.fill")
                            .font(.subheadline.bold())
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(
                                LinearGradient(colors: [.themePrimary, .themeSecondary], startPoint: .leading, endPoint: .trailing)
                                    .cornerRadius(12)
                            )
                    }
                    .disabled(!storeItem.isAvailable)
                    .listRowBackground(Color.clear)
                    
                    Button {
                        openChatWithSeller()
                    } label: {
                        Label("Contacter le vendeur", systemImage: "message.fill")
                            .font(.subheadline.bold())
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(
                                LinearGradient(colors: [Color.themeTeal, Color.themeAqua], startPoint: .leading, endPoint: .trailing)
                                    .cornerRadius(12)
                            )
                    }
                    .disabled(!storeItem.isAvailable)
                    .listRowBackground(Color.clear)
                }
                .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
            }
            .navigationTitle("Détails de l'article")
            .navigationBarTitleDisplayMode(.inline)
            .background(
                Color.themeSoftPink.opacity(UITraitCollection.current.userInterfaceStyle == .dark ? 0.1 : 0.25)
                    .ignoresSafeArea()
            )
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Fermer") {
                        dismiss()
                    }
                    .foregroundColor(.themePrimary)
                    .font(.subheadline.bold())
                }
            }
        }
    }
}
