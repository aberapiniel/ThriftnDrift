import SwiftUI

struct FavoritesView: View {
    @StateObject private var favoritesService = FavoritesService.shared
    @State private var searchText = ""
    
    private let themeColor = Color(red: 0.4, green: 0.5, blue: 0.95)
    
    private var filteredStores: [Store] {
        if searchText.isEmpty {
            return favoritesService.favoriteStores
        }
        return favoritesService.favoriteStores.filter { store in
            store.name.localizedCaseInsensitiveContains(searchText) ||
            store.address.localizedCaseInsensitiveContains(searchText) ||
            store.categories.contains { $0.localizedCaseInsensitiveContains(searchText) }
        }
    }
    
    var body: some View {
        NavigationView {
            Group {
                if favoritesService.favoriteStores.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "heart.fill")
                            .font(.system(size: 64))
                            .foregroundColor(themeColor.opacity(0.3))
                        Text("No Favorite Stores Yet")
                            .font(.title2)
                            .fontWeight(.medium)
                            .foregroundColor(.gray)
                        Text("Add stores to your favorites to see them here")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color(UIColor.systemGray6))
                } else {
                    List {
                        ForEach(filteredStores) { store in
                            NavigationLink(destination: StoreDetailView(store: store)) {
                                StoreRow(store: store)
                                    .swipeActions(edge: .trailing) {
                                        Button(role: .destructive) {
                                            withAnimation {
                                                favoritesService.removeFavorite(store)
                                            }
                                        } label: {
                                            Label("Remove", systemImage: "heart.slash.fill")
                                        }
                                        .tint(themeColor)
                                    }
                            }
                        }
                    }
                    .searchable(text: $searchText, prompt: "Search favorites")
                }
            }
            .navigationTitle("Favorites")
        }
        .accentColor(themeColor) // This will style the back button and other navigation elements
    }
} 