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
                StoreImageView(imageUrls: store.imageUrls, imageAttribution: store.imageAttribution)
                
                // Store Information
                VStack(alignment: .leading, spacing: 8) {
                    Text(store.name)
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text(store.address)
                        .font(.subheadline)
                        .foregroundColor(.gray)
                    
                    if !store.categories.isEmpty {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                ForEach(store.categories, id: \.self) { category in
                                    Text(category)
                                        .font(.caption)
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 6)
                                        .background(Color.gray.opacity(0.1))
                                        .cornerRadius(12)
                                }
                            }
                        }
                    }
                    
                    // Rating and Price
                    HStack {
                        if store.rating > 0 {
                            HStack(spacing: 4) {
                                Image(systemName: "star.fill")
                                    .foregroundColor(.yellow)
                                Text(String(format: "%.1f", store.rating))
                                Text("(\(store.reviewCount))")
                                    .foregroundColor(.gray)
                            }
                        }
                        
                        Spacer()
                        
                        Text(store.priceRange)
                            .foregroundColor(.gray)
                    }
                    .font(.subheadline)
                }
                .padding(.horizontal)
                
                // Store Features
                VStack(alignment: .leading, spacing: 12) {
                    Text("Store Features")
                        .font(.headline)
                    
                    Grid(alignment: .leading, horizontalSpacing: 16, verticalSpacing: 8) {
                        GridRow {
                            FeatureItem(
                                icon: "tshirt",
                                text: "Clothing",
                                isEnabled: store.hasClothingSection
                            )
                            FeatureItem(
                                icon: "chair",
                                text: "Furniture",
                                isEnabled: store.hasFurnitureSection
                            )
                        }
                        
                        GridRow {
                            FeatureItem(
                                icon: "desktopcomputer",
                                text: "Electronics",
                                isEnabled: store.hasElectronicsSection
                            )
                        }
                    }
                }
                .padding()
                .background(Color.gray.opacity(0.05))
                .cornerRadius(12)
                .padding(.horizontal)
                
                // Contact Information
                if store.phoneNumber != nil || store.website != nil {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Contact")
                            .font(.headline)
                        
                        if let phone = store.phoneNumber {
                            Button(action: {
                                if let url = URL(string: "tel:\(phone)") {
                                    UIApplication.shared.open(url)
                                }
                            }) {
                                HStack {
                                    Image(systemName: "phone.fill")
                                    Text(phone)
                                }
                                .foregroundColor(.primary)
                            }
                        }
                        
                        if let website = store.website {
                            Button(action: {
                                if let url = URL(string: website) {
                                    UIApplication.shared.open(url)
                                }
                            }) {
                                HStack {
                                    Image(systemName: "globe")
                                    Text(website)
                                }
                                .foregroundColor(.primary)
                            }
                        }
                    }
                    .padding()
                    .background(Color.gray.opacity(0.05))
                    .cornerRadius(12)
                    .padding(.horizontal)
                }
                
                // Action Buttons
                HStack(spacing: 16) {
                    Button(action: {
                        let url = URL(string: "maps://?q=\(store.name)&ll=\(store.coordinate.latitude),\(store.coordinate.longitude)")
                        if let url = url {
                            UIApplication.shared.open(url)
                        }
                    }) {
                        HStack {
                            Image(systemName: "map.fill")
                            Text("Directions")
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(themeColor)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                    }
                    
                    Button(action: {
                        withAnimation {
                            if favoritesService.isFavorite(store) {
                                favoritesService.removeFavorite(store)
                            } else {
                                favoritesService.addFavorite(store)
                            }
                        }
                    }) {
                        HStack {
                            Image(systemName: favoritesService.isFavorite(store) ? "heart.fill" : "heart")
                            Text(favoritesService.isFavorite(store) ? "Favorited" : "Favorite")
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(favoritesService.isFavorite(store) ? themeColor : Color.white)
                        .foregroundColor(favoritesService.isFavorite(store) ? .white : themeColor)
                        .cornerRadius(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(themeColor, lineWidth: 1)
                        )
                    }
                }
                .padding(.horizontal)
            }
            .padding(.vertical)
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: { dismiss() }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.gray)
                }
            }
        }
    }
}

struct FeatureItem: View {
    let icon: String
    let text: String
    let isEnabled: Bool
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(isEnabled ? .green : .gray)
            Text(text)
                .foregroundColor(isEnabled ? .primary : .gray)
        }
    }
}

// End of file
