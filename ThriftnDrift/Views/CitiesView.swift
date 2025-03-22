import SwiftUI
import SDWebImageSwiftUI

struct CitiesView: View {
    @StateObject private var citiesService = CitiesService.shared
    @StateObject private var storeService = StoreService.shared
    @State private var searchText = ""
    @State private var selectedTags: Set<String> = []
    @State private var selectedCity: City?
    @State private var showingStateSelector = false
    @State private var isStateTransitioning = false
    
    private let columns = [
        GridItem(.flexible(), spacing: 16),
        GridItem(.flexible(), spacing: 16)
    ]
    
    private let themeColor = Color(red: 0.4, green: 0.5, blue: 0.95)
    
    private var filteredCities: [City] {
        citiesService.searchCities(query: searchText)
    }
    
    private let allTags = [
        "Urban", "Vintage", "Boutiques", "Upscale", "Consignment",
        "Eco-Friendly", "Diverse", "Local", "Artistic", "Sustainable",
        "Coastal", "Casual", "Beach", "College", "Affordable",
        "Traditional", "Modern", "Arts", "Student"
    ]
    
    var body: some View {
        VStack(spacing: 0) {
            // State Selection ScrollView
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 16) {
                    ForEach(citiesService.getAvailableStates(), id: \.code) { state in
                        StateButton(
                            name: state.name,
                            code: state.code,
                            isSelected: state.code == citiesService.selectedState,
                            action: {
                                withAnimation(.spring(response: 0.3)) {
                                    isStateTransitioning = true
                                    citiesService.loadCitiesForState(state.code)
                                    storeService.switchToState(state.code)
                                    Task {
                                        await citiesService.updateStoreCounts()
                                    }
                                }
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                    isStateTransitioning = false
                                }
                            }
                        )
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
            }
            .background(ThemeManager.warmOverlay.opacity(0.05))
            
            // Search Bar
            SearchBar(text: $searchText)
                .padding(.horizontal)
                .padding(.top, 16)
            
            // Tags ScrollView
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(allTags, id: \.self) { tag in
                        TagButton(
                            title: tag,
                            isSelected: selectedTags.contains(tag),
                            action: {
                                if selectedTags.contains(tag) {
                                    selectedTags.remove(tag)
                                } else {
                                    selectedTags.insert(tag)
                                    searchText = tag
                                }
                            }
                        )
                    }
                }
                .padding(.horizontal)
            }
            .padding(.vertical, 8)
            
            // Cities Grid with transition
            if filteredCities.isEmpty {
                VStack(spacing: 16) {
                    Image(systemName: "magnifyingglass")
                        .font(.largeTitle)
                        .foregroundColor(.gray)
                    Text("No cities found")
                        .font(.headline)
                        .foregroundColor(.gray)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollView {
                    LazyVGrid(columns: columns, spacing: 16) {
                        ForEach(filteredCities) { city in
                            CityCard(city: city)
                                .onTapGesture {
                                    selectedCity = city
                                }
                                .opacity(isStateTransitioning ? 0 : 1)
                                .animation(.easeInOut(duration: 0.3), value: isStateTransitioning)
                        }
                    }
                    .padding(.horizontal)
                }
            }
        }
        .background(ThemeManager.backgroundStyle)
        .navigationTitle("Cities")
        .sheet(item: $selectedCity) { city in
            CityDetailView(city: city)
        }
    }
}

struct StateButton: View {
    let name: String
    let code: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Text(code)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(isSelected ? .white : ThemeManager.textColor)
                Text(name)
                    .font(.system(size: 12))
                    .foregroundColor(isSelected ? .white.opacity(0.9) : ThemeManager.textColor.opacity(0.7))
            }
            .frame(width: 80)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? ThemeManager.brandPurple : Color.clear)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(
                                isSelected ? Color.clear : ThemeManager.textColor.opacity(0.2),
                                lineWidth: 1
                            )
                    )
            )
            .scaleEffect(isSelected ? 1.05 : 1.0)
            .animation(.spring(response: 0.3), value: isSelected)
        }
    }
}

struct TagButton: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 14, weight: .medium))
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(isSelected ? ThemeManager.brandPurple : ThemeManager.warmOverlay.opacity(0.05))
                .foregroundColor(isSelected ? .white : ThemeManager.textColor)
                .cornerRadius(20)
                .shadow(color: ThemeManager.warmOverlay.opacity(0.2), radius: 2, x: 0, y: 1)
        }
    }
}

struct CityCard: View {
    let city: City
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // City Image with enhanced gradient overlay
            GeometryReader { geometry in
                Image(city.imageUrl)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: geometry.size.width, height: 120)
                    .scaledToFill()
                    .clipped()
                    .overlay(
                        ZStack {
                            // Bottom gradient for text readability
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    .clear,
                                    ThemeManager.warmOverlay.opacity(0.3),
                                    ThemeManager.warmOverlay.opacity(0.6)
                                ]),
                                startPoint: .top,
                                endPoint: .bottom
                            )
                            
                            // Warm vintage overlay
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    ThemeManager.brandPurple.opacity(0.2),
                                    ThemeManager.warmOverlay.opacity(0.15)
                                ]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                            .blendMode(.overlay)
                        }
                    )
                    .cornerRadius(12)
            }
            .frame(height: 120)
            
            // City Info
            VStack(alignment: .leading, spacing: 4) {
                Text(city.name)
                    .font(.headline)
                    .foregroundColor(ThemeManager.textColor)
                    .lineLimit(1)
                
                Text("\(city.storeCount) Stores")
                    .font(.subheadline)
                    .foregroundColor(ThemeManager.textColor.opacity(0.7))
                
                // Tags
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 4) {
                        ForEach(city.tags.prefix(3), id: \.self) { tag in
                            Text(tag)
                                .font(.caption)
                                .foregroundColor(ThemeManager.textColor.opacity(0.8))
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(ThemeManager.warmOverlay.opacity(0.1))
                                .cornerRadius(8)
                        }
                    }
                }
            }
            .padding(.horizontal, 8)
            .padding(.bottom, 8)
        }
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: ThemeManager.warmOverlay.opacity(0.1), radius: 4, x: 0, y: 2)
    }
}

struct CityDetailView: View {
    let city: City
    @Environment(\.dismiss) private var dismiss
    @StateObject private var citiesService = CitiesService.shared
    @State private var stores: [Store] = []
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    // Hero Image with enhanced gradient overlay
                    GeometryReader { geometry in
                        Image(city.imageUrl)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: geometry.size.width, height: 200)
                            .scaledToFill()
                            .clipped()
                            .overlay(
                                ZStack {
                                    // Bottom gradient for text readability
                                    LinearGradient(
                                        gradient: Gradient(colors: [
                                            .clear,
                                            ThemeManager.warmOverlay.opacity(0.3),
                                            ThemeManager.warmOverlay.opacity(0.6)
                                        ]),
                                        startPoint: .top,
                                        endPoint: .bottom
                                    )
                                    
                                    // Warm vintage overlay
                                    LinearGradient(
                                        gradient: Gradient(colors: [
                                            ThemeManager.brandPurple.opacity(0.2),
                                            ThemeManager.warmOverlay.opacity(0.15)
                                        ]),
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                    .blendMode(.overlay)
                                }
                            )
                    }
                    .frame(height: 200)
                    
                    VStack(alignment: .leading, spacing: 16) {
                        // City Info
                        VStack(alignment: .leading, spacing: 8) {
                            Text(city.name)
                                .font(.title)
                                .fontWeight(.bold)
                                .foregroundColor(ThemeManager.textColor)
                            
                            Text("\(stores.count) Thrift Stores")
                                .font(.headline)
                                .foregroundColor(ThemeManager.textColor.opacity(0.7))
                            
                            Text(city.description)
                                .font(.body)
                                .foregroundColor(ThemeManager.textColor.opacity(0.8))
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        
                        // Tags
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                ForEach(city.tags, id: \.self) { tag in
                                    Text(tag)
                                        .font(.subheadline)
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 6)
                                        .background(ThemeManager.warmOverlay.opacity(0.1))
                                        .foregroundColor(ThemeManager.textColor)
                                        .cornerRadius(16)
                                }
                            }
                        }
                        
                        // Stores in this city
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Text("Popular Stores")
                                    .font(.title2)
                                    .fontWeight(.bold)
                                    .foregroundColor(ThemeManager.textColor)
                                Text("(Top 5)")
                                    .font(.subheadline)
                                    .foregroundColor(ThemeManager.textColor.opacity(0.6))
                            }
                            
                            ForEach(stores.prefix(5)) { store in
                                NavigationLink(destination: StoreDetailView(store: store)) {
                                    StoreRow(store: store)
                                }
                                Divider()
                                    .background(ThemeManager.warmOverlay.opacity(0.1))
                            }
                            
                            // View All Stores Button
                            NavigationLink(destination: CityStoresView(city: city)) {
                                HStack {
                                    Text("View All Stores")
                                        .font(.headline)
                                        .foregroundColor(ThemeManager.textColor)
                                    Text("(\(stores.count))")
                                        .foregroundColor(ThemeManager.textColor.opacity(0.6))
                                    Spacer()
                                    Image(systemName: "chevron.right")
                                        .foregroundColor(ThemeManager.textColor.opacity(0.6))
                                }
                                .padding()
                                .background(ThemeManager.warmOverlay.opacity(0.05))
                                .cornerRadius(12)
                                .shadow(color: ThemeManager.warmOverlay.opacity(0.1), radius: 2, x: 0, y: 1)
                            }
                            .buttonStyle(PlainButtonStyle())
                            .padding(.top, 24)
                        }
                    }
                    .padding()
                }
            }
            .background(ThemeManager.backgroundStyle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(ThemeManager.brandPurple)
                }
            }
        }
        .task {
            // Load stores when view appears
            stores = citiesService.getStoresForCity(city.id)
        }
    }
}

struct CitiesView_Previews: PreviewProvider {
    static var previews: some View {
        CitiesView()
    }
} 