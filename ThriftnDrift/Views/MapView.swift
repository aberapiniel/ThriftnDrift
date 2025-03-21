import SwiftUI
import MapKit
import SDWebImageSwiftUI

struct MapView: View {
    @StateObject private var viewModel = MapViewModel()
    @State private var selectedStore: Store?
    @State private var searchText = ""
    @State private var showingStateSelector = false
    @State private var position: MapCameraPosition = .region(MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 35.7796, longitude: -78.6382),
        span: MKCoordinateSpan(latitudeDelta: 0.5, longitudeDelta: 0.5)
    ))
    
    private let themeColor = Color(red: 0.4, green: 0.5, blue: 0.95)
    
    var body: some View {
        let _ = print("🗺 MapView body called, stores count: \(viewModel.stores.count)")
        
        NavigationView {
            ZStack {
                MapContent(
                    position: $position,
                    selectedStore: $selectedStore,
                    stores: viewModel.stores,
                    isLoading: viewModel.isLoading,
                    viewModel: viewModel
                )
                .ignoresSafeArea(edges: [.horizontal, .bottom])
                .onChange(of: viewModel.stores) { newStores in
                    print("🗺 Stores updated in MapView, new count: \(newStores.count)")
                    if !newStores.isEmpty {
                        print("🗺 First store in updated list: \(newStores[0].name)")
                        updateMapRegion()
                    }
                }
                
                VStack(spacing: 0) {
                    // Search Bar
                    SearchBar(text: $searchText)
                        .padding(.horizontal)
                        .padding(.top, 12)
                        .padding(.bottom, 4)
                    
                    if let error = viewModel.errorMessage {
                        Text(error)
                            .foregroundColor(.red)
                            .padding()
                            .background(Color.white)
                            .cornerRadius(8)
                            .padding()
                    }
                    
                    Spacer()
                    
                    // State selector button
                    HStack {
                        Spacer()
                        Button(action: {
                            showingStateSelector = true
                        }) {
                            HStack {
                                Text(viewModel.getAvailableStates().first { $0.code == viewModel.selectedState }?.name ?? "Select State")
                                    .fontWeight(.medium)
                                Image(systemName: "chevron.up.chevron.down")
                                    .font(.caption)
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 12)
                            .background(themeColor)
                            .foregroundColor(.white)
                            .cornerRadius(20)
                            .shadow(radius: 2)
                        }
                        .padding(.trailing)
                        .padding(.bottom, 8)
                    }
                }
            }
            .navigationBarHidden(true)
            .sheet(isPresented: $showingStateSelector) {
                StateSelectionSheet(
                    selectedState: viewModel.selectedState,
                    states: viewModel.getAvailableStates(),
                    onStateSelected: { stateCode in
                        Task {
                            await viewModel.switchToState(stateCode)
                        }
                        showingStateSelector = false
                    }
                )
                .presentationDetents([.height(300)])
            }
        }
        .onChange(of: searchText) { newValue in
            Task {
                await viewModel.searchStores(query: newValue)
            }
        }
        .sheet(item: $selectedStore) { store in
            StoreDetailSheet(store: store, isPresented: Binding(
                get: { selectedStore != nil },
                set: { if !$0 { selectedStore = nil } }
            ))
            .presentationDetents([.medium, .large])
        }
        .onAppear {
            Task {
                viewModel.checkLocationAuthorization()
                await viewModel.initializeStores()
                updateMapRegion()
            }
        }
    }
    
    private func updateMapRegion() {
        if !viewModel.stores.isEmpty {
            let coordinates = viewModel.stores.map { $0.coordinate }
            let region = regionForCoordinates(coordinates)
            
            // Reset zoom level first
            position = .region(MKCoordinateRegion(
                center: region.center,
                span: MKCoordinateSpan(latitudeDelta: 10, longitudeDelta: 10)
            ))
            
            // Then animate to the correct region after a short delay
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                withAnimation(.easeInOut(duration: 0.5)) {
                    position = .region(region)
                }
            }
        }
    }
    
    private func regionForCoordinates(_ coordinates: [CLLocationCoordinate2D]) -> MKCoordinateRegion {
        var minLat = coordinates[0].latitude
        var maxLat = coordinates[0].latitude
        var minLon = coordinates[0].longitude
        var maxLon = coordinates[0].longitude
        
        for coordinate in coordinates {
            minLat = min(minLat, coordinate.latitude)
            maxLat = max(maxLat, coordinate.latitude)
            minLon = min(minLon, coordinate.longitude)
            maxLon = max(maxLon, coordinate.longitude)
        }
        
        let center = CLLocationCoordinate2D(
            latitude: (minLat + maxLat) / 2,
            longitude: (minLon + maxLon) / 2
        )
        
        // Calculate the span with some padding
        let latDelta = (maxLat - minLat) * 1.5
        let lonDelta = (maxLon - minLon) * 1.5
        
        // Ensure minimum span to avoid too much zoom
        let span = MKCoordinateSpan(
            latitudeDelta: max(latDelta, 0.5),
            longitudeDelta: max(lonDelta, 0.5)
        )
        
        return MKCoordinateRegion(center: center, span: span)
    }
}

struct MapContent: View {
    @Binding var position: MapCameraPosition
    @Binding var selectedStore: Store?
    let stores: [Store]
    let isLoading: Bool
    let viewModel: MapViewModel
    
    // Add minimum and maximum zoom levels
    private let minZoomDelta: Double = 0.001 // Maximum zoom in
    private let maxZoomDelta: Double = 50.0   // Maximum zoom out
    
    private func zoomIn() {
        guard let region = position.region else { return }
        let newLatDelta = max(region.span.latitudeDelta * 0.5, minZoomDelta)
        let newLonDelta = max(region.span.longitudeDelta * 0.5, minZoomDelta)
        let newSpan = MKCoordinateSpan(
            latitudeDelta: newLatDelta,
            longitudeDelta: newLonDelta
        )
        withAnimation(.easeInOut(duration: 0.3)) {
            position = .region(MKCoordinateRegion(center: region.center, span: newSpan))
        }
    }
    
    private func zoomOut() {
        guard let region = position.region else { return }
        let newLatDelta = min(region.span.latitudeDelta * 2.0, maxZoomDelta)
        let newLonDelta = min(region.span.longitudeDelta * 2.0, maxZoomDelta)
        let newSpan = MKCoordinateSpan(
            latitudeDelta: newLatDelta,
            longitudeDelta: newLonDelta
        )
        withAnimation(.easeInOut(duration: 0.3)) {
            position = .region(MKCoordinateRegion(center: region.center, span: newSpan))
        }
    }
    
    var body: some View {
        let _ = print("🗺 MapContent rendering with \(stores.count) stores")
        if !stores.isEmpty {
            let _ = print("🗺 First store: \(stores[0].name)")
        }
        
        Map(position: $position) {
            UserAnnotation()
            ForEach(stores) { store in
                Annotation(store.name, coordinate: store.coordinate) {
                    StoreAnnotation(store: store, isSelected: selectedStore?.id == store.id)
                        .onTapGesture {
                            selectedStore = store
                        }
                }
            }
        }
        .mapStyle(.standard)
        .mapControls {
            MapCompass()
            MapScaleView()
        }
        .overlay(alignment: .topTrailing) {
            VStack(spacing: 8) {
                Button(action: zoomIn) {
                    Image(systemName: "plus")
                        .font(.system(size: 22))
                        .foregroundColor(.white)
                        .frame(width: 44, height: 44)
                        .background(Color(red: 0.4, green: 0.5, blue: 0.95))
                        .clipShape(Circle())
                        .shadow(color: Color.black.opacity(0.2), radius: 5, x: 0, y: 2)
                }
                .buttonStyle(ScaleButtonStyle())
                
                Button(action: zoomOut) {
                    Image(systemName: "minus")
                        .font(.system(size: 22))
                        .foregroundColor(.white)
                        .frame(width: 44, height: 44)
                        .background(Color(red: 0.4, green: 0.5, blue: 0.95))
                        .clipShape(Circle())
                        .shadow(color: Color.black.opacity(0.2), radius: 5, x: 0, y: 2)
                }
                .buttonStyle(ScaleButtonStyle())
                
                Spacer()
                    .frame(height: 16)  // Add space between zoom and navigation buttons
                
                Button(action: { viewModel.centerOnUserLocation() }) {
                    Image(systemName: "location.fill")
                        .font(.system(size: 22))
                        .foregroundColor(.white)
                        .frame(width: 44, height: 44)
                        .background(Color(red: 0.4, green: 0.5, blue: 0.95))
                        .clipShape(Circle())
                        .shadow(color: Color.black.opacity(0.2), radius: 5, x: 0, y: 2)
                }
                .buttonStyle(ScaleButtonStyle())
            }
            .padding(.trailing)
            .padding(.top, 70)
        }
        .overlay(alignment: .center) {
            if isLoading {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle())
                    .scaleEffect(1.5)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color.black.opacity(0.2))
            }
        }
    }
}

// Add a custom button style for better touch feedback
struct ScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.9 : 1.0)
            .animation(.easeInOut(duration: 0.2), value: configuration.isPressed)
    }
}

struct StoreAnnotation: View {
    let store: Store
    let isSelected: Bool
    
    var body: some View {
        VStack(spacing: 4) {
            ZStack {
                Circle()
                    .fill(Color.white)
                    .frame(width: 40, height: 40)
                    .shadow(color: Color.black.opacity(0.2), radius: 3, x: 0, y: 2)
                
                Image(systemName: "bag.fill")
                    .font(.system(size: 20))
                    .foregroundColor(Color(red: 0.4, green: 0.5, blue: 0.95))
            }
            
            if isSelected {
                Text(store.name)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.black)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.white)
                    .cornerRadius(8)
                    .shadow(color: Color.black.opacity(0.1), radius: 2, x: 0, y: 1)
            }
        }
    }
}

struct StoreDetailSheet: View {
    let store: Store
    @Environment(\.dismiss) private var dismiss
    @Binding var isPresented: Bool
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    StoreImageView(imageUrl: store.imageUrls.first)
                    StoreInfoView(store: store)
                    ContactSection(store: store)
                    ActionButtonsView(store: store)
                }
                .padding()
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.gray)
                            .font(.system(size: 24))
                    }
                }
            }
        }
    }
}

struct StoreImageView: View {
    let imageUrl: String?
    
    var body: some View {
        if let firstImage = imageUrl {
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
    }
}

struct StoreInfoView: View {
    let store: Store
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(store.name)
                .font(.title2)
                .fontWeight(.bold)
            
            Text(store.address)
                .font(.subheadline)
                .foregroundColor(.gray)
            
            if !store.categories.isEmpty {
                CategoryScrollView(categories: store.categories)
            }
            
            RatingView(rating: store.rating, reviewCount: store.reviewCount, priceRange: store.priceRange)
        }
    }
}

struct CategoryScrollView: View {
    let categories: [String]
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(categories, id: \.self) { category in
                    Text(category.capitalized)
                        .font(.caption)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(12)
                }
            }
        }
    }
}

struct RatingView: View {
    let rating: Double
    let reviewCount: Int
    let priceRange: String
    
    var body: some View {
        HStack {
            if rating > 0 {
                HStack(spacing: 4) {
                    Image(systemName: "star.fill")
                        .foregroundColor(.yellow)
                    Text(String(format: "%.1f", rating))
                    Text("(\(reviewCount))")
                        .foregroundColor(.gray)
                }
            }
            
            Spacer()
            
            Text(priceRange)
                .foregroundColor(.gray)
        }
        .font(.subheadline)
    }
}

struct ContactSection: View {
    let store: Store
    
    var body: some View {
        if store.phoneNumber != nil || store.instagram != nil || store.tiktok != nil || store.website != nil || store.facebook != nil {
            VStack(alignment: .leading, spacing: 12) {
                Text("Contact & Social")
                    .font(.headline)
                    .padding(.top, 8)
                
                ContactButtons(store: store)
                SocialMediaIcons(store: store)
            }
            .padding(.vertical, 8)
        }
    }
}

struct ContactButtons: View {
    let store: Store
    
    var body: some View {
        VStack(spacing: 8) {
            if let phone = store.phoneNumber {
                Button(action: {
                    if let url = URL(string: "tel:\(phone.replacingOccurrences(of: " ", with: ""))") {
                        UIApplication.shared.open(url)
                    }
                }) {
                    HStack {
                        Image(systemName: "phone.circle.fill")
                            .font(.system(size: 24))
                        Text(phone)
                            .font(.system(size: 16))
                        Spacer()
                    }
                    .foregroundColor(.blue)
                    .padding(.vertical, 8)
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
                            .font(.system(size: 24))
                        Text("Visit Website")
                            .font(.system(size: 16))
                        Spacer()
                    }
                    .foregroundColor(.teal)
                    .padding(.vertical, 8)
                }
            }
        }
    }
}

struct SocialMediaIcons: View {
    let store: Store
    
    var body: some View {
        if store.instagram != nil || store.tiktok != nil || store.facebook != nil {
            HStack(spacing: 20) {
                if let instagram = store.instagram {
                    Link(destination: URL(string: "https://instagram.com/\(instagram.replacingOccurrences(of: "@", with: ""))")!) {
                        Image("Instagram")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 32, height: 32)
                    }
                }
                
                if let tiktok = store.tiktok {
                    Link(destination: URL(string: "https://tiktok.com/@\(tiktok.replacingOccurrences(of: "@", with: ""))")!) {
                        Image("TikTok")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 32, height: 32)
                    }
                }
                
                if let facebook = store.facebook {
                    Link(destination: URL(string: "https://facebook.com/\(facebook)")!) {
                        Image("Facebook")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 32, height: 32)
                    }
                }
            }
            .padding(.top, 4)
        }
    }
}

struct ActionButtonsView: View {
    let store: Store
    @StateObject private var favoritesService = FavoritesService.shared
    
    var body: some View {
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
                .background(Color(red: 0.4, green: 0.5, blue: 0.95))
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
                .background(favoritesService.isFavorite(store) ? Color(red: 0.4, green: 0.5, blue: 0.95) : Color.white)
                .foregroundColor(favoritesService.isFavorite(store) ? .white : Color(red: 0.4, green: 0.5, blue: 0.95))
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color(red: 0.4, green: 0.5, blue: 0.95), lineWidth: 1)
                )
            }
        }
    }
}

// New view for state selection sheet
struct StateSelectionSheet: View {
    let selectedState: String
    let states: [(code: String, name: String)]
    let onStateSelected: (String) -> Void
    private let themeColor = Color(red: 0.4, green: 0.5, blue: 0.95)
    
    var body: some View {
        VStack(spacing: 0) {
            Text("Select State")
                .font(.title2)
                .fontWeight(.bold)
                .padding(.vertical, 20)
            
            ScrollView {
                VStack(spacing: 0) {
                    ForEach(states, id: \.code) { state in
                        Button(action: {
                            onStateSelected(state.code)
                        }) {
                            HStack {
                                Text(state.name)
                                    .font(.title3)
                                    .foregroundColor(.primary)
                                Spacer()
                                if state.code == selectedState {
                                    Image(systemName: "checkmark")
                                        .foregroundColor(themeColor)
                                        .font(.system(size: 20, weight: .medium))
                                }
                            }
                            .padding(.horizontal, 24)
                            .padding(.vertical, 16)
                            .background(
                                state.code == selectedState ?
                                themeColor.opacity(0.1) :
                                Color.clear
                            )
                        }
                        
                        if state.code != states.last?.code {
                            Divider()
                                .padding(.horizontal, 24)
                        }
                    }
                }
                .padding(.vertical, 8)
            }
        }
        .background(Color(UIColor.systemBackground))
    }
} 
