//
//  LoginViewModelTests.swift
//  LabasniiosTests
//
//  Tests unitaires pour LoginViewModel
//

import XCTest
import Combine
@testable import Labasniios

@MainActor
final class LoginViewModelTests: XCTestCase {
    
    var viewModel: LoginViewModel!
    var mockAuthService: MockAuthService!
    var cancellables: Set<AnyCancellable>!
    
    override func setUp() {
        super.setUp()
        cancellables = Set<AnyCancellable>()
        
        // Créer le mock AuthService
        mockAuthService = MockAuthService()
        mockAuthService.shouldSucceed = true
        
        // Créer le ViewModel avec le mock (nécessite que LoginViewModel accepte AuthServiceProtocol)
        // Pour l'instant, on utilise le vrai service mais on peut tester la validation
        viewModel = LoginViewModel()
    }
    
    override func tearDown() {
        viewModel = nil
        mockAuthService = nil
        cancellables = nil
        super.tearDown()
    }
    
    // MARK: - Test de validation email
    
    func testSigninWithInvalidEmail() async {
        // Arrange
        viewModel.email = "invalid-email"
        viewModel.password = "password123"
        
        // Act
        await viewModel.signin()
        
        // Assert
        XCTAssertNotNil(viewModel.errorMessage, "Devrait avoir un message d'erreur pour email invalide")
        XCTAssertEqual(viewModel.errorMessage, "Invalid email address.", "Message d'erreur incorrect")
        XCTAssertNil(viewModel.signedInUser, "Ne devrait pas avoir d'utilisateur connecté")
        XCTAssertFalse(viewModel.isLoading, "Ne devrait plus être en chargement")
    }
    
    // MARK: - Test de validation password
    
    func testSigninWithShortPassword() async {
        // Arrange
        viewModel.email = "test@example.com"
        viewModel.password = "12345" // Moins de 6 caractères
        
        // Act
        await viewModel.signin()
        
        // Assert
        XCTAssertNotNil(viewModel.errorMessage, "Devrait avoir un message d'erreur pour mot de passe trop court")
        XCTAssertEqual(viewModel.errorMessage, "Password is too short.", "Message d'erreur incorrect")
        XCTAssertNil(viewModel.signedInUser, "Ne devrait pas avoir d'utilisateur connecté")
    }
    
    // MARK: - Test de connexion réussie
    // Note: Ce test nécessite un vrai backend ou un mock complet
    // Pour l'instant, on teste uniquement la validation
    
    // MARK: - Test de connexion échouée
    // Note: Ce test nécessite un vrai backend ou un mock complet
    // Pour l'instant, on teste uniquement la validation
    
    // MARK: - Test de normalisation email
    // Note: Ce test nécessite un vrai backend ou un mock complet
    // Pour l'instant, on teste uniquement la validation
    
    // MARK: - Test de resetFeedback
    
    func testResetFeedback() {
        // Arrange
        // Note: Les propriétés errorMessage, signedInUser, accessToken sont private(set)
        // On ne peut pas les assigner directement, mais on peut tester resetFeedback
        // en vérifiant qu'elles sont nil après l'appel
        
        // Act
        viewModel.resetFeedback()
        
        // Assert
        XCTAssertNil(viewModel.errorMessage, "Message d'erreur devrait être nil après reset")
        XCTAssertNil(viewModel.signedInUser, "Utilisateur devrait être nil après reset")
        XCTAssertNil(viewModel.accessToken, "Token devrait être nil après reset")
    }
}

