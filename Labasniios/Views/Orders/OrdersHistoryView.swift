// Views/Orders/OrdersHistoryView.swift
import SwiftUI

struct OrdersHistoryView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var orders: [OrderResponse] = []
    @State private var isLoading = true
    @State private var errorMessage: String?
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.themeBackground.ignoresSafeArea()
                
                if isLoading {
                    ProgressView()
                        .tint(.themePrimary)
                } else if let error = errorMessage {
                    VStack(spacing: 16) {
                        Image(systemName: "exclamationmark.triangle")
                            .font(.system(size: 48))
                            .foregroundColor(.red.opacity(0.7))
                        Text("Error")
                            .font(.title2.bold())
                            .foregroundColor(.themeText)
                        Text(error)
                            .font(.body)
                            .foregroundColor(.themeSecondaryText)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                } else if orders.isEmpty {
                    VStack(spacing: 20) {
                        Image(systemName: "bag.fill")
                            .font(.system(size: 64))
                            .foregroundColor(.themeSecondaryText.opacity(0.6))
                        Text("No orders yet!")
                            .font(.title2.bold())
                            .foregroundColor(.themeText)
                        Text("Start exploring the store and make your first purchase.")
                            .font(.body)
                            .foregroundColor(.themeSecondaryText)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 32)
                    }
                } else {
                    ScrollView {
                        LazyVStack(spacing: 16) {
                            ForEach(orders, id: \.id) { order in
                                OrderCardView(order: order)
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 16)
                    }
                }
            }
            .navigationTitle("Order History")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        dismiss()
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "chevron.left")
                            Text("Back")
                        }
                        .foregroundColor(.themePrimary)
                    }
                }
            }
            .task {
                await loadOrders()
            }
        }
    }
    
    private func loadOrders() async {
        isLoading = true
        errorMessage = nil
        
        do {
            orders = try await OrdersService.shared.getMyOrders()
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
}

// MARK: - Order Card
private struct OrderCardView: View {
    let order: OrderResponse
    
    private var formattedDate: String {
        let displayFormatter = DateFormatter()
        displayFormatter.dateFormat = "MMM dd, yyyy"
        return displayFormatter.string(from: order.orderDate)
    }
    
    var body: some View {
        HStack(spacing: 12) {
            // Image
            let clothInfo = order.clothesId
            if let imageUrl = clothInfo.displayImageUrl, !imageUrl.isEmpty, let url = URL(string: imageUrl) {
                AsyncImage(url: url) { image in
                    image
                        .resizable()
                        .scaledToFill()
                } placeholder: {
                    Rectangle()
                        .fill(Color.themeSoftPink.opacity(0.2))
                        .overlay(
                            ProgressView()
                                .tint(.themePrimary)
                        )
                }
                .frame(width: 80, height: 80)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            } else {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.themeSoftPink.opacity(0.2))
                    .frame(width: 80, height: 80)
                    .overlay(
                        Image(systemName: "photo")
                            .font(.system(size: 32))
                            .foregroundColor(.themeSecondaryText.opacity(0.4))
                    )
            }
            
            // Info
            VStack(alignment: .leading, spacing: 8) {
                Text(clothInfo.name ?? "Clothes Item")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.themeText)
                    .lineLimit(1)
                
                if let type = clothInfo.displayType {
                    Text(type.capitalized)
                        .font(.system(size: 13))
                        .foregroundColor(.themeSecondaryText)
                }
                
                Text("\(String(format: "%.2f", order.price)) TND")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.themeTeal)
                
                HStack(spacing: 6) {
                    Image(systemName: "calendar")
                        .font(.system(size: 11))
                        .foregroundColor(.themeSecondaryText.opacity(0.7))
                    Text(formattedDate)
                        .font(.system(size: 12))
                        .foregroundColor(.themeSecondaryText.opacity(0.7))
                }
            }
            
            Spacer()
        }
        .padding(16)
        .background(Color.themeCard)
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.06), radius: 8, x: 0, y: 4)
    }
}

#Preview {
    OrdersHistoryView()
}

