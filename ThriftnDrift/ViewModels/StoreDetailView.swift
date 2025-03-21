//
//  StoreDetailView.swift
//  ThriftnDrift
//
//  Created by Piniel Abera on 3/11/25.
//

import SwiftUI
import MapKit
import SDWebImageSwiftUI

struct StoreDetailView: View {
    let store: Store
    @Environment(\.dismiss) private var dismiss
    @StateObject private var favoritesService = FavoritesService.shared
    private let themeColor = Color(red: 0.4, green: 0.5, blue: 0.95)
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                // Store Image or Placeholder
                if let firstImage = store.imageUrls.first {
                    WebImage(url: URL(string: firstImage))
                        .resizable()
                        .onFailure { _ in
                            Color.gray.opacity(0.2)
                        }
                        .indicator { _, _ in
                            ProgressView()
                        }
                        .animation(.easeInOut, value: 0.5)
                        .scaledToFill()
                        .frame(height: 200)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                } else {
                    Rectangle()
                        .fill(Color.gray.opacity(0.2))
                        .frame(height: 200)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    Text(store.name)
                        .font(.title)
                        .fontWeight(.bold)
                    
                    Text(store.address)
                        .foregroundColor(.secondary)
                    
                    HStack {
                        Text(store.priceRange)
                        Text("•")
                        Text(store.categories.joined(separator: ", "))
                    }
                    .foregroundColor(.secondary)
                    
                    Text(store.description)
                        .padding(.top, 8)
                    
                    HStack {
                        Label("\(store.rating, specifier: "%.1f")", systemImage: "star.fill")
                        Text("(\(store.reviewCount) reviews)")
                    }
                    .foregroundColor(.orange)
                }
                .padding(.horizontal)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: {
                    withAnimation {
                        if favoritesService.isFavorite(store) {
                            favoritesService.removeFavorite(store)
                        } else {
                            favoritesService.addFavorite(store)
                        }
                    }
                }) {
                    Image(systemName: favoritesService.isFavorite(store) ? "heart.fill" : "heart")
                        .foregroundColor(themeColor)
                }
            }
        }
        .accentColor(themeColor)
    }
}

// End of file
