//
//  GoogleSignInHelper.swift
//  Labasniios
//
//  Helper pour l'authentification Google Sign-In
//
//  Ce fichier gère l'intégration avec Google Sign-In pour permettre
//  aux utilisateurs de se connecter avec leur compte Google. Il utilise
//  le SDK Google Sign-In pour gérer le flux d'authentification OAuth.
//
//  Architecture : Helper avec ObservableObject (Combine)
//  Dépendances : GoogleSignIn, GoogleSignInSwift, Foundation, UIKit
//

import GoogleSignIn
import GoogleSignInSwift
import Foundation
import UIKit

/**
 * Helper pour l'authentification Google Sign-In
 * 
 * Cette classe gère le flux d'authentification Google Sign-In en utilisant
 * GIDSignIn. Elle est marquée @MainActor pour garantir que toutes les
 * opérations se déroulent sur le thread principal.
 * 
 * Fonctionnalités :
 * - Lancement du flux Google Sign-In
 * - Gestion des profils Google
 * - Délégation vers AuthService pour l'authentification backend
 * - Gestion des erreurs et des états de chargement
 * 
 * @see ObservableObject pour la réactivité avec SwiftUI
 * @see @MainActor pour l'exécution sur le thread principal
 * @see GIDSignIn pour le SDK Google Sign-In
 */
@MainActor
final class GoogleSignInHelper: ObservableObject {
    private let authService: AuthService
    @Published var errorMessage: String?
    @Published var isLoading: Bool = false

    var onSuccess: ((SigninResponse) -> Void)?
    var onError: ((Error) -> Void)?

    init(authService: AuthService = .shared) {
        self.authService = authService
    }

    func signInWithGoogle(presenting: UIViewController) {
        isLoading = true

        GIDSignIn.sharedInstance.signIn(withPresenting: presenting) { [weak self] result, error in
            Task { @MainActor in
                guard let self = self else { return }
                self.isLoading = false

                if let error = error {
                    self.errorMessage = error.localizedDescription
                    self.onError?(error)
                    return
                }

                guard let user = result?.user,
                      let profile = user.profile else {
                    let err = NSError(domain: "GoogleSignIn", code: -1, userInfo: [NSLocalizedDescriptionKey: "Données utilisateur manquantes"])
                    self.onError?(err)
                    return
                }

                let googleId = user.userID ?? ""
                let fullName = profile.name
                let email = profile.email
                let profilePicture = profile.hasImage ? profile.imageURL(withDimension: 320)?.absoluteString : nil

                do {
                    let response = try await self.authService.authenticateWithGoogle(
                        googleId: googleId,
                        fullName: fullName,
                        email: email,
                        profilePicture: profilePicture,
                        gender: nil
                    )

                    self.onSuccess?(response)
                    self.errorMessage = nil
                } catch let networkError as NetworkError {
                    self.errorMessage = networkError.errorDescription
                    self.onError?(networkError)
                } catch {
                    self.errorMessage = "Erreur inattendue."
                    self.onError?(error)
                }
            }
        }
    }
}
