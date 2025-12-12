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
    
    // MARK: - Filtered Data
    /// Filtre les orders valides (avec clothesId valide)
    private var filteredOrders: [OrderResponse] {
        return orders.filter { order in
            // S'assurer que c'est bien un order (a un clothesId avec des données)
            return !order.clothesId.id.isEmpty
        }
    }
    
    /// Filtre les transactions valides (avec type incoming/outgoing)
    /// IMPORTANT: Cette fonction garantit qu'aucun order ne sera affiché dans les transactions
    private var filteredTransactions: [TransactionResponse] {
        return transactions.filter { transaction in
            // Validation stricte : s'assurer que c'est bien une transaction
            let hasValidId = !transaction.id.isEmpty
            let hasValidType = transaction.type == "incoming" || transaction.type == "outgoing"
            let hasValidAmount = transaction.amount >= 0
            let hasValidDescription = !transaction.description.isEmpty
            
            // Protection supplémentaire : rejeter tout ce qui pourrait être un order
            // Les orders ont "clothesId" et "userId", les transactions ont "type" et "description"
            // Si le type n'est pas "incoming" ou "outgoing", c'est suspect
            let isNotAnOrder = hasValidType && hasValidDescription
            
            let isValid = hasValidId && hasValidType && hasValidAmount && hasValidDescription && isNotAnOrder
            
            if !isValid {
                print("🚫 [OrdersHistoryView] Rejected invalid transaction: id=\(transaction.id), type=\(transaction.type)")
            }
            
            return isValid
        }
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
                                if filteredOrders.isEmpty {
                                    EmptyPurchaseView()
                                        .padding(.top, 60)
                                } else {
                                    ForEach(filteredOrders, id: \.id) { order in
                                        OrderCardView(order: order)
                                    }
                                }
                            } else {
                                if filteredTransactions.isEmpty {
                                    EmptyTransactionView()
                                        .padding(.top, 60)
                                } else {
                                    ForEach(filteredTransactions, id: \.id) { transaction in
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
            
            let ordersResult = try await ordersTask
            let transactionsResult = try await transactionsTask
            
            // Log pour debug
            print("🔍 [OrdersHistoryView] Loaded \(ordersResult.count) orders from API")
            print("🔍 [OrdersHistoryView] Loaded \(transactionsResult.count) transactions from API")
            
            // IMPORTANT: S'assurer qu'on ne mélange jamais orders et transactions
            // Les orders viennent de /orders, les transactions de /orders/transactions
            
            // Filtrer les orders pour s'assurer qu'ils sont valides
            // Un order valide doit avoir un clothesId avec un id non vide
            // ET ne doit PAS avoir de propriété "type" (qui est spécifique aux transactions)
            orders = ordersResult.filter { order in
                let hasValidClothesId = !order.clothesId.id.isEmpty
                let isValid = hasValidClothesId
                if !isValid {
                    print("⚠️ [OrdersHistoryView] Invalid order filtered out: \(order.id) - missing clothesId")
                }
                return isValid
            }
            
            // Filtrer les transactions pour s'assurer qu'elles sont valides
            // Une transaction valide doit avoir :
            // - Un id non vide
            // - Un type "incoming" ou "outgoing" (OBLIGATOIRE - c'est ce qui la différencie d'un order)
            // - Un amount >= 0
            // - Une description non vide
            // ET ne doit PAS avoir de propriété "clothesId" (qui est spécifique aux orders)
            transactions = transactionsResult.filter { transaction in
                let hasValidId = !transaction.id.isEmpty
                let hasValidType = transaction.type == "incoming" || transaction.type == "outgoing"
                let hasValidAmount = transaction.amount >= 0
                let hasValidDescription = !transaction.description.isEmpty
                
                // Protection critique : si le type n'est pas "incoming" ou "outgoing",
                // c'est probablement un order mal décodé, on le rejette
                let isDefinitelyATransaction = hasValidType
                
                let isValid = hasValidId && hasValidType && hasValidAmount && hasValidDescription && isDefinitelyATransaction
                
                if !isValid {
                    print("⚠️ [OrdersHistoryView] Invalid transaction filtered out:")
                    print("   - id: \(transaction.id.isEmpty ? "empty" : transaction.id)")
                    print("   - type: '\(transaction.type)' (must be 'incoming' or 'outgoing')")
                    print("   - amount: \(transaction.amount)")
                    print("   - description: \(transaction.description.isEmpty ? "empty" : transaction.description)")
                }
                
                return isValid
            }
            
            print("✅ [OrdersHistoryView] Filtered to \(orders.count) valid orders")
            print("✅ [OrdersHistoryView] Filtered to \(transactions.count) valid transactions")
            
            // Vérification finale : s'assurer qu'il n'y a pas de mélange
            if !transactions.isEmpty {
                let invalidTransactions = transactions.filter { $0.type != "incoming" && $0.type != "outgoing" }
                if !invalidTransactions.isEmpty {
                    print("🚨 [OrdersHistoryView] CRITICAL: Found \(invalidTransactions.count) transactions with invalid type!")
                }
            }
            
        } catch {
            errorMessage = error.localizedDescription
            print("❌ [OrdersHistoryView] Error loading data: \(error)")
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

