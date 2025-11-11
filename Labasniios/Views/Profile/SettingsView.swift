//
//  SettingsView.swift
//  Labasniios
//
//  Created by MacBook on 2/11/2025.
//

import SwiftUI
import PhotosUI

// MARK: - Models
private enum Gender: String, CaseIterable {
    case male = "Male"
    case female = "Female"
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
    
    // Edit Profile State
    @State private var fullName: String = ""
    @State private var email: String = ""
    @State private var phone: String = ""
    @State private var gender: Gender = .female
    @State private var password: String = ""
    @State private var showPasswordUpdate: Bool = false
    
    // Original values for cancel
    @State private var originalFullName: String = ""
    @State private var originalPhone: String = ""
    @State private var originalGender: Gender = .female
    
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
        
        _fullName = State(initialValue: resolvedFullName)
        _email = State(initialValue: resolvedEmail)
        _phone = State(initialValue: resolvedPhone)
        _gender = State(initialValue: resolvedGender)
        _originalFullName = State(initialValue: resolvedFullName)
        _originalPhone = State(initialValue: resolvedPhone)
        _originalGender = State(initialValue: resolvedGender)
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
                SettingsOption(icon: "textformat.size", title: "Font Size", hasToggle: false, toggleValue: false, hasChevron: true)
            ],
            isEditProfile: false
        ),
        SettingsSection(
            icon: "paintbrush",
            title: "Preferences",
            options: [
                SettingsOption(icon: "moon", title: "Theme", hasToggle: false, toggleValue: false, hasChevron: true),
                SettingsOption(icon: "paintpalette", title: "Color Theme", hasToggle: false, toggleValue: false, hasChevron: true),
                SettingsOption(icon: "square.grid.2x2", title: "Interface Layout", hasToggle: false, toggleValue: false, hasChevron: true),
                SettingsOption(icon: "sparkles", title: "Animation Style", hasToggle: false, toggleValue: false, hasChevron: true),
                SettingsOption(icon: "heart", title: "Favorite Styles", hasToggle: false, toggleValue: false, hasChevron: true)
            ],
            isEditProfile: false
        ),
        SettingsSection(
            icon: "lock.shield",
            title: "Security",
            options: [
                SettingsOption(icon: "faceid", title: "Face ID", hasToggle: true, toggleValue: true, hasChevron: false),
                SettingsOption(icon: "key", title: "Two-Factor Authentication", hasToggle: true, toggleValue: false, hasChevron: false),
                SettingsOption(icon: "eye.slash", title: "Privacy Mode", hasToggle: true, toggleValue: false, hasChevron: false),
                SettingsOption(icon: "hand.raised", title: "Data Protection", hasToggle: false, toggleValue: false, hasChevron: true)
            ],
            isEditProfile: false
        ),
        SettingsSection(
            icon: "questionmark.circle",
            title: "Help & Support",
            options: [
                SettingsOption(icon: "envelope.badge", title: "Contact Us", hasToggle: false, toggleValue: false, hasChevron: true),
                SettingsOption(icon: "doc.text", title: "FAQ", hasToggle: false, toggleValue: false, hasChevron: true),
                SettingsOption(icon: "info.circle", title: "About", hasToggle: false, toggleValue: false, hasChevron: true),
                SettingsOption(icon: "app.badge", title: "Version 1.0.0", hasToggle: false, toggleValue: false, hasChevron: false)
            ],
            isEditProfile: false
        )
    ]
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
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
                                password: $password,
                                showPasswordUpdate: $showPasswordUpdate,
                                viewModel: viewModel,
                                onSave: { showSaveConfirmation = true },
                                onCancel: {
                                    fullName = originalFullName
                                    phone = originalPhone
                                    gender = originalGender
                                    password = ""
                                    showPasswordUpdate = false
                                    viewModel.profileImage = nil
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
                                showThemePicker: $showThemePicker
                            )
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
            }
            .background(Color.themeBackground.ignoresSafeArea())
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.large)
            .navigationBarBackButtonHidden(true)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button { showLogoutConfirmation = true } label: {
                        Image(systemName: "rectangle.portrait.and.arrow.right")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.themePrimary)
                    }
                }
            }
            .sheet(isPresented: $showThemePicker) {
                ThemePickerSheet(themeManager: themeManager)
            }
            .alert("Confirmer la modification", isPresented: $showSaveConfirmation) {
                Button("Annuler", role: .cancel) {}
                Button("Confirmer") { Task { await saveProfile() } }
            } message: { Text("Voulez-vous vraiment enregistrer ces modifications ?") }
            .alert("Succès", isPresented: $showSuccessAlert) {
                Button("OK") {
                    if let updatedUser = viewModel.updatedUser {
                        originalFullName = updatedUser.fullName
                        originalPhone = updatedUser.phoneNumber ?? ""
                        originalGender = updatedUser.gender == .male ? .male : .female
                        fullName = updatedUser.fullName
                        phone = updatedUser.phoneNumber ?? ""
                        gender = updatedUser.gender == .male ? .male : .female
                    } else {
                        originalFullName = fullName
                        originalPhone = phone
                        originalGender = gender
                    }
                    password = ""
                    showPasswordUpdate = false
                }
            } message: { Text(viewModel.successMessage ?? "Profil mis à jour avec succès.") }
            .alert("Erreur", isPresented: $showErrorAlert) {
                Button("OK") {}
            } message: { Text(viewModel.errorMessage ?? "Une erreur est survenue.") }
            .onChange(of: viewModel.successMessage) { _ in showSuccessAlert = true }
            .onChange(of: viewModel.errorMessage) { _ in showErrorAlert = true }
            .alert("Déconnexion", isPresented: $showLogoutConfirmation) {
                Button("Annuler", role: .cancel) {}
                Button("Déconnexion", role: .destructive) { performLogout() }
            } message: { Text("Voulez-vous vraiment vous déconnecter ?") }
        }
    }
    
    private var hasChanges: Bool {
        fullName != originalFullName ||
        phone != originalPhone ||
        gender != originalGender ||
        !password.isEmpty ||
        viewModel.profileImage != nil
    }
    
    private func performLogout() {
        TokenManager.shared.clearToken()
        AppPreferences.shared.clearLoginState()
        onLogout?()
    }
    
    private func saveProfile() async {
        let genderString: String? = gender == .male ? "male" : "female"
        let passwordToUpdate: String? = password.isEmpty ? nil : password
        
        await viewModel.updateProfile(
            fullName: fullName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : fullName.trimmingCharacters(in: .whitespacesAndNewlines),
            phoneNumber: phone.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : phone.trimmingCharacters(in: .whitespacesAndNewlines),
            gender: genderString,
            password: passwordToUpdate,
            profileImage: viewModel.profileImage
        )
    }
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
    @Binding var password: String
    @Binding var showPasswordUpdate: Bool
    @ObservedObject var viewModel: SettingsViewModel
    
    @State private var selectedPhoto: PhotosPickerItem?
    @State private var profileImage: UIImage?
    
    let onSave: () -> Void
    let onCancel: () -> Void
    let hasChanges: Bool
    let user: User?
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
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
            
            // Expanded content
            if isExpanded {
                VStack(spacing: 24) {
                    // Avatar
                    VStack(spacing: 12) {
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
                        }
                        
                        PhotosPicker(selection: $selectedPhoto, matching: .images) {
                            Text("Change photo")
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundColor(.themePrimary)
                        }
                        .onChange(of: selectedPhoto) { newItem in
                            Task {
                                if let data = try? await newItem?.loadTransferable(type: Data.self),
                                   let uiImg = UIImage(data: data) {
                                    profileImage = uiImg
                                    viewModel.profileImage = uiImg
                                }
                            }
                        }
                    }
                    .padding(.top, 20)
                    
                    Divider().padding(.horizontal, 20)
                    
                    // Fields
                    VStack(spacing: 20) {
                        // Full Name
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Full Name")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.themeSecondaryText)
                            TextField("Full Name", text: $fullName)
                                .textFieldStyle(CustomTextFieldStyle())
                        }
                        
                        // Email (read-only)
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
                        
                        // Password
                        VStack(alignment: .leading, spacing: 12) {
                            if showPasswordUpdate {
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("New Password")
                                        .font(.system(size: 14, weight: .medium))
                                        .foregroundColor(.themeSecondaryText)
                                    SecureField("New Password", text: $password)
                                        .textFieldStyle(CustomTextFieldStyle())
                                }
                            }
                            Button {
                                withAnimation { showPasswordUpdate.toggle() }
                            } label: {
                                Text(showPasswordUpdate ? "Cancel password update" : "Update password")
                                    .font(.system(size: 15, weight: .semibold))
                                    .foregroundColor(.themePrimary)
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    
                    Divider().padding(.horizontal, 20)
                    
                    // Buttons
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
    
    private func initials(from name: String) -> String {
        name.split(separator: " ").prefix(2).compactMap { $0.first }.map(String.init).joined().uppercased()
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
                SettingsOptionRow(option: option, themeManager: themeManager, showThemePicker: option.title == "Theme" ? $showThemePicker : nil)
                if index < section.options.count - 1 {
                    //Divider().padding(.leading: 80)
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
    @State private var toggleValue: Bool
    
    init(option: SettingsOption, themeManager: ThemeManager, showThemePicker: Binding<Bool>? = nil) {
        self.option = option
        self.themeManager = themeManager
        self.showThemePicker = showThemePicker
        _toggleValue = State(initialValue: option.toggleValue)
    }
    
    var body: some View {
        Button {
            if option.title == "Theme" { showThemePicker?.wrappedValue = true }
        } label: {
            HStack(spacing: 16) {
                Image(systemName: option.icon)
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(.themeSecondaryText)
                    .frame(width: 24)
                Text(option.title)
                    .font(.system(size: 16, weight: .regular))
                    .foregroundColor(.themeText)
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

#Preview {
    SettingsView()
}
