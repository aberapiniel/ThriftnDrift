import Foundation
import SwiftUI

@MainActor
class FavoritesService: ObservableObject {
    static let shared = FavoritesService()
    @Published private(set) var favoriteStores: [Store] = []
    
    private let favoritesKey = "favoriteStores"
    
    private init() {
        loadFavorites()
    }
    
    private func loadFavorites() {
        if let data = UserDefaults.standard.data(forKey: favoritesKey),
           let stores = try? JSONDecoder().decode([Store].self, from: data) {
            favoriteStores = stores
        }
    }
    
    private func saveFavorites() {
        if let data = try? JSONEncoder().encode(favoriteStores) {
            UserDefaults.standard.set(data, forKey: favoritesKey)
        }
    }
    
    func addFavorite(_ store: Store) {
        guard !favoriteStores.contains(where: { $0.id == store.id }) else { return }
        favoriteStores.append(store)
        saveFavorites()
    }
    
    func removeFavorite(_ store: Store) {
        favoriteStores.removeAll { $0.id == store.id }
        saveFavorites()
    }
    
    func isFavorite(_ store: Store) -> Bool {
        favoriteStores.contains { $0.id == store.id }
    }
} 