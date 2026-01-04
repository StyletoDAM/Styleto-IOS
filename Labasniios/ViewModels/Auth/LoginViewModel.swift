//
//  LoginViewModel.swift
//  Labasniios
//
//  ViewModel pour l'écran de connexion
//
//  Ce fichier gère la logique métier de l'écran de connexion :
//  - Validation des champs (email, mot de passe)
//  - Appel au service d'authentification
//  - Gestion des états (chargement, erreurs, succès)
//  - Sauvegarde des tokens d'authentification
//
//  Architecture : MVVM avec ObservableObject (Combine)
//  Dépendances : Foundation, Combine, AuthService
//

import Combine
import Foundation

/**
 * ViewModel pour l'écran de connexion
 * 
 * Cette classe gère toute la logique métier de l'écran de connexion.
 * Elle est marquée @MainActor pour garantir que toutes les opérations
 * se déroulent sur le thread principal, nécessaire pour les mises à jour
 * de l'UI via les @Published properties.
 * 
 * Fonctionnalités :
 * - Validation des champs de formulaire
 * - Authentification via AuthService
 * - Gestion des états (chargement, erreurs, succès)
 * - Sauvegarde automatique des tokens (access + refresh)
 * - Extraction automatique de l'ID utilisateur depuis le JWT
 * 
 * @see ObservableObject pour la réactivité avec SwiftUI
 * @see @MainActor pour l'exécution sur le thread principal
 * @see AuthService pour l'authentification backend
 */
@MainActor
final class LoginViewModel: ObservableObject {
    @Published var email: String = ""
    @Published var password: String = ""

    @Published private(set) var isLoading: Bool = false
    @Published private(set) var errorMessage: String?
    @Published private(set) var signedInUser: User?
    @Published private(set) var accessToken: String?

    private let authService: AuthService  

    init(authService: AuthService = AuthService.shared) { // utilise le singleton par défaut
        self.authService = authService
    }

    func signin() async {
        resetFeedback()

        guard validateFields() else { return }

        isLoading = true
        defer { isLoading = false }

        do {
            let response = try await authService.signin(
                email: email.lowercased().trimmingCharacters(in: .whitespacesAndNewlines),
                password: password
            )
            debugPrint("[LoginViewModel] Signed in user: \(response.user.email)")
            signedInUser = response.user
            accessToken = response.accessToken
            
            // ✨ CRITIQUE : Sauvegarder le token (qui va automatiquement extraire et sauvegarder le userId du JWT)
            TokenManager.shared.saveToken(response.accessToken)
            TokenManager.shared.saveRefreshToken(response.refreshToken)
            
            // ✨ Debug : Afficher les infos du token
            print("═══════════════════════════════════════════════════════════")
            print("✅ [LoginViewModel] Login réussi")
            TokenManager.shared.printDebugInfo()
            print("═══════════════════════════════════════════════════════════")
        } catch let networkError as NetworkError {
            errorMessage = networkError.errorDescription ?? "An error occurred."
            debugPrint("[LoginViewModel] Network error: \(errorMessage ?? "")")
        } catch {
            errorMessage = error.localizedDescription
            debugPrint("[LoginViewModel] Unexpected error: \(error.localizedDescription)")
        }
    }

    func resetFeedback() {
        errorMessage = nil
        signedInUser = nil
        accessToken = nil
    }

    private func validateFields() -> Bool {
        guard isValidEmail(email) else {
            errorMessage = "Invalid email address."
            return false
        }

        guard password.count >= 6 else {
            errorMessage = "Password is too short."
            return false
        }

        return true
    }

    private func isValidEmail(_ value: String) -> Bool {
        let pattern = #"^[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$"#
        return value.range(of: pattern, options: .regularExpression) != nil
    }
}
