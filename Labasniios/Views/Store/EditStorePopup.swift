//
//  EditStorePopup.swift
//  Labasniios
//
//  Created by Salma Mahjoub on 14/11/2025.
//

import SwiftUI

struct EditStorePopup: View {
    @ObservedObject var viewModel: StoreViewModel
    let storeItem: Store
    @State private var newPrice: String = ""
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationView {
            Form {
                // MARK: - Image + Infos
                Section {
                    HStack(spacing: 16) {
                        AsyncImage(url: URL(string: storeItem.clothesId.imageURL)) { image in
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
                            Text(storeItem.clothesId.category?.capitalized ?? "Item")
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
                            
                            // STATUS BADGE
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

                // MARK: - Current Price
                Section("Current Price") {
                    HStack {
                        Image(systemName: "dollarsign.circle.fill")
                            .foregroundColor(.themeAqua)
                        Text("\(Int(storeItem.price)) DT")
                            .font(.title3.bold())
                            .foregroundColor(.themeText)
                    }
                }
                .listRowBackground(Color.themeSoftPink.opacity(0.15))

                // MARK: - New Price (only if available)
                if storeItem.isAvailable {
                    Section("New Price") {
                        HStack {
                            Image(systemName: "pencil.circle.fill")
                                .foregroundColor(.themeSecondary)
                            TextField("Ex: 55", text: $newPrice)
                                .keyboardType(.decimalPad)
                                .font(.body)
                                .foregroundColor(.themeText)
                        }
                    }
                    .listRowBackground(Color.themeCard)
                }

                // MARK: - Actions
                Section {
                    // Update price (only if available)
                    if storeItem.isAvailable {
                        Button {
                            let price = Double(newPrice) ?? storeItem.price
                            viewModel.updateStorePrice(storeItem.id, price: price)
                            dismiss()
                        } label: {
                            HStack {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.white)
                                Text("Update Price")
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
                        .disabled(newPrice.isEmpty || Double(newPrice) == nil)
                        .listRowBackground(Color.clear)
                    }

                    // Mark as sold
                    Button {
                        if storeItem.isAvailable {
                            viewModel.markAsSold(storeItem.id)
                            dismiss()
                        }
                    } label: {
                        HStack {
                            Image(systemName: storeItem.isAvailable ? "bag.fill" : "checkmark.circle.fill")
                                .foregroundColor(.white)
                            Text(storeItem.isAvailable ? "Mark as Sold" : "Already Sold")
                                .font(.subheadline.bold())
                                .foregroundColor(.white)
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(
                            LinearGradient(
                                colors: storeItem.isAvailable
                                    ? [Color.red.opacity(0.9), Color.red.opacity(0.7)]
                                    : [Color.gray.opacity(0.5), Color.gray.opacity(0.3)],
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
            .navigationTitle("Edit Item")
            .navigationBarTitleDisplayMode(.inline)
            .background(Color.themeBackground.ignoresSafeArea())
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(.themePrimary)
                    .font(.subheadline.bold())
                }
            }
            .onAppear {
                newPrice = String(Int(storeItem.price))
            }
        }
    }
}
