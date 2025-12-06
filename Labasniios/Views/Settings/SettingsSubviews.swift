import SwiftUI

// MARK: - Theme Picker Sheet
struct ThemePickerSheet: View {
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

// MARK: - Color Theme Picker Sheet
struct ColorThemePickerSheet: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var themeManager: ThemeManager
   
    var body: some View {
        VStack(spacing: 0) {
            Text("Color Theme")
                .font(.system(size: 22, weight: .bold))
                .foregroundColor(.themePrimary)
                .padding(.top, 24)
                .padding(.bottom, 20)
           
            VStack(spacing: 0) {
                ForEach(ThemeVariant.allCases, id: \.self) { variant in
                    Button {
                        themeManager.setThemeVariant(variant)
                        dismiss()
                    } label: {
                        HStack {
                            Text(variant.rawValue)
                                .font(.system(size: 17, weight: .regular))
                                .foregroundColor(.themeText)
                            Spacer()
                            if themeManager.getThemeVariant() == variant {
                                Image(systemName: "checkmark")
                                    .foregroundColor(.themePrimary)
                                    .font(.system(size: 16, weight: .semibold))
                            }
                        }
                        .padding(.horizontal, 24)
                        .padding(.vertical, 16)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                   
                    if variant != ThemeVariant.allCases.last {
                        Divider()
                            .padding(.leading, 80)
                    }
                }
            }
            .background(Color.themeCard)
            .cornerRadius(20)
            .padding(.horizontal, 24)
           
            Spacer()
           
            Button {
                dismiss()
            } label: {
                Text("Cancel")
                    .font(.system(size: 17, weight: .bold))
                    .foregroundColor(.themePrimary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 24)
        }
        .frame(maxWidth: .infinity)
        .background(Color.themeBackground.ignoresSafeArea())
        .presentationDetents([.medium])
        .presentationDragIndicator(.visible)
    }
}

// MARK: - Edit Profile Section Card
struct EditProfileSectionCard: View {
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
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(Color.themeCard)
                        .shadow(color: .black.opacity(0.05), radius: 10, x: 0, y: 5)
                )
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
                       
                        // Style Preferences
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
struct CustomTextFieldStyle: TextFieldStyle {
    @ObservedObject private var themeManager = ThemeManager.shared
   
    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(RoundedRectangle(cornerRadius: 16).fill(Color.themeBackground))
            .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.themeTeal.opacity(0.2), lineWidth: 1))
            .foregroundColor(.themeText)
    }
}

// MARK: - Regular Section Card
struct SettingsSectionCard: View {
    let section: SettingsSection
    let isExpanded: Bool
    let onToggle: () -> Void
    @ObservedObject var themeManager: ThemeManager
    @Binding var showThemePicker: Bool
    @Binding var showColorThemePicker: Bool
    @Binding var showPasswordUpdate: Bool
    @Binding var password: String
    var onPasswordChange: (() -> Void)?
    var onDeleteAccount: (() -> Void)?
    @Binding var showAboutSheet: Bool
    @Binding var showContactSheet: Bool
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
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color.themeCard)
                    .shadow(color: .black.opacity(0.05), radius: 10, x: 0, y: 5)
            )
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
                        .background(RoundedRectangle(cornerRadius: 16).fill(Color.themePrimary))
                        .padding(.top, 8)
                    }
                    .padding(.horizontal, 20)
                } else {
                    SettingsOptionRow(
                        option: option,
                        themeManager: themeManager,
                        showThemePicker: option.title == "Theme" ? $showThemePicker : nil,
                        showColorThemePicker: option.title == "Color Theme" ? $showColorThemePicker : nil,
                        onPasswordChange: option.title == "Change Password" ? onPasswordChange : nil,
                        onDeleteAccount: option.title == "Delete Account" ? onDeleteAccount : nil,
                        showAboutSheet: option.title == "About" ? $showAboutSheet : nil,
                        showContactSheet: option.title == "Contact Us" ? $showContactSheet : nil
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
struct SettingsOptionRow: View {
    let option: SettingsOption
    @ObservedObject var themeManager: ThemeManager
    var showThemePicker: Binding<Bool>?
    var showColorThemePicker: Binding<Bool>?
    var onPasswordChange: (() -> Void)?
    var onDeleteAccount: (() -> Void)?
    var showAboutSheet: Binding<Bool>?
    var showContactSheet: Binding<Bool>?
    @State private var toggleValue: Bool
   
    init(
        option: SettingsOption,
        themeManager: ThemeManager,
        showThemePicker: Binding<Bool>? = nil,
        showColorThemePicker: Binding<Bool>? = nil,
        onPasswordChange: (() -> Void)? = nil,
        onDeleteAccount: (() -> Void)? = nil,
        showAboutSheet: Binding<Bool>? = nil,
        showContactSheet: Binding<Bool>? = nil
    ) {
        self.option = option
        self.themeManager = themeManager
        self.showThemePicker = showThemePicker
        self.showColorThemePicker = showColorThemePicker
        self.onPasswordChange = onPasswordChange
        self.onDeleteAccount = onDeleteAccount
        self.showAboutSheet = showAboutSheet
        self.showContactSheet = showContactSheet
        _toggleValue = State(initialValue: option.toggleValue)
    }
   
    private var isDeleteAccount: Bool {
        option.title == "Delete Account"
    }
   
    var body: some View {
        Button {
            if option.title == "Theme" {
                showThemePicker?.wrappedValue = true
            } else if option.title == "Color Theme" {
                showColorThemePicker?.wrappedValue = true
            } else if option.title == "Change Password" {
                onPasswordChange?()
            } else if option.title == "Delete Account" {
                onDeleteAccount?()
            } else if option.title == "About" {
                showAboutSheet?.wrappedValue = true
            } else if option.title == "Contact Us" {
                showContactSheet?.wrappedValue = true
            }
        } label: {
            HStack(spacing: 16) {
                Image(systemName: option.icon)
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(isDeleteAccount ? .red : .themeSecondaryText)
                    .frame(width: 24)
               
                Text(option.title)
                    .font(.system(size: 16, weight: isDeleteAccount ? .semibold : .regular))
                    .foregroundColor(isDeleteAccount ? .red : .themeText)
               
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

// MARK: - About Sheet
struct AboutSheet: View {
    @Environment(\.dismiss) private var dismiss
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    VStack(alignment: .leading, spacing: 16) {
                        Text("About")
                            .font(.title2).bold()
                            .foregroundColor(.themePrimary)
                        Text("""
                        Styleto is an innovative fashion app that lets you discover, share, and sell your clothes.
                        Create your virtual wardrobe in seconds, get personalized outfit suggestions every day, explore the latest trends, and connect with thousands of women who love fashion just like you.
                        Whether you want to refresh your style, make some extra money by selling pieces you no longer wear, or simply find daily inspiration — Styleto is made for you.
                        Join a caring, creative, and passionate community.
                        Because every woman deserves to feel beautiful and confident every single day.
                        Thank you for being part of the Styleto adventure
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

// MARK: - Contact Sheet
struct ContactSheet: View {
    let onPhone: () -> Void
    let onEmail: () -> Void
    @Environment(\.dismiss) private var dismiss
    var body: some View {
        VStack(spacing: 0) {
            Text("Contact Us")
                .font(.system(size: 22, weight: .bold))
                .foregroundColor(.themePrimary)
                .padding(.top, 24)
                .padding(.bottom, 20)
           
            VStack(spacing: 0) {
                Button {
                    onPhone()
                } label: {
                    HStack(spacing: 12) {
                        Image(systemName: "phone.fill")
                            .font(.system(size: 20))
                            .foregroundColor(.themePrimary)
                            .frame(width: 24)
                       
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Phone")
                                .font(.system(size: 17, weight: .semibold))
                                .foregroundColor(.themeText)
                            Text("+216 52904114")
                                .font(.system(size: 15))
                                .foregroundColor(.themeText.opacity(0.7))
                        }
                       
                        Spacer()
                       
                        Image(systemName: "chevron.right")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.themeText.opacity(0.6))
                    }
                    .padding(.horizontal, 24)
                    .padding(.vertical, 16)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
               
                Divider()
                    .padding(.leading, 80)
               
                Button {
                    onEmail()
                } label: {
                    HStack(spacing: 12) {
                        Image(systemName: "envelope.fill")
                            .font(.system(size: 20))
                            .foregroundColor(.themePrimary)
                            .frame(width: 24)
                       
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Email")
                                .font(.system(size: 17, weight: .semibold))
                                .foregroundColor(.themeTeal)
                            Text("styleto.app.team@gmail.com")
                                .font(.system(size: 15))
                                .foregroundColor(.themeTeal.opacity(0.7))
                        }
                       
                        Spacer()
                       
                        Image(systemName: "chevron.right")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.themeText.opacity(0.6))
                    }
                    .padding(.horizontal, 24)
                    .padding(.vertical, 16)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
            .background(Color.themeCard)
            .cornerRadius(20)
            .padding(.horizontal, 24)
           
            Spacer()
           
            Button {
                dismiss()
            } label: {
                Text("Cancel")
                    .font(.system(size: 17, weight: .bold))
                    .foregroundColor(.themePrimary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 24)
        }
        .frame(maxWidth: .infinity)
        .background(Color.themeBackground.ignoresSafeArea())
        .presentationDetents([.medium])
        .presentationDragIndicator(.visible)
    }
}

// Notification quand le solde est mis à jour
extension Notification.Name {
    static let balanceDidUpdate = Notification.Name("balanceDidUpdate")
}
