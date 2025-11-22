// CartManager.swift
import Foundation
import CoreData
import Combine

class CartManager: ObservableObject {
    static let shared = CartManager()
    
    private let context = PersistenceController.shared.container.viewContext
    
    @Published var cartItems: [CartItem] = []
    
    private init() {
        fetchCartItems()
    }
    
    func fetchCartItems() {
        let request: NSFetchRequest<CartItem> = CartItem.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(keyPath: \CartItem.addedAt, ascending: false)]
        
        do {
            cartItems = try context.fetch(request)
        } catch {
            print("Erreur fetch panier: \(error)")
        }
    }
    
    func addToCart(storeItem: Store) {
        // Éviter les doublons
        let request: NSFetchRequest<CartItem> = CartItem.fetchRequest()
        request.predicate = NSPredicate(format: "storeItemID == %@", storeItem.id)
        
        if let existing = try? context.fetch(request).first {
            print("Déjà dans le panier")
            return
        }
        
        let newItem = CartItem(context: context)
        newItem.id = UUID().uuidString
        newItem.storeItemID = storeItem.id
        newItem.title = storeItem.clothe?.category?.capitalized ?? "Article"
        newItem.size = storeItem.size
        newItem.price = storeItem.price
        newItem.imageURL = storeItem.clothe?.imageURL
        newItem.addedAt = Date()
        
        saveContext()
        fetchCartItems()
    }
    
    func removeFromCart(_ cartItem: CartItem) {
        context.delete(cartItem)
        saveContext()
        fetchCartItems()
    }
    
    func clearCart() {
        for item in cartItems {
            context.delete(item)
        }
        saveContext()
        fetchCartItems()
    }
    
    var totalPrice: Double {
        cartItems.reduce(0) { $0 + $1.price }
    }
    
    var itemCount: Int {
        cartItems.count
    }
    
    private func saveContext() {
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                print("Erreur sauvegarde panier: \(error)")
            }
        }
    }
}
