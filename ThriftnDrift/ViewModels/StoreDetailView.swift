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
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Store Image or Placeholder
                ZStack {
                    if store.imageUrls.isEmpty {
                        ZStack {
                            Rectangle()
                                .fill(ThemeManager.warmOverlay.opacity(0.1))
                                .frame(height: 200)
                            
                            VStack(spacing: 12) {
                                Image(systemName: "camera.fill")
                                    .font(.system(size: 40))
                                    .foregroundColor(ThemeManager.brandPurple)
                                
                                Text("No Photos Yet")
                                    .font(.title3)
                                    .fontWeight(.semibold)
                                    .foregroundColor(ThemeManager.textColor)
                                
                                Text("Photos of this store will be added soon")
                                    .font(.subheadline)
                                    .foregroundColor(ThemeManager.textColor.opacity(0.7))
                                    .multilineTextAlignment(.center)
                                    .padding(.horizontal)
                            }
                        }
                    } else {
                        StoreImageView(imageUrls: store.imageUrls, imageAttribution: store.imageAttribution)
                    }
                }
                .background(ThemeManager.warmOverlay.opacity(0.05))
                
                // Store Information
                VStack(alignment: .leading, spacing: 20) {
                    // Name and Basic Info
                    VStack(alignment: .leading, spacing: 8) {
                        Text(store.name)
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(ThemeManager.textColor)
                        
                        Text(store.address)
                            .font(.subheadline)
                            .foregroundColor(ThemeManager.textColor.opacity(0.7))
                    }
                    
                    // Categories
                    if !store.categories.isEmpty {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                ForEach(store.categories, id: \.self) { category in
                                    Text(category)
                                        .font(.subheadline)
                                        .foregroundColor(ThemeManager.textColor.opacity(0.8))
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 6)
                                        .background(ThemeManager.warmOverlay.opacity(0.1))
                                        .cornerRadius(12)
                                }
                            }
                        }
                    }
                    
                    // Store Features Section
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Store Features")
                            .font(.title3)
                            .fontWeight(.semibold)
                            .foregroundColor(ThemeManager.textColor)
                        
                        HStack(spacing: 24) {
                            if store.hasClothingSection {
                                FeatureItem(icon: "tshirt", text: "Clothing", isActive: true)
                            }
                            if store.hasFurnitureSection {
                                FeatureItem(icon: "chair", text: "Furniture", isActive: true)
                            }
                            if store.hasElectronicsSection {
                                FeatureItem(icon: "desktopcomputer", text: "Electronics", isActive: true)
                            }
                        }
                    }
                    .padding(.vertical, 8)
                    
                    // Contact Section
                    if store.phoneNumber != nil || store.website != nil {
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Contact")
                                .font(.title3)
                                .fontWeight(.semibold)
                                .foregroundColor(ThemeManager.textColor)
                            
                            if let phone = store.phoneNumber,
                               let phoneURL = URL(string: "tel:\(phone)") {
                                Link(destination: phoneURL) {
                                    HStack {
                                        Image(systemName: "phone")
                                        Text(phone)
                                    }
                                    .foregroundColor(ThemeManager.brandPurple)
                                }
                            }
                            
                            if let website = store.website,
                               let websiteURL = URL(string: website) {
                                Link(destination: websiteURL) {
                                    HStack {
                                        Image(systemName: "globe")
                                        Text(website)
                                            .lineLimit(1)
                                    }
                                    .foregroundColor(ThemeManager.brandPurple)
                                }
                            }
                        }
                        .padding(.vertical, 8)
                    }
                }
                .padding(.horizontal, 24)
                
                // Action Buttons
                HStack(spacing: 20) {
                    Button(action: {
                        // Handle directions
                        if let url = URL(string: "maps://?address=\(store.address.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")") {
                            UIApplication.shared.open(url)
                        }
                    }) {
                        HStack {
                            Image(systemName: "map")
                            Text("Directions")
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(ThemeManager.brandPurple)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                    }
                    
                    Button(action: {
                        withAnimation {
                            favoritesService.toggleFavorite(store)
                        }
                    }) {
                        HStack {
                            Image(systemName: favoritesService.isFavorite(store) ? "heart.fill" : "heart")
                            Text(favoritesService.isFavorite(store) ? "Favorited" : "Favorite")
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(
                            favoritesService.isFavorite(store) ?
                            ThemeManager.brandLightPurple : ThemeManager.warmOverlay.opacity(0.1)
                        )
                        .foregroundColor(
                            favoritesService.isFavorite(store) ?
                            .white : ThemeManager.brandPurple
                        )
                        .cornerRadius(12)
                    }
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 16)
            }
        }
        .background(ThemeManager.backgroundStyle)
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct FeatureItem: View {
    let icon: String
    let text: String
    let isActive: Bool
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 24))
                .foregroundColor(isActive ? ThemeManager.brandPurple : ThemeManager.textColor.opacity(0.3))
            Text(text)
                .font(.caption)
                .foregroundColor(isActive ? ThemeManager.textColor : ThemeManager.textColor.opacity(0.3))
        }
    }
}

// End of file
