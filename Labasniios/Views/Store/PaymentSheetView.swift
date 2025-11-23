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
    
    func makeUIViewController(context: Context) -> UIViewController {
        let viewController = UIViewController()
        return viewController
    }
    
    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {
        DispatchQueue.main.async {
            paymentSheet.present(from: uiViewController) { result in
                onCompletion(result)
            }
        }
    }
}
