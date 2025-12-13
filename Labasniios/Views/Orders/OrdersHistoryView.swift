// Views/Orders/OrdersHistoryView.swift
import SwiftUI

struct OrdersHistoryView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var historyItems: [HistoryItemResponse] = []
    @State private var isLoading = true
    @State private var errorMessage: String?
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Contenu
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
                            if historyItems.isEmpty {
                                EmptyHistoryView()
                                    .padding(.top, 60)
                            } else {
                                ForEach(historyItems, id: \.id) { item in
                                    HistoryItemCardView(item: item)
                                }
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 16)
                    }
                }
            }
            .background(Color.themeBackground.ignoresSafeArea())
            .navigationTitle("Transaction History")
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
    
    private func loadData() async {
        isLoading = true
        errorMessage = nil
        
        do {
            let result = try await OrdersService.shared.getUnifiedHistory()
            
            print("🔍 [OrdersHistoryView] Loaded \(result.count) history items from API")
            
            historyItems = result
            
            print("✅ [OrdersHistoryView] Displaying \(historyItems.count) history items")
            
        } catch {
            errorMessage = error.localizedDescription
            print("❌ [OrdersHistoryView] Error loading data: \(error)")
        }
        
        isLoading = false
    }
}

// MARK: - History Item Card
private struct HistoryItemCardView: View {
    let item: HistoryItemResponse
    
    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM dd, yyyy"
        return formatter.string(from: item.date)
    }
    
    private var isPurchased: Bool {
        item.isPurchased
    }
    
    private var tagText: String {
        isPurchased ? "Purchased" : "Sold"
    }
    
    private var tagColor: Color {
        isPurchased ? Color(red: 0.898, green: 0.224, blue: 0.208) : Color(red: 0.298, green: 0.686, blue: 0.314)
    }
    
    private var tagBackgroundColor: Color {
        isPurchased ? Color(red: 1.0, green: 0.922, blue: 0.933) : Color(red: 0.91, green: 0.961, blue: 0.914)
    }
    
    private var arrowColor: Color {
        isPurchased ? Color(red: 0.898, green: 0.224, blue: 0.208) : Color(red: 0.298, green: 0.686, blue: 0.314)
    }
    
    private var arrowIcon: String {
        isPurchased ? "arrow.down" : "arrow.up"
    }
    
    private var amountPrefix: String {
        isPurchased ? "-" : "+"
    }
    
    var body: some View {
        HStack(spacing: 12) {
            // Image
            if let imageUrl = item.clothesId.displayImageUrl, !imageUrl.isEmpty, let url = URL(string: imageUrl) {
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
                // Tag (Purchased/Sold)
                HStack(spacing: 4) {
                    Text(tagText)
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(tagColor)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(tagBackgroundColor)
                        .cornerRadius(8)
                }
                
                Text(item.clothesId.name ?? "Clothes Item")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.themeText)
                    .lineLimit(1)
                
                if let type = item.clothesId.displayType {
                    Text(type.capitalized)
                        .font(.system(size: 13))
                        .foregroundColor(.themeSecondaryText)
                }
                
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
            
            // Prix avec flèche
            VStack(alignment: .trailing, spacing: 4) {
                HStack(spacing: 4) {
                    // Petite flèche
                    Image(systemName: arrowIcon)
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(arrowColor)
                    
                    Text("\(String(format: "%.2f", item.price)) TND")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(arrowColor)
                }
            }
        }
        .padding(16)
        .background(Color.themeCard)
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.06), radius: 8, x: 0, y: 4)
    }
}

// MARK: - Empty History View
private struct EmptyHistoryView: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "clock.fill")
                .font(.system(size: 64))
                .foregroundColor(.themeSecondaryText.opacity(0.6))
            Text("No history yet!")
                .font(.title2.bold())
                .foregroundColor(.themeText)
            Text("Your purchase and sale history will appear here.")
                .font(.body)
                .foregroundColor(.themeSecondaryText)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
        }
    }
}

#Preview {
    OrdersHistoryView()
}
