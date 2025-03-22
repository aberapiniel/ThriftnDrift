import SwiftUI

struct FavoritesView: View {
    @StateObject private var favoritesService = FavoritesService.shared
    @State private var isAnimating = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Image(systemName: "heart.fill")
                                .font(.system(size: 28, weight: .semibold))
                                .foregroundColor(ThemeManager.brandPurple)
                                .shadow(color: Color.black.opacity(0.1), radius: 1, x: 0, y: 1)
                            Text("Favorites")
                                .font(.system(size: 28, weight: .bold))
                                .foregroundColor(ThemeManager.textColor)
                        }
                        
                        Text("Your curated collection of thrift stores")
                            .font(.system(size: 16))
                            .foregroundColor(ThemeManager.textColor.opacity(0.7))
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 24)
                    .padding(.top, 16)
                    .opacity(isAnimating ? 1 : 0)
                    .offset(y: isAnimating ? 0 : 20)
                    
                    if favoritesService.favoriteStores.isEmpty {
                        // Empty state with vintage style
                        VStack(spacing: 16) {
                            ZStack {
                                Circle()
                                    .fill(ThemeManager.warmOverlay.opacity(0.15))
                                    .frame(width: 80, height: 80)
                                
                                Image(systemName: "heart")
                                    .font(.system(size: 32))
                                    .foregroundColor(ThemeManager.brandPurple)
                            }
                            
                            Text("No Favorites Yet")
                                .font(.system(size: 20, weight: .semibold))
                                .foregroundColor(ThemeManager.textColor)
                            
                            Text("Start exploring and save your favorite thrift stores here")
                                .font(.system(size: 16))
                                .foregroundColor(ThemeManager.textColor.opacity(0.7))
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 32)
                            
                            NavigationLink(destination: MapView()) {
                                HStack {
                                    Image(systemName: "map.fill")
                                    Text("Explore Stores")
                                }
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.white)
                                .padding(.horizontal, 24)
                                .padding(.vertical, 12)
                                .background(
                                    LinearGradient(
                                        gradient: Gradient(colors: [
                                            ThemeManager.brandPurple,
                                            ThemeManager.brandLightPurple
                                        ]),
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .cornerRadius(20)
                                .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 40)
                        .background(
                            ZStack {
                                Color.white
                                ThemeManager.warmOverlay.opacity(0.05)
                            }
                        )
                        .cornerRadius(20)
                        .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
                        .padding(.horizontal, 24)
                        .opacity(isAnimating ? 1 : 0)
                        .offset(y: isAnimating ? 0 : 20)
                    } else {
                        // Favorite stores list with vintage styling
                        VStack(spacing: 16) {
                            ForEach(favoritesService.favoriteStores) { store in
                                if let store = favoritesService.getStore(store.id) {
                                    NavigationLink(destination: StoreDetailView(store: store)) {
                                        StoreRow(store: store)
                                            .background(
                                                ZStack {
                                                    Color.white
                                                    ThemeManager.warmOverlay.opacity(0.05)
                                                }
                                                .cornerRadius(15)
                                            )
                                            .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
                                            .swipeActions(edge: .trailing) {
                                                Button(role: .destructive) {
                                                    withAnimation {
                                                        favoritesService.removeFavorite(store)
                                                    }
                                                } label: {
                                                    Label("Remove", systemImage: "heart.slash.fill")
                                                }
                                            }
                                    }
                                    .opacity(isAnimating ? 1 : 0)
                                    .offset(y: isAnimating ? 0 : 20)
                                }
                            }
                        }
                        .padding(.horizontal, 24)
                    }
                }
                .padding(.vertical, 16)
            }
            .background(ThemeManager.backgroundStyle)
            .navigationBarHidden(true)
            .onAppear {
                withAnimation(.easeOut(duration: 0.5)) {
                    isAnimating = true
                }
            }
            .onDisappear {
                isAnimating = false
            }
        }
    }
} 