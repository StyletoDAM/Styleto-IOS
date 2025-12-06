//
//  VTOClothe.swift
//  Labasniios
//
//  Created by Aziz on 6/12/2025.
//

import Foundation

// MARK: - VTOClothe
/// Modèle de vêtement avec support VTO
struct VTOClothe: Identifiable, Codable {
    let id: String
    let imageURL: String
    let processedImageURL: String?      // ✨ NOUVEAU : URL image détourée
    let category: String
    let season: String?
    let color: String?
    let style: String?
    let processingStatus: ProcessingStatus  // ✨ NOUVEAU : Statut traitement
    let isProcessed: Bool                   // ✨ NOUVEAU : Flag traité
    let processingError: String?            // ✨ NOUVEAU : Message d'erreur
    
    enum CodingKeys: String, CodingKey {
        case id = "_id"
        case imageURL
        case processedImageURL
        case category
        case season
        case color
        case style
        case processingStatus
        case isProcessed
        case processingError
    }
    
    // Statut de traitement
    enum ProcessingStatus: String, Codable {
        case pending = "pending"        // En attente
        case processing = "processing"  // En cours
        case ready = "ready"           // Prêt pour VTO
        case failed = "failed"         // Échec
    }
    
    /// Indique si le vêtement est prêt pour le VTO
    var isReadyForVTO: Bool {
        processingStatus == .ready && processedImageURL != nil
    }
    
    /// URL à utiliser pour le VTO (priorité à l'image traitée)
    var vtoImageURL: String {
        processedImageURL ?? imageURL
    }
}

// MARK: - Response Wrappers
struct VTOReadyClothesResponse: Codable {
    let success: Bool
    let totalItems: Int
    let data: [String: [VTOClothe]]  // Groupé par catégorie
}

struct VTOBatchResponse: Codable {
    let success: Bool
    let count: Int
    let data: [VTOClothe]
}
