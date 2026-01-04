# 📱 Documentation Technique - Validation Projet iOS Labasni

**Version**: 1.0.0  
**Date**: 2024  
**Plateforme**: iOS 17.0+  
**Langage**: Swift 5.9  
**Framework**: SwiftUI + Combine  
**Architecture**: MVVM (Model-View-ViewModel)

---

## 📋 Table des Matières

1. [Vue d'Ensemble du Projet](#vue-densemble-du-projet)
2. [Architecture Globale](#architecture-globale)
3. [Technologies et Dépendances](#technologies-et-dépendances)
4. [Injection de Dépendances](#injection-de-dépendances)
5. [Analyse Fichier par Fichier](#analyse-fichier-par-fichier)
6. [Tests Unitaires](#tests-unitaires)
7. [Documentation Technique](#documentation-technique)

---

## 🎯 Vue d'Ensemble du Projet

### Description
**Labasni** est une application iOS de mode et e-commerce alimentée par l'IA, permettant aux utilisateurs de :
- Gérer leur garde-robe avec détection IA des vêtements
- Recevoir des recommandations d'outfits personnalisées
- Acheter et vendre des vêtements sur une marketplace
- Communiquer en temps réel avec les vendeurs via chat
- Gérer des abonnements et paiements via Stripe

### Stack Technique Principal
- **Swift 5.9** : Langage de programmation
- **SwiftUI** : Framework UI déclaratif
- **Combine** : Programmation réactive
- **CoreData** : Persistance locale
- **URLSession** : Réseau natif avec async/await
- **Socket.IO** : Communication temps réel

---

## 🏗 Architecture Globale

### Pattern Architectural : MVVM

```
┌─────────────────────────────────────────────────────────┐
│                        VIEWS                            │
│  (SwiftUI Views - Présentation UI)                     │
│  - LabasniLoginView                                     │
│  - DressingView                                         │
│  - OutfitsView                                         │
│  - StoreView                                           │
└──────────────────┬──────────────────────────────────────┘
                   │ @StateObject / @ObservedObject
                   │ @Published properties
                   ▼
┌─────────────────────────────────────────────────────────┐
│                     VIEWMODELS                          │
│  (Logique métier - ObservableObject)                    │
│  - LoginViewModel                                       │
│  - DressingViewModel                                    │
│  - OutfitsViewModel                                     │
│  - StoreViewModel                                       │
└──────────────────┬──────────────────────────────────────┘
                   │ Dependency Injection
                   │ Service calls
                   ▼
┌─────────────────────────────────────────────────────────┐
│                      SERVICES                           │
│  (Couche d'accès aux données)                           │
│  - AuthService                                          │
│  - ClothesService                                       │
│  - OutfitsService                                       │
│  - StoreService                                         │
│  - ChatService                                          │
└──────────────────┬──────────────────────────────────────┘
                   │ API Calls / WebSocket
                   ▼
┌─────────────────────────────────────────────────────────┐
│                    BACKEND API                          │
│  (NestJS - Render.com)                                  │
│  https://labasni-backend-mh3j.onrender.com              │
└─────────────────────────────────────────────────────────┘
```

### Séparation des Responsabilités

1. **Views** : Présentation uniquement, pas de logique métier
2. **ViewModels** : Logique métier, état de l'UI, validation
3. **Services** : Communication réseau, transformation de données
4. **Models** : Structures de données (DTOs et Entities)
5. **Utils** : Helpers, managers (TokenManager, ThemeManager, etc.)

---

## 📦 Technologies et Dépendances

### Dépendances Externes (Swift Package Manager)

#### 1. **GoogleSignIn-iOS** (v9.0.0+)
- **URL**: `https://github.com/google/GoogleSignIn-iOS`
- **Usage**: Authentification OAuth avec Google
- **Implémentation**: 
  - `GoogleSignInHelper.swift` encapsule la logique
  - Utilise `GIDSignIn` pour l'authentification
  - Callback vers `AuthService` pour l'API backend

#### 2. **Socket.IO Client Swift** (master branch)
- **URL**: `https://github.com/socketio/socket.io-client-swift`
- **Usage**: Communication WebSocket temps réel pour le chat
- **Implémentation**:
  - `ChatSocketManager` (singleton) gère la connexion
  - Namespace `/chat` pour les conversations
  - Événements: `new-message`, `send-message`, `join-conversation`, `typing`

#### 3. **Stripe iOS SDK** (v25.1.0+)
- **URL**: `https://github.com/stripe/stripe-ios`
- **Modules utilisés**:
  - `Stripe` (core)
  - `StripePayments`
  - `StripePaymentSheet`
  - `StripePaymentsUI`
  - `StripeApplePay`
  - `StripeCardScan`
  - `StripeConnect`
  - `StripeFinancialConnections`
  - `StripeIdentity`
  - `StripeIssuing`
- **Usage**: Paiements sécurisés, checkout Stripe, Apple Pay

### Frameworks Natifs iOS

#### 1. **SwiftUI**
- Framework UI déclaratif
- `@State`, `@StateObject`, `@ObservedObject` pour la gestion d'état
- `@Published` pour la réactivité Combine

#### 2. **Combine**
- Programmation réactive
- `Publisher`, `Subscriber`, `Subject`
- Utilisé dans ViewModels pour les flux de données

#### 3. **CoreData**
- Persistance locale (panier, messages)
- `CoreDataManager` (singleton) gère le stack
- Modèle de données dans `Labasniios.xcdatamodeld`

#### 4. **URLSession**
- Réseau natif avec async/await
- Pas de dépendance externe (Alamofire)
- Configuration dans chaque Service

#### 5. **AuthenticationServices**
- Apple Sign-In natif
- `ASAuthorizationAppleIDCredential`
- Implémenté dans `AppleSignInHelper`

#### 6. **AVFoundation**
- Capture photo/vidéo
- Utilisé dans `AvatarView` et `DressingView`

---

## 🔌 Injection de Dépendances

### Pattern Utilisé : Singleton + Initialisation Optionnelle

L'application utilise principalement le pattern **Singleton** pour les services partagés, avec possibilité d'injection pour les tests.

### Exemples d'Implémentation

#### 1. **AuthService** (Singleton avec injection optionnelle)

```swift
@MainActor
final class AuthService: NSObject, ObservableObject {
    static let shared = AuthService()
    
    private let session: URLSession
    private let encoder: JSONEncoder
    private let decoder: JSONDecoder
    
    private override init() {
        self.session = .shared
        self.encoder = JSONEncoder()
        self.decoder = JSONDecoder()
        // Configuration...
    }
}
```

**Utilisation dans ViewModel**:
```swift
@MainActor
final class LoginViewModel: ObservableObject {
    private let authService: AuthService
    
    // Injection par défaut (singleton)
    init(authService: AuthService = AuthService.shared) {
        self.authService = authService
    }
}
```

**Avantages**:
- ✅ Facilite les tests (mock possible)
- ✅ Singleton pour usage global
- ✅ Pas de dépendance forte

#### 2. **TokenManager** (Singleton pur)

```swift
final class TokenManager {
    static let shared = TokenManager()
    private init() {}
    
    func saveToken(_ token: String) { ... }
    func getToken() -> String? { ... }
}
```

**Utilisation**:
```swift
TokenManager.shared.saveToken(response.accessToken)
```

#### 3. **ThemeManager** (Singleton avec @Published)

```swift
@MainActor
class ThemeManager: ObservableObject {
    static let shared = ThemeManager()
    
    @Published var currentTheme: Theme
    
    private init() {
        // Initialisation...
    }
}
```

**Utilisation dans View**:
```swift
@ObservedObject private var themeManager = ThemeManager.shared
```

### Services avec Injection

| Service | Pattern | Injection Possible |
|---------|---------|-------------------|
| `AuthService` | Singleton + init param | ✅ Oui (pour tests) |
| `TokenManager` | Singleton pur | ❌ Non |
| `ThemeManager` | Singleton + @Published | ❌ Non |
| `ChatSocketManager` | Singleton | ❌ Non |
| `CoreDataManager` | Singleton | ❌ Non |

### Amélioration Possible : Container de DI

Pour une meilleure testabilité, on pourrait implémenter un container de dépendances :

```swift
// Exemple conceptuel
protocol ServiceContainer {
    var authService: AuthService { get }
    var tokenManager: TokenManager { get }
}

class AppServiceContainer: ServiceContainer {
    let authService = AuthService.shared
    let tokenManager = TokenManager.shared
}

// Dans ViewModel
init(container: ServiceContainer = AppServiceContainer()) {
    self.authService = container.authService
}
```

---

## 📄 Analyse Fichier par Fichier

### 1. Point d'Entrée : `LabasniiosApp.swift`

#### Fonctionnalités
- Point d'entrée de l'application (`@main`)
- Gestion du splash screen
- Navigation conditionnelle (login vs main app)
- Gestion des deep links (Stripe checkout)
- Initialisation des singletons

#### Logique Métier
```swift
@main
struct LabasniiosApp: App {
    @StateObject private var themeManager = ThemeManager.shared
    @StateObject private var appPreferences = AppPreferences.shared
    
    var body: some Scene {
        WindowGroup {
            if appPreferences.isLoggedIn, let user = appPreferences.currentUser {
                MainTabView(user: user, onLogout: handleLogout)
            } else {
                LabasniIntroView()
            }
        }
    }
}
```

**Flux**:
1. Vérifie `AppPreferences.isLoggedIn`
2. Si connecté → `MainTabView`
3. Sinon → `LabasniIntroView` (écran d'intro/login)

#### Architecture
- **Pattern**: App Entry Point
- **Dépendances**: 
  - `ThemeManager.shared`
  - `AppPreferences.shared`
  - `CoreDataManager.shared`
  - `StripeConfig.shared`
  - `ChatSocketManager.shared`

#### Technologies
- SwiftUI `@main`
- `@StateObject` pour la réactivité
- `@UIApplicationDelegateAdaptor` pour AppDelegate

#### Deep Links
Gère les URLs `labasni://subscriptions/success` et `labasni://subscriptions/cancel` pour Stripe checkout.

---

### 2. Configuration API : `APIConstants.swift`

#### Fonctionnalités
- Centralise toutes les URLs d'API
- Base URL configurée
- Chemins d'endpoints organisés par domaine

#### Structure
```swift
enum APIConstants {
    static let baseURL = URL(string: "https://labasni-backend-mh3j.onrender.com")!
    
    // AUTH
    static let signupPath = "/auth/signup"
    static let signinPath = "/auth/signin"
    static let googleAuthPath = "/auth/google"
    static let appleAuthPath = "/auth/apple"
    
    // CLOTHES
    static let clothMePath = "/cloth/me"
    
    // OUTFITS
    static let outfitsPath = "/outfits"
    static let outfitsMyPath = "/outfits/my"
    
    // STORE
    static let storePath = "/store"
    static let storeMyPath = "/store/my"
    
    // SUBSCRIPTIONS
    static let createCheckoutSessionPath = "/subscriptions/create-checkout-session"
    static let subscriptionMePath = "/subscriptions/me"
}
```

#### Architecture
- **Pattern**: Constants Enum
- Centralisation pour faciliter la maintenance
- URL relative avec `URL(string:path, relativeTo:baseURL)`

---

### 3. Gestion des Tokens : `TokenManager.swift`

#### Fonctionnalités
- Stockage sécurisé des tokens JWT (access + refresh)
- Extraction automatique du `userId` depuis le JWT
- Normalisation des IDs pour comparaisons
- Gestion du cycle de vie des tokens

#### Logique Métier
```swift
func saveToken(_ token: String) {
    UserDefaults.standard.set(token, forKey: tokenKey)
    
    // ✨ CRITIQUE : Extraire et sauvegarder le userId du JWT automatiquement
    if let userId = JWTDecoder.extractUserId(from: token) {
        saveUserId(userId)
    }
}
```

**Flux de sauvegarde**:
1. Token reçu → sauvegarde dans UserDefaults
2. Extraction du `userId` depuis le JWT (champ `sub`)
3. Sauvegarde du `userId` pour usage ultérieur

#### Architecture
- **Pattern**: Singleton
- **Stockage**: UserDefaults (pourrait être Keychain pour plus de sécurité)
- **Dépendances**: `JWTDecoder` pour l'extraction

#### Sécurité
⚠️ **Note**: Utilise `UserDefaults` au lieu de `Keychain`. Pour production, migrer vers Keychain pour plus de sécurité.

---

### 4. Service d'Authentification : `AuthService.swift`

#### Fonctionnalités
- Authentification email/password
- OAuth Google
- OAuth Apple
- Forgot password flow (OTP)
- Refresh token automatique

#### Logique Métier
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

**Flux de connexion**:
1. Validation des champs (email, password)
2. Appel API `POST /auth/signin`
3. Réception de `SigninResponse` (user + tokens)
4. Sauvegarde des tokens via `TokenManager`
5. Callback `onSuccess` ou `onError`

#### Architecture
- **Pattern**: Service Layer + Singleton
- **Concurrence**: `@MainActor` pour thread-safety
- **Networking**: `URLSession` avec async/await
- **Décodage**: `JSONDecoder` avec stratégie snake_case

#### Gestion d'Erreurs
```swift
enum NetworkError: Error {
    case invalidURL
    case noData
    case requestFailed(Int)
    case serverMessage(String)
}
```

#### Injection de Dépendances
- Singleton par défaut : `AuthService.shared`
- Injection possible dans ViewModels pour tests

---

### 5. ViewModel de Login : `LoginViewModel.swift`

#### Fonctionnalités
- Gestion de l'état du formulaire (email, password)
- Validation des champs
- Appel au service d'authentification
- Gestion des états de chargement et d'erreur

#### Logique Métier
```swift
@MainActor
final class LoginViewModel: ObservableObject {
    @Published var email: String = ""
    @Published var password: String = ""
    @Published private(set) var isLoading: Bool = false
    @Published private(set) var errorMessage: String?
    
    private let authService: AuthService
    
    func signin() async {
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
}
```

**Flux**:
1. Utilisateur saisit email/password
2. Validation (email format, password length)
3. Appel `authService.signin()`
4. Mise à jour de l'état (`isLoading`, `errorMessage`, `signedInUser`)
5. Sauvegarde du token

#### Architecture
- **Pattern**: MVVM ViewModel
- **Réactivité**: `@Published` + Combine
- **Concurrence**: `@MainActor` (UI thread)
- **Dépendances**: `AuthService` (injecté)

#### Validation
- Email : regex `^[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$`
- Password : minimum 6 caractères

---

### 6. Vue de Login : `LabasniLoginView.swift`

#### Fonctionnalités
- Interface utilisateur du formulaire de connexion
- Support OAuth (Google, Apple)
- Gestion des erreurs avec snackbar
- Navigation conditionnelle

#### Structure UI
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

#### Architecture
- **Pattern**: SwiftUI View
- **État**: `@StateObject` pour ViewModels, `@State` pour état local
- **Thème**: Utilise `ThemeManager` pour couleurs dynamiques
- **Navigation**: `NavigationStack` avec `NavigationLink`

#### Intégration OAuth
```swift
Button {
    googleSignInHelper.signInWithGoogle(presenting: rootVC)
} label: {
    // UI du bouton Google
}
.onChange(of: googleSignInHelper.errorMessage) { message in
    if let message {
        displaySnackbar(message)
    }
}
```

**Flux OAuth**:
1. Utilisateur clique sur "Continue with Google/Apple"
2. Helper gère l'authentification native
3. Callback avec credentials
4. Appel `AuthService.authenticateWithGoogle/Apple()`
5. Sauvegarde du token
6. Navigation vers `MainTabView`

---

### 7. Gestionnaire de Thème : `ThemeManager.swift`

#### Fonctionnalités
- Gestion des thèmes Light/Dark/System
- Variantes Pink (Female) / Blue (Male)
- Mise à jour dynamique des couleurs
- Persistance des préférences

#### Logique Métier
```swift
@MainActor
class ThemeManager: ObservableObject {
    static let shared = ThemeManager()
    
    @Published var currentTheme: Theme
    @AppStorage("selectedTheme") private var selectedThemeMode: String
    
    func updateTheme() {
        let shouldUseDark: Bool
        switch themeMode {
        case .light: shouldUseDark = false
        case .dark: shouldUseDark = true
        case .system:
            // Détecte le mode système
            shouldUseDark = window.traitCollection.userInterfaceStyle == .dark
        }
        
        let variant = getThemeVariant()
        let isMale = variant == .blue
        
        currentTheme = shouldUseDark 
            ? DarkTheme(isMale: isMale) 
            : LightTheme(isMale: isMale)
    }
}
```

#### Architecture
- **Pattern**: Singleton + Observer
- **Stockage**: `@AppStorage` (UserDefaults wrapper)
- **Réactivité**: `@Published` pour mise à jour UI automatique
- **Protocol**: `Theme` pour abstraction

#### Variantes de Couleur
- **Pink (Female)** : Primaire `#CA3C66`, Secondaire `#DB6A8F`
- **Blue (Male)** : Primaire `#4AA3A2`, Secondaire `#6BC4C3`

#### Extension Color
```swift
extension Color {
    @MainActor
    static var themePrimary: Color {
        ThemeManager.shared.currentTheme.primary
    }
    // ... autres couleurs
}
```

**Usage dans Views**:
```swift
Text("Hello")
    .foregroundColor(.themePrimary)  // Couleur dynamique
```

---

### 8. Gestionnaire WebSocket : `SocketManager.swift` (ChatSocketManager)

#### Fonctionnalités
- Connexion WebSocket via Socket.IO
- Gestion des conversations en temps réel
- Envoi/réception de messages
- Indicateurs de frappe (typing)
- Reconnexion automatique

#### Logique Métier
```swift
@MainActor
final class ChatSocketManager: ObservableObject {
    static let shared = ChatSocketManager()
    
    private var manager: SocketManager!
    private var socket: SocketIOClient!
    
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
    
    func sendMessage(_ content: String, in conversationId: String) {
        let payload: [String: Any] = [
            "conversationId": conversationId,
            "content": content,
            "token": TokenManager.shared.getToken() ?? ""
        ]
        socket.emit("send-message", payload)
    }
}
```

#### Architecture
- **Pattern**: Singleton
- **Library**: Socket.IO Client Swift
- **Namespace**: `/chat`
- **Événements**:
  - `new-message` : Réception de message
  - `send-message` : Envoi de message
  - `join-conversation` : Rejoindre une conversation
  - `typing` : Indicateur de frappe

#### Gestion de Connexion
- Reconnexion automatique en cas de déconnexion
- Vérification du token avant connexion
- Mise à jour si le token change

#### Publishers Combine
```swift
private let messageSubject = PassthroughSubject<ChatMessage, Never>()
var messagePublisher: AnyPublisher<ChatMessage, Never> {
    messageSubject.eraseToAnyPublisher()
}
```

**Usage dans ViewModel**:
```swift
ChatSocketManager.shared.messagePublisher
    .sink { message in
        // Traiter le nouveau message
    }
```

---

## 🧪 Tests Unitaires

### Structure Actuelle

Le projet contient deux cibles de test :
1. **LabasniiosTests** : Tests unitaires
2. **LabasniiosUITests** : Tests UI

### Fichiers de Test

#### `LabasniiosTests.swift`
```swift
import XCTest
@testable import Labasniios

final class LabasniiosTests: XCTestCase {
    func testExample() throws {
        // TODO: Implémenter les tests
    }
}
```

### Recommandations pour Tests

#### 1. Tests de ViewModels

```swift
// Exemple : LoginViewModelTests
@MainActor
final class LoginViewModelTests: XCTestCase {
    var viewModel: LoginViewModel!
    var mockAuthService: MockAuthService!
    
    override func setUp() {
        super.setUp()
        mockAuthService = MockAuthService()
        viewModel = LoginViewModel(authService: mockAuthService)
    }
    
    func testSigninSuccess() async {
        // Given
        viewModel.email = "test@example.com"
        viewModel.password = "password123"
        mockAuthService.shouldSucceed = true
        
        // When
        await viewModel.signin()
        
        // Then
        XCTAssertNotNil(viewModel.signedInUser)
        XCTAssertNil(viewModel.errorMessage)
    }
    
    func testSigninInvalidEmail() async {
        // Given
        viewModel.email = "invalid-email"
        viewModel.password = "password123"
        
        // When
        await viewModel.signin()
        
        // Then
        XCTAssertNotNil(viewModel.errorMessage)
        XCTAssertNil(viewModel.signedInUser)
    }
}
```

#### 2. Tests de Services

```swift
final class AuthServiceTests: XCTestCase {
    var authService: AuthService!
    var mockURLSession: MockURLSession!
    
    func testSigninSuccess() async throws {
        // Mock response
        let mockData = """
        {
            "user": {...},
            "accessToken": "token123",
            "refreshToken": "refresh123"
        }
        """.data(using: .utf8)!
        
        mockURLSession.mockResponse = (mockData, HTTPURLResponse(
            url: URL(string: "https://api.example.com")!,
            statusCode: 200,
            httpVersion: nil,
            headerFields: nil
        )!)
        
        // Test
        let response = try await authService.signin(
            email: "test@example.com",
            password: "password"
        )
        
        XCTAssertEqual(response.accessToken, "token123")
    }
}
```

#### 3. Tests de TokenManager

```swift
final class TokenManagerTests: XCTestCase {
    func testSaveAndGetToken() {
        // Given
        let token = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."
        
        // When
        TokenManager.shared.saveToken(token)
        
        // Then
        XCTAssertEqual(TokenManager.shared.getToken(), token)
    }
    
    func testExtractUserIdFromToken() {
        // Given
        let token = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiI2NzhiYzEyMzQ1Njc4OSJ9..."
        
        // When
        TokenManager.shared.saveToken(token)
        let userId = TokenManager.shared.getUserId()
        
        // Then
        XCTAssertNotNil(userId)
    }
}
```

### Coverage Cible

| Composant | Coverage Cible | Priorité |
|-----------|---------------|----------|
| ViewModels | 80%+ | Haute |
| Services | 70%+ | Haute |
| Utils (TokenManager, etc.) | 90%+ | Moyenne |
| Views | 30%+ (UI Tests) | Basse |

---

## 📚 Documentation Technique

### Documentation du Code

#### Commentaires dans le Code

Le projet utilise des commentaires pour expliquer :
- Les sections critiques (`// ✨ CRITIQUE`)
- Les flux de données
- Les décisions d'architecture
- Les workarounds

**Exemple**:
```swift
// ✨ CRITIQUE : Sauvegarder le token (qui va automatiquement extraire et sauvegarder le userId du JWT)
TokenManager.shared.saveToken(response.accessToken)
```

#### Markdown Documentation

- `README.md` : Documentation générale du projet
- `IOS_ANALYSIS.md` : Analyse de l'architecture iOS
- `GUIDE_MODIFICATIONS_CHAT.md` : Guide des modifications du chat
- `RESUME_MODIFICATIONS.md` : Résumé des modifications

### Diagrammes Recommandés

#### 1. Diagramme de Séquence - Authentification

```
User -> LoginView: Saisit credentials
LoginView -> LoginViewModel: signin()
LoginViewModel -> AuthService: signin(email, password)
AuthService -> API: POST /auth/signin
API -> AuthService: SigninResponse
AuthService -> LoginViewModel: response
LoginViewModel -> TokenManager: saveToken()
LoginViewModel -> LoginView: @Published signedInUser
LoginView -> MainTabView: Navigation
```

#### 2. Diagramme de Classes - Architecture MVVM

```
┌─────────────┐
│   View      │
│ (SwiftUI)   │
└──────┬──────┘
       │ @StateObject
       ▼
┌─────────────┐
│ ViewModel   │
│(@Published) │
└──────┬──────┘
       │ Dependency
       ▼
┌─────────────┐
│  Service    │
│  (Network)  │
└─────────────┘
```

#### 3. Diagramme de Flux - Chat Temps Réel

```
User -> ChatDetailView: Envoie message
ChatDetailView -> ChatDetailViewModel: sendMessage()
ChatDetailViewModel -> ChatSocketManager: sendMessage()
ChatSocketManager -> Socket.IO: emit("send-message")
Socket.IO -> Backend: WebSocket message
Backend -> Socket.IO: broadcast("new-message")
Socket.IO -> ChatSocketManager: on("new-message")
ChatSocketManager -> Publisher: messageSubject.send()
ChatDetailViewModel -> ChatDetailView: @Published messages
```

### Documentation API

#### Endpoints Principaux

| Endpoint | Méthode | Description | Service |
|----------|---------|-------------|---------|
| `/auth/signin` | POST | Connexion | `AuthService` |
| `/auth/signup` | POST | Inscription | `AuthService` |
| `/auth/google` | POST | OAuth Google | `AuthService` |
| `/auth/apple` | POST | OAuth Apple | `AuthService` |
| `/cloth/me` | GET | Vêtements utilisateur | `ClothesService` |
| `/outfits/recommend` | POST | Recommandations IA | `OutfitsService` |
| `/store` | GET | Items du store | `StoreService` |
| `/chat/conversations` | GET | Conversations | `ChatService` |

### Guide de Contribution

#### Standards de Code

1. **Naming**:
   - Views : `*View.swift` (ex: `LabasniLoginView`)
   - ViewModels : `*ViewModel.swift` (ex: `LoginViewModel`)
   - Services : `*Service.swift` (ex: `AuthService`)
   - Utils : `*Manager.swift` ou `*Helper.swift`

2. **Structure**:
   - `@MainActor` pour les ViewModels et Services UI
   - `@Published` pour les propriétés réactives
   - `private(set)` pour les propriétés en lecture seule

3. **Error Handling**:
   - Utiliser `NetworkError` enum
   - Toujours gérer les erreurs avec `do-catch`
   - Afficher des messages utilisateur-friendly

---

## 🔍 Points d'Attention pour la Validation

### 1. Sécurité
- ⚠️ **TokenManager** utilise `UserDefaults` au lieu de `Keychain`
- ✅ Tokens JWT correctement gérés
- ✅ Validation des champs côté client
- ✅ HTTPS pour toutes les requêtes

### 2. Performance
- ✅ Utilisation d'async/await (pas de blocage UI)
- ✅ Lazy loading des images
- ✅ Cache CoreData pour le panier
- ⚠️ Pas de pagination visible pour les listes

### 3. Architecture
- ✅ Séparation claire MVVM
- ✅ Services réutilisables
- ⚠️ Injection de dépendances limitée (singletons)
- ✅ Gestion d'état réactive (Combine)

### 4. Tests
- ⚠️ Tests unitaires à implémenter
- ⚠️ Tests UI à développer
- ✅ Structure de tests présente

### 5. Maintenabilité
- ✅ Code bien structuré
- ✅ Commentaires pour sections critiques
- ✅ Documentation markdown
- ⚠️ Pas de documentation inline complète

---

## 📝 Conclusion

Le projet iOS **Labasni** suit une architecture **MVVM** solide avec :
- ✅ Séparation claire des responsabilités
- ✅ Utilisation moderne de SwiftUI et Combine
- ✅ Services bien organisés
- ✅ Gestion d'état réactive

**Points d'amélioration**:
- Migration vers Keychain pour les tokens
- Implémentation de tests unitaires
- Amélioration de l'injection de dépendances
- Documentation inline plus complète

---

**Document généré pour la validation technique**  
**Date**: 2024  
**Version**: 1.0.0

