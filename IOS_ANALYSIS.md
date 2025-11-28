# 📱 Analyse de l'Application iOS Labasni

**Version**: 1.0.0  
**Plateforme**: iOS 17.x  
**Framework**: SwiftUI + Combine  
**Architecture**: MVVM

---

## 📁 Structure du Projet

```
Labasniios/
├── Models/
│   ├── DTOs/              # Data Transfer Objects
│   │   ├── AuthDTO.swift
│   │   ├── SubscriptionDTO.swift
│   │   └── JSONDecoder+ISO8601.swift
│   └── Entities/          # Modèles de données
│       ├── User.swift
│       ├── Clothe.swift
│       ├── Outfit.swift
│       ├── Store.swift
│       ├── Conversation.swift
│       └── ChatMessage.swift
│
├── Services/              # Couche d'accès aux données
│   ├── Auth/
│   │   ├── AuthService.swift
│   │   ├── AppleSignInHelper.swift
│   │   └── GoogleSignInHelper.swift
│   ├── Clothes/
│   │   └── ClothesService.swift
│   ├── Outfits/
│   │   ├── OutfitsService.swift
│   │   └── FavoritesService.swift
│   ├── Store/
│   │   ├── StoreService.swift
│   │   ├── CartService.swift
│   │   ├── PaymentService.swift
│   │   └── ChatService.swift
│   ├── Subscriptions/
│   │   └── SubscriptionService.swift
│   └── Profile/
│       └── ProfileService.swift
│
├── ViewModels/            # Logique métier et état
│   ├── Auth/
│   │   ├── LoginViewModel.swift
│   │   ├── SignupViewModel.swift
│   │   └── ForgotPasswordViewModel.swift
│   ├── Dressing/
│   │   └── DressingViewModel.swift
│   ├── Outfits/
│   │   └── OutfitsViewModel.swift
│   ├── Store/
│   │   ├── StoreViewModel.swift
│   │   ├── PaymentViewModel.swift
│   │   ├── ChatViewModel.swift
│   │   └── ChatDetailViewModel.swift
│   ├── Subscription/
│   │   └── SubscriptionViewModel.swift
│   ├── Avatar/
│   │   └── AvatarViewModel.swift
│   └── Profile/
│       └── SettingsViewModel.swift
│
├── Views/                 # Interface utilisateur
│   ├── MainTabView.swift  # Navigation principale
│   ├── Auth/
│   │   ├── LabasniLoginView.swift
│   │   ├── LabasniSignupView.swift
│   │   ├── LabasniForgotPasswordView.swift
│   │   ├── OtpEntrySheet.swift
│   │   ├── PinEntrySheet.swift
│   │   └── ResetPasswordSheet.swift
│   ├── Dressing/
│   │   ├── DressingView.swift
│   │   ├── PhotoGuidePopupView.swift
│   │   ├── DetectionResultView.swift
│   │   ├── ClothingDetailSheet.swift
│   │   └── AIAnalysisLoadingView.swift
│   ├── Outfits/
│   │   ├── OutfitsView.swift
│   │   ├── FavoritesView.swift
│   │   ├── SuggestionCard.swift
│   │   └── StyleSelectionPopup.swift
│   ├── Store/
│   │   ├── StoreView.swift
│   │   ├── CartView.swift
│   │   ├── ChatView.swift
│   │   ├── ChatDetailView.swift
│   │   ├── AddToStoreSheet.swift
│   │   ├── DiscoverItemDetailSheet.swift
│   │   ├── EditStorePopup.swift
│   │   └── PaymentSheetView.swift
│   ├── Settings/
│   │   ├── SettingsView.swift
│   │   └── BalanceTopUpSheet.swift
│   ├── Packs/
│   │   ├── PackProfileCard.swift
│   │   ├── SubscriptionPlansView.swift
│   │   ├── SubscriptionDetailView.swift
│   │   └── GenericLimitPaywallView.swift
│   ├── Avatar/
│   │   ├── AvatarView.swift
│   │   ├── CameraPreview.swift
│   │   └── CameraOverlayView.swift
│   └── Intro/
│       ├── LabasniIntroView.swift
│       └── LaunchSplashView.swift
│
└── Utils/                 # Utilitaires
    ├── APIConstants.swift
    ├── TokenManager.swift
    ├── ThemeManager.swift
    ├── AppPreferences.swift
    ├── NetworkError.swift
    ├── CoreDataManager.swift
    ├── StripeConfig.swift
    ├── SocketManager.swift
    ├── CategoryColors.swift
    └── NavigationTheme.swift
```

---

## 🏗️ Architecture

### **Pattern: MVVM (Model-View-ViewModel)**

- **Models**: Entités de données (`Clothe`, `User`, `Store`, etc.) + DTOs
- **Views**: Composants SwiftUI déclaratifs
- **ViewModels**: Gestion d'état avec `@Published` et `ObservableObject`
- **Services**: Couche d'accès aux APIs (REST, WebSocket)

### **Gestion d'état**

- **Combine**: Publishers, Subscribers pour la réactivité
- **@Published**: Propriétés observables dans les ViewModels
- **@StateObject / @ObservedObject**: Injection de dépendances SwiftUI
- **NotificationCenter**: Communication entre composants

---

## 🎨 Thème et Personnalisation

### **ThemeManager**
- **Mode**: Light / Dark / System
- **Variant**: Pink (Female) / Blue (Male)
- **Couleurs dynamiques** basées sur le genre de l'utilisateur:
  - **Pink Theme** (Femme):
    - Primary: `#CA3C66`
    - Secondary: `#DB6A8F`
    - Teal: `#4AA3A2`
  - **Blue Theme** (Homme):
    - Primary: `#4AA3A2`
    - Secondary: `#6BC4C3`
    - Teal: `#CA3C66`

---

## 🔑 Fonctionnalités Principales

### **1. Authentification**
- ✅ Login/Signup avec email/password
- ✅ Google Sign In
- ✅ Apple Sign In
- ✅ Forgot Password (OTP via email)
- ✅ JWT Token Management (`TokenManager`)

### **2. Dressing (Wardrobe)**
- ✅ Affichage des vêtements en grille
- ✅ Filtrage par catégorie (All, Top, Bottom, Dress, Shoes, Accessory, Jacket)
- ✅ Recherche textuelle
- ✅ Détection IA via `/detect` (upload image multipart)
- ✅ PhotoGuidePopupView (tips avant capture)
- ✅ DetectionResultView (affichage résultats + édition)
- ✅ Suppression de vêtements
- ⚠️ **MANQUE**: Vérification de quota avant détection
- ⚠️ **MANQUE**: Affichage de `SubscriptionPlansView` quand quota dépassé

### **3. Outfits (Tenues)**
- ✅ Génération de suggestions
- ✅ Favoris
- ✅ Sélection de style

### **4. Store**
- ✅ Liste des articles (My Items / Discover)
- ✅ Ajout d'articles au store
- ✅ Panier (`CartManager` avec CoreData)
- ✅ Chat avec WebSocket (`ChatSocketManager`)
- ✅ Paiement Stripe (`PaymentService`)
- ✅ Création de commandes après achat

### **5. Subscriptions (Packs)**
- ✅ Affichage du pack actuel (`PackProfileCard`)
- ✅ Statistiques d'usage (clothesDetection, outfitSuggestions, storeSelling)
- ✅ `SubscriptionPlansView` (Free, Premium, Pro Seller)
- ✅ `SubscriptionDetailView` (détails + paiement Stripe)
- ✅ Vérification de quotas (`SubscriptionService.canDetectClothes()`)
- ⚠️ **MANQUE**: Intégration dans le flux de détection

### **6. Settings**
- ✅ Édition du profil
- ✅ Upload photo de profil
- ✅ Thème (Light/Dark/System)
- ✅ Color Theme (Pink/Blue)
- ✅ Balance Top-Up avec Stripe
- ✅ Change Password
- ✅ Delete Account

### **7. Avatar 3D**
- ✅ Caméra pour capture
- ✅ Sélection de vêtements

---

## 🔌 Intégrations

### **Stripe**
- Configuration: `StripeConfig.shared.initialize()`
- Utilisé pour:
  - Top-up de balance
  - Paiement d'abonnements (Premium, Pro Seller)
- Service: `PaymentService.swift`

### **Cloudinary**
- Upload d'images (avatars, vêtements)
- Utilisé dans `ProfileService` et `ClothesService`

### **Socket.IO**
- Chat en temps réel (`ChatSocketManager`)
- Namespace: `/chat`
- Événements: `message`, `typing`, `join`, etc.

### **CoreData**
- Panier local (`CartManager`)
- Persistence: `CoreDataManager.shared`

---

## 📡 API Endpoints Utilisés

### **Auth**
- `POST /auth/signin`
- `POST /auth/signup`
- `POST /auth/google`
- `POST /auth/apple`
- `POST /auth/forgot-password`
- `POST /auth/verify-otp`
- `POST /auth/reset-password`
- `POST /auth/verify-email`

### **Clothes**
- `GET /cloth/my`
- `POST /cloth`
- `DELETE /cloth/:id`
- `POST /detect` (détection IA avec multipart/form-data)

### **Outfits**
- `GET /outfits/my`
- `POST /outfits/generate`
- `POST /outfits` (create)
- `DELETE /outfits/:id`

### **Store**
- `GET /store`
- `GET /store/my`
- `POST /store`
- `PATCH /store/:id`
- `DELETE /store/:id`
- `POST /store/payment-intent`
- `POST /store/purchase/:id`

### **Subscriptions**
- `GET /subscriptions/me`
- `GET /subscriptions/me/stats`
- `GET /subscriptions/quota/clothes-detection`
- `GET /subscriptions/quota/outfit-generation`
- `GET /subscriptions/quota/store-selling`
- `POST /subscriptions/purchase/:plan` (simulation)
- ⚠️ **MANQUE**: `PATCH /subscriptions/me` (déjà implémenté dans Android)

### **Profile**
- `GET /auth/profile`
- `PATCH /auth/profile`
- `PATCH /auth/profile/photo`
- `DELETE /auth/profile/photo`
- `POST /auth/balance/topup`

### **Orders** (nouveau - pas encore intégré iOS)
- `POST /orders`
- `GET /orders`

---

## ⚠️ Points d'Amélioration / Manquants

### **1. Détection de Vêtements - Quota**
❌ **Problème actuel**: 
- La détection se fait sans vérification de quota préalable
- Pas d'affichage de `SubscriptionPlansView` si quota dépassé

✅ **Solution nécessaire**:
- Vérifier le quota avant d'ouvrir `ImageSourceSheet` (après "Got it")
- Afficher `SubscriptionPlansView` si quota dépassé
- Détecter les erreurs 403/quota dans `DetectionResultView.saveClotheToDatabase()`

### **2. Orders (Commandes)**
❌ **Manquant**:
- Pas d'accès à l'historique des commandes
- Pas d'affichage dans Settings

✅ **À ajouter**:
- Bouton/carte "Order History" dans `SettingsView`
- Vue `OrdersHistoryView` avec liste des commandes
- Service `OrdersService.swift` avec endpoints POST/GET `/orders`

### **3. Subscription Upgrade**
❌ **Backend changé**:
- L'endpoint est maintenant `PATCH /subscriptions/me` (au lieu de `POST /subscriptions/upgrade/:plan`)
- Le body doit contenir `{ "plan": "PREMIUM" }` ou `{ "plan": "PRO_SELLER" }`

✅ **À mettre à jour**:
- `SubscriptionService.purchasePlan()` doit utiliser le nouveau endpoint
- Ou créer une nouvelle méthode `updateSubscription(plan:)`

---

## 📝 Flow de Détection Actuel

1. **Bouton "+"** → `showPhotoGuide = true`
2. **PhotoGuidePopupView** affiche les tips
3. **"Got it!"** → `showImageSourceSheet = true`
4. **ImageSourceSheet** → Choix Caméra/Galerie
5. **Image sélectionnée** → `uploadAndDetect(image:)`
6. **POST /detect** → Réponse avec `detection_result` et `image_url`
7. **DetectionResultView** → Affichage résultats + édition
8. **"Add to Wardrobe"** → `saveClotheToDatabase()`
9. **POST /cloth** → Sauvegarde en base

**Problème**: Pas de vérification de quota à l'étape 3 (après "Got it!")

---

## 🎯 Comparaison avec Android

### **Fonctionnalités présentes dans Android mais manquantes iOS:**

1. ✅ **Orders (Commandes)**
   - Android: `OrdersHistoryView` + bouton dans Settings
   - iOS: ❌ Manquant

2. ✅ **Quota Check dans Détection**
   - Android: Vérifie quota après "Got it" → affiche `ViewPackages` si dépassé
   - iOS: ❌ Pas de vérification

3. ✅ **Subscription Upgrade (nouveau endpoint)**
   - Android: Utilise `PATCH /subscriptions/me`
   - iOS: Utilise encore `POST /subscriptions/purchase/:plan`

---

## 🛠️ Technologies Utilisées

- **Swift**: 5.9
- **SwiftUI**: Interface déclarative
- **Combine**: Programmation réactive
- **URLSession**: Appels réseau
- **Socket.IO**: Chat temps réel
- **Stripe SDK**: Paiements
- **CoreData**: Stockage local (panier)
- **AVFoundation**: Caméra (Avatar)
- **PhotosUI**: Sélection d'images

---

## 📊 Services Principaux

### **AuthService**
- Authentification complète (login, signup, OAuth)
- Gestion JWT tokens
- Forgot password flow

### **ClothesService**
- `fetchMyClothes()`: Récupération des vêtements
- `addClotheAsync()`: Ajout avec originalDetection
- `deleteClothe()`: Suppression

### **SubscriptionService**
- `getMySubscription()`: Abonnement actuel
- `getUsageStats()`: Statistiques d'usage
- `canDetectClothes()`, `canGenerateOutfit()`, `canSellItem()`: Vérification quotas
- `purchasePlan()`: Achat d'abonnement (⚠️ à mettre à jour)

### **StoreService**
- `fetchAllStoreItems()`: Découvrir
- `fetchMyStore()`: Mes articles
- `createStoreItem()`: Créer un article
- `updateStore()`, `updateStoreSize()`, `updateStorePrice()`: Mises à jour
- `markAsSold()`: Marquer comme vendu
- `deleteStoreItem()`: Suppression

### **CartService (CartManager)**
- Gestion du panier avec CoreData
- Ajout/suppression d'articles
- Synchronisation avec l'utilisateur

### **PaymentService**
- Intégration Stripe
- Création de PaymentIntent
- Confirmation de paiement

---

## 🎨 Composants UI Réutilisables

### **Packs/SubscriptionPlansView**
- Affichage des 3 plans (Free, Premium, Pro)
- Navigation vers `SubscriptionDetailView` pour Premium/Pro
- Callback `onUpgradeTapped` pour chaque plan

### **Packs/PackProfileCard**
- Affichage du pack actuel
- Statistiques d'usage (progress bars)
- Bouton upgrade

### **Dressing/PhotoGuidePopupView**
- Carousel de tips photo
- Bouton "Got it!" qui déclenche la suite

### **Dressing/DetectionResultView**
- Affichage image détectée
- Sélection Category, Style, Season
- Couleur détectée par IA
- Sauvegarde vers backend

---

## 🔐 Sécurité

- **JWT Tokens**: Stockage dans `UserDefaults` via `TokenManager`
- **Authorization Header**: `Bearer {token}` sur toutes les requêtes authentifiées
- **Token Refresh**: À vérifier (probablement géré côté backend)

---

## 📱 Navigation

### **MainTabView** (Bottom Navigation)
1. **Dressing** (`tshirt` icon)
2. **Outfits** (`person.2` icon)
3. **Avatar** (`sparkles` icon - bouton central)
4. **Store** (`bag` icon)
5. **Settings** (`person.crop.circle` icon)

---

## 💾 Persistence

- **UserDefaults**: Tokens, préférences utilisateur, thème
- **CoreData**: Panier local (`CartItem` entity)
- **AppPreferences**: Singleton pour état global de l'app

---

## 🌐 Configuration API

**Base URL**: `http://192.168.216.1:3000` (configuré dans `APIConstants.baseURL`)

**Endpoints principaux**:
- `/auth/*` - Authentification
- `/cloth/*` - Gestion des vêtements
- `/detect` - Détection IA
- `/store/*` - Store et paiements
- `/subscriptions/*` - Abonnements et quotas
- `/outfits/*` - Suggestions de tenues
- `/orders/*` - Commandes (nouveau, pas encore intégré iOS)

---

## ✅ Ce qui fonctionne bien

1. ✅ Architecture MVVM claire
2. ✅ Gestion de thème dynamique (Pink/Blue selon genre)
3. ✅ Intégration Stripe fonctionnelle
4. ✅ Chat temps réel avec Socket.IO
5. ✅ Navigation fluide avec SwiftUI
6. ✅ CoreData pour panier local
7. ✅ Détection IA avec upload multipart
8. ✅ Gestion d'état réactive avec Combine

---

## 🔄 Ce qui doit être ajouté/modifié

### **1. Intégration Quota dans Détection** ⚠️ PRIORITAIRE

**Fichier**: `Views/Dressing/DressingView.swift`

**Modifications nécessaires**:
```swift
// Après "Got it!" dans PhotoGuidePopupView
.onContinue = {
    Task {
        // Vérifier le quota AVANT d'ouvrir ImageSourceSheet
        do {
            let quotaCheck = try await SubscriptionService.shared.canDetectClothes()
            if quotaCheck.allowed {
                showImageSourceSheet = true
            } else {
                // Afficher SubscriptionPlansView
                showPlansView = true
            }
        } catch {
            // En cas d'erreur, continuer quand même
            showImageSourceSheet = true
        }
    }
}
```

**Dans DetectionResultView.saveClotheToDatabase()**:
```swift
// Détecter erreur 403/quota
catch {
    if let urlError = error as? URLError,
       let httpResponse = urlError.userInfo["response"] as? HTTPURLResponse,
       httpResponse.statusCode == 403 {
        // Afficher SubscriptionPlansView
        showPlansView = true
    }
}
```

### **2. Ajout Order History** 📦

**Nouveaux fichiers à créer**:
- `Services/Orders/OrdersService.swift`
- `Views/Orders/OrdersHistoryView.swift`

**Modification SettingsView.swift**:
- Ajouter une carte "Order History" (comme Balance card)
- Navigation vers `OrdersHistoryView`

### **3. Mise à jour Subscription Upgrade**

**Fichier**: `Services/Subscriptions/SubscriptionService.swift`

**Modifier `purchasePlan()` pour utiliser**:
- `PATCH /subscriptions/me`
- Body: `{ "plan": "PREMIUM" }` ou `{ "plan": "PRO_SELLER" }`

---

## 📋 Checklist pour Synchronisation Android ↔ iOS

### ✅ Déjà synchronisé
- [x] Structure MVVM
- [x] Gestion de thème dynamique
- [x] Stripe integration
- [x] Chat temps réel
- [x] Détection IA
- [x] Store avec panier
- [x] Subscriptions (affichage)

### ❌ À synchroniser
- [ ] **Quota check dans détection** (Android ✅, iOS ❌)
- [ ] **Order History** (Android ✅, iOS ❌)
- [ ] **Subscription upgrade endpoint** (Android utilise PATCH, iOS utilise encore POST)
- [ ] **Orders API** (Android ✅, iOS ❌)

---

## 🎯 Prochaines Étapes Recommandées

1. **Immédiat**: Intégrer la vérification de quota dans le flux de détection iOS
2. **Immédiat**: Mettre à jour l'endpoint de subscription upgrade (`PATCH /subscriptions/me`)
3. **Court terme**: Ajouter Order History dans iOS (service + vue)
4. **Court terme**: Créer automatiquement une commande après achat Store (comme Android)

---

**Date d'analyse**: 28 Novembre 2025  
**Analyseur**: AI Assistant  
**Version iOS analysée**: 1.0.0

