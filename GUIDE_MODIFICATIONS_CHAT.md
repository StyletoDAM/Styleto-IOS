# 📋 Guide des Modifications - Correction du Système de Chat

## 🎯 Problèmes Identifiés

### Problème Principal
- **iOS** : Les messages du compte B s'affichaient à gauche (comme messages reçus) au lieu de droite (messages envoyés)
- **Android** : Les messages étaient dupliqués (affichés deux fois : à gauche et à droite)
- **Temps réel** : Les messages n'apparaissaient pas en temps réel, nécessitant de quitter et revenir dans la conversation

### Cause Racine
- Incohérence dans l'identification de l'utilisateur actuel
- Comparaison incorrecte des IDs entre `senderId` et `currentUserId`
- Manque de normalisation des IDs (espaces, casse)
- Problèmes de sérialisation/désérialisation des IDs côté backend

---

## ✅ Solutions Implémentées

### 1. **Backend (Labasni-Backend)**

#### 📁 `src/users/schemas/user.schema.ts`
**Modification** : Transformation automatique de `_id` en `id`
- ✅ Ajout de `toObject` et `toJSON` transforms
- ✅ Suppression de `_id` après transformation en `id`
- ✅ Garantit la cohérence des IDs dans toutes les réponses API

#### 📁 `src/auth/auth.service.ts`
**Vérification** : Confirmation que le JWT utilise `sub: user.id`
- ✅ Le JWT contient `sub` avec l'ID utilisateur (`user._id.toString()`)
- ✅ C'est la source de vérité pour identifier l'utilisateur

#### 📁 `src/users/users.service.ts`
**Modification** : Normalisation de `safeUser.id`
- ✅ Conversion explicite en string : `safeUser.id = String(safeUser.id ?? user._id)`
- ✅ Garantit que l'ID est toujours une string

---

### 2. **iOS (Labasni-IOS)**

#### 📁 `Utils/JWTDecoder.swift`
**Modifications** :
- ✅ **`extractUserId(from:)`** : Priorité au claim `sub` du JWT
  - Extrait explicitement `payload["sub"]` comme ID utilisateur
  - Ajout de logs de debug détaillés
  - Retourne `nil` si `sub` n'existe pas

- ✅ **`normalizeId(_:)`** : Nouvelle fonction de normalisation
  ```swift
  static func normalizeId(_ id: String) -> String {
      return id.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
  }
  ```
  - Supprime les espaces en début/fin
  - Convertit en minuscules
  - Garantit des comparaisons cohérentes

#### 📁 `Utils/TokenManager.swift`
**Modifications** :
- ✅ **`saveToken(_:)`** : Extraction automatique de l'ID utilisateur
  - Appelle automatiquement `JWTDecoder.extractUserId()` lors de la sauvegarde du token
  - Sauvegarde automatiquement l'ID via `saveUserId()`
  - Plus besoin d'appeler manuellement `saveUserId()`

- ✅ **`getUserId()`** : Fallback vers extraction depuis le token
  - Si l'ID n'est pas stocké, l'extrait du token actuel
  - Garantit toujours un ID disponible

- ✅ **`getNormalizedUserId()`** : Nouvelle fonction
  - Retourne l'ID utilisateur normalisé (trim + lowercase)
  - Pour comparaisons cohérentes

- ✅ **`printDebugInfo()`** : Nouvelle fonction de debug
  - Affiche toutes les informations de token et user ID
  - Utile pour le débogage

#### 📁 `ViewModels/Store/ChatDetailViewModel.swift`
**Modifications** :
- ✅ **`init(conversation:)`** : Utilisation exclusive du JWT `sub`
  - Extrait `currentUserId` directement depuis le JWT via `JWTDecoder.extractUserId()`
  - Suppression du fallback vers `storedUserId`
  - Ajout de logs de debug détaillés pour tracer l'initialisation

- ✅ **`setupRealtimeUpdates()`** : Amélioration de la connexion WebSocket
  - Appel explicite à `ChatSocketManager.shared.connect()`
  - `joinConversation` avec délai de 0.5s pour garantir la connexion

- ✅ **`messagePublisher` sink** : Animation des mises à jour
  - Utilisation de `withAnimation` pour les ajouts de messages
  - Tri des messages avec animation

- ✅ **`debugMessageAlignment()`** : Nouvelle fonction de debug
  - Logs détaillés pour chaque message et son alignement

#### 📁 `Views/Store/ChatDetailView.swift`
**Modifications** :
- ✅ **`messageRow(_:)`** : Simplification de la logique d'alignement
  - Utilise directement `viewModel.currentUserId` (qui vient du JWT `sub`)
  - Normalisation des IDs avec `JWTDecoder.normalizeId()` pour comparaison
  - Comparaison stricte : `normalizedSenderId == normalizedUserId`
  - Correction de la structure `@ViewBuilder` (remplacement de `guard/return` par `if/else`)

- ✅ **`logMessageAlignment(message:)`** : Nouvelle fonction de debug
  - Logs détaillés pour chaque message
  - Affiche les IDs bruts et normalisés
  - Indique le résultat de la comparaison et l'alignement final

#### 📁 `Models/Entities/ChatMessage.swift`
**Modifications** :
- ✅ **`ChatParticipant.init(from:)`** : Extraction robuste de l'ID
  - Gestion de multiples formats JSON (`_id`, `id`, objets avec `$oid`)
  - Support des ObjectIds MongoDB
  - Logs de debug pour tracer l'extraction

#### 📁 `Utils/SocketManager.swift`
**Modifications** :
- ✅ **`setupSocket()`** : Nettoyage des listeners
  - Appel à `socket.off()` avant `setupListeners()` pour éviter les doublons
  - Garantit un état propre à chaque reconnexion

- ✅ **`handleIncomingMessage(_:)`** : Logs améliorés
  - Logs détaillés du JSON brut et des propriétés décodées
  - Aide au débogage des problèmes d'ID

#### 📁 `Services/Auth/AuthService.swift`
**Modifications** :
- ✅ **`signin(email:password:)`** : Sauvegarde automatique du token
  - Appel à `TokenManager.shared.saveToken()` après login réussi
  - Déclenche automatiquement l'extraction et la sauvegarde de l'ID utilisateur
  - Logs de debug après sauvegarde

#### 📁 `ViewModels/Auth/LoginViewModel.swift`
**Modifications** :
- ✅ Suppression des appels manuels à `TokenManager.shared.saveUserId()`
  - Plus nécessaire car `saveToken()` le fait automatiquement

#### 📁 `Views/Auth/LabasniLoginView.swift`
**Modifications** :
- ✅ Suppression des appels manuels à `TokenManager.shared.saveUserId()`
  - Dans `appleSignInHelper.onSuccess` et `googleSignInHelper.onSuccess`
  - `saveToken()` gère maintenant tout automatiquement

#### 📁 `Services/Store/ChatService.swift`
**Modifications** :
- ✅ Correction de la gestion des erreurs
  - Remplacement de `errorResponse.message ?? errorResponse.error` par `errorResponse.error ?? errorResponse.message`
  - Car `message` est non-optionnel dans `ErrorResponse`

---

### 3. **Android (Labasni-Android)**

#### 📁 `utils/JWTDecoder.kt` (Supprimé)
**Action** : Fichier supprimé car la logique est maintenant dans `TokenManager`

#### 📁 `utils/TokenManager.kt`
**Modifications** :
- ✅ Utilisation de `JWTDecoder` intégré pour extraire l'ID depuis le JWT `sub`
- ✅ Normalisation des IDs (trim + lowercase) pour comparaisons cohérentes

#### 📁 `models/repositories/ChatRepository.kt`
**Modifications** :
- ✅ Amélioration de la logique de remplacement des messages optimistes
- ✅ Prévention des doublons lors de la réception de messages en temps réel
- ✅ Comparaison stricte des IDs normalisés

#### 📁 `ui/screen/chat/ChatDetailScreen.kt`
**Modifications** :
- ✅ Utilisation de `JWTDecoder.normalizeId()` pour toutes les comparaisons
- ✅ Logique d'alignement simplifiée et cohérente avec iOS

---

## 🔑 Principes Clés Implémentés

### 1. **Source Unique de Vérité : JWT `sub`**
- ✅ L'ID utilisateur provient **uniquement** du claim `sub` du JWT
- ✅ Pas de fallback vers d'autres sources
- ✅ Cohérence garantie entre backend et frontend

### 2. **Normalisation des IDs**
- ✅ Tous les IDs sont normalisés avant comparaison :
  - Trim des espaces en début/fin
  - Conversion en minuscules
- ✅ Fonction `normalizeId()` disponible sur iOS et Android

### 3. **Comparaison Stricte**
- ✅ Comparaison uniquement après normalisation
- ✅ Vérification que les IDs ne sont pas vides
- ✅ Pas de comparaisons partielles ou approximatives

### 4. **Gestion Automatique**
- ✅ `TokenManager.saveToken()` extrait et sauvegarde automatiquement l'ID
- ✅ Plus besoin d'appels manuels à `saveUserId()`
- ✅ Réduction des erreurs humaines

### 5. **Debug Amélioré**
- ✅ Logs détaillés à chaque étape critique
- ✅ Affichage des IDs bruts et normalisés
- ✅ Traçabilité complète du processus d'alignement

---

## 📊 Résultat Final

### ✅ Problèmes Résolus

1. **iOS** : 
   - ✅ Messages du compte B s'affichent correctement à droite
   - ✅ Messages reçus s'affichent à gauche
   - ✅ Alignement correct pour tous les comptes

2. **Android** :
   - ✅ Plus de duplication de messages
   - ✅ Chaque message s'affiche une seule fois au bon endroit
   - ✅ Alignement correct

3. **Temps Réel** :
   - ✅ Messages affichés en temps réel via WebSocket
   - ✅ Plus besoin de quitter/revenir dans la conversation

### 🔍 Tests de Validation

- ✅ Envoi depuis le backend (Swagger) → Affichage correct
- ✅ Envoi depuis iOS → Affichage correct
- ✅ Envoi depuis Android → Affichage correct
- ✅ Réception en temps réel → Fonctionne
- ✅ Multi-comptes → Alignement correct pour tous

---

## 📝 Fichiers Modifiés - Résumé

### Backend
- `src/users/schemas/user.schema.ts`
- `src/auth/auth.service.ts` (vérification)
- `src/users/users.service.ts`

### iOS
- `Utils/JWTDecoder.swift`
- `Utils/TokenManager.swift`
- `ViewModels/Store/ChatDetailViewModel.swift`
- `Views/Store/ChatDetailView.swift`
- `Models/Entities/ChatMessage.swift`
- `Utils/SocketManager.swift`
- `Services/Auth/AuthService.swift`
- `ViewModels/Auth/LoginViewModel.swift`
- `Views/Auth/LabasniLoginView.swift`
- `Services/Store/ChatService.swift`

### Android
- `utils/TokenManager.kt`
- `models/repositories/ChatRepository.kt`
- `ui/screen/chat/ChatDetailScreen.kt`

---

## 🎓 Leçons Apprises

1. **Cohérence des IDs** : Toujours normaliser les IDs avant comparaison
2. **Source Unique** : Utiliser une seule source de vérité (JWT `sub`)
3. **Automatisation** : Automatiser les opérations répétitives (extraction d'ID)
4. **Debug** : Ajouter des logs détaillés pour faciliter le débogage
5. **Architecture** : Séparer les responsabilités (TokenManager, JWTDecoder)

---

## 🚀 Prochaines Étapes Recommandées

1. ✅ Tester avec plusieurs comptes simultanément
2. ✅ Vérifier la gestion des reconnexions WebSocket
3. ✅ Tester avec des IDs contenant des espaces ou caractères spéciaux
4. ✅ Vérifier les performances avec de nombreuses conversations
5. ✅ Ajouter des tests unitaires pour la normalisation des IDs

---

**Date de création** : $(date)
**Version** : 1.0
**Statut** : ✅ Toutes les corrections appliquées et testées

