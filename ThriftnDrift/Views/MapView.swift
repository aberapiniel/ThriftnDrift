import SwiftUI
import MapKit
import SDWebImageSwiftUI

struct MapView: View {
    @StateObject private var viewModel = MapViewModel()
    @State private var selectedStore: Store?
    @State private var searchText = ""
    @State private var showingStateSelector = false
    @State private var isTransitioning = false
    @State private var viewMode: ViewMode = .map
    @State private var position: MapCameraPosition = .region(MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 35.7796, longitude: -78.6382),
        span: MKCoordinateSpan(latitudeDelta: 0.5, longitudeDelta: 0.5)
    ))
    
    private let themeColor = Color(red: 0.4, green: 0.5, blue: 0.95)
    
    enum ViewMode {
        case map
        case list
    }
    
    var body: some View {
        let _ = print("🗺 MapView body called, stores count: \(viewModel.stores.count)")
        
        NavigationView {
            VStack(spacing: 0) {
                // Search Bar and View Mode Toggle
                VStack(spacing: 8) {
                    SearchBar(text: $searchText)
                        .padding(.horizontal)
                    
                    Picker("View Mode", selection: $viewMode) {
                        Image(systemName: "map")
                            .tag(ViewMode.map)
                        Image(systemName: "list.bullet")
                            .tag(ViewMode.list)
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal)
                    .tint(ThemeManager.brandPurple)
                }
                .padding(.top, 12)
                .padding(.bottom, 4)
                .background(ThemeManager.warmOverlay.opacity(0.1))
                
                if let error = viewModel.errorMessage {
                    Text(error)
                        .foregroundColor(.red)
                        .padding()
                        .background(Color.white)
                        .cornerRadius(8)
                        .padding()
                }
                
                // Main Content
                ZStack {
                    if viewMode == .map {
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
                                updateMapRegion(animated: true)
                            }
                        }
                    } else {
                        StoreListContent(
                            stores: viewModel.stores,
                            selectedStore: $selectedStore
                        )
                    }
                    
                    // State selector button
                    VStack {
                        Spacer()
                        HStack {
                            Spacer()
                            Button(action: {
                                showingStateSelector = true
                            }) {
                                HStack(spacing: 12) {
                                    Image(systemName: "mappin.circle.fill")
                                        .font(.system(size: 20))
                                        .foregroundColor(ThemeManager.brandPurple)
                                    
                                    Text(viewModel.getAvailableStates().first { $0.code == viewModel.selectedState }?.name ?? "Select State")
                                        .font(.system(size: 16, weight: .medium))
                                        .foregroundColor(ThemeManager.textColor)
                                    
                                    Image(systemName: "chevron.up")
                                        .font(.system(size: 14, weight: .semibold))
                                        .foregroundColor(ThemeManager.textColor.opacity(0.6))
                                }
                                .padding(.horizontal, 16)
                                .padding(.vertical, 12)
                                .background(
                                    ZStack {
                                        Color.white
                                        ThemeManager.warmOverlay.opacity(0.05)
                                    }
                                )
                                .clipShape(RoundedRectangle(cornerRadius: 20))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 20)
                                        .stroke(ThemeManager.warmOverlay.opacity(0.2), lineWidth: 1)
                                )
                                .shadow(
                                    color: ThemeManager.warmOverlay.opacity(0.1),
                                    radius: 8,
                                    x: 0,
                                    y: 4
                                )
                            }
                            .padding(.trailing)
                            .padding(.bottom, 16)
                            .scaleEffect(isTransitioning ? 0.95 : 1.0)
                            .animation(.spring(response: 0.3), value: isTransitioning)
                        }
                    }
                }
            }
            .navigationBarHidden(true)
            .background(ThemeManager.backgroundStyle)
            .sheet(isPresented: $showingStateSelector) {
                StateSelectionSheet(
                    selectedState: viewModel.selectedState,
                    states: viewModel.getAvailableStates(),
                    onStateSelected: { stateCode in
                        Task {
                            withAnimation(.easeInOut(duration: 0.3)) {
                                isTransitioning = true
                            }
                            await viewModel.switchToState(stateCode)
                            updateMapRegion(animated: true)
                            withAnimation(.easeInOut(duration: 0.3)) {
                                isTransitioning = false
                            }
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
                updateMapRegion(animated: false)
            }
        }
    }
    
    private func updateMapRegion(animated: Bool = true) {
        if !viewModel.stores.isEmpty {
            let coordinates = viewModel.stores.map { $0.coordinate }
            let region = regionForCoordinates(coordinates)
            
            if animated {
                withAnimation(.easeInOut(duration: 0.3)) {
                    position = .region(MKCoordinateRegion(
                        center: region.center,
                        span: MKCoordinateSpan(
                            latitudeDelta: region.span.latitudeDelta * 2,
                            longitudeDelta: region.span.longitudeDelta * 2
                        )
                    ))
                }
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    withAnimation(.easeInOut(duration: 0.5)) {
                        position = .region(region)
                    }
                }
            } else {
                position = .region(region)
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
        
        let span = MKCoordinateSpan(
            latitudeDelta: (maxLat - minLat) * 1.5,
            longitudeDelta: (maxLon - minLon) * 1.5
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
    @State private var mapCameraIsDragging = false
    
    // Add minimum and maximum zoom levels
    private let minZoomDelta: Double = 0.001 // Maximum zoom in
    private let maxZoomDelta: Double = 50.0   // Maximum zoom out
    private let clusterRadius: Double = 50 // Points on screen
    
    private struct Cluster: Identifiable {
        let id = UUID()
        let coordinate: CLLocationCoordinate2D
        let stores: [Store]
    }
    
    private func calculateClusters() -> [Cluster] {
        guard let region = position.region else { 
            return stores.map { store in
                Cluster(coordinate: store.coordinate, stores: [store])
            }
        }
        
        // Calculate points per coordinate degree
        let height = UIScreen.main.bounds.height
        let pointsPerLatitude = height / region.span.latitudeDelta
        
        // If zoomed out too far, show individual stores
        if region.span.latitudeDelta > maxZoomDelta {
            return stores.map { store in
                Cluster(coordinate: store.coordinate, stores: [store])
            }
        }
        
        var clusters: [Cluster] = []
        var processedStores = Set<String>()
        
        for store in stores {
            if processedStores.contains(store.id) { continue }
            
            var clusterStores = [store]
            processedStores.insert(store.id)
            
            // Find nearby stores
            for otherStore in stores where !processedStores.contains(otherStore.id) {
                let distance = calculateScreenDistance(
                    from: store.coordinate,
                    to: otherStore.coordinate,
                    pointsPerLatitude: pointsPerLatitude
                )
                
                if distance <= clusterRadius {
                    clusterStores.append(otherStore)
                    processedStores.insert(otherStore.id)
                }
            }
            
            // Create cluster
            let centerCoordinate = calculateClusterCenter(stores: clusterStores)
            clusters.append(Cluster(coordinate: centerCoordinate, stores: clusterStores))
        }
        
        return clusters
    }
    
    private func calculateScreenDistance(
        from coord1: CLLocationCoordinate2D,
        to coord2: CLLocationCoordinate2D,
        pointsPerLatitude: Double
    ) -> Double {
        let latDiff = abs(coord1.latitude - coord2.latitude) * pointsPerLatitude
        let lonDiff = abs(coord1.longitude - coord2.longitude) * pointsPerLatitude
        return sqrt(latDiff * latDiff + lonDiff * lonDiff)
    }
    
    private func calculateClusterCenter(stores: [Store]) -> CLLocationCoordinate2D {
        let totalLat = stores.reduce(0.0) { $0 + $1.coordinate.latitude }
        let totalLon = stores.reduce(0.0) { $0 + $1.coordinate.longitude }
        let count = Double(stores.count)
        
        return CLLocationCoordinate2D(
            latitude: totalLat / count,
            longitude: totalLon / count
        )
    }
    
    private func zoomIn() {
        guard let region = position.region else { return }
        let newLatDelta = max(region.span.latitudeDelta * 0.5, minZoomDelta)
        let newLonDelta = max(region.span.longitudeDelta * 0.5, minZoomDelta)
        let newSpan = MKCoordinateSpan(
            latitudeDelta: newLatDelta,
            longitudeDelta: newLonDelta
        )
        withAnimation(.easeInOut(duration: 0.5)) {
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
        withAnimation(.easeInOut(duration: 0.5)) {
            position = .region(MKCoordinateRegion(center: region.center, span: newSpan))
        }
    }
    
    var body: some View {
        let _ = print("🗺 MapContent rendering with \(stores.count) stores")
        if !stores.isEmpty {
            let _ = print("🗺 First store: \(stores[0].name)")
        }
        
        let clusters = calculateClusters()
        
        Map(position: $position, interactionModes: .all) {
            UserAnnotation()
            ForEach(clusters) { cluster in
                if cluster.stores.count == 1 {
                    let store = cluster.stores[0]
                    Annotation(
                        coordinate: store.coordinate,
                        content: {
                            StoreAnnotation(store: store, isSelected: selectedStore?.id == store.id)
                                .onTapGesture {
                                    withAnimation(.easeInOut(duration: 0.3)) {
                                        selectedStore = store
                                    }
                                }
                        },
                        label: { EmptyView() }
                    )
                } else {
                    Annotation(
                        coordinate: cluster.coordinate,
                        content: {
                            ClusterAnnotation(count: cluster.stores.count)
                                .onTapGesture {
                                    let region = regionForCoordinates(
                                        cluster.stores.map { $0.coordinate }
                                    )
                                    withAnimation(.easeInOut(duration: 0.5)) {
                                        position = .region(region)
                                    }
                                }
                        },
                        label: { EmptyView() }
                    )
                }
            }
        }
        .mapStyle(.standard)
        .mapControls {
            MapCompass()
            MapScaleView()
        }
        .onMapCameraChange { context in
            // Update clusters when the map camera changes
            let _ = calculateClusters()
        }
        .overlay(alignment: .topTrailing) {
            VStack(spacing: 8) {
                Button(action: zoomIn) {
                    Image(systemName: "plus")
                        .font(.system(size: 22))
                        .foregroundColor(.white)
                        .frame(width: 44, height: 44)
                        .background(ThemeManager.brandPurple)
                        .clipShape(Circle())
                        .shadow(color: ThemeManager.warmOverlay.opacity(0.3), radius: 4, x: 0, y: 2)
                }
                .buttonStyle(ScaleButtonStyle())
                
                Button(action: zoomOut) {
                    Image(systemName: "minus")
                        .font(.system(size: 22))
                        .foregroundColor(.white)
                        .frame(width: 44, height: 44)
                        .background(ThemeManager.brandPurple)
                        .clipShape(Circle())
                        .shadow(color: ThemeManager.warmOverlay.opacity(0.3), radius: 4, x: 0, y: 2)
                }
                .buttonStyle(ScaleButtonStyle())
                
                Spacer()
                    .frame(height: 16)
                
                Button(action: { viewModel.centerOnUserLocation() }) {
                    Image(systemName: "location.fill")
                        .font(.system(size: 22))
                        .foregroundColor(.white)
                        .frame(width: 44, height: 44)
                        .background(ThemeManager.brandPurple)
                        .clipShape(Circle())
                        .shadow(color: ThemeManager.warmOverlay.opacity(0.3), radius: 4, x: 0, y: 2)
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
        
        let span = MKCoordinateSpan(
            latitudeDelta: (maxLat - minLat) * 1.5,
            longitudeDelta: (maxLon - minLon) * 1.5
        )
        
        return MKCoordinateRegion(center: center, span: span)
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

// Update StoreAnnotation to support clustering
struct StoreAnnotation: View {
    let store: Store
    let isSelected: Bool
    
    var body: some View {
        VStack(spacing: 4) {
            ZStack {
                Circle()
                    .fill(ThemeManager.warmOverlay.opacity(0.1))
                    .frame(width: 44, height: 44)
                    .shadow(color: ThemeManager.warmOverlay.opacity(0.3), radius: 4, x: 0, y: 2)
                
                Circle()
                    .stroke(ThemeManager.brandPurple, lineWidth: 2)
                    .frame(width: 44, height: 44)
                
                Image(systemName: "storefront.fill")
                    .font(.system(size: 20))
                    .foregroundColor(ThemeManager.brandPurple)
            }
            .scaleEffect(isSelected ? 1.2 : 1.0)
            .animation(.spring(response: 0.3), value: isSelected)
            
            if isSelected {
                Text(store.name)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(ThemeManager.textColor)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(ThemeManager.warmOverlay.opacity(0.1))
                    .cornerRadius(8)
                    .shadow(color: ThemeManager.warmOverlay.opacity(0.2), radius: 3, x: 0, y: 1)
                    .transition(.scale.combined(with: .opacity))
            }
        }
    }
}

// Add ClusterAnnotation view
struct ClusterAnnotation: View {
    let count: Int
    
    var body: some View {
        ZStack {
            Circle()
                .fill(ThemeManager.brandPurple)
                .frame(width: 44, height: 44)
                .shadow(color: ThemeManager.warmOverlay.opacity(0.3), radius: 4, x: 0, y: 2)
            
            Circle()
                .stroke(ThemeManager.warmOverlay.opacity(0.3), lineWidth: 2)
                .frame(width: 44, height: 44)
            
            Text("\(count)")
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(ThemeManager.warmOverlay)
        }
    }
}

struct StoreDetailSheet: View {
    let store: Store
    @Environment(\.dismiss) private var dismiss
    @Binding var isPresented: Bool
    @StateObject private var favoritesService = FavoritesService.shared
    @State private var showingPhotoSubmission = false
    
    var body: some View {
        NavigationView {
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
                    
                    // Submit Photos Button
                    Button(action: {
                        showingPhotoSubmission = true
                    }) {
                        HStack {
                            Image(systemName: "camera.fill")
                            Text("Submit Store Photos")
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(ThemeManager.warmOverlay.opacity(0.1))
                        .foregroundColor(ThemeManager.textColor)
                        .cornerRadius(12)
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 16)
                }
            }
            .background(ThemeManager.backgroundStyle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(ThemeManager.textColor.opacity(0.6))
                            .font(.system(size: 24))
                    }
                }
            }
            .sheet(isPresented: $showingPhotoSubmission) {
                StorePhotoSubmissionView(store: store)
            }
        }
    }
}

struct StoreImageView: View {
    let imageUrls: [String]
    let imageAttribution: String?
    @State private var currentPage = 0
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            if !imageUrls.isEmpty {
                ZStack(alignment: .bottom) {
                    TabView(selection: $currentPage) {
                        ForEach(imageUrls.indices, id: \.self) { index in
                            WebImage(url: URL(string: imageUrls[index]))
                                .resizable()
                                .onFailure { _ in
                                    defaultStoreImage
                                }
                                .indicator { _, _ in
                                    ProgressView()
                                }
                                .animation(.easeInOut, value: 0.5)
                                .scaledToFill()
                                .tag(index)
                        }
                    }
                    .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
                    .frame(height: 200)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    
                    // Custom page indicator
                    if imageUrls.count > 1 {
                        HStack(spacing: 8) {
                            ForEach(0..<imageUrls.count, id: \.self) { index in
                                Circle()
                                    .fill(currentPage == index ? Color.white : Color.white.opacity(0.5))
                                    .frame(width: 8, height: 8)
                            }
                        }
                        .padding(.vertical, 8)
                        .padding(.horizontal, 12)
                        .background(Color.black.opacity(0.3))
                        .cornerRadius(12)
                        .padding(.bottom, 8)
                    }
                }
                
                if let attribution = imageAttribution {
                    Text(attribution)
                        .font(.caption2)
                        .foregroundColor(.gray)
                        .padding(.horizontal, 4)
                }
            } else {
                defaultStoreImage
            }
        }
    }
    
    private var defaultStoreImage: some View {
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
        .frame(height: 200)
        .frame(maxWidth: .infinity)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(ThemeManager.brandPurple.opacity(0.3), lineWidth: 1)
        )
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
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            VStack(spacing: 8) {
                RoundedRectangle(cornerRadius: 2.5)
                    .fill(ThemeManager.textColor.opacity(0.3))
                    .frame(width: 36, height: 5)
                    .padding(.top, 8)
                
                Text("Select State")
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundColor(ThemeManager.textColor)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(ThemeManager.warmOverlay.opacity(0.05))
            
            // States Grid
            ScrollView {
                LazyVGrid(
                    columns: [
                        GridItem(.flexible()),
                        GridItem(.flexible())
                    ],
                    spacing: 12
                ) {
                    ForEach(states, id: \.code) { state in
                        Button(action: {
                            onStateSelected(state.code)
                        }) {
                            VStack(spacing: 4) {
                                Text(state.code)
                                    .font(.system(size: 18, weight: .semibold))
                                    .foregroundColor(state.code == selectedState ? .white : ThemeManager.textColor)
                                Text(state.name)
                                    .font(.system(size: 12))
                                    .foregroundColor(state.code == selectedState ? .white.opacity(0.9) : ThemeManager.textColor.opacity(0.7))
                                    .lineLimit(1)
                                    .minimumScaleFactor(0.8)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(state.code == selectedState ? ThemeManager.brandPurple : Color.white)
                                    .shadow(
                                        color: state.code == selectedState ? 
                                            ThemeManager.brandPurple.opacity(0.3) : 
                                            ThemeManager.warmOverlay.opacity(0.1),
                                        radius: 4,
                                        x: 0,
                                        y: 2
                                    )
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(
                                        state.code == selectedState ?
                                            Color.clear :
                                            ThemeManager.warmOverlay.opacity(0.2),
                                        lineWidth: 1
                                    )
                            )
                        }
                        .buttonStyle(ScaleButtonStyle())
                    }
                }
                .padding(16)
            }
        }
        .background(ThemeManager.backgroundStyle)
    }
}

struct StoreListContent: View {
    let stores: [Store]
    @Binding var selectedStore: Store?
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                ForEach(stores) { store in
                    StoreListItem(store: store)
                        .onTapGesture {
                            selectedStore = store
                        }
                }
            }
            .padding()
        }
        .background(ThemeManager.backgroundStyle)
    }
}

struct StoreListItem: View {
    let store: Store
    
    var body: some View {
        HStack(spacing: 12) {
            // Store icon
            ZStack {
                Circle()
                    .fill(ThemeManager.warmOverlay.opacity(0.1))
                    .frame(width: 50, height: 50)
                    .shadow(color: ThemeManager.warmOverlay.opacity(0.2), radius: 3)
                
                Image(systemName: "bag.fill")
                    .font(.system(size: 24))
                    .foregroundColor(ThemeManager.brandPurple)
            }
            
            // Store info
            VStack(alignment: .leading, spacing: 4) {
                Text(store.name)
                    .font(.headline)
                    .foregroundColor(ThemeManager.textColor)
                Text(store.address)
                    .font(.subheadline)
                    .foregroundColor(ThemeManager.textColor.opacity(0.7))
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .foregroundColor(ThemeManager.brandPurple.opacity(0.7))
        }
        .padding()
        .background(Color.white)
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(ThemeManager.warmOverlay.opacity(0.2), lineWidth: 1)
        )
        .shadow(color: ThemeManager.warmOverlay.opacity(0.1), radius: 3)
    }
} 
