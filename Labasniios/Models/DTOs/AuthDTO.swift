//
//  AuthDTO.swift
//  Labasniios
//
//  Data Transfer Objects pour l'authentification
//
//  Ce fichier définit toutes les structures de données utilisées pour
//  les opérations d'authentification (signin, signup, password reset, etc.).
//  Ces DTOs sont utilisés pour la sérialisation/désérialisation JSON
//  lors des communications avec le backend.
//
//  Architecture : Data Transfer Objects (DTOs)
//  Dépendances : Foundation, Codable
//

import Foundation

// MARK: - Signin / Signup

/**
 * Réponse de connexion (signin)
 * 
 * Cette structure contient les données retournées par le serveur
 * après une connexion réussie, incluant le token d'accès et le
 * refresh token pour maintenir la session active.
 * 
 * @property user Informations de l'utilisateur connecté
 * @property accessToken Token JWT pour l'authentification des requêtes
 * @property refreshToken Token pour renouveler l'access token lorsqu'il expire
 */
struct SigninResponse: Codable {
    let user: User
    let accessToken: String
    let refreshToken: String // ✨ NOUVEAU : Refresh token pour renouveler l'access token
}

/**
 * Réponse d'inscription (signup)
 * 
 * Cette structure contient les données retournées par le serveur
 * après une inscription réussie. Un token temporaire est fourni
 * pour la vérification de l'email.
 * 
 * @property message Message de confirmation
 * @property tempToken Token temporaire pour la vérification d'email
 */
struct SignupResponse: Codable {
    let message: String
    let tempToken: String
}

// MARK: - Forgot Password Flow

/**
 * Réponse de demande de réinitialisation de mot de passe
 * 
 * Cette structure contient les informations retournées après une
 * demande de réinitialisation de mot de passe, incluant un numéro
 * de téléphone masqué pour confirmation.
 * 
 * @property message Message de confirmation
 * @property maskedPhoneNumber Numéro de téléphone masqué (ex: "******1234")
 * @property expiresAt Date d'expiration du code OTP
 */
struct ForgotPasswordResponse: Codable {
    let message: String
    let maskedPhoneNumber: String?
    let expiresAt: Date?
}

// MARK: - Verify Otp

/**
 * Réponse de vérification du code OTP
 * 
 * Cette structure contient le token de réinitialisation obtenu
 * après vérification réussie du code OTP envoyé par email/SMS.
 * 
 * @property message Message de confirmation
 * @property resetToken Token de réinitialisation pour changer le mot de passe
 */
struct VerifyOtpResponse: Codable {
    let message: String
    let resetToken: String
}

// MARK: - Reset Password

/**
 * Réponse de réinitialisation de mot de passe
 * 
 * Cette structure confirme que le mot de passe a été réinitialisé
 * avec succès.
 * 
 * @property message Message de confirmation
 */
struct ResetPasswordResponse: Codable {
    let message: String
}

// MARK: - Verify Email

/**
 * Réponse de vérification d'email
 * 
 * Cette structure contient les informations utilisateur après
 * vérification réussie de l'adresse email.
 * 
 * @property message Message de confirmation
 * @property user Informations utilisateur vérifiées
 */
struct VerifyEmailResponse: Codable {
    let message: String
    let user: UserResponse
}

/**
 * Réponse utilisateur simplifiée
 * 
 * Structure simplifiée contenant uniquement les informations
 * essentielles d'un utilisateur (utilisée pour la vérification d'email).
 * 
 * @property id Identifiant utilisateur
 * @property fullName Nom complet
 * @property email Adresse email
 * @property gender Genre
 */
struct UserResponse: Codable {
    let id: String
    let fullName: String
    let email: String
    let gender: String
}
