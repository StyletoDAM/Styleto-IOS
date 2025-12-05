// Views/Orders/OrdersHistoryView.swift
import SwiftUI

struct OrdersHistoryView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var orders: [OrderResponse] = []
    @State private var transactions: [TransactionResponse] = []
    @State private var isLoading = true
    @State private var errorMessage: String?
    @State private var selectedTab: HistoryTab = .purchase
    
    enum HistoryTab {
        case purchase
        case transaction
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Navbar avec deux onglets (comme Store)
                tabSegment
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                
                // Contenu selon l'onglet
                if isLoading {
                    Spacer()
                    ProgressView()
                        .tint(.themePrimary)
                    Spacer()
                } else if let error = errorMessage {
                    Spacer()
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
                    Spacer()
                } else {
                    ScrollView {
                        LazyVStack(spacing: 16) {
                            if selectedTab == .purchase {
                                if orders.isEmpty {
                                    EmptyPurchaseView()
                                        .padding(.top, 60)
                                } else {
                                    ForEach(orders, id: \.id) { order in
                                        OrderCardView(order: order)
                                    }
                                }
                            } else {
                                if transactions.isEmpty {
                                    EmptyTransactionView()
                                        .padding(.top, 60)
                                } else {
                                    ForEach(transactions, id: \.id) { transaction in
                                        TransactionCardView(transaction: transaction)
                                    }
                                }
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 16)
                    }
                }
            }
            .background(Color.themeBackground.ignoresSafeArea())
            .navigationTitle("History")
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
                await loadData()
            }
        }
    }
    
    // MARK: - Tab Segment (comme Store)
    private var tabSegment: some View {
        HStack(spacing: 0) {
            // Bouton "Purchase"
            Button {
                withAnimation(.easeInOut(duration: 0.25)) {
                    selectedTab = .purchase
                }
            } label: {
                Text("Purchase")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(selectedTab == .purchase ? .white : Color.themePrimary.opacity(0.6))
                    .frame(maxWidth: .infinity, maxHeight: 50)
                    .background(
                        RoundedRectangle(cornerRadius: 25)
                            .fill(selectedTab == .purchase ? Color.themePrimary : Color.clear)
                    )
            }
            
            // Bouton "Transaction"
            Button {
                withAnimation(.easeInOut(duration: 0.25)) {
                    selectedTab = .transaction
                }
            } label: {
                Text("Transaction")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(selectedTab == .transaction ? .white : Color.themePrimary.opacity(0.6))
                    .frame(maxWidth: .infinity, maxHeight: 50)
                    .background(
                        RoundedRectangle(cornerRadius: 25)
                            .fill(selectedTab == .transaction ? Color.themePrimary : Color.clear)
                    )
            }
        }
        .padding(4)
        .background(
            Capsule()
                .fill(Color.white)
                .shadow(color: .black.opacity(0.08), radius: 8, x: 0, y: 4)
        )
        .overlay(
            Capsule()
                .stroke(Color.themePrimary.opacity(0.2), lineWidth: 1)
        )
    }
    
    private func loadData() async {
        isLoading = true
        errorMessage = nil
        
        do {
            async let ordersTask = OrdersService.shared.getMyOrders()
            async let transactionsTask = OrdersService.shared.getMyTransactions()
            
            orders = try await ordersTask
            transactions = try await transactionsTask
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

// MARK: - Empty Purchase View
private struct EmptyPurchaseView: View {
    var body: some View {
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
    }
}

// MARK: - Empty Transaction View
private struct EmptyTransactionView: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "creditcard.fill")
                .font(.system(size: 64))
                .foregroundColor(.themeSecondaryText.opacity(0.6))
            Text("No transactions yet!")
                .font(.title2.bold())
                .foregroundColor(.themeText)
            Text("Your transaction history will appear here.")
                .font(.body)
                .foregroundColor(.themeSecondaryText)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
        }
    }
}

// MARK: - Transaction Card View
private struct TransactionCardView: View {
    let transaction: TransactionResponse
    
    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM dd, yyyy"
        return formatter.string(from: transaction.date)
    }
    
    private var isOutgoing: Bool {
        transaction.type == "outgoing"
    }
    
    private var amountColor: Color {
        isOutgoing ? Color(red: 0.898, green: 0.224, blue: 0.208) : Color(red: 0.298, green: 0.686, blue: 0.314)
    }
    
    private var amountPrefix: String {
        isOutgoing ? "-" : "+"
    }
    
    private var backgroundColor: Color {
        isOutgoing ? Color(red: 1.0, green: 0.922, blue: 0.933) : Color(red: 0.91, green: 0.961, blue: 0.914)
    }
    
    var body: some View {
        HStack(spacing: 12) {
            // Icône selon le type
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(backgroundColor)
                    .frame(width: 56, height: 56)
                
                Image(systemName: isOutgoing ? "arrow.down" : "arrow.up")
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundColor(amountColor)
            }
            
            // Informations
            VStack(alignment: .leading, spacing: 6) {
                Text(transaction.description)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.themeText)
                    .lineLimit(2)
                
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
            
            // Montant
            VStack(alignment: .trailing, spacing: 4) {
                Text("\(amountPrefix)\(String(format: "%.2f", transaction.amount)) DT")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(amountColor)
                
                Text(isOutgoing ? "Envoyé" : "Reçu")
                    .font(.system(size: 12))
                    .foregroundColor(.themeSecondaryText)
            }
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

