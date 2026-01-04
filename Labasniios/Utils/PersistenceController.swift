//
//  PersistenceController.swift
//  Labasniios
//
//  Contrôleur de persistance Core Data
//
//  Ce fichier gère la configuration et l'accès à Core Data pour
//  la persistance locale des données de l'application. Core Data
//  est utilisé pour stocker les favoris et autres données locales.
//
//  Architecture : Structure avec singleton pattern
//  Dépendances : CoreData, Foundation
//

import CoreData

/**
 * Contrôleur de persistance Core Data
 * 
 * Cette structure gère la configuration et l'accès au stack Core Data.
 * Elle fournit un singleton pour un accès global au contexte de persistance.
 * 
 * Fonctionnalités :
 * - Initialisation du NSPersistentContainer avec le modèle de données
 * - Configuration de la politique de merge pour éviter les conflits
 * - Support du mode in-memory pour les tests
 * - Méthodes pour sauvegarder les changements
 * 
 * Le contexte de vue (viewContext) est utilisé pour toutes les opérations
 * de lecture/écriture et est automatiquement synchronisé avec le parent.
 * 
 * @see NSPersistentContainer pour la configuration Core Data
 * @see NSMergeByPropertyObjectTrumpMergePolicy pour la résolution de conflits
 */
struct PersistenceController {
    static let shared = PersistenceController()

    let container: NSPersistentContainer

    init(inMemory: Bool = false) {
        container = NSPersistentContainer(name: "Labasniios") // ← même nom que ton .xcdatamodeld
        
        if inMemory {
            container.persistentStoreDescriptions.first?.url = URL(fileURLWithPath: "/dev/null")
        }
        
        container.loadPersistentStores { description, error in
            if let error = error {
                fatalError("Core Data failed to load: \(error.localizedDescription)")
            }
        }
        
        container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        container.viewContext.automaticallyMergesChangesFromParent = true
    }
    
    func save() {
        let context = container.viewContext
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                print("Erreur sauvegarde: \(error)")
            }
        }
    }
}
