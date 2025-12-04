import SwiftUI
import Stripe
import StripePaymentSheet

struct CartView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var cartManager = CartManager.shared
    @StateObject private var paymentViewModel = PaymentViewModel()
    
    // MARK: - Alert States
    @State private var itemToDelete: CartItemModel? // ✨ MODIFIÉ : Utiliser CartItemModel
    @State private var showingDeleteAlert = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                ScrollView {
                    VStack(spacing: 20) {
                        if cartManager.cartItems.isEmpty {
                            emptyState
                        } else {
                            cartItemsList
                            orderSummary
                        }
                        
                        Spacer(minLength: 100)
                    }
                    .padding(.vertical, 10)
                }
                .background(Color.themeBackground.ignoresSafeArea())
                
                // Loading overlay
                if paymentViewModel.isProcessing {
                    Color.black.opacity(0.4)
                        .ignoresSafeArea()
                    
                    VStack(spacing: 20) {
                        ProgressView()
                            .scaleEffect(1.5)
                            .tint(.white)
                        Text("Processing payment...")
                            .foregroundColor(.white)
                            .font(.headline)
                    }
                    .padding(30)
                    .background(Color.themePrimary)
                    .cornerRadius(20)
                }
            }
            .navigationTitle("My Cart (\(cartManager.itemCount))")
            .task {
                // ✨ NOUVEAU : Rafraîchir le panier au démarrage
                await cartManager.fetchCartItems()
                
                // Rafraîchir le balance au démarrage (comme Android LaunchedEffect)
                // Vérifier que le token est disponible avant de rafraîchir
                if TokenManager.shared.getToken() != nil {
                    await paymentViewModel.refreshBalance()
                } else {
                    print("⚠️ [CartView] No token available, skipping balance refresh")
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .foregroundColor(.themePrimary)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "chevron.left")
                            .fontWeight(.bold)
                            .foregroundColor(.themePrimary)
                    }
                }
            }
            // MARK: - Delete Confirmation Alert
            .alert("Remove from cart?", isPresented: $showingDeleteAlert) {
                Button("Cancel", role: .cancel) {
                    itemToDelete = nil
                }
                Button("Remove", role: .destructive) {
                    if let item = itemToDelete {
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                            cartManager.removeFromCart(item)
                        }
                    }
                    itemToDelete = nil
                }
            } message: {
                Text("This item will be removed from your cart.")
            }
            // MARK: - Error Alert
            .alert("Payment Error", isPresented: Binding(
                get: { paymentViewModel.errorMessage != nil },
                set: { if !$0 { paymentViewModel.errorMessage = nil } }
            )) {
                Button("OK", role: .cancel) {
                    paymentViewModel.errorMessage = nil
                }
            } message: {
                if let error = paymentViewModel.errorMessage {
                    Text(error)
                }
            }
            // MARK: - Success Alert
            .alert("Purchase Successful! 🎉", isPresented: $paymentViewModel.showSuccess) {
                Button("OK") {
                    paymentViewModel.resetAfterSuccess()
                    dismiss()
                }
            } message: {
                Text("Your items have been purchased successfully!")
            }
            // MARK: - Payment Sheet
            .sheet(isPresented: Binding(
                get: { paymentViewModel.paymentSheet != nil },
                set: { if !$0 { paymentViewModel.paymentSheet = nil } }
            )) {
                if let paymentSheet = paymentViewModel.paymentSheet {
                    PaymentSheetView(
                        paymentSheet: paymentSheet,
                        onCompletion: paymentViewModel.onPaymentCompletion
                    )
                }
            }
        }
    }
    
    // MARK: - Empty State
    private var emptyState: some View {
        VStack(spacing: 28) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Color.themeSoftPink.opacity(0.3), Color.themePrimary.opacity(0.2)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 160, height: 160)
                    .overlay(
                        Circle()
                            .stroke(Color.themePrimary.opacity(0.2), lineWidth: 2)
                    )
                
                Image(systemName: "bag.badge.plus")
                    .font(.system(size: 58, weight: .bold))
                    .foregroundColor(.themePrimary)
            }
            .padding(.top, 40)
            
            VStack(spacing: 8) {
                Text("Your cart is feeling lonely")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundColor(.themePrimary)
                
                Text("Discover new outfits and add them to your cart to continue.")
                    .font(.system(size: 15))
                    .foregroundColor(.themeSecondaryText)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }
            
            VStack(spacing: 12) {
                Button {
                    dismiss()
                } label: {
                    Text("Browse Discover")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 15)
                        .background(
                            LinearGradient(
                                colors: [Color.themePrimary, Color.themeTeal],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .clipShape(Capsule())
                        .shadow(color: .themePrimary.opacity(0.35), radius: 10, y: 4)
                }
                .padding(.horizontal, 40)
                
                Button {
                    dismiss()
                } label: {
                    Text("Back to Store")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(.themePrimary)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 10)
                        .background(
                            Capsule()
                                .stroke(Color.themePrimary.opacity(0.4), lineWidth: 1.5)
                        )
                }
            }
            
            Spacer()
        }
    }
    
    // MARK: - Cart Items List
    private var cartItemsList: some View {
        ForEach(cartManager.cartItems, id: \.id) { item in
            CartItemRow(
                imageURL: item.imageURL,
                title: item.title,
                size: item.size,
                price: item.price,
                isSold: item.isSold, // ✨ NOUVEAU : Passer le statut
                onDelete: {
                    itemToDelete = item
                    showingDeleteAlert = true
                }
            )
        }
    }
    
    // MARK: - Order Summary
    private var orderSummary: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Order Summary")
                .font(.title3.bold())
                .foregroundColor(.themePrimary)
            
            HStack {
                Text("Available Balance")
                Spacer()
                Text(String(format: "%.2f DT", paymentViewModel.userBalance))
                    .fontWeight(.semibold)
                    .foregroundColor(paymentViewModel.canPayWithBalance ? .themeTeal : .red)
            }
            
            // Payment method choice
            HStack(spacing: 20) {
                Button {
                    paymentViewModel.useBalance = true
                } label: {
                    HStack {
                        Image(systemName: paymentViewModel.useBalance ? "largecircle.fill.circle" : "circle")
                        Text("Balance")
                    }
                    .foregroundColor(paymentViewModel.useBalance ? .themeTeal : .secondary)
                }
                
                Button {
                    paymentViewModel.useBalance = false
                } label: {
                    HStack {
                        Image(systemName: !paymentViewModel.useBalance ? "largecircle.fill.circle" : "circle")
                        Text("Card")
                    }
                    .foregroundColor(!paymentViewModel.useBalance ? .themePrimary : .secondary)
                }
            }
            .font(.system(size: 17, weight: .medium))
            
            Divider()
            
            HStack {
                Text("Total")
                    .font(.title2.bold())
                Spacer()
                Text("\(cartManager.totalPrice, specifier: "%.2f") DT")
                    .font(.title2.bold())
                    .foregroundColor(.themePrimary)
            }
            
            Button {
                Task { await paymentViewModel.startCheckout() }
            } label: {
                HStack {
                    if paymentViewModel.isProcessing {
                        ProgressView().tint(.white)
                    } else {
                        Image(systemName: paymentViewModel.useBalance ? "wallet.pass.fill" : "creditcard.fill")
                    }
                    Text(paymentViewModel.isProcessing ? "Processing..." : "Pay Now")
                        .font(.title3.bold())
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(
                    (paymentViewModel.useBalance && !paymentViewModel.canPayWithBalance) || cartManager.cartItems.allSatisfy { $0.isSold } ? Color.gray : Color.themePrimary
                )
                .cornerRadius(20)
            }
            .disabled(paymentViewModel.isProcessing || (paymentViewModel.useBalance && !paymentViewModel.canPayWithBalance) || cartManager.cartItems.allSatisfy { $0.isSold }) // ✨ Désactiver si tous les items sont vendus
            
            if paymentViewModel.useBalance && !paymentViewModel.canPayWithBalance {
                Text("Insufficient balance")
                    .font(.caption)
                    .foregroundColor(.red)
            }
        }
        .padding()
        .background(Color.themeCard)
        .cornerRadius(20)
        .padding(.horizontal)
    }
}

// MARK: - Cart Item Row
struct CartItemRow: View {
    let imageURL: String?
    let title: String
    let size: String
    let price: Double
    let isSold: Bool // ✨ NOUVEAU : Statut de l'article
    let onDelete: () -> Void
    
    var body: some View {
        HStack(spacing: 16) {
            // ✨ MODIFIÉ : Image avec overlay "SOLD OUT" si vendu
            ZStack(alignment: .topTrailing) {
                AsyncImage(url: URL(string: imageURL ?? "")) { image in
                    image
                        .resizable()
                        .scaledToFill()
                        .grayscale(isSold ? 0.7 : 0) // ✨ Griser si vendu
                        .opacity(isSold ? 0.6 : 1.0) // ✨ Opacité réduite si vendu
                } placeholder: {
                    Rectangle()
                        .fill(Color.themeSoftPink.opacity(0.3))
                        .overlay(
                            Image(systemName: "tshirt")
                                .font(.title2)
                                .foregroundColor(.themeTeal.opacity(0.6))
                        )
                }
                .frame(width: 90, height: 90)
                .clipped()
                .cornerRadius(16)
                
                // ✨ NOUVEAU : Badge "SOLD OUT"
                if isSold {
                    Text("SOLD OUT")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 3)
                        .background(Color.red)
                        .cornerRadius(6)
                        .padding(4)
                }
            }
            
            VStack(alignment: .leading, spacing: 8) {
                Text(title)
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(isSold ? .gray : .themePrimary) // ✨ Griser si vendu
                    .lineLimit(2)
                
                HStack(spacing: 12) {
                    Label(size, systemImage: "ruler")
                        .font(.caption)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(Color.themeSoftPink.opacity(0.4))
                        .cornerRadius(10)
                }
                
                Text("\(price, specifier: "%.2f") DT")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(isSold ? .gray : .themePrimary) // ✨ Griser si vendu
            }
            
            Spacer()
            
            // ✨ MODIFIÉ : Bouton delete toujours actif mais grisé si vendu
            Button {
                onDelete()
            } label: {
                Image(systemName: "trash")
                    .foregroundColor(isSold ? .gray.opacity(0.6) : .red.opacity(0.8))
                    .font(.title2)
            }
        }
        .padding()
        .background(isSold ? Color.gray.opacity(0.1) : Color.themeCard) // ✨ Fond grisé si vendu
        .cornerRadius(20)
        .padding(.horizontal)
        .shadow(color: .black.opacity(0.05), radius: 8)
    }
}

#Preview {
    CartView()
}
