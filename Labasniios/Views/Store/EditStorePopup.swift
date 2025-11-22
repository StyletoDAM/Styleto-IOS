//
//  EditStorePopup.swift
//  Labasniios
//

import SwiftUI

struct EditStorePopup: View {
    @ObservedObject var viewModel: StoreViewModel
    let storeItem: Store
    
    @State private var newPrice: String = ""
    @State private var newSize: String = ""
    @State private var isShoes: Bool = false
    @State private var showDeleteAlert = false
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            Form {
                // MARK: - Image + Infos (compact, as before)
                Section {
                    HStack(spacing: 16) {
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
                                .overlay(Capsule().stroke(Color.themePrimary.opacity(0.3), lineWidth: 1))
                            }
                            
                            // STATUS
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
                            .background(Capsule().fill(storeItem.isAvailable ? Color.green.opacity(0.1) : Color.gray.opacity(0.1)))
                        }
                        Spacer()
                    }
                    .padding(.vertical, 8)
                }
                .listRowBackground(Color.themeCard)
                .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                
                // CURRENT PRICE
                Section("Current price") {
                    HStack {
                        Image(systemName: "dollarsign.circle.fill")
                            .foregroundColor(.themeAqua)
                        Text("\(Int(storeItem.price)) DT")
                            .font(.title3.bold())
                            .foregroundColor(.themeText)
                    }
                }
                .listRowBackground(Color.themeSoftPink.opacity(0.15))
                
                // NEW PRICE
                if storeItem.isAvailable {
                    Section("New price") {
                        HStack {
                            Image(systemName: "pencil.circle.fill")
                                .foregroundColor(.themeSecondary)
                            TextField("e.g. 75", text: $newPrice)
                                .keyboardType(.decimalPad)
                                .font(.body)
                                .foregroundColor(.themeText)
                        }
                    }
                    .listRowBackground(Color.themeCard)
                }
                
                // SIZE UPDATE
                if storeItem.isAvailable {
                    Section("Update size") {
                        if isShoes {
                            TextField("Shoe size (e.g. 42)", text: $newSize)
                                .keyboardType(.numberPad)
                        } else {
                            Picker("Size", selection: $newSize) {
                                Text("Select").tag("")
                                ForEach(["XS", "S", "M", "L", "XL", "XXL", "XXXL"], id: \.self) { size in
                                    Text(size).tag(size)
                                }
                            }
                            .pickerStyle(.segmented)
                            .onChange(of: newSize) { _, newValue in
                                if newValue == "" { newSize = storeItem.size ?? "" }
                            }
                        }
                    }
                    .listRowBackground(Color.themeCard)
                }
                
                // ACTIONS
                Section {
                    if storeItem.isAvailable, !newPrice.isEmpty, Double(newPrice) != nil {
                        Button {
                            let price = Double(newPrice) ?? storeItem.price
                            viewModel.updateStorePrice(storeItem.id, price: price)
                            dismiss()
                        } label: {
                            Label("Update price", systemImage: "checkmark.circle.fill")
                                .font(.subheadline.bold())
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(LinearGradient(colors: [.themePrimary, .themeSecondary], startPoint: .leading, endPoint: .trailing))
                                .cornerRadius(12)
                        }
                        .listRowBackground(Color.clear)
                    }
                    
                    if storeItem.isAvailable, !newSize.isEmpty, newSize != storeItem.size {
                        Button {
                            viewModel.updateStoreSize(storeItem.id, newSize: newSize)
                            dismiss()
                        } label: {
                            Label("Update size", systemImage: "ruler.fill")
                                .font(.subheadline.bold())
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(LinearGradient(colors: [.themeTeal, .themeAqua], startPoint: .leading, endPoint: .trailing))
                                .cornerRadius(12)
                        }
                        .listRowBackground(Color.clear)
                    }
                    
                    Button {
                        if storeItem.isAvailable {
                            viewModel.markAsSold(storeItem.id)
                            dismiss()
                        }
                    } label: {
                        Label("Mark as sold", systemImage: "bag.fill")
                            .font(.subheadline.bold())
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(LinearGradient(colors: [Color.red.opacity(0.9), Color.red.opacity(0.7)], startPoint: .leading, endPoint: .trailing))
                            .cornerRadius(12)
                    }
                    .disabled(!storeItem.isAvailable)
                    .listRowBackground(Color.clear)
                    
                    Button {
                        showDeleteAlert = true
                    } label: {
                        Label("Delete item", systemImage: "trash.fill")
                            .font(.subheadline.bold())
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(LinearGradient(colors: [Color.red, Color.red.opacity(0.8)], startPoint: .leading, endPoint: .trailing))
                            .cornerRadius(12)
                    }
                    .listRowBackground(Color.clear)
                }
                .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
            }
            .navigationTitle("Edit item")
            .navigationBarTitleDisplayMode(.inline)
            .background(Color.themeBackground.ignoresSafeArea())
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .foregroundColor(.themePrimary)
                        .font(.subheadline.bold())
                }
            }
            .onAppear {
                newPrice = String(Int(storeItem.price))
                newSize = storeItem.size ?? ""
                let cat = (storeItem.clothe?.category ?? "").lowercased()
                isShoes = cat.contains("shoe") || cat.contains("sneaker") || cat.contains("chaussure")
            }
            .alert("Delete this item?", isPresented: $showDeleteAlert) {
                Button("Cancel", role: .cancel) { }
                Button("Delete", role: .destructive) {
                    viewModel.deleteStoreItem(storeItem)
                    dismiss()
                }
            } message: { Text("This action cannot be undone.") }
        }
    }
}
