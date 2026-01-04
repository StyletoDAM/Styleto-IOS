import SwiftUI
import PhotosUI

// MARK: - Models
enum Gender: String, CaseIterable {
    case male = "Male"
    case female = "Female"
}

enum StylePreference: String, CaseIterable {
    case casual = "Casual"
    case chic = "Chic"
    case sport = "Sport"
    case boheme = "Bohème"
    case minimal = "Minimal"
}

struct StyleChip: View {
    let title: String
    let isSelected: Bool
   
    var body: some View {
        Text(title)
            .font(.system(size: 15, weight: .semibold))
            .foregroundColor(isSelected ? .white : Color.themeTeal)
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 50)
                    .fill(isSelected ? Color.themePrimary : Color.themeSoftPink.opacity(0.6))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 50)
                    .stroke(Color.themeTeal.opacity(0.3), lineWidth: isSelected ? 0 : 1)
            )
    }
}

struct SettingsSection: Identifiable {
    let id = UUID()
    let icon: String
    let title: String
    let options: [SettingsOption]
    let isEditProfile: Bool
}

struct SettingsOption: Identifiable {
    let id = UUID()
    let icon: String
    let title: String
    let hasToggle: Bool
    let toggleValue: Bool
    let hasChevron: Bool
}

// MARK: - Settings View
struct SettingsView: View {
    let user: User?
    let onLogout: (() -> Void)?
   
    @StateObject private var themeManager = ThemeManager.shared
    @StateObject private var viewModel = SettingsViewModel()
    @State private var expandedSections: Set<UUID> = []
    @State private var showThemePicker = false
    @State private var showSaveConfirmation = false
    @State private var showSuccessAlert = false
    @State private var showErrorAlert = false
    @State private var showLogoutConfirmation = false
    @State private var showPhotoConfirmation = false
    @State private var pendingPhoto: UIImage?
    @State private var showDeleteConfirmation = false
   
    // Edit Profile State
    @State private var fullName: String = ""
    @State private var email: String = ""
    @State private var phone: String = ""
    @State private var gender: Gender = .female
    @State private var selectedStyles: Set<StylePreference> = []
    @State private var originalStyles: Set<StylePreference> = []
   
    // Security State
    @State private var password: String = ""
    @State private var showPasswordUpdate: Bool = false
   
    @State private var selectedPhoto: PhotosPickerItem?
    @State private var profileImage: UIImage?
   
    // Original values for cancel
    @State private var originalFullName: String = ""
    @State private var originalPhone: String = ""
    @State private var originalGender: Gender = .female
   
    @State private var showImageSourcePicker = false
    @State private var showCamera = false
    @State private var showPhotoPicker = false
    @State private var showDeletePhotoConfirmation = false
   
    @State private var showAboutSheet = false
    @State private var showContactSheet = false
    @State private var showColorThemePicker = false
   
    @State private var showBalanceTopUp = false
    @State private var showOrdersHistory = false
   
    init(user: User? = nil, onLogout: (() -> Void)? = nil) {
        self.user = user
        self.onLogout = onLogout
       
        let resolvedFullName = user?.fullName ?? "Amira Ben Salem"
        let resolvedEmail = user?.email ?? "amira@email.com"
        let resolvedPhone = user?.phoneNumber ?? "+216 12 345 678"
        let resolvedGender: Gender = {
            switch user?.gender {
            case .male: return .male
            case .female: return .female
            default: return .female
            }
        }()
       
        let userStyles = user?.preferences ?? []
        let mapped = userStyles.compactMap { s -> StylePreference? in
            switch s.lowercased() {
            case "casual": return .casual
            case "chic": return .chic
            case "sport": return .sport
            case "boheme", "bohème": return .boheme
            case "minimal": return .minimal
            default: return nil
            }
        }
        let styleSet = Set(mapped)
       
        _fullName = State(initialValue: resolvedFullName)
        _email = State(initialValue: resolvedEmail)
        _phone = State(initialValue: resolvedPhone)
        _gender = State(initialValue: resolvedGender)
        _selectedStyles = State(initialValue: styleSet)
        _originalStyles = State(initialValue: styleSet)
       
        _originalFullName = State(initialValue: resolvedFullName)
        _originalPhone = State(initialValue: resolvedPhone)
        _originalGender = State(initialValue: resolvedGender)
    }
    
    // MARK: - Contact Actions
    private func openPhone() {
        let phoneNumber = "+21652904114"
        if let url = URL(string: "tel://\(phoneNumber)") {
            if UIApplication.shared.canOpenURL(url) {
                UIApplication.shared.open(url, options: [:], completionHandler: nil)
            }
        }
    }
    
    private func openEmail() {
        let email = "styleto.app.team@gmail.com"
        if let url = URL(string: "mailto:\(email)?subject=Contact%20from%20Styleto%20App") {
            if UIApplication.shared.canOpenURL(url) {
                UIApplication.shared.open(url, options: [:], completionHandler: nil)
            }
        }
    }
    
    private let sections: [SettingsSection] = [
        SettingsSection(
            icon: "person.circle",
            title: "Edit Profile",
            options: [],
            isEditProfile: true
        ),
        SettingsSection(
            icon: "gearshape",
            title: "App Settings",
            options: [
                SettingsOption(icon: "bell", title: "Notifications", hasToggle: true, toggleValue: true, hasChevron: false),
                SettingsOption(icon: "globe", title: "Language", hasToggle: false, toggleValue: false, hasChevron: true),
            ],
            isEditProfile: false
        ),
        SettingsSection(
            icon: "paintbrush",
            title: "Preferences",
            options: [
                SettingsOption(icon: "moon", title: "Theme", hasToggle: false, toggleValue: false, hasChevron: true),
                SettingsOption(icon: "paintpalette", title: "Color Theme", hasToggle: false, toggleValue: false, hasChevron: true),
            ],
            isEditProfile: false
        ),
        SettingsSection(
            icon: "lock.shield",
            title: "Security",
            options: [
                SettingsOption(icon: "key", title: "Change Password", hasToggle: false, toggleValue: false, hasChevron: true),
                SettingsOption(icon: "trash", title: "Delete Account", hasToggle: false, toggleValue: false, hasChevron: true)
            ],
            isEditProfile: false
        ),
        SettingsSection(
            icon: "questionmark.circle",
            title: "Help & Support",
            options: [
                SettingsOption(icon: "envelope.badge", title: "Contact Us", hasToggle: false, toggleValue: false, hasChevron: true),
                SettingsOption(icon: "info.circle", title: "About", hasToggle: false, toggleValue: false, hasChevron: true),
                SettingsOption(icon: "app.badge", title: "Version 1.0.0", hasToggle: false, toggleValue: false, hasChevron: false)
            ],
            isEditProfile: false
        )
    ]
   
    var body: some View {
        NavigationStack {
            ScrollView {
                mainContent
            }
            .background(Color.themeBackground.ignoresSafeArea())
            .navigationBarBackButtonHidden(true)
            .alert("Confirm Modification", isPresented: $showSaveConfirmation) {
                Button("Cancel", role: .cancel) {}
                Button("Confirm") { Task { await saveProfile() } }
            } message: {
                Text("Do you really want to save these changes?")
            }
            .alert("Success", isPresented: $showSuccessAlert) {
                Button("OK") {
                    if let updatedUser = viewModel.updatedUser {
                        originalFullName = updatedUser.fullName
                        originalPhone = updatedUser.phoneNumber ?? ""
                        originalGender = updatedUser.gender == .male ? .male : .female
                        fullName = updatedUser.fullName
                        phone = updatedUser.phoneNumber ?? ""
                        gender = updatedUser.gender == .male ? .male : .female
                        
                        let mapped = updatedUser.preferences.compactMap { s -> StylePreference? in
                            switch s.lowercased() {
                            case "casual": return .casual
                            case "chic": return .chic
                            case "sport": return .sport
                            case "boheme", "bohème": return .boheme
                            case "minimal": return .minimal
                            default: return nil
                            }
                        }
                        originalStyles = Set(mapped)
                        selectedStyles = originalStyles
                        
                        AppPreferences.shared.currentUser = updatedUser
                        AppPreferences.shared.saveLoginState(user: updatedUser)
                        ThemeManager.shared.updateThemeBasedOnUser()
                    } else {
                        originalFullName = fullName
                        originalPhone = phone
                        originalGender = gender
                        originalStyles = selectedStyles
                    }
                }
            } message: { Text(viewModel.successMessage ?? "Profile updated successfully.") }
            .alert("Error", isPresented: $showErrorAlert) {
                Button("OK") {}
            } message: {
                Text(viewModel.errorMessage ?? "An error has occurred.")
            }
            .onChange(of: viewModel.successMessage) { oldValue, newValue in
                if newValue != nil {
                    showSuccessAlert = true
                }
            }
            .onChange(of: viewModel.errorMessage) { oldValue, newValue in
                if newValue != nil {
                    showErrorAlert = true
                }
            }
            .alert("Logout", isPresented: $showLogoutConfirmation) {
                Button("Cancel", role: .cancel) {}
                Button("Logout", role: .destructive) { performLogout() }
            } message: {
                Text("Do you really want to log out?")
            }
            .alert("Confirm Photo Change", isPresented: $showPhotoConfirmation) {
                Button("Cancel", role: .cancel) {
                    selectedPhoto = nil
                    pendingPhoto = nil
                }
                Button("Confirm") {
                    withAnimation(.easeInOut) {
                        profileImage = pendingPhoto
                        viewModel.profileImage = pendingPhoto
                    }
                    pendingPhoto = nil
                    selectedPhoto = nil
                    Task {
                        await viewModel.updateProfilePhoto(image: profileImage)
                    }
                }
            } message: {
                Text("Do you really want to change your profile picture?")
            }
            .alert("Delete account", isPresented: $showDeleteConfirmation) {
                Button("Cancel", role: .cancel) {}
                Button("Delete", role: .destructive) {
                    Task {
                        await viewModel.deleteProfile()
                        if viewModel.errorMessage == nil {
                            performLogout()
                        }
                    }
                }
            } message: {
                Text("Do you really want to delete your account? This action is irreversible.")
            }
            .alert("Delete profile photo", isPresented: $showDeletePhotoConfirmation) {
                Button("Cancel", role: .cancel) {}
                Button("Delete", role: .destructive) {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        profileImage = nil
                        viewModel.profileImage = nil
                    }
                    Task {
                        await viewModel.deleteProfilePhoto()
                    }
                }
            } message: {
                Text("Are you sure you want to delete your profile picture?")
            }
        }
        .sheet(isPresented: $showThemePicker) {
            ThemePickerSheet(themeManager: themeManager)
        }
        .sheet(isPresented: $showColorThemePicker) {
            ColorThemePickerSheet(themeManager: themeManager)
        }
        .sheet(isPresented: $showCamera) {
            ImagePicker(sourceType: .camera) { image in
                if let image = image {
                    pendingPhoto = image
                    showPhotoConfirmation = true
                }
            }
        }
        .sheet(isPresented: $showPhotoPicker) {
            ImagePicker(sourceType: .photoLibrary) { image in
                if let image = image {
                    pendingPhoto = image
                    showPhotoConfirmation = true
                }
            }
        }
        .sheet(isPresented: $showAboutSheet) {
            AboutSheet()
        }
        .sheet(isPresented: $showContactSheet) {
            ContactSheet(
                onPhone: openPhone,
                onEmail: openEmail
            )
        }
        .task(id: "initial_load") {
            await viewModel.loadProfile()
        }
    }
   
    @ViewBuilder
    private var mainContent: some View {
        VStack(spacing: 16) {
            settingsTitle
            profileSection
            balanceCard
            sectionsList
            orderHistoryCard
            PackProfileCard()
            logoutSection
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 16)
    }
   
    private var settingsTitle: some View {
        Text("Settings")
            .font(.system(size: 36, weight: .bold))
            .foregroundColor(.themePrimary)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.top, 12)
    }
   
    // MARK: - Order History Card
    private var orderHistoryCard: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(Color.themePrimary.opacity(0.15))
                    .frame(width: 56, height: 56)
               
                Image(systemName: "bag.fill")
                    .font(.system(size: 24))
                    .foregroundColor(.themePrimary)
            }
           
            VStack(alignment: .leading, spacing: 4) {
                Text("Order History")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(.themeText)
               
                Text("View your purchase history")
                    .font(.system(size: 13))
                    .foregroundColor(.themeSecondaryText)
            }
           
            Spacer()
           
            Image(systemName: "chevron.right")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.themePrimary)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .background(Color.themeCard)
        .cornerRadius(20)
        .shadow(color: .black.opacity(0.05), radius: 10, x: 0, y: 5)
        .onTapGesture {
            showOrdersHistory = true
        }
        .sheet(isPresented: $showOrdersHistory) {
            OrdersHistoryView()
        }
    }
   
    // MARK: - Balance Card
    private var balanceCard: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Balance")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white.opacity(0.9))
               
                Text("\(String(format: "%.2f", (viewModel.updatedUser?.balance ?? user?.balance ?? 0.0))) TND")
                    .font(.system(size: 26, weight: .bold))
                    .foregroundColor(.white)
               
                Text("Available for withdrawal")
                    .font(.system(size: 11, weight: .regular))
                    .foregroundColor(.white.opacity(0.8))
            }
           
            Spacer()
           
            Circle()
                .fill(Color.white.opacity(0.2))
                .frame(width: 56, height: 56)
                .overlay(
                    Image(systemName: "creditcard.fill")
                        .font(.system(size: 26))
                        .foregroundColor(.white)
                )
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .background(
            LinearGradient(
                colors: [
                    Color.themePrimary.opacity(0.8),
                    Color.themeTeal.opacity(0.9),
                    Color.themeSecondary.opacity(0.7)
                ],
                startPoint: .leading,
                endPoint: .trailing
            )
        )
        .cornerRadius(20)
        .padding(.vertical, 8)
        .onTapGesture {
            showBalanceTopUp = true
        }
        .sheet(isPresented: $showBalanceTopUp) {
            BalanceTopUpSheet(viewModel: viewModel)
        }
    }
   
    @ViewBuilder
    private var profileSection: some View {
        VStack(spacing: 12) {
            Button {
                showImageSourcePicker = true
            } label: {
                ZStack {
                    Circle()
                        .fill(Color.themePrimary.opacity(0.15))
                        .frame(width: 80, height: 80)
                   
                    if let img = profileImage ?? viewModel.profileImage {
                        Image(uiImage: img)
                            .resizable()
                            .scaledToFill()
                            .frame(width: 80, height: 80)
                            .clipShape(Circle())
                    } else if let updatedUser = viewModel.updatedUser,
                              let pic = updatedUser.profilePicture,
                              !pic.isEmpty,
                              let url = URL(string: pic) {
                        AsyncImage(url: url) { image in
                            image
                                .resizable()
                                .scaledToFill()
                        } placeholder: {
                            Text(initials(from: fullName))
                                .font(.system(size: 28, weight: .bold))
                                .foregroundColor(.themePrimary)
                        }
                        .frame(width: 80, height: 80)
                        .clipShape(Circle())
                    } else if let pic = user?.profilePicture, !pic.isEmpty, let url = URL(string: pic) {
                        AsyncImage(url: url) { image in
                            image
                                .resizable()
                                .scaledToFill()
                        } placeholder: {
                            Text(initials(from: fullName))
                                .font(.system(size: 28, weight: .bold))
                                .foregroundColor(.themePrimary)
                        }
                        .frame(width: 80, height: 80)
                        .clipShape(Circle())
                    } else {
                        Text(initials(from: fullName))
                            .font(.system(size: 28, weight: .bold))
                            .foregroundColor(.themePrimary)
                    }
                   
                    VStack {
                        Spacer()
                        HStack {
                            Spacer()
                            ZStack {
                                Circle()
                                    .fill(Color.themePrimary)
                                    .frame(width: 28, height: 28)
                                Image(systemName: "camera.fill")
                                    .font(.system(size: 12, weight: .semibold))
                                    .foregroundColor(.white)
                            }
                        }
                    }
                    .frame(width: 80, height: 80)
                }
            }
            .buttonStyle(.plain)
            .confirmationDialog("Choose an option", isPresented: $showImageSourcePicker) {
                Button("Take a new photo") {
                    showCamera = true
                }
                Button("Choose from gallery") {
                    showPhotoPicker = true
                }
               
                if hasProfilePhoto {
                    Button("Delete photo", role: .destructive) {
                        showDeletePhotoConfirmation = true
                    }
                }
               
                Button("Cancel", role: .cancel) {}
            }
           
            Text(fullName)
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.themeText)
        }
        .padding(.top, 20)
    }
   
    @ViewBuilder
    private var sectionsList: some View {
        ForEach(sections) { section in
            if section.isEditProfile {
                EditProfileSectionCard(
                    isExpanded: expandedSections.contains(section.id),
                    onToggle: {
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                            if expandedSections.contains(section.id) {
                                expandedSections.remove(section.id)
                            } else {
                                expandedSections.insert(section.id)
                            }
                        }
                    },
                    fullName: $fullName,
                    email: $email,
                    phone: $phone,
                    gender: $gender,
                    selectedStyles: $selectedStyles,
                    viewModel: viewModel,
                    onSave: { showSaveConfirmation = true },
                    onCancel: {
                        fullName = originalFullName
                        phone = originalPhone
                        gender = originalGender
                        selectedStyles = originalStyles
                    },
                    hasChanges: hasChanges,
                    user: user
                )
            } else {
                SettingsSectionCard(
                    section: section,
                    isExpanded: expandedSections.contains(section.id),
                    onToggle: {
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                            if expandedSections.contains(section.id) {
                                expandedSections.remove(section.id)
                            } else {
                                expandedSections.insert(section.id)
                            }
                        }
                    },
                    themeManager: themeManager,
                    showThemePicker: $showThemePicker,
                    showColorThemePicker: $showColorThemePicker,
                    showPasswordUpdate: $showPasswordUpdate,
                    password: $password,
                    onPasswordChange: { showPasswordUpdate = true },
                    onDeleteAccount: { showDeleteConfirmation = true },
                    showAboutSheet: $showAboutSheet,
                    showContactSheet: $showContactSheet,
                    viewModel: viewModel
                )
            }
        }
    }
   
    private var logoutSection: some View {
        Button {
            showLogoutConfirmation = true
        } label: {
            Group {
                if viewModel.isLoading {
                    ProgressView()
                        .progressViewStyle(.circular)
                } else {
                    Text("Logout")
                        .font(.system(size: 17, weight: .semibold))
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
        }
        .buttonStyle(PillButtonStyle(background: .themePrimary, foreground: .white))
        .padding(.horizontal, 22)
        .padding(.top, 32)
        .padding(.bottom, 20)
    }
   
    private var hasChanges: Bool {
        fullName != originalFullName ||
        phone != originalPhone ||
        gender != originalGender ||
        selectedStyles != originalStyles
    }
    
    private var hasProfilePhoto: Bool {
        if profileImage != nil || viewModel.profileImage != nil {
            return true
        }
        if let updatedUser = viewModel.updatedUser,
           let pic = updatedUser.profilePicture,
           !pic.isEmpty {
            return true
        }
        if let pic = user?.profilePicture, !pic.isEmpty {
            return true
        }
        return false
    }
   
    private func performLogout() {
        debugPrint("[SettingsView] performLogout called - using simple closure")
        TokenManager.shared.clearToken()
        AppPreferences.shared.clearLoginState()
        onLogout?()
        debugPrint("[SettingsView] onLogout called")
    }
   
    private func saveProfile() async {
        let genderString: String? = gender == .male ? "male" : "female"
        let styleStrings = selectedStyles.map { $0.rawValue.lowercased() }
       
        await viewModel.updateProfileText(
            fullName: fullName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : fullName.trimmingCharacters(in: .whitespacesAndNewlines),
            phoneNumber: phone.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : phone.trimmingCharacters(in: .whitespacesAndNewlines),
            gender: genderString,
            password: nil,
            preferences: styleStrings.isEmpty ? nil : styleStrings
        )
    }
}

private func initials(from name: String) -> String {
    name.split(separator: " ").prefix(2).compactMap { $0.first }.map(String.init).joined().uppercased()
}
