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
                // MARK: - Image + Infos (compact, comme avant)
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
                            Text(storeItem.clothe?.category?.capitalized ?? "Article")
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
                            
                            // TAILLE – Ajoutée ici, compacte et discrète
                            if let size = storeItem.size, !size.isEmpty {
                                HStack(spacing: 6) {
                                    Image(systemName: "ruler")
                                        .font(.caption)
                                        .foregroundColor(.themeSecondary)
                                    Text("Taille: \(size)")
                                        .font(.caption.bold())
                                        .foregroundColor(.themeSecondary)
                                }
                                .padding(.horizontal, 10)
                                .padding(.vertical, 4)
                                .background(Color.themeCard.opacity(0.8))
                                .clipShape(Capsule())
                                .overlay(Capsule().stroke(Color.themePrimary.opacity(0.3), lineWidth: 1))
                            }
                            
                            // Statut
                            HStack(spacing: 4) {
                                Image(systemName: storeItem.isAvailable ? "circle.fill" : "checkmark.circle.fill")
                                    .font(.caption2)
                                    .foregroundColor(storeItem.isAvailable ? .green : .gray)
                                Text(storeItem.isAvailable ? "Disponible" : "Vendu")
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
                
                // Prix actuel
                Section("Prix actuel") {
                    HStack {
                        Image(systemName: "dollarsign.circle.fill")
                            .foregroundColor(.themeAqua)
                        Text("\(Int(storeItem.price)) DT")
                            .font(.title3.bold())
                            .foregroundColor(.themeText)
                    }
                }
                .listRowBackground(Color.themeSoftPink.opacity(0.15))
                
                // Nouveau prix
                if storeItem.isAvailable {
                    Section("Nouveau prix") {
                        HStack {
                            Image(systemName: "pencil.circle.fill")
                                .foregroundColor(.themeSecondary)
                            TextField("Ex: 75", text: $newPrice)
                                .keyboardType(.decimalPad)
                                .font(.body)
                                .foregroundColor(.themeText)
                        }
                    }
                    .listRowBackground(Color.themeCard)
                }
                
                // Modifier la taille
                if storeItem.isAvailable {
                    Section("Modifier la taille") {
                        if isShoes {
                            TextField("Pointure (ex: 42)", text: $newSize)
                                .keyboardType(.numberPad)
                        } else {
                            Picker("Taille", selection: $newSize) {
                                Text("Choisir").tag("")
                                ForEach(["XS", "S", "M", "L", "XL", "XXL", "XXXL"], id: \.self) { size in
                                    Text(size).tag(size)
                                }
                            }
                            .pickerStyle(.segmented)
                            .onChange(of: newSize) { _, newValue in
                                if newValue == "" { newSize = storeItem.size ?? "" } // reset si on choisit "Choisir"
                            }
                        }
                    }
                    .listRowBackground(Color.themeCard)
                }
                
                // Actions
                Section {
                    if storeItem.isAvailable, !newPrice.isEmpty, Double(newPrice) != nil {
                        Button {
                            let price = Double(newPrice) ?? storeItem.price
                            viewModel.updateStorePrice(storeItem.id, price: price)
                            dismiss()
                        } label: {
                            Label("Mettre à jour le prix", systemImage: "checkmark.circle.fill")
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
                            Label("Mettre à jour la taille", systemImage: "ruler.fill")
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
                        Label("Marquer comme vendu", systemImage: "bag.fill")
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
                        Label("Supprimer l’article", systemImage: "trash.fill")
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
            .navigationTitle("Modifier l’article")
            .navigationBarTitleDisplayMode(.inline)
            .background(Color.themeBackground.ignoresSafeArea())
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Annuler") { dismiss() }
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
            .alert("Supprimer cet article ?", isPresented: $showDeleteAlert) {
                Button("Annuler", role: .cancel) { }
                Button("Supprimer", role: .destructive) {
                    viewModel.deleteStoreItem(storeItem)
                    dismiss()
                }
            } message: { Text("Cette action est irréversible.") }
        }
    }
}
