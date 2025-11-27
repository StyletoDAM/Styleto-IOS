import Foundation
import UIKit
import _PhotosUI_SwiftUI
import StripePaymentSheet

@MainActor
final class SettingsViewModel: ObservableObject {
    @Published private(set) var isLoading: Bool = false
    @Published private(set) var errorMessage: String?
    @Published private(set) var successMessage: String?
    @Published var updatedUser: User?
    @Published var profileImage: UIImage?
    @Published var selectedPhoto: PhotosPickerItem?
    
    // MARK: - Stripe Payment Properties
    @Published var paymentSheet: PaymentSheet?
    @Published var isProcessingPayment = false
    @Published var pendingTopUpAmount: Double?
    @Published var showPaymentSheet = false
    
    private let profileService: ProfileService
    private let paymentService = PaymentService.shared
    
    init(profileService: ProfileService = ProfileService()) {
        self.profileService = profileService
    }
    
    // MARK: - Load Profile
    func loadProfile() async {
        guard let token = TokenManager.shared.getToken() else {
            debugPrint("[SettingsViewModel] No token available for profile loading")
            return
        }
        
        resetFeedback()
        isLoading = true
        defer { isLoading = false }
        
        do {
            let freshUser = try await profileService.getProfile()
            updatedUser = freshUser
            debugPrint("[SettingsViewModel] Profile loaded - Balance: \(freshUser.balance ?? 0.0) TND")
        } catch {
            errorMessage = "Failed to load profile. Please try again."
            debugPrint("[SettingsViewModel] Load profile error: \(error)")
        }
    }
    
    // MARK: - Update Text Profile
    func updateProfileText(
        fullName: String?,
        phoneNumber: String?,
        gender: String?,
        password: String?,
        preferences: [String]? = nil
    ) async {
        resetFeedback()
        isLoading = true
        defer { isLoading = false }
        
        do {
            let updatedUser = try await profileService.updateProfileText(
                fullName: fullName,
                phoneNumber: phoneNumber,
                gender: gender,
                preferences: preferences,
                password: password
            )
            self.updatedUser = updatedUser
            successMessage = "Profile information updated."
            debugPrint("[SettingsViewModel] Text profile updated")
        } catch let networkError as NetworkError {
            errorMessage = networkError.errorDescription ?? "An error occurred."
            debugPrint("[SettingsViewModel] Text update error: \(errorMessage ?? "")")
        } catch {
            errorMessage = error.localizedDescription
            debugPrint("[SettingsViewModel] Unexpected error: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Update Profile Photo
    func updateProfilePhoto(image: UIImage?) async {
        guard let image = image else { return }
        
        resetFeedback()
        isLoading = true
        defer { isLoading = false }
        
        do {
            let updatedUser = try await profileService.updateProfilePhoto(image: image)
            self.updatedUser = updatedUser
            self.profileImage = image
            
            if let newURL = updatedUser.profilePicture {
                UserDefaults.standard.set(newURL, forKey: "cachedProfilePicture")
            }
            
            successMessage = "Profile photo updated successfully."
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    
    // MARK: - Delete Profile
    func deleteProfile() async {
        resetFeedback()
        isLoading = true
        defer { isLoading = false }
        
        do {
            let success = try await profileService.deleteProfile()
            if success {
                successMessage = "Account deleted successfully."
                updatedUser = nil
                profileImage = nil
                
                TokenManager.shared.clearToken()
                UserDefaults.standard.removeObject(forKey: "cachedProfilePicture")
                
                debugPrint("[SettingsViewModel] Profile deleted successfully")
            } else {
                errorMessage = "Unable to delete account."
            }
        } catch let networkError as NetworkError {
            errorMessage = networkError.errorDescription ?? "An error occurred."
            debugPrint("[SettingsViewModel] Delete profile error: \(errorMessage ?? "")")
        } catch {
            errorMessage = error.localizedDescription
            debugPrint("[SettingsViewModel] Unexpected error: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Delete Profile Photo
    func deleteProfilePhoto() async {
        resetFeedback()
        isLoading = true
        defer { isLoading = false }
        
        do {
            let updatedUser = try await profileService.deleteProfilePhoto()
            
            self.updatedUser = updatedUser
            self.profileImage = nil
            
            UserDefaults.standard.removeObject(forKey: "cachedProfilePicture")
            
            successMessage = "Profile photo removed successfully."
            debugPrint("[SettingsViewModel] Profile photo deleted successfully")
        } catch let networkError as NetworkError {
            errorMessage = networkError.errorDescription ?? "An error occurred."
            debugPrint("[SettingsViewModel] Delete photo error: \(networkError)")
        } catch {
            errorMessage = error.localizedDescription
            debugPrint("[SettingsViewModel] Unexpected error: \(error)")
        }
    }
    
    // MARK: - 🆕 Top-up Balance avec Stripe Payment
    func initiateTopUp(amount: Double) async {
        guard let user = updatedUser ?? AppPreferences.shared.currentUser else {
            errorMessage = "You must be logged in"
            return
        }
        
        resetFeedback()
        isProcessingPayment = true
        pendingTopUpAmount = amount
        
        do {
            print("💰 [SettingsViewModel] Initiating top-up for \(amount) TND")
            
            // 1. Créer le Payment Intent via Stripe
            let clientSecret = try await paymentService.createPaymentIntent(
                amount: amount,
                currency: "usd" // Change en "tnd" si supporté par ton backend
            )
            
            // 2. Configurer le Payment Sheet
            var configuration = StripeConfig.shared.createPaymentSheetConfiguration(
                customerEmail: user.email
            )
            configuration.primaryButtonLabel = "Pay \(String(format: "%.2f", amount)) TND"
            
            self.paymentSheet = PaymentSheet(
                paymentIntentClientSecret: clientSecret,
                configuration: configuration
            )
            
            // 3. Afficher le Payment Sheet
            showPaymentSheet = true
            isProcessingPayment = false
            
            print("✅ [SettingsViewModel] Payment Sheet ready!")
            
        } catch {
            print("❌ [SettingsViewModel] Top-up initiation error: \(error)")
            errorMessage = "Failed to initialize payment: \(error.localizedDescription)"
            isProcessingPayment = false
            pendingTopUpAmount = nil
        }
    }
    
    // MARK: - 🆕 Handle Payment Result
    func handlePaymentResult(_ result: PaymentSheetResult) {
        isProcessingPayment = true
        
        switch result {
        case .completed:
            print("✅ [SettingsViewModel] Payment completed!")
            Task {
                await confirmTopUpWithBackend()
            }
            
        case .failed(let error):
            print("❌ [SettingsViewModel] Payment failed: \(error.localizedDescription)")
            errorMessage = "Payment failed: \(error.localizedDescription)"
            isProcessingPayment = false
            pendingTopUpAmount = nil
            showPaymentSheet = false
            
        case .canceled:
            print("ℹ️ [SettingsViewModel] Payment canceled by user")
            isProcessingPayment = false
            pendingTopUpAmount = nil
            showPaymentSheet = false
        }
    }
    
    // MARK: - 🆕 Confirm Top-up with Backend
    private func confirmTopUpWithBackend() async {
        guard let amount = pendingTopUpAmount else {
            errorMessage = "Missing top-up amount"
            isProcessingPayment = false
            return
        }
        
        do {
            // Appeler l'API backend pour mettre à jour le balance
            let updatedUser = try await profileService.topUpBalance(amount: amount)
            
            // Mettre à jour l'état local
            self.updatedUser = updatedUser
            
            // Afficher le succès
            successMessage = "Balance topped up successfully! +\(String(format: "%.2f", amount)) TND"
            
            // Cleanup
            isProcessingPayment = false
            pendingTopUpAmount = nil
            showPaymentSheet = false
            paymentSheet = nil
            
            print("✅ [SettingsViewModel] Top-up confirmed! New balance: \(updatedUser.balance ?? 0)")
            
        } catch {
            print("❌ [SettingsViewModel] Backend confirmation error: \(error)")
            errorMessage = "Payment succeeded but confirmation failed. Please contact support."
            isProcessingPayment = false
        }
    }
    
    // MARK: - Reset Feedback
    func resetFeedback() {
        errorMessage = nil
        successMessage = nil
    }
}
