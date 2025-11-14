import GoogleSignIn
import GoogleSignInSwift
import Foundation
import UIKit

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
