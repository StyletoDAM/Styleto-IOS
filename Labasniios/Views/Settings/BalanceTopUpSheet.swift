//  BalanceTopUpSheet.swift
//  Labasniios

import SwiftUI

struct BalanceTopUpSheet: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var viewModel: SettingsViewModel
    
    @State private var selectedAmount: Double? = nil
    @State private var customAmount = ""
    @State private var isCustomSelected = false
    
    private let presetAmounts: [Double] = [50, 100, 200, 500, 1000]
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            Text("Top Up Balance")
                .font(.title2.bold())
                .foregroundColor(.themeTeal)
                .padding(.top, 24)
                .padding(.bottom, 8)
            
            Text("Choose an amount to add to your balance")
                .font(.body)
                .foregroundColor(.themeSecondaryText)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
                .padding(.bottom, 32)
            
            // Preset amounts grid
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                ForEach(presetAmounts, id: \.self) { amount in
                    amountButton(amount: amount)
                }
                
                // "Other" button
                Button {
                    withAnimation(.spring(response: 0.4)) {
                        isCustomSelected = true
                        selectedAmount = nil
                    }
                } label: {
                    VStack(spacing: 8) {
                        Image(systemName: "pencil")
                            .font(.system(size: 24))
                            .foregroundColor(isCustomSelected ? .white : .themePrimary)
                        
                        Text("Other")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(isCustomSelected ? .white : .themePrimary)
                    }
                    .frame(height: 90)
                    .frame(maxWidth: .infinity)
                    .background(
                        RoundedRectangle(cornerRadius: 20)
                            .fill(isCustomSelected ? Color.themePrimary : Color.themeCard)
                            .overlay(
                                RoundedRectangle(cornerRadius: 20)
                                    .stroke(isCustomSelected ? Color.themePrimary : Color.themeTeal.opacity(0.3), lineWidth: 2)
                            )
                    )
                }
            }
            .padding(.horizontal, 24)
            
            // Custom amount field
            if isCustomSelected {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Custom Amount")
                        .font(.headline)
                        .foregroundColor(.themeText)
                    
                    HStack {
                        TextField("Enter amount", text: $customAmount)
                            .keyboardType(.decimalPad)
                            .padding(16)
                            .background(Color.themeBackground)
                            .cornerRadius(16)
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(Color.themeTeal.opacity(0.3), lineWidth: 1)
                            )
                        
                        Text("TND")
                            .font(.title3.bold())
                            .foregroundColor(.themeTeal)
                            .padding(.trailing, 16)
                    }
                }
                .padding(.horizontal, 24)
                .padding(.top, 24)
                .transition(.opacity.combined(with: .move(edge: .bottom)))
            }
            
            Spacer()
            
            // Action buttons
            HStack(spacing: 16) {
                Button("Cancel") {
                    dismiss()
                }
                .font(.system(size: 17, weight: .semibold))
                .foregroundColor(.themeText)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(Color.themeCard)
                .cornerRadius(16)
                
                Button("Top Up") {
                    let finalAmount = isCustomSelected && !customAmount.isEmpty ?
                        (Double(customAmount.replacingOccurrences(of: ",", with: ".")) ?? 0) :
                        (selectedAmount ?? 0)
                    
                    guard finalAmount > 0 else { return }
                    
                    Task { @MainActor in
                        await viewModel.topUpBalance(amount: finalAmount)
                        if viewModel.errorMessage == nil {
                            dismiss()
                        }
                    }
                }
                .font(.system(size: 17, weight: .semibold))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(
                    LinearGradient(colors: [Color.themePrimary, Color.themeTeal], startPoint: .leading, endPoint: .trailing)
                )
                .cornerRadius(16)
                .disabled(
                    (isCustomSelected && (customAmount.isEmpty || Double(customAmount.replacingOccurrences(of: ",", with: ".")) ?? 0 <= 0)) &&
                    selectedAmount == nil
                )
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 34)
        }
        .frame(maxWidth: .infinity)
        .background(Color.themeBackground.ignoresSafeArea())
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
        .alert("Error", isPresented: .constant(viewModel.errorMessage != nil)) {
            Button("OK") { viewModel.resetFeedback() }
        } message: {
            Text(viewModel.errorMessage ?? "")
        }
        .alert("Success", isPresented: .constant(viewModel.successMessage != nil)) {
            Button("OK") { viewModel.resetFeedback() }
        } message: {
            Text(viewModel.successMessage ?? "")
        }
    }
    
    private func amountButton(amount: Double) -> some View {
        Button {
            withAnimation(.spring(response: 0.4)) {
                selectedAmount = amount
                isCustomSelected = false
                customAmount = ""
            }
        } label: {
            VStack(spacing: 8) {
                Text("\(Int(amount))")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(selectedAmount == amount ? .white : .themeTeal)
                
                Text("TND")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(selectedAmount == amount ? .white : .themeTeal.opacity(0.8))
            }
            .frame(height: 90)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(selectedAmount == amount ? Color.themeTeal : Color.themeCard)
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(selectedAmount == amount ? Color.themeTeal : Color.themeTeal.opacity(0.3), lineWidth: 2)
                    )
            )
        }
    }
}

struct BalanceTopUpSheet_Previews: PreviewProvider {
    static var previews: some View {
        BalanceTopUpSheet()
            .environmentObject(SettingsViewModel())
    }
}
