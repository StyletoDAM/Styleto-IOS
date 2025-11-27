import SwiftUI
import StripePaymentSheet

struct BalanceTopUpSheet: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var viewModel: SettingsViewModel
    
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
                    isCustomSelected = true
                    selectedAmount = nil
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
                
                Button {
                    handleTopUpAction()
                } label: {
                    if viewModel.isProcessingPayment {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    } else {
                        Text("Continue")
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
                    viewModel.isProcessingPayment ||
                    ((isCustomSelected && (customAmount.isEmpty || Double(customAmount.replacingOccurrences(of: ",", with: ".")) ?? 0 <= 0)) &&
                    selectedAmount == nil)
                )
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 34)
        }
        .frame(maxWidth: .infinity)
        .background(Color.themeBackground.ignoresSafeArea())
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
        // 🆕 Payment Sheet s'affiche comme un sheet séparé
        .paymentSheet(
            isPresented: $viewModel.showPaymentSheet,
            paymentSheet: viewModel.paymentSheet,
            onCompletion: viewModel.handlePaymentResult
        )
        .alert("Error", isPresented: .constant(viewModel.errorMessage != nil)) {
            Button("OK") { viewModel.resetFeedback() }
        } message: {
            Text(viewModel.errorMessage ?? "")
        }
        .alert("Success", isPresented: .constant(viewModel.successMessage != nil)) {
            Button("OK") {
                viewModel.resetFeedback()
                dismiss()
            }
        } message: {
            Text(viewModel.successMessage ?? "")
        }
    }
    
    // MARK: - Amount Button
    private func amountButton(amount: Double) -> some View {
        Button {
            selectedAmount = amount
            isCustomSelected = false
            customAmount = ""
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
    
    // MARK: - Handle Top-Up Action
    private func handleTopUpAction() {
        let finalAmount = isCustomSelected && !customAmount.isEmpty ?
            (Double(customAmount.replacingOccurrences(of: ",", with: ".")) ?? 0) :
            (selectedAmount ?? 0)
        
        guard finalAmount > 0 else { return }
        
        Task {
            await viewModel.initiateTopUp(amount: finalAmount)
        }
    }
}

// MARK: - 🆕 Payment Sheet ViewModifier (solution propre)
struct PaymentSheetModifier: ViewModifier {
    @Binding var isPresented: Bool
    let paymentSheet: PaymentSheet?
    let onCompletion: (PaymentSheetResult) -> Void
    
    func body(content: Content) -> some View {
        content
            .background(
                PaymentSheetPresenter(
                    isPresented: $isPresented,
                    paymentSheet: paymentSheet,
                    onCompletion: onCompletion
                )
            )
    }
}

// MARK: - Payment Sheet Presenter (UIKit bridge)
struct PaymentSheetPresenter: UIViewControllerRepresentable {
    @Binding var isPresented: Bool
    let paymentSheet: PaymentSheet?
    let onCompletion: (PaymentSheetResult) -> Void
    
    func makeUIViewController(context: Context) -> UIViewController {
        UIViewController()
    }
    
    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {
        if isPresented, let paymentSheet = paymentSheet {
            // Attendre que la présentation soit prête
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                if !context.coordinator.hasPresented {
                    paymentSheet.present(from: uiViewController) { result in
                        context.coordinator.hasPresented = false
                        onCompletion(result)
                        isPresented = false
                    }
                    context.coordinator.hasPresented = true
                }
            }
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator()
    }
    
    class Coordinator {
        var hasPresented = false
    }
}

// MARK: - View Extension
extension View {
    func paymentSheet(
        isPresented: Binding<Bool>,
        paymentSheet: PaymentSheet?,
        onCompletion: @escaping (PaymentSheetResult) -> Void
    ) -> some View {
        modifier(PaymentSheetModifier(
            isPresented: isPresented,
            paymentSheet: paymentSheet,
            onCompletion: onCompletion
        ))
    }
}

struct BalanceTopUpSheet_Previews: PreviewProvider {
    static var previews: some View {
        BalanceTopUpSheet(viewModel: SettingsViewModel())
    }
}
