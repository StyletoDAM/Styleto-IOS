# 📄 Analyse Détaillée Fichier par Fichier - Projet iOS Labasni

**Document de référence pour validation technique**  
**Version**: 1.0.0

---

## 📋 Table des Matières

1. [Point d'Entrée](#1-point-dentrée)
2. [Configuration et Utilitaires](#2-configuration-et-utilitaires)
3. [Modèles de Données](#3-modèles-de-données)
4. [Services](#4-services)
5. [ViewModels](#5-viewmodels)
6. [Vues](#6-vues)

---

## 1. Point d'Entrée

### 1.1 `LabasniiosApp.swift`

#### 📍 Localisation
`Labasniios/LabasniiosApp.swift`

#### 🎯 Fonctionnalités
- Point d'entrée de l'application (`@main`)
- Gestion du splash screen avec animation
- Navigation conditionnelle basée sur l'état de connexion
- Gestion des deep links (Stripe checkout)
- Initialisation des singletons globaux

#### 🧠 Logique Métier

**Flux d'initialisation**:
```swift
init() {
    StripeConfig.shared.initialize()
    _ = ChatSocketManager.shared
    _ = NavigationTheme()
    
    DispatchQueue.main.async {
        ThemeManager.shared.updateThemeBasedOnUser()
    }
}
```

**Flux de navigation**:
1. Vérifie `AppPreferences.isLoggedIn`
2. Si `true` et `currentUser` existe → `MainTabView`
3. Sinon → `LabasniIntroView`
4. Affiche `LaunchSplashView` pendant 1.8 secondes

**Gestion des deep links**:
- Format: `labasni://subscriptions/success?session_id=xxx`
- Format: `labasni://subscriptions/cancel`
- Rafraîchit l'abonnement après succès Stripe

#### 🏗 Architecture
- **Pattern**: App Entry Point (SwiftUI)
- **Dépendances**:
  - `ThemeManager.shared` (singleton)
  - `AppPreferences.shared` (singleton)
  - `CoreDataManager.shared` (singleton)
  - `StripeConfig.shared` (singleton)
  - `ChatSocketManager.shared` (singleton)

#### 🔧 Technologies
- SwiftUI `@main` struct
- `@StateObject` pour réactivité
- `@UIApplicationDelegateAdaptor` pour AppDelegate
- `WindowGroup` pour la fenêtre principale

#### 📦 Dépendances
- Aucune dépendance externe directe
- Utilise les singletons internes

#### 🧪 Tests Recommandés
- Test de navigation conditionnelle
- Test de gestion des deep links
- Test d'initialisation des singletons

---

## 2. Configuration et Utilitaires

### 2.1 `APIConstants.swift`

#### 📍 Localisation
`Labasniios/Utils/APIConstants.swift`

#### 🎯 Fonctionnalités
- Centralise toutes les URLs d'API
- Définit la base URL du backend
- Organise les chemins d'endpoints par domaine fonctionnel

#### 🧠 Logique Métier
```swift
enum APIConstants {
    static let baseURL = URL(string: "https://labasni-backend-mh3j.onrender.com")!
    
    // Organisation par domaine
    static let signinPath = "/auth/signin"
    static let clothMePath = "/cloth/me"
    static let outfitsPath = "/outfits"
    // ...
}
```

**Avantages**:
- Maintenance facilitée (changement d'URL centralisé)
- Réduction des erreurs de typage
- Documentation implicite des endpoints

#### 🏗 Architecture
- **Pattern**: Constants Enum
- Pas d'instanciation nécessaire
- Utilisation: `URL(string: APIConstants.signinPath, relativeTo: APIConstants.baseURL)`

#### 🔧 Technologies
- Swift Enum (pas de cas, seulement constantes)
- `URL` type pour type-safety

---

### 2.2 `TokenManager.swift`

#### 📍 Localisation
`Labasniios/Utils/TokenManager.swift`

#### 🎯 Fonctionnalités
- Stockage des tokens JWT (access + refresh)
- Extraction automatique du `userId` depuis le JWT
- Normalisation des IDs pour comparaisons fiables
- Gestion du cycle de vie des tokens

#### 🧠 Logique Métier

**Sauvegarde de token**:
```swift
func saveToken(_ token: String) {
    UserDefaults.standard.set(token, forKey: tokenKey)
    
    // Extraction automatique du userId depuis le JWT
    if let userId = JWTDecoder.extractUserId(from: token) {
        saveUserId(userId)
    }
}
```

**Flux**:
1. Token reçu → sauvegarde dans UserDefaults
2. Décodage JWT pour extraire `sub` (userId)
3. Sauvegarde du userId pour usage ultérieur

**Normalisation**:
```swift
func getNormalizedUserId() -> String? {
    guard let userId = getUserId() else { return nil }
    return userId.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
}
```

#### 🏗 Architecture
- **Pattern**: Singleton
- **Stockage**: UserDefaults (⚠️ devrait être Keychain pour production)
- **Dépendances**: `JWTDecoder` pour extraction

#### 🔧 Technologies
- `UserDefaults` pour stockage simple
- Décodage Base64 pour JWT

#### ⚠️ Points d'Attention
- **Sécurité**: UserDefaults n'est pas sécurisé. Migrer vers Keychain.
- **Performance**: Pas de cache, lecture directe à chaque appel

#### 🧪 Tests Recommandés
- Test de sauvegarde/récupération de token
- Test d'extraction de userId
- Test de normalisation d'ID
- Test de nettoyage (`clearToken`)

---

### 2.3 `ThemeManager.swift`

#### 📍 Localisation
`Labasniios/Utils/ThemeManager.swift`

#### 🎯 Fonctionnalités
- Gestion des thèmes Light/Dark/System
- Variantes Pink (Female) / Blue (Male)
- Mise à jour dynamique des couleurs
- Persistance des préférences utilisateur

#### 🧠 Logique Métier

**Mise à jour du thème**:
```swift
func updateTheme() {
    let shouldUseDark: Bool
    switch themeMode {
    case .light: shouldUseDark = false
    case .dark: shouldUseDark = true
    case .system:
        // Détecte le mode système iOS
        shouldUseDark = window.traitCollection.userInterfaceStyle == .dark
    }
    
    let variant = getThemeVariant()
    let isMale = variant == .blue
    
    withAnimation(.easeInOut(duration: 0.35)) {
        currentTheme = shouldUseDark 
            ? DarkTheme(isMale: isMale) 
            : LightTheme(isMale: isMale)
    }
}
```

**Variantes de couleur**:
- **Pink (Female)**: Primaire `#CA3C66`, Secondaire `#DB6A8F`
- **Blue (Male)**: Primaire `#4AA3A2`, Secondaire `#6BC4C3`

#### 🏗 Architecture
- **Pattern**: Singleton + Observer
- **Stockage**: `@AppStorage` (wrapper UserDefaults)
- **Réactivité**: `@Published` pour mise à jour UI automatique
- **Protocol**: `Theme` pour abstraction

#### 🔧 Technologies
- SwiftUI `@AppStorage`
- Combine `@Published`
- Protocol-oriented design

#### 📦 Dépendances
- Aucune dépendance externe
- Utilise `AppPreferences` pour récupérer le genre utilisateur

#### 🧪 Tests Recommandés
- Test de changement de thème
- Test de variante Pink/Blue
- Test de persistance des préférences
- Test de détection du mode système

---

### 2.4 `SocketManager.swift` (ChatSocketManager)

#### 📍 Localisation
`Labasniios/Utils/SocketManager.swift`

#### 🎯 Fonctionnalités
- Connexion WebSocket via Socket.IO
- Gestion des conversations en temps réel
- Envoi/réception de messages
- Indicateurs de frappe (typing)
- Reconnexion automatique

#### 🧠 Logique Métier

**Configuration du socket**:
```swift
func setupSocket() {
    guard let token = TokenManager.shared.getToken() else { return }
    
    manager = SocketManager(
        socketURL: baseURL,
        config: [
            .extraHeaders(["Authorization": "Bearer \(token)"]),
            .connectParams(["token": token]),
            .path("/socket.io/")
        ]
    )
    
    socket = manager.socket(forNamespace: "/chat")
    setupListeners()
}
```

**Envoi de message**:
```swift
func sendMessage(_ content: String, in conversationId: String) {
    let payload: [String: Any] = [
        "conversationId": conversationId,
        "content": content,
        "token": TokenManager.shared.getToken() ?? ""
    ]
    socket.emit("send-message", payload)
}
```

**Réception de message**:
```swift
socket.on("new-message") { [weak self] data, _ in
    self?.handleIncomingMessage(data)
}
```

#### 🏗 Architecture
- **Pattern**: Singleton
- **Library**: Socket.IO Client Swift
- **Namespace**: `/chat`
- **Événements**:
  - `new-message` : Réception
  - `send-message` : Envoi
  - `join-conversation` : Rejoindre
  - `typing` : Indicateur de frappe

#### 🔧 Technologies
- Socket.IO Client Swift
- Combine Publishers (`PassthroughSubject`)
- Async/await pour décodage

#### 📦 Dépendances
- **Socket.IO Client Swift** (SPM)

#### ⚠️ Points d'Attention
- Gestion de la reconnexion automatique
- Vérification du token avant connexion
- Nettoyage des listeners avant reconnexion

#### 🧪 Tests Recommandés
- Test de connexion/déconnexion
- Test d'envoi de message
- Test de réception de message
- Test de reconnexion automatique

---

### 2.5 `CoreDataManager.swift`

#### 📍 Localisation
`Labasniios/Utils/CoreDataManager.swift`

#### 🎯 Fonctionnalités
- Initialisation du stack CoreData
- Gestion du contexte de persistance
- Sauvegarde des données

#### 🧠 Logique Métier
```swift
private init() {
    container = NSPersistentContainer(name: "Labasniios")
    container.loadPersistentStores { _, error in
        if let error = error {
            print("Core Data failed to load: \(error)")
        }
    }
    container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
}
```

**Sauvegarde**:
```swift
func save() {
    let context = container.viewContext
    if context.hasChanges {
        do {
            try context.save()
        } catch {
            print("Failed to save context: \(error)")
        }
    }
}
```

#### 🏗 Architecture
- **Pattern**: Singleton
- **Stack**: NSPersistentContainer
- **Merge Policy**: `NSMergeByPropertyObjectTrumpMergePolicy`

#### 🔧 Technologies
- CoreData framework
- NSPersistentContainer

#### 📦 Dépendances
- Aucune dépendance externe
- Utilise le modèle `Labasniios.xcdatamodeld`

#### 🧪 Tests Recommandés
- Test d'initialisation du stack
- Test de sauvegarde
- Test de chargement des données

---

## 3. Modèles de Données

### 3.1 `User.swift`

#### 📍 Localisation
`Labasniios/Models/Entities/User.swift`

#### 🎯 Fonctionnalités
- Modèle de données utilisateur
- Décodage personnalisé pour compatibilité backend
- Support de plusieurs providers d'authentification

#### 🧠 Logique Métier

**Décodage personnalisé**:
```swift
init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    
    // Support de "id" et "_id" (MongoDB)
    if container.contains(.id) {
        id = try container.decode(String.self, forKey: .id)
    } else if container.contains(.mongoId) {
        id = try container.decode(String.self, forKey: .mongoId)
    } else {
        throw DecodingError.keyNotFound(...)
    }
    
    // Gender avec fallback
    let genderStr = try container.decode(String.self, forKey: .gender)
    gender = Gender(rawValue: genderStr.lowercased()) ?? .female
}
```

**Propriétés calculées**:
```swift
var balanceInTND: Double {
    balance ?? 0.0
}

var formattedBalance: String {
    String(format: "%.2f DT", balanceInTND)
}
```

#### 🏗 Architecture
- **Pattern**: Codable Entity
- **Conformité**: `Codable`, `Identifiable`
- **Support**: Multiple auth providers (local, Google, Apple)

#### 🔧 Technologies
- Swift Codable
- Custom decoding/encoding

#### 📦 Dépendances
- Aucune dépendance externe

#### 🧪 Tests Recommandés
- Test de décodage avec "id"
- Test de décodage avec "_id"
- Test de fallback pour gender
- Test de propriétés calculées

---

## 4. Services

### 4.1 `AuthService.swift`

#### 📍 Localisation
`Labasniios/Services/Auth/AuthService.swift`

#### 🎯 Fonctionnalités
- Authentification email/password
- OAuth Google
- OAuth Apple
- Forgot password flow (OTP)
- Refresh token automatique

#### 🧠 Logique Métier

**Signin**:
```swift
func signin(email: String, password: String) async throws -> SigninResponse {
    let payload = ["email": email, "password": password]
    return try await performRequest(
        path: APIConstants.signinPath,
        payload: payload,
        responseType: SigninResponse.self
    )
}
```

**Refresh token**:
```swift
func refreshToken() async throws -> (accessToken: String, refreshToken: String) {
    guard let refreshToken = TokenManager.shared.getRefreshToken() else {
        throw NetworkError.serverMessage("Refresh token manquant.")
    }
    
    let payload = ["refreshToken": refreshToken]
    // Appel API /auth/refresh
    // ...
}
```

#### 🏗 Architecture
- **Pattern**: Service Layer + Singleton
- **Concurrence**: `@MainActor` pour thread-safety
- **Networking**: `URLSession` avec async/await
- **Décodage**: `JSONDecoder` avec stratégie snake_case

#### 🔧 Technologies
- URLSession (async/await)
- JSONEncoder/Decoder
- AuthenticationServices (Apple)
- GoogleSignIn SDK

#### 📦 Dépendances
- **GoogleSignIn-iOS** (SPM)
- **AuthenticationServices** (framework natif)

#### 🧪 Tests Recommandés
- Test de signin success/error
- Test de OAuth Google
- Test de OAuth Apple
- Test de refresh token
- Test de forgot password flow

---

### 4.2 `StoreService.swift`

#### 📍 Localisation
`Labasniios/Services/Store/StoreService.swift`

#### 🎯 Fonctionnalités
- Récupération des items du store
- Création d'item
- Mise à jour (status, size, price)
- Suppression d'item
- Marquage comme vendu

#### 🧠 Logique Métier

**Fetch avec Combine**:
```swift
func fetchMyStore() -> AnyPublisher<[Store], NetworkError> {
    guard let url = URL(string: "/store/my", relativeTo: baseURL) else {
        return Fail(error: .invalidURL).eraseToAnyPublisher()
    }
    
    var request = URLRequest(url: url)
    request.httpMethod = "GET"
    request.setValue("Bearer \(tokenManager.getToken() ?? "")", forHTTPHeaderField: "Authorization")
    
    return URLSession.shared.dataTaskPublisher(for: request)
        .map(\.data)
        .decode(type: [Store].self, decoder: JSONDecoder().withISO8601())
        .mapError { error -> NetworkError in
            // Gestion d'erreurs
        }
        .receive(on: DispatchQueue.main)
        .eraseToAnyPublisher()
}
```

**Update avec body**:
```swift
func updateStoreSize(_ storeId: String, size: String) -> AnyPublisher<Store, NetworkError> {
    let body: [String: Any] = ["size": size]
    request.httpBody = try JSONSerialization.data(withJSONObject: body)
    // ...
}
```

#### 🏗 Architecture
- **Pattern**: Service Layer + Singleton
- **Réactivité**: Combine Publishers
- **Networking**: URLSession avec Combine

#### 🔧 Technologies
- URLSession
- Combine (`AnyPublisher`)
- JSONEncoder/Decoder

#### 📦 Dépendances
- Aucune dépendance externe
- Utilise `TokenManager` pour l'authentification

#### 🧪 Tests Recommandés
- Test de fetch success/error
- Test de création d'item
- Test de mise à jour (size, price, status)
- Test de suppression
- Test de marquage comme vendu

---

## 5. ViewModels

### 5.1 `LoginViewModel.swift`

#### 📍 Localisation
`Labasniios/ViewModels/Auth/LoginViewModel.swift`

#### 🎯 Fonctionnalités
- Gestion de l'état du formulaire (email, password)
- Validation des champs
- Appel au service d'authentification
- Gestion des états de chargement et d'erreur

#### 🧠 Logique Métier

**Signin flow**:
```swift
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
        signedInUser = response.user
        TokenManager.shared.saveToken(response.accessToken)
    } catch {
        errorMessage = error.localizedDescription
    }
}
```

**Validation**:
```swift
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
```

#### 🏗 Architecture
- **Pattern**: MVVM ViewModel
- **Réactivité**: `@Published` + Combine
- **Concurrence**: `@MainActor` (UI thread)
- **Dépendances**: `AuthService` (injecté)

#### 🔧 Technologies
- Combine `@Published`
- Async/await
- Regex pour validation email

#### 📦 Dépendances
- `AuthService` (injection)
- `TokenManager` (singleton)

#### 🧪 Tests Recommandés
- Test de validation email
- Test de validation password
- Test de signin success
- Test de signin error
- Test de nettoyage des champs

---

### 5.2 `DressingViewModel.swift`

#### 📍 Localisation
`Labasniios/ViewModels/Dressing/DressingViewModel.swift`

#### 🎯 Fonctionnalités
- Gestion de la liste des vêtements
- Filtrage par catégorie
- Recherche textuelle
- Suppression de vêtement

#### 🧠 Logique Métier

**Fetch**:
```swift
func fetchClothes() {
    isLoading = true
    ClothesService.shared.fetchMyClothes { [weak self] result in
        DispatchQueue.main.async {
            self?.isLoading = false
            switch result {
            case .success(let clothes):
                self?.clothes = clothes
                self?.filterClothes()
            case .failure(let error):
                print("Erreur: \(error)")
            }
        }
    }
}
```

**Filtrage réactif avec Combine**:
```swift
private func setupBindings() {
    Publishers.CombineLatest($selectedCategory, $searchText)
        .debounce(for: .milliseconds(300), scheduler: RunLoop.main)
        .removeDuplicates(by: { $0.0 == $1.0 && $0.1 == $1.1 })
        .sink { [weak self] _ in
            self?.filterClothes()
        }
        .store(in: &cancellables)
}
```

**Filtrage combiné**:
```swift
private func filterClothes() {
    var result = clothes
    
    // Filtre par catégorie
    if selectedCategory != "All" {
        result = result.filter { $0.category?.lowercased() == selectedCategory.lowercased() }
    }
    
    // Filtre par recherche textuelle
    if !searchText.isEmpty {
        let query = searchText.lowercased()
        result = result.filter { clothe in
            let categoryMatch = clothe.category?.lowercased().contains(query) ?? false
            let colorMatch = clothe.color?.lowercased().contains(query) ?? false
            let styleMatch = clothe.style?.lowercased().contains(query) ?? false
            let seasonMatch = clothe.season?.lowercased().contains(query) ?? false
            
            return categoryMatch || colorMatch || styleMatch || seasonMatch
        }
    }
    
    filteredClothes = result
}
```

#### 🏗 Architecture
- **Pattern**: MVVM ViewModel
- **Réactivité**: Combine Publishers avec debounce
- **Filtrage**: Combiné (catégorie + recherche)

#### 🔧 Technologies
- Combine (`Publishers.CombineLatest`, `debounce`)
- Callback-based service (pas async/await)

#### 📦 Dépendances
- `ClothesService` (singleton)

#### ⚠️ Points d'Attention
- Utilise callbacks au lieu d'async/await (cohérence)
- Debounce de 300ms pour la recherche (performance)

#### 🧪 Tests Recommandés
- Test de fetch clothes
- Test de filtrage par catégorie
- Test de recherche textuelle
- Test de filtrage combiné
- Test de suppression

---

## 6. Vues

### 6.1 `LabasniLoginView.swift`

#### 📍 Localisation
`Labasniios/Views/Auth/LabasniLoginView.swift`

#### 🎯 Fonctionnalités
- Interface utilisateur du formulaire de connexion
- Support OAuth (Google, Apple)
- Gestion des erreurs avec snackbar
- Navigation conditionnelle

#### 🧠 Logique Métier

**Structure UI**:
```swift
struct LabasniLoginView: View {
    @StateObject private var viewModel = LoginViewModel()
    @StateObject private var appleSignInHelper = AppleSignInHelper()
    @StateObject private var googleSignInHelper = GoogleSignInHelper()
    @ObservedObject private var themeManager = ThemeManager.shared
    
    var body: some View {
        NavigationStack {
            // Logo
            // Formulaire (email, password)
            // Bouton "Log In"
            // Séparateur "OU"
            // Boutons OAuth (Google, Apple)
            // Lien "Sign up"
        }
    }
}
```

**Gestion OAuth**:
```swift
.onAppear {
    appleSignInHelper.onSuccess = { response in
        TokenManager.shared.saveToken(response.accessToken)
        profileUser = response.user
        AppPreferences.shared.saveLoginState(user: response.user)
        navigateToProfile = true
    }
}
```

#### 🏗 Architecture
- **Pattern**: SwiftUI View
- **État**: `@StateObject` pour ViewModels, `@State` pour état local
- **Thème**: Utilise `ThemeManager` pour couleurs dynamiques
- **Navigation**: `NavigationStack` avec `NavigationLink`

#### 🔧 Technologies
- SwiftUI
- Combine (via ViewModels)
- AuthenticationServices (Apple)
- GoogleSignIn SDK

#### 📦 Dépendances
- `LoginViewModel`
- `AppleSignInHelper`
- `GoogleSignInHelper`
- `ThemeManager`

#### 🧪 Tests Recommandés
- Tests UI (UITests)
- Test de navigation après login
- Test d'affichage des erreurs
- Test des boutons OAuth

---

## 📊 Résumé des Patterns et Technologies

### Patterns Architecturaux

| Pattern | Utilisation | Fichiers Exemples |
|---------|-------------|-------------------|
| **Singleton** | Services, Managers | `TokenManager`, `ThemeManager`, `AuthService` |
| **MVVM** | Architecture principale | `LoginViewModel` + `LabasniLoginView` |
| **Repository** | Abstraction données | Services (implicite) |
| **Observer** | Réactivité | `@Published`, Combine |
| **Factory** | Création objets | Helpers OAuth |

### Technologies par Couche

| Couche | Technologies |
|--------|-------------|
| **UI** | SwiftUI, Combine |
| **Business Logic** | Swift, Combine, async/await |
| **Networking** | URLSession, Socket.IO |
| **Storage** | CoreData, UserDefaults |
| **Authentication** | AuthenticationServices, GoogleSignIn |

### Dépendances Externes

| Dépendance | Version | Usage |
|-----------|---------|-------|
| GoogleSignIn-iOS | 9.0.0+ | OAuth Google |
| Socket.IO Client | master | WebSocket chat |
| Stripe iOS SDK | 25.1.0+ | Paiements |

---

## ✅ Checklist de Validation

### Architecture
- [x] Séparation MVVM claire
- [x] Services réutilisables
- [x] Gestion d'état réactive
- [ ] Injection de dépendances complète (partielle)

### Sécurité
- [x] Tokens JWT gérés
- [ ] Keychain pour tokens (actuellement UserDefaults)
- [x] Validation des champs
- [x] HTTPS pour toutes les requêtes

### Performance
- [x] Async/await (pas de blocage UI)
- [x] Debounce pour recherche
- [x] Lazy loading images
- [ ] Pagination (à vérifier)

### Tests
- [ ] Tests unitaires ViewModels
- [ ] Tests unitaires Services
- [ ] Tests UI
- [ ] Coverage > 70%

### Documentation
- [x] README.md
- [x] Commentaires code
- [x] Documentation technique
- [ ] Documentation inline complète

---

**Document généré pour la validation technique**  
**Date**: 2024  
**Version**: 1.0.0

