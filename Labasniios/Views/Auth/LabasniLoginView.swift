import SwiftUI

struct LabasniLoginView: View {
    @StateObject private var viewModel = LoginViewModel()
    @StateObject private var appleSignInHelper = AppleSignInHelper()
    @StateObject private var googleSignInHelper = GoogleSignInHelper()
    @ObservedObject private var themeManager = ThemeManager.shared  // ✅ AJOUT
    @State private var navigateToProfile = false
    @State private var snackbarMessage: String?
    @State private var isSnackbarVisible = false
    @State private var profileUser: User?

    var body: some View {
        NavigationStack {
            Group {
                if navigateToProfile, let user = profileUser {
                    MainTabView(user: user, onLogout: handleLogout)
                } else {
                    loginContentView
                }
            }
        }
    }
    
    private var loginContentView: some View {
        ZStack {
            // ✅ CORRECTION: Fond dynamique selon le thème
            LinearGradient(
                colors: [Color.themeBackground, Color.themeAqua.opacity(0.25)],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack(spacing: 20) {
                Spacer(minLength: 0)

                // Logo
                Image("logocercle")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 150, height: 150)
                    .shadow(color: .black.opacity(0.18), radius: 18, x: 0, y: 8)
                    .padding(.top, 6)

                // Titre + sous-titre
                VStack(spacing: 6) {
                    Text("Styleto")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(.themePrimary)  // ✅ Dynamique

                    Text("Welcome! Please log in")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(.themeSecondary)  // ✅ Dynamique
                }
                .padding(.bottom, 8)

                // Form
                VStack(alignment: .leading, spacing: 18) {
                    Group {
                        Text("Email")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.themeText)  // ✅ Dynamique

                        IconField(systemName: "envelope",
                                  placeholder: "your@email.com",
                                  text: $viewModel.email)
                    }

                    Group {
                        Text("Password")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.themeText)  // ✅ Dynamique

                        IconSecureField(systemName: "lock",
                                        placeholder: "••••••••",
                                        text: $viewModel.password)
                    }

                    HStack {
                        Spacer()
                        NavigationLink {
                            LabasniForgotPasswordView()
                        } label: {
                            Text("Forgot password?")
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundColor(.themeSecondary)  // ✅ Dynamique
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 22)

                // Bouton principal
                Button {
                    Task {
                        await viewModel.signin()
                        if let user = viewModel.signedInUser {
                            viewModel.password = ""
                            hideSnackbar()
                            profileUser = user
                            AppPreferences.shared.saveLoginState(user: user)
                            navigateToProfile = true
                        }
                    }
                } label: {
                    Group {
                        if viewModel.isLoading {
                            ProgressView()
                                .progressViewStyle(.circular)
                                .tint(.white)
                        } else {
                            Text("Log In")
                                .font(.system(size: 17, weight: .semibold))
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                }
                .buttonStyle(PillButtonStyle(background: .themePrimary, foreground: .white))  // ✅ Dynamique
                .padding(.horizontal, 22)
                .padding(.top, 6)
                .disabled(viewModel.isLoading)

                // Séparateur
                HStack {
                    Rectangle()
                        .fill(Color.themeSecondary.opacity(0.3))  // ✅ Dynamique
                        .frame(height: 1)
                    Text("OU")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.themeSecondary.opacity(0.7))  // ✅ Dynamique
                        .padding(.horizontal, 12)
                    Rectangle()
                        .fill(Color.themeSecondary.opacity(0.3))  // ✅ Dynamique
                        .frame(height: 1)
                }
                .padding(.horizontal, 22)
                .padding(.top, 12)

                // Boutons OAuth
                VStack(spacing: 12) {
                    // Bouton Google
                    Button {
                        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                              let rootVC = windowScene.windows.first?.rootViewController else {
                            displaySnackbar("Unable to open Google Sign-In")
                            return
                        }
                        googleSignInHelper.signInWithGoogle(presenting: rootVC)
                    } label: {
                        HStack(spacing: 12) {
                            Image(systemName: "globe")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(.themeSecondary)  // ✅ Dynamique
                                .frame(width: 24, height: 24)
                            
                            Text("Continue with Google")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.themeText)  // ✅ Dynamique
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Color.themeCard)  // ✅ Dynamique
                        .overlay(
                            RoundedRectangle(cornerRadius: 22, style: .continuous)
                                .stroke(Color.themeSecondary.opacity(0.4), lineWidth: 1.5)  // ✅ Dynamique
                        )
                    }
                    .buttonStyle(.plain)
                    .disabled(googleSignInHelper.isLoading)

                    // Bouton Apple
                    Button {
                        appleSignInHelper.signInWithApple()
                    } label: {
                        HStack {
                            Image(systemName: "applelogo")
                                .font(.system(size: 18, weight: .semibold))
                            Text("Continue with Apple")
                                .font(.system(size: 16, weight: .semibold))
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Color.black)
                        .foregroundColor(.white)
                        .cornerRadius(22)
                    }
                    .buttonStyle(.plain)
                    .disabled(appleSignInHelper.isLoading)
                }
                .padding(.horizontal, 22)
                .padding(.top, 8)

                // Lien créer un compte
                NavigationLink {
                    LabasniSignupView()
                } label: {
                    Text("Don't have an account yet? Sign up")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.themeSecondary)  // ✅ Dynamique
                }
                .buttonStyle(.plain)
                .padding(.top, 12)

                Spacer(minLength: 20)
            }
            
            if isSnackbarVisible, let snackbarMessage {
                VStack {
                    Spacer()
                    Text(snackbarMessage)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 12)
                        .background(
                            Capsule().fill(Color.themePrimary.opacity(0.92))  // ✅ Dynamique
                        )
                        .padding(.bottom, 28)
                }
                .transition(.move(edge: .bottom).combined(with: .opacity))
                .padding(.horizontal, 16)
            }
        }
        .contentShape(Rectangle())
        .onTapGesture {
            UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
        }
        .navigationBarBackButtonHidden(true)
        .toolbar(.hidden, for: .navigationBar)
        .onChange(of: viewModel.errorMessage) { message in
            if let message {
                displaySnackbar(message)
            }
        }
        .onChange(of: appleSignInHelper.errorMessage) { message in
            if let message {
                displaySnackbar(message)
            }
        }
        .onChange(of: googleSignInHelper.errorMessage) { message in
            if let message {
                displaySnackbar(message)
            }
        }
        .onAppear {
            themeManager.updateTheme()  // ✅ IMPORTANT
            hideSnackbar()
            
            appleSignInHelper.onSuccess = { response in
                TokenManager.shared.saveToken(response.accessToken)
                TokenManager.shared.saveRefreshToken(response.refreshToken)
                // ✨ NOUVEAU : Sauvegarder le userId (comme Android)
                TokenManager.shared.saveUserId(response.user.id)
                viewModel.password = ""
                hideSnackbar()
                profileUser = response.user
                AppPreferences.shared.saveLoginState(user: response.user)
                navigateToProfile = true
            }
            appleSignInHelper.onError = { error in
                displaySnackbar(error.localizedDescription)
            }
            
            googleSignInHelper.onSuccess = { response in
                TokenManager.shared.saveToken(response.accessToken)
                TokenManager.shared.saveRefreshToken(response.refreshToken)
                // ✨ NOUVEAU : Sauvegarder le userId (comme Android)
                TokenManager.shared.saveUserId(response.user.id)
                viewModel.password = ""
                hideSnackbar()
                profileUser = response.user
                AppPreferences.shared.saveLoginState(user: response.user)
                navigateToProfile = true
            }
            googleSignInHelper.onError = { error in
                displaySnackbar(error.localizedDescription)
            }
        }
    }

    private func handleLogout() {
        TokenManager.shared.clearToken()
        AppPreferences.shared.clearLoginState()
        navigateToProfile = false
        profileUser = nil
        viewModel.email = ""
        viewModel.password = ""
        viewModel.resetFeedback()
        hideSnackbar()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            navigateToProfile = false
        }
    }

    private func displaySnackbar(_ message: String) {
        snackbarMessage = message
        withAnimation(.easeOut(duration: 0.2)) {
            isSnackbarVisible = true
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.2) {
            hideSnackbar()
        }
    }

    private func hideSnackbar() {
        withAnimation(.easeInOut(duration: 0.2)) {
            isSnackbarVisible = false
        }
        if !isSnackbarVisible {
            snackbarMessage = nil
        }
    }
}

// MARK: - Champs stylés (avec couleurs dynamiques)
private struct IconField: View {
    let systemName: String
    let placeholder: String
    @Binding var text: String

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: systemName)
                .foregroundColor(.themeSecondary)  // ✅ Dynamique
                .font(.system(size: 18, weight: .semibold))
                .frame(width: 24)

            TextField(placeholder, text: $text)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled(true)
                .keyboardType(.emailAddress)
                .foregroundColor(.themeText)  // ✅ Dynamique
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 14)
        .background(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(Color.themeCard)  // ✅ Dynamique
        )
        .overlay(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(Color.themePrimary.opacity(0.6), lineWidth: 1.5)  // ✅ Dynamique
        )
        .shadow(color: .black.opacity(0.06), radius: 8, x: 0, y: 4)
    }
}

private struct IconSecureField: View {
    let systemName: String
    let placeholder: String
    @Binding var text: String
    @State private var isSecure: Bool

    init(systemName: String, placeholder: String, text: Binding<String>, initiallySecure: Bool = true) {
        self.systemName = systemName
        self.placeholder = placeholder
        _text = text
        _isSecure = State(initialValue: initiallySecure)
    }

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: systemName)
                .foregroundColor(.themeSecondary)  // ✅ Dynamique
                .font(.system(size: 18, weight: .semibold))
                .frame(width: 24)

            if isSecure {
                SecureField(placeholder, text: $text)
                    .foregroundColor(.themeText)  // ✅ Dynamique
            } else {
                TextField(placeholder, text: $text)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled(true)
                    .foregroundColor(.themeText)  // ✅ Dynamique
            }

            Spacer(minLength: 0)

            Button {
                isSecure.toggle()
            } label: {
                Image(systemName: isSecure ? "eye.slash" : "eye")
                    .foregroundColor(.themePrimary)  // ✅ Dynamique
                    .font(.system(size: 16, weight: .semibold))
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 14)
        .background(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(Color.themeCard)  // ✅ Dynamique
        )
        .overlay(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(Color.themePrimary.opacity(0.6), lineWidth: 1.5)  // ✅ Dynamique
        )
        .shadow(color: .black.opacity(0.06), radius: 8, x: 0, y: 4)
    }
}
