// CartView.swift
import SwiftUI

struct CartView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var themeManager = ThemeManager.shared
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // MARK: - Articles
                    CartItemRow(
                        imageName: "logocercle",
                        title: "Pink knitted sweater",
                        size: "M",
                        colorName: "Pink",
                        price: 45.00
                    )
                    
                    CartItemRow(
                        imageName: "logocercle",
                        title: "White sneakers",
                        size: "38",
                        colorName: "White",
                        price: 120.00
                    )
                    
                    CartItemRow(
                        imageName: "logocercle",
                        title: "Leather jacket",
                        size: "L",
                        colorName: "Black",
                        price: 180.00
                    )
                    
                    // MARK: - Livraison gratuite
                    HStack {
                        Image(systemName: "truck.box.fill")
                            .foregroundColor(.themeTeal)
                        Text("Free delivery!")
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
                    
                    // MARK: - Résumé de la commande
                    VStack(alignment: .leading, spacing: 14) {
                        Text("Order Summary")
                            .font(.title3.bold())
                            .foregroundColor(.themePrimary)
                        
                        Divider().background(Color.themePrimary.opacity(0.3))
                        
                        HStack {
                            Text("Subtotal")
                                .foregroundColor(.themeTeal)
                            Spacer()
                            Text("525.00 DT")
                                .foregroundColor(.themeTeal)
                                .font(.system(size: 17, weight: .medium))
                        }
                        
                        HStack {
                            Text("Delivery")
                                .foregroundColor(.themeTeal)

                            Spacer()
                            Text("Free")
                                .foregroundColor(.green)
                                .fontWeight(.semibold)
                        }
                        
                        Divider().background(Color.themePrimary.opacity(0.3))
                        
                        HStack {
                            Text("Total")
                                .font(.title2.bold())
                            Spacer()
                            Text("525.00 DT")
                                .font(.title2.bold())
                                .foregroundColor(.themePrimary)
                        }
                        
                        Button {
                            // Checkout action
                        } label: {
                            HStack {
                                Image(systemName: "creditcard.fill")
                                Text("Proceed to Checkout")
                                    .font(.title3.bold())
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.themePrimary)
                            .cornerRadius(20)
                            .shadow(color: .themePrimary.opacity(0.4), radius: 10, y: 5)
                        }
                        .padding(.top, 12)
                    }
                    .padding()
                    .background(Color.themeCard)
                    .cornerRadius(20)
                    .shadow(color: .black.opacity(0.08), radius: 12)
                    .padding(.horizontal)
                    
                    Spacer(minLength: 100)
                }
                .padding(.vertical, 10)
            }
            .background(Color.themeBackground.ignoresSafeArea())
            .navigationTitle("My Cart")
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
        }
    }
}

// MARK: - Article du panier (sans + / -)
struct CartItemRow: View {
    let imageName: String
    let title: String
    let size: String
    let colorName: String
    let price: Double
    
    var body: some View {
        HStack(spacing: 16) {
            Image(imageName)
                .resizable()
                .scaledToFill()
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
                    
                    Text(colorName)
                        .font(.caption)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(Color.themeAqua.opacity(0.4))
                        .cornerRadius(10)
                }
                
                Text("\(price, specifier: "%.2f") DT")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.themePrimary)
            }
            
            Spacer()
            
            Button {
                // Delete action (future)
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
        .shadow(color: .black.opacity(0.05), radius: 8)
    }
}

#Preview {
    CartView()
}
