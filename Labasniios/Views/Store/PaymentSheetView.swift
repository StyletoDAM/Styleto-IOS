//
//  PaymentSheetView.swift
//  Labasniios
//
//  Created by Aziz on 23/11/2025.
//

//
//  PaymentSheetView.swift
//  Labasniios
//

import SwiftUI
import StripePaymentSheet

struct PaymentSheetView: UIViewControllerRepresentable {
    let paymentSheet: PaymentSheet
    let onCompletion: (PaymentSheetResult) -> Void
    
    // Utiliser une classe pour garder l'état
    class Coordinator {
        var hasPresented = false
        let paymentSheet: PaymentSheet
        let onCompletion: (PaymentSheetResult) -> Void
        
        init(paymentSheet: PaymentSheet, onCompletion: @escaping (PaymentSheetResult) -> Void) {
            self.paymentSheet = paymentSheet
            self.onCompletion = onCompletion
        }
        
        func presentSheet(from viewController: UIViewController) {
            paymentSheet.present(from: viewController) { [weak self] result in
                self?.onCompletion(result)
            }
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(paymentSheet: paymentSheet, onCompletion: onCompletion)
    }
    
    func makeUIViewController(context: Context) -> UIViewController {
        let viewController = UIViewController()
        return viewController
    }
    
    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {
        // Ne présenter qu'une seule fois
        guard !context.coordinator.hasPresented else { return }
        context.coordinator.hasPresented = true
        
        // Attendre que la vue soit complètement chargée
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            guard uiViewController.isViewLoaded && uiViewController.view.window != nil else {
                // Réessayer après un court délai
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    context.coordinator.presentSheet(from: uiViewController)
                }
                return
            }
            context.coordinator.presentSheet(from: uiViewController)
        }
    }
}
