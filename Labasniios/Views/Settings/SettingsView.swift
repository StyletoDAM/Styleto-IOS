import SwiftUI
import PhotosUI

// MARK: - Models
private enum Gender: String, CaseIterable {
    case male = "Male"
    case female = "Female"
}

private enum StylePreference: String, CaseIterable {
    case casual = "Casual"
    case chic = "Chic"
    case sport = "Sport"
    case boheme = "Bohème"
    case minimal = "Minimal"
}

private struct StyleChip: View {
    let title: String
    let isSelected: Bool
    
    var body: some View {
        Text(title)
            .font(.system(size: 15, weight: .semibold))
            .foregroundColor(isSelected ? .white : Color.themeTeal)
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(
                Capsule()
                    .fill(isSelected ? Color.themePrimary : Color.themeSoftPink.opacity(0.6))
            )
            .overlay(
                Capsule()
                    .stroke(Color.themeTeal.opacity(0.3), lineWidth: isSelected ? 0 : 1)
            )
    }
}

private struct SettingsSection: Identifiable {
    let id = UUID()
    let icon: String
    let title: String
    let options: [SettingsOption]
    let isEditProfile: Bool
}

private struct SettingsOption: Identifiable {
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
        
        // Chargement des préférences de style depuis `preferences`
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
        guard let url = URL(string: "tel://+21652904114") else { return }
        if UIApplication.shared.canOpenURL(url) {
            UIApplication.shared.open(url)
        }
    }

    private func openEmail() {
        let email = "labasni@gmail.com"
        if let url = URL(string: "mailto:\(email)") {
            if UIApplication.shared.canOpenURL(url) {
                UIApplication.shared.open(url)
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
                SettingsOption(icon: "envelope.badge", title: "Contact Us", hasToggle: false, toggleValue: false, hasChevron: true),                SettingsOption(icon: "info.circle", title: "About", hasToggle: false, toggleValue: false, hasChevron: true),
                SettingsOption(icon: "app.badge", title: "Version 1.0.0", hasToggle: false, toggleValue: false, hasChevron: false)
            ],
            isEditProfile: false
        )
    ]
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    Text("Settings")
                        .font(.system(size: 36, weight: .bold))
                        .foregroundColor(.themePrimary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 20)
                        .padding(.top, 12)
                    // Profile Photo
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
                                
                                // Icône d'édition
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
                    
                    // Sections
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
                                showPasswordUpdate: $showPasswordUpdate,
                                password: $password,
                                onPasswordChange: { showPasswordUpdate = true },
                                onDeleteAccount: { showDeleteConfirmation = true },
                                showAboutSheet: $showAboutSheet,
                                showContactSheet: $showContactSheet,   // ← AJOUTÉ ICI
                                viewModel: viewModel
                            )
                        }
                    }
                    
                    // Logout Button
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
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
            }
            .background(Color.themeBackground.ignoresSafeArea())
            
            .navigationBarBackButtonHidden(true)
            .sheet(isPresented: $showThemePicker) {
                ThemePickerSheet(themeManager: themeManager)
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
                            
                            // Mise à jour des styles
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
                            // CRUCIAL : Mettre à jour l'utilisateur dans AppPreferences
                            AppPreferences.shared.currentUser = updatedUser
                            AppPreferences.shared.saveLoginState(user: updatedUser) // SAUVEGARDE DANS USERDEFAULTS !
                            
                            // Et forcer le rafraîchissement du thème
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
                .onChange(of: viewModel.successMessage) { _ in showSuccessAlert = true }
                .onChange(of: viewModel.errorMessage) { _ in showErrorAlert = true }
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
                .alert("Delete aacount", isPresented: $showDeleteConfirmation) {
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
                        // Supprimer immédiatement de l'UI
                        withAnimation(.easeInOut(duration: 0.3)) {
                            profileImage = nil
                            viewModel.profileImage = nil
                        }
                        
                        // Puis appeler l'API
                        Task {
                            await viewModel.deleteProfilePhoto()
                        }
                    }
                } message: {
                    Text("Are you sure you want to delete your profile picture?")
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
        }
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
        TokenManager.shared.clearToken()
        AppPreferences.shared.clearLoginState()
        onLogout?()
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

// MARK: - Theme Picker Sheet
private struct ThemePickerSheet: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var themeManager: ThemeManager
    
    var body: some View {
        NavigationStack {
            List {
                ForEach(ThemeMode.allCases, id: \.self) { mode in
                    Button {
                        themeManager.setThemeMode(mode)
                        dismiss()
                    } label: {
                        HStack {
                            Text(mode.rawValue)
                                .foregroundColor(.themeText)
                            Spacer()
                            if themeManager.getThemeMode() == mode {
                                Image(systemName: "checkmark")
                                    .foregroundColor(.themePrimary)
                            }
                        }
                    }
                }
            }
            .background(Color.themeBackground)
            .navigationTitle("Theme")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }
}

// MARK: - Edit Profile Section Card
private struct EditProfileSectionCard: View {
    @ObservedObject private var themeManager = ThemeManager.shared
    let isExpanded: Bool
    let onToggle: () -> Void
    @Binding var fullName: String
    @Binding var email: String
    @Binding var phone: String
    @Binding var gender: Gender
    @Binding var selectedStyles: Set<StylePreference>
    @ObservedObject var viewModel: SettingsViewModel
    let onSave: () -> Void
    let onCancel: () -> Void
    let hasChanges: Bool
    let user: User?
    
    var body: some View {
        VStack(spacing: 0) {
            Button(action: onToggle) {
                HStack(spacing: 16) {
                    ZStack {
                        Circle()
                            .fill(Color.themePrimary.opacity(0.15))
                            .frame(width: 44, height: 44)
                        Image(systemName: "person.circle")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(.themePrimary)
                    }
                    Text("Edit Profile")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.themeText)
                    Spacer()
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.themeSecondaryText)
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 18)
                .background(Color.themeCard)
            }
            .buttonStyle(.plain)
            
            if isExpanded {
                VStack(spacing: 24) {
                    VStack(spacing: 20) {
                        // Full Name
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Full Name")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.themeSecondaryText)
                            TextField("Full Name", text: $fullName)
                                .textFieldStyle(CustomTextFieldStyle())
                        }
                        
                        // Email
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Email")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.themeSecondaryText)
                            TextField("Email", text: .constant(email))
                                .textFieldStyle(CustomTextFieldStyle())
                                .disabled(true)
                                .foregroundColor(.themeSecondaryText)
                        }
                        
                        // Phone
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Phone")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.themeSecondaryText)
                            TextField("Phone", text: $phone)
                                .keyboardType(.phonePad)
                                .textFieldStyle(CustomTextFieldStyle())
                        }
                        
                        // Gender
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Gender")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.themeSecondaryText)
                            Picker("Gender", selection: $gender) {
                                ForEach(Gender.allCases, id: \.self) { g in
                                    Text(g.rawValue).tag(g)
                                }
                            }
                            .pickerStyle(.segmented)
                            .tint(.themePrimary)
                        }
                        
                        // Préférences de style
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Style Preferences")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.themeSecondaryText)
                            
                            LazyVGrid(columns: [
                                GridItem(.flexible()), GridItem(.flexible())
                            ], spacing: 12) {
                                ForEach(StylePreference.allCases, id: \.self) { style in
                                    StyleChip(
                                        title: style.rawValue,
                                        isSelected: selectedStyles.contains(style)
                                    )
                                    .onTapGesture {
                                        if selectedStyles.contains(style) {
                                            selectedStyles.remove(style)
                                        } else {
                                            selectedStyles.insert(style)
                                        }
                                    }
                                }
                            }
                        }
                        .padding(.top, 8)
                    }
                    .padding(.horizontal, 20)
                    
                    Divider().padding(.horizontal, 20)
                    
                    HStack(spacing: 12) {
                        Button(action: onCancel) {
                            Text("Cancel")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.themeText)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                                .background(RoundedRectangle(cornerRadius: 14).fill(Color.themeTeal.opacity(0.1)))
                        }
                        Button(action: onSave) {
                            Text("Save changes")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                                .background(RoundedRectangle(cornerRadius: 14).fill(hasChanges ? Color.themePrimary : Color.themePrimary.opacity(0.5)))
                        }
                        .disabled(!hasChanges)
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 20)
                }
                .background(Color.themeCard)
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.themeCard)
                .shadow(color: .black.opacity(0.06), radius: 12, x: 0, y: 4)
        )
    }
}

// MARK: - Custom Text Field Style
private struct CustomTextFieldStyle: TextFieldStyle {
    @ObservedObject private var themeManager = ThemeManager.shared
    
    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(RoundedRectangle(cornerRadius: 12).fill(Color.themeBackground))
            .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.themeTeal.opacity(0.2), lineWidth: 1))
            .foregroundColor(.themeText)
    }
}

// MARK: - Regular Section Card
private struct SettingsSectionCard: View {
    let section: SettingsSection
    let isExpanded: Bool
    let onToggle: () -> Void
    @ObservedObject var themeManager: ThemeManager
    @Binding var showThemePicker: Bool
    @Binding var showPasswordUpdate: Bool
    @Binding var password: String
    var onPasswordChange: (() -> Void)?
    var onDeleteAccount: (() -> Void)?
    @Binding var showAboutSheet: Bool
    @Binding var showContactSheet: Bool   // ← Doit être présent
    @ObservedObject var viewModel: SettingsViewModel
    
    var body: some View {
        VStack(spacing: 0) {
            headerView
            if isExpanded { optionsView }
        }
        .background(cardBackground)
    }
    
    private var headerView: some View {
        Button(action: onToggle) {
            HStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(Color.themePrimary.opacity(0.15))
                        .frame(width: 44, height: 44)
                    Image(systemName: section.icon)
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(.themePrimary)
                }
                Text(section.title)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.themeText)
                Spacer()
                Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.themeSecondaryText)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 18)
            .background(Color.themeCard)
        }
        .buttonStyle(.plain)
    }
    
    private var optionsView: some View {
        VStack(spacing: 0) {
            ForEach(Array(section.options.enumerated()), id: \.element.id) { index, option in
                if option.title == "Change Password" && showPasswordUpdate {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("New Password")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.themeSecondaryText)
                        SecureField("Enter new password", text: $password)
                            .textFieldStyle(CustomTextFieldStyle())
                        Button("Save Password") {
                            Task {
                                await viewModel.updateProfileText(
                                    fullName: nil,
                                    phoneNumber: nil,
                                    gender: nil,
                                    password: password,
                                    preferences: nil
                                )
                                showPasswordUpdate = false
                                password = ""
                            }
                        }
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(RoundedRectangle(cornerRadius: 12).fill(Color.themePrimary))
                        .padding(.top, 8)
                    }
                    .padding(.horizontal, 20)
                } else {
                    SettingsOptionRow(
                        option: option,
                        themeManager: themeManager,
                        showThemePicker: option.title == "Theme" ? $showThemePicker : nil,
                        onPasswordChange: option.title == "Change Password" ? onPasswordChange : nil,
                        onDeleteAccount: option.title == "Delete Account" ? onDeleteAccount : nil,
                        showAboutSheet: option.title == "About" ? $showAboutSheet : nil,
                        showContactSheet: option.title == "Contact Us" ? $showContactSheet : nil   // ← AJOUTE ÇA
                    )
                }
                
                if index < section.options.count - 1 {
                    Divider().padding(.leading, 80)
                }
            }
        }
        .background(Color.themeCard)
        .transition(.opacity.combined(with: .move(edge: .top)))
    }
    
    private var cardBackground: some View {
        RoundedRectangle(cornerRadius: 20)
            .fill(Color.themeCard)
            .shadow(color: .black.opacity(0.06), radius: 12, x: 0, y: 4)
    }
}

// MARK: - Option Row
private struct SettingsOptionRow: View {
    let option: SettingsOption
    @ObservedObject var themeManager: ThemeManager
    var showThemePicker: Binding<Bool>?
    var onPasswordChange: (() -> Void)?
    var onDeleteAccount: (() -> Void)?
    var showAboutSheet: Binding<Bool>?
    var showContactSheet: Binding<Bool>?
    @State private var toggleValue: Bool
    
    init(
        option: SettingsOption,
        themeManager: ThemeManager,
        showThemePicker: Binding<Bool>? = nil,
        onPasswordChange: (() -> Void)? = nil,
        onDeleteAccount: (() -> Void)? = nil,
        showAboutSheet: Binding<Bool>? = nil,
        showContactSheet: Binding<Bool>? = nil
    ) {
        self.option = option
        self.themeManager = themeManager
        self.showThemePicker = showThemePicker
        self.onPasswordChange = onPasswordChange
        self.onDeleteAccount = onDeleteAccount
        self.showAboutSheet = showAboutSheet
        _toggleValue = State(initialValue: option.toggleValue)
    }
    
    // Variable pour détecter si c'est la ligne "Delete Account"
    private var isDeleteAccount: Bool {
        option.title == "Delete Account"
    }
    
    var body: some View {
        Button {
            if option.title == "Theme" {
                showThemePicker?.wrappedValue = true
            } else if option.title == "Change Password" {
                onPasswordChange?()
            } else if option.title == "Delete Account" {
                onDeleteAccount?()
            }else if option.title == "About" {
                showAboutSheet?.wrappedValue = true
            }else if option.title == "Contact Us" {
                // On montre le petit menu comme sur ta capture
                showContactSheet?.wrappedValue = true            }
        } label: {
            HStack(spacing: 16) {
                Image(systemName: option.icon)
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(isDeleteAccount ? .red : .themeSecondaryText)  // Icône en rouge
                    .frame(width: 24)
                
                Text(option.title)
                    .font(.system(size: 16, weight: isDeleteAccount ? .semibold : .regular))
                    .foregroundColor(isDeleteAccount ? .red : .themeText)  // Texte en rouge
                
                Spacer()
                
                if option.title == "Theme" {
                    Text(themeManager.getThemeMode().rawValue)
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(.themeSecondaryText)
                    Image(systemName: "chevron.right")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.themeSecondaryText)
                } else if option.hasToggle {
                    Toggle("", isOn: $toggleValue)
                        .labelsHidden()
                        .tint(.themePrimary)
                } else if option.hasChevron {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.themeSecondaryText)
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
        }
        .buttonStyle(.plain)
        
    }
}

private struct AboutSheet: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Image ou logo de l’app (optionnel)
//                    Image("app-logo") // remplace par ton asset ou enlève
//                        .resizable()
//                        .scaledToFit()
//                        .frame(height: 120)
//                        .frame(maxWidth: .infinity)

                    VStack(alignment: .leading, spacing: 16) {
                        Text("About")
                            .font(.title2).bold()
                            .foregroundColor(.themePrimary)

                        Text("""
                        Labasni is an innovative fashion app that lets you discover, share, and sell your clothes.

                        Create your virtual wardrobe in seconds, get personalized outfit suggestions every day, explore the latest trends, and connect with thousands of women who love fashion just like you.

                        Whether you want to refresh your style, make some extra money by selling pieces you no longer wear, or simply find daily inspiration — Labasni is made for you.

                        Join a caring, creative, and passionate community.
                        Because every woman deserves to feel beautiful and confident every single day.

                        Thank you for being part of the Labasni adventure

                        Version 1.0.0 • 2025
                        """)
                        .font(.body)
                        .foregroundColor(.themeText)
                        .lineSpacing(6)
                    }
                    .padding(.horizontal, 24)

                    Spacer()
                }
                .padding(.top, 20)
            }
            .background(Color.themeBackground.ignoresSafeArea())
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Close") { dismiss() }
                        .foregroundColor(.themePrimary)
                }
            }
        }
    }
}
private struct ContactSheet: View {
    let onPhone: () -> Void
    let onEmail: () -> Void
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Spacer().frame(height: 20)

                Text("Contact Us")
                    .font(.title2.bold())
                    .foregroundColor(.themePrimary)

                VStack(spacing: 16) {
                    Button {
                        onPhone()
                        dismiss()
                    } label: {
                        HStack {
                            Image(systemName: "phone.fill")
                            Text("Phone +216 52 904 114")
                            Spacer()
                            Image(systemName: "chevron.right")
                        }
                        .foregroundColor(.themeText)
                        .font(.system(size: 17))
                        .padding()
                        .background(Color.themeCard)
                        .cornerRadius(12)
                    }

                    Button {
                        onEmail()
                        dismiss()
                    } label: {
                        HStack {
                            Image(systemName: "envelope.fill")
                            Text("Email labasni@gmail.com")
                            Spacer()
                            Image(systemName: "chevron.right")
                        }
                        .foregroundColor(.themeText)
                        .font(.system(size: 17))
                        .padding()
                        .background(Color.themeCard)
                        .cornerRadius(12)
                    }
                }
                .padding(.horizontal, 24)

                Spacer()
            }
            .background(Color.themeBackground.ignoresSafeArea())
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .foregroundColor(.themePrimary)
                        .fontWeight(.medium)
                }
            }
        }
        .presentationDetents([.medium])
        .presentationDragIndicator(.visible)
    }
}
