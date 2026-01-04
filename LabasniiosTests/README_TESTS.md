# Tests Unitaires iOS - Labasni

## 📋 Vue d'ensemble

Ce dossier contient les tests unitaires pour l'application iOS Labasni.

## 📁 Structure

```
LabasniiosTests/
├── Mocks/
│   ├── MockAuthService.swift      # Mock pour AuthService
│   └── MockClothesService.swift   # Helper pour créer des Clothe dans les tests
├── LoginViewModelTests.swift       # Tests pour le login
├── DressingViewModelTests.swift    # Tests pour l'ajout de produits dans le dressing
└── README_TESTS.md                 # Ce fichier
```

## 🧪 Tests créés

### 1. LoginViewModelTests.swift

Tests unitaires pour la fonctionnalité de connexion :

- ✅ **testSigninWithInvalidEmail** : Vérifie que l'email invalide est rejeté
- ✅ **testSigninWithShortPassword** : Vérifie que le mot de passe trop court est rejeté
- ✅ **testResetFeedback** : Vérifie que les messages d'erreur sont réinitialisés

**Note** : Les tests de connexion réussie/échouée nécessitent un mock complet ou un backend fonctionnel. Pour l'instant, on teste principalement la validation côté client.

### 2. DressingViewModelTests.swift

Tests unitaires pour l'ajout de produits dans le dressing :

- ✅ **testAddClotheSuccess** : Teste l'ajout d'un vêtement via ClothesService
- ✅ **testAddClotheWithAllProperties** : Teste l'ajout avec toutes les propriétés
- ✅ **testFilterClothesByCategory** : Teste le filtrage par catégorie
- ✅ **testSearchClothesByText** : Teste la recherche textuelle
- ✅ **testDeleteClothe** : Teste la suppression d'un vêtement

**Note** : Les tests d'ajout nécessitent un backend fonctionnel ou un mock complet. Les tests de filtrage et recherche fonctionnent sans backend.

## 🛠️ Utilisation

### Exécuter tous les tests

```bash
# Dans Xcode : Cmd + U
# Ou en ligne de commande :
xcodebuild test -project Labasniios.xcodeproj -scheme Labasniios -destination 'platform=iOS Simulator,name=iPhone 17'
```

### Exécuter un test spécifique

Dans Xcode, cliquez sur le bouton ▶️ à côté du nom du test.

## 📝 Notes importantes

1. **Mocks** : Les mocks sont créés mais nécessitent une refactorisation des ViewModels pour permettre l'injection de dépendances complète.

2. **Backend** : Certains tests nécessitent un backend fonctionnel. Ils acceptent les erreurs réseau si le backend n'est pas disponible.

3. **Clothe.testClothe()** : Helper créé pour faciliter la création d'objets `Clothe` dans les tests.

## 🔄 Améliorations futures

- [ ] Refactoriser `DressingViewModel` pour permettre l'injection de `ClothesService`
- [ ] Créer des mocks complets pour tous les services
- [ ] Ajouter des tests d'intégration
- [ ] Ajouter des tests UI avec XCTest UI Testing

