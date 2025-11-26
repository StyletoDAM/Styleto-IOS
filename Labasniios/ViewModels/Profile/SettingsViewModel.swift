import Foundation
import UIKit
import _PhotosUI_SwiftUI

@MainActor
final class SettingsViewModel: ObservableObject {
    @Published private(set) var isLoading: Bool = false
    @Published private(set) var errorMessage: String?
    @Published private(set) var successMessage: String?
    @Published var updatedUser: User?
    @Published var profileImage: UIImage?
    @Published var selectedPhoto: PhotosPickerItem?
    
    private let profileService: ProfileService
    
    init(profileService: ProfileService = ProfileService()) {
        self.profileService = profileService
    }
    
    // MARK: - Update Text Profile (fullName, phone, gender, password)
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
    
    // MARK: - Update Profile Photo Only
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
    
    // MARK: - Reset Feedback
    func resetFeedback() {
        errorMessage = nil
        successMessage = nil
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
    
    // MARK: - Top-up Balance
    func topUpBalance(amount: Double) async {
        resetFeedback()
        isLoading = true
        defer { isLoading = false }
        
        do {
            let updatedUser = try await profileService.topUpBalance(amount: amount)
            
            // Global update
            AppPreferences.shared.currentUser = updatedUser
            AppPreferences.shared.saveLoginState(user: updatedUser)
            self.updatedUser = updatedUser
            
            // Notify other views
            NotificationCenter.default.post(name: .balanceDidUpdate, object: nil)
            
            let newBalance = (updatedUser.balance ?? 0.0) / 100.0
            
            successMessage = "Balance topped up successfully! +\(String(format: "%.2f", amount)) TND"
            debugPrint("New balance: \(String(format: "%.2f", newBalance)) TND (raw: \(updatedUser.balance ?? 0))")
            
        } catch {
            errorMessage = "Top-up failed. Please try again."
            debugPrint("[SettingsViewModel] Top-up error: \(error)")
        }
    }
}
