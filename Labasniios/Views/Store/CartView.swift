import SwiftUI

import Stripe
import StripePaymentSheet

struct CartView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var cartManager = CartManager.shared
    @StateObject private var paymentViewModel = PaymentViewModel()
    
    // MARK: - Alert States
    @State private var itemToDelete: CartItem?
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
                            freeShippingBanner
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
        VStack(spacing: 20) {
            Image(systemName: "cart")
                .font(.system(size: 60))
                .foregroundColor(.gray.opacity(0.5))
            
            Text("Your cart is empty")
                .font(.title2)
                .foregroundColor(.gray)
            
            Text("Add items from the store!")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.top, 100)
    }
    
    // MARK: - Cart Items List
    private var cartItemsList: some View {
        ForEach(cartManager.cartItems, id: \.id) { item in
            CartItemRow(
                imageURL: item.imageURL,
                title: item.title ?? "Item",
                size: item.size ?? "One Size",
                price: item.price,
                onDelete: {
                    itemToDelete = item
                    showingDeleteAlert = true
                }
            )
        }
    }
    
    // MARK: - Free Shipping Banner
    private var freeShippingBanner: some View {
        HStack {
            Image(systemName: "truck.box.fill")
                .foregroundColor(.themeTeal)
            Text("Free shipping!")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.themeTeal)
            Spacer()
            Image(systemName: "party.popper.fill")
                .foregroundColor(.orange)
        }
        .padding()
        .background(Color.themeCard)
        .cornerRadius(16)
        .padding(.horizontal)
    }
    
    // MARK: - Order Summary
    private var orderSummary: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Order Summary")
                .font(.title3.bold())
                .foregroundColor(.themePrimary)
            
            Divider().background(Color.themePrimary.opacity(0.3))
            
            Text(String(format: "%.2f DT", cartManager.totalPrice))
            summaryRow(title: "Shipping", value: "Free", color: .green, bold: true)
            
            Divider().background(Color.themePrimary.opacity(0.3))
            
            HStack {
                Text("Total")
                    .font(.title2.bold())
                Spacer()
                Text("\(cartManager.totalPrice, specifier: "%.2f") DT")
                    .font(.title2.bold())
                    .foregroundColor(.themePrimary)
            }
            
            // MARK: - Checkout Button
            Button {
                Task {
                    await paymentViewModel.startCheckout()
                }
            } label: {
                HStack {
                    if paymentViewModel.isProcessing {
                        ProgressView()
                            .tint(.white)
                    } else {
                        Image(systemName: "creditcard.fill")
                    }
                    Text(paymentViewModel.isProcessing ? "Processing..." : "Proceed to Checkout")
                        .font(.title3.bold())
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(
                    paymentViewModel.isProcessing
                        ? Color.gray
                        : Color.themePrimary
                )
                .cornerRadius(20)
                .shadow(
                    color: paymentViewModel.isProcessing
                        ? .clear
                        : .themePrimary.opacity(0.4),
                    radius: 10,
                    y: 5
                )
            }
            .disabled(paymentViewModel.isProcessing)
            .padding(.top, 12)
        }
        .padding()
        .background(Color.themeCard)
        .cornerRadius(20)
        .shadow(color: .black.opacity(0.08), radius: 12)
        .padding(.horizontal)
    }
    
    private func summaryRow(title: String, value: String, color: Color = Color("themeTeal"), bold: Bool = false) -> some View {
        HStack {
            Text(title)
                .foregroundColor(.themeTeal)
            Spacer()
            Text(value)
                .foregroundColor(color)
                .font(.system(size: 17, weight: bold ? .semibold : .medium))
        }
    }
}

// MARK: - Cart Item Row
struct CartItemRow: View {
    let imageURL: String?
    let title: String
    let size: String
    let price: Double
    let onDelete: () -> Void
    
    var body: some View {
        HStack(spacing: 16) {
            AsyncImage(url: URL(string: imageURL ?? "")) { image in
                image
                    .resizable()
                    .scaledToFill()
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
            
            VStack(alignment: .leading, spacing: 8) {
                Text(title)
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(.themePrimary)
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
                    .foregroundColor(.themePrimary)
            }
            
            Spacer()
            
            Button {
                onDelete()
            } label: {
                Image(systemName: "trash")
                    .foregroundColor(.red.opacity(0.8))
                    .font(.title2)
            }
        }
        .padding()
        .background(Color.themeCard)
        .cornerRadius(20)
        .padding(.horizontal)
        .shadow(color: .black.opacity(0.05), radius:8)
    }
}

#Preview {
    CartView()
}
