//
//  CoreDataManager.swift
//  Labasniios
//
//  Gestionnaire Core Data pour la persistance locale
//
//  Ce fichier gère la configuration et l'accès à Core Data pour
//  la persistance locale des données de l'application. Core Data
//  est utilisé pour stocker les favoris et autres données locales.
//
//  Architecture : Singleton pattern
//  Dépendances : CoreData, Foundation
//

import CoreData
import Foundation

/**
 * Gestionnaire Core Data pour la persistance locale
 * 
 * Cette classe implémente le pattern Singleton pour fournir un accès
 * global au stack Core Data. Elle :
 * - Initialise le NSPersistentContainer avec le modèle de données
 * - Configure la politique de merge pour éviter les conflits
 * - Fournit des méthodes pour sauvegarder les changements
 * 
 * Le contexte de vue (viewContext) est injecté dans l'environnement
 * SwiftUI pour permettre l'utilisation de @FetchRequest et autres fonctionnalités.
 * 
 * @see NSPersistentContainer pour la configuration Core Data
 */
class CoreDataManager {
    static let shared = CoreDataManager()
    
    let container: NSPersistentContainer
    
    private init() {
        container = NSPersistentContainer(name: "Labasniios")
        container.loadPersistentStores { _, error in
            if let error = error {
                print("Core Data failed to load: \(error)")
            }
        }
        container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
    }
    
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
}
