//
//  SettingsViewModel.swift
//  Labasniios
//
//  Created by MacBook on 2/11/2025.
//

import Foundation
import UIKit

@MainActor
final class SettingsViewModel: ObservableObject {
    @Published private(set) var isLoading: Bool = false
    @Published private(set) var errorMessage: String?
    @Published private(set) var successMessage: String?
    @Published var updatedUser: User?
    @Published var profileImage: UIImage?

    private let profileService: ProfileService

    init(profileService: ProfileService = ProfileService()) {
        self.profileService = profileService
    }

    func updateProfile(
        fullName: String?,
        phoneNumber: String?,
        gender: String?,
        password: String?,
        profileImage: UIImage?
    ) async {
        resetFeedback()
        isLoading = true
        defer { isLoading = false }

        do {
            let updatedUser = try await profileService.updateProfile(
                fullName: fullName,
                phoneNumber: phoneNumber,
                gender: gender,
                password: password,
                profileImage: profileImage
            )
            self.updatedUser = updatedUser
            self.profileImage = profileImage
            successMessage = "Profil mis à jour avec succès."
            debugPrint("[SettingsViewModel] Profile updated successfully")
        } catch let networkError as NetworkError {
            errorMessage = networkError.errorDescription ?? "Une erreur est survenue."
            debugPrint("[SettingsViewModel] Network error: \(errorMessage ?? "")")
        } catch {
            errorMessage = error.localizedDescription
            debugPrint("[SettingsViewModel] Unexpected error: \(error.localizedDescription)")
        }
    }

    func resetFeedback() {
        errorMessage = nil
        successMessage = nil
    }
}
