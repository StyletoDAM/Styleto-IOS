//
//  AppleSignInHelper.swift
//  Labasniios
//
//  Helper pour l'authentification Apple Sign-In
//
//  Ce fichier gère l'intégration avec Apple Sign-In pour permettre
//  aux utilisateurs de se connecter avec leur compte Apple. Il utilise
//  AuthenticationServices pour gérer le flux d'authentification OAuth.
//
//  Architecture : Helper avec ObservableObject (Combine)
//  Dépendances : Foundation, AuthenticationServices, SwiftUI, UIKit
//

import Foundation
import AuthenticationServices
import SwiftUI
import UIKit

/**
 * Helper pour l'authentification Apple Sign-In
 * 
 * Cette classe gère le flux d'authentification Apple Sign-In en utilisant
 * ASAuthorizationController. Elle est marquée @MainActor pour garantir que
 * toutes les opérations se déroulent sur le thread principal.
 * 
 * Fonctionnalités :
 * - Lancement du flux Apple Sign-In
 * - Gestion des credentials Apple
 * - Délégation vers AuthService pour l'authentification backend
 * - Gestion des erreurs et des états de chargement
 * 
 * @see ObservableObject pour la réactivité avec SwiftUI
 * @see @MainActor pour l'exécution sur le thread principal
 * @see ASAuthorizationControllerDelegate pour les callbacks Apple
 */
@MainActor
final class AppleSignInHelper: NSObject, ObservableObject {
    private let authService: AuthService
    @Published var errorMessage: String?
    @Published var isLoading: Bool = false
    
    var onSuccess: ((SigninResponse) -> Void)?
    var onError: ((Error) -> Void)?
    
    init(authService: AuthService = .shared) {
        self.authService = authService
        super.init()
    }

    func signInWithApple() {
        let request = ASAuthorizationAppleIDProvider().createRequest()
        request.requestedScopes = [.fullName, .email]
        
        let authorizationController = ASAuthorizationController(authorizationRequests: [request])
        authorizationController.delegate = self
        authorizationController.presentationContextProvider = self
        authorizationController.performRequests()
    }
    
    private func handleAppleIDCredential(_ credential: ASAuthorizationAppleIDCredential) {
        Task {
            isLoading = true
            defer { isLoading = false }
            
            do {
                let appleId = credential.user
                let fullName = [credential.fullName?.givenName, credential.fullName?.familyName]
                    .compactMap { $0 }
                    .joined(separator: " ")
                
                let displayName = fullName.isEmpty ? (credential.email ?? "User") : fullName
                let email = credential.email ?? ""
                
                let response = try await authService.authenticateWithApple(
                    appleId: appleId,
                    fullName: displayName,
                    email: email,
                    profilePicture: nil,
                    gender: nil
                )
                
                await MainActor.run {
                    onSuccess?(response)
                    errorMessage = nil
                }
            } catch {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                    onError?(error)
                }
            }
        }
    }
    
}

// MARK: - ASAuthorizationControllerDelegate
extension AppleSignInHelper: ASAuthorizationControllerDelegate {
    func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
        if let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential {
            handleAppleIDCredential(appleIDCredential)
        }
    }
    
    func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
        errorMessage = error.localizedDescription
        onError?(error)
    }
}

// MARK: - ASAuthorizationControllerPresentationContextProviding
extension AppleSignInHelper: ASAuthorizationControllerPresentationContextProviding {
    func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = windowScene.windows.first else {
            fatalError("No window available")
        }
        return window
    }
}
