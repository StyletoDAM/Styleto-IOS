import SwiftUI

struct DiscoverItemDetailSheet: View {
    let storeItem: Store
    @Environment(\.dismiss) var dismiss
    
    @State private var isLoadingChat = false
    @State private var showChatView = false
    @State private var chatConversation: ChatConversationResponse?
    @State private var errorMessage: String?
    
    private func addToCart() {
        CartManager.shared.addToCart(storeItem: storeItem)
        
        // Haptic feedback + toast
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
        
        dismiss()
    }
    
    private func openChatWithSeller() {
        guard let sellerId = storeItem.userInfo?.id else {
            errorMessage = "Seller not found"
            return
        }
        
        isLoadingChat = true
        errorMessage = nil
        
        Task {
            do {
                var conversation = try await ChatService.shared.createOrGetConversation(withUserId: sellerId)
                
                // Replace ghost participant with real seller
                if let sellerInfo = storeItem.userInfo {
                    let realSeller = ChatParticipant(
                        id: sellerInfo.id,
                        fullName: sellerInfo.fullName ?? "Seller",
                        profilePicture: sellerInfo.profilePicture
                    )
                    
                    conversation.participants = conversation.participants.map { p in
                        p.id == sellerId ? realSeller : p
                    }
                }
                
                await MainActor.run {
                    self.chatConversation = conversation
                    self.showChatView = true
                    self.isLoadingChat = false
                }
                
            } catch {
                await MainActor.run {
                    self.errorMessage = "Unable to open chat"
                    self.isLoadingChat = false
                    print("Error:", error)
                }
            }
        }
    }
    
    var body: some View {
        NavigationView {
            Form {
                // MARK: - Image + Main Infos
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
                            
                            // SIZE
                            if let size = storeItem.size, !size.isEmpty {
                                HStack(spacing: 6) {
                                    Image(systemName: "ruler")
                                        .font(.caption)
                                        .foregroundColor(.themeSecondary)
                                    Text("Size: \(size)")
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
                            
                            // Status
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
                
                // MARK: - Error Message
                if let errorMessage = errorMessage {
                    Section {
                        HStack {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundColor(.orange)
                            Text(errorMessage)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .listRowBackground(Color.orange.opacity(0.1))
                }
                
                // MARK: - Sold Item Message
                if !storeItem.isAvailable {
                    Section {
                        HStack {
                            Image(systemName: "info.circle.fill")
                                .foregroundColor(.gray)
                            Text("This item has already been sold")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        .padding(.vertical, 8)
                    }
                    .listRowBackground(Color.gray.opacity(0.1))
                }
                
                // MARK: - Action Buttons
                Section {
                    // 🔹 Add to Cart button - only if available
                    if storeItem.isAvailable {
                        Button {
                            addToCart()
                        } label: {
                            Label("Add to Cart", systemImage: "cart.fill")
                                .font(.subheadline.bold())
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(
                                    LinearGradient(colors: [.themePrimary, .themeSecondary], startPoint: .leading, endPoint: .trailing)
                                        .cornerRadius(12)
                                )
                        }
                        .listRowBackground(Color.clear)
                    }
                    
                    // 🔹 Contact Seller button - always visible
                    Button {
                        openChatWithSeller()
                    } label: {
                        HStack {
                            if isLoadingChat {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                    .scaleEffect(0.8)
                            } else {
                                Label(storeItem.isAvailable ? "Contact Seller" : "Ask a Question",
                                      systemImage: "message.fill")
                                    .font(.subheadline.bold())
                            }
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(
                            LinearGradient(colors: [Color.themeTeal, Color.themeAqua], startPoint: .leading, endPoint: .trailing)
                                .cornerRadius(12)
                        )
                    }
                    .disabled(isLoadingChat)
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
            // ⭐ Chat navigation
            .fullScreenCover(isPresented: $showChatView) {
                if let conversation = chatConversation {
                    ChatDetailView(conversation: conversation)
                }
            }
        }
    }
}
