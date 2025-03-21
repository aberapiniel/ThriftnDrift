import SwiftUI
import SDWebImageSwiftUI

struct CitiesView: View {
    @StateObject private var citiesService = CitiesService.shared
    @StateObject private var storeService = StoreService.shared
    @State private var searchText = ""
    @State private var selectedTags: Set<String> = []
    @State private var selectedCity: City?
    @State private var showingStateSelector = false
    
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
        VStack(spacing: 16) {
            // State selector button
            Button(action: {
                showingStateSelector = true
            }) {
                HStack {
                    Text(citiesService.getAvailableStates().first { $0.code == citiesService.selectedState }?.name ?? "Select State")
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
            .padding(.horizontal)
            
            // Search Bar
            SearchBar(text: $searchText)
                .padding(.horizontal)
            
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
            
            // Cities Grid
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
                        }
                    }
                    .padding(.horizontal)
                }
            }
        }
        .padding(.vertical)
        .background(Color(UIColor.systemGray6))
        .navigationTitle("Cities")
        .sheet(item: $selectedCity) { city in
            CityDetailView(city: city)
        }
        .sheet(isPresented: $showingStateSelector) {
            StateSelectionSheet(
                selectedState: citiesService.selectedState,
                states: citiesService.getAvailableStates(),
                onStateSelected: { stateCode in
                    citiesService.loadCitiesForState(stateCode)
                    storeService.switchToState(stateCode)
                    Task {
                        await citiesService.updateStoreCounts()
                    }
                    showingStateSelector = false
                }
            )
            .presentationDetents([.height(300)])
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
                .background(isSelected ? Color(red: 0.4, green: 0.5, blue: 0.95) : Color.white)
                .foregroundColor(isSelected ? .white : .primary)
                .cornerRadius(20)
                .shadow(color: Color.black.opacity(0.1), radius: 2, x: 0, y: 1)
        }
    }
}

struct CityCard: View {
    let city: City
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // City Image
            Image(city.imageUrl)
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(height: 120)
                .clipped()
                .cornerRadius(12)
                .overlay(
                    LinearGradient(
                        gradient: Gradient(colors: [.clear, .black.opacity(0.4)]),
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    .cornerRadius(12)
                )
            
            // City Info
            VStack(alignment: .leading, spacing: 4) {
                Text(city.name)
                    .font(.headline)
                
                Text("\(city.storeCount) Stores")
                    .font(.subheadline)
                    .foregroundColor(.gray)
                
                // Tags
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 4) {
                        ForEach(city.tags.prefix(3), id: \.self) { tag in
                            Text(tag)
                                .font(.caption)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color.gray.opacity(0.1))
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
        .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
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
                    // Hero Image
                    Image(city.imageUrl)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(height: 200)
                        .clipped()
                        .overlay(
                            LinearGradient(
                                gradient: Gradient(colors: [.clear, .black.opacity(0.5)]),
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                    
                    VStack(alignment: .leading, spacing: 16) {
                        // City Info
                        VStack(alignment: .leading, spacing: 8) {
                            Text(city.name)
                                .font(.title)
                                .fontWeight(.bold)
                            
                            Text("\(stores.count) Thrift Stores")
                                .font(.headline)
                                .foregroundColor(.gray)
                            
                            Text(city.description)
                                .font(.body)
                                .foregroundColor(.secondary)
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
                                        .background(Color.gray.opacity(0.1))
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
                                Text("(Top 5)")
                                    .font(.subheadline)
                                    .foregroundColor(.gray)
                            }
                            
                            ForEach(stores.prefix(5)) { store in
                                NavigationLink(destination: StoreDetailView(store: store)) {
                                    StoreRow(store: store)
                                }
                                Divider()
                            }
                            
                            // View All Stores Button
                            NavigationLink(destination: CityStoresView(city: city)) {
                                HStack {
                                    Text("View All Stores")
                                        .font(.headline)
                                    Text("(\(stores.count))")
                                        .foregroundColor(.gray)
                                    Spacer()
                                    Image(systemName: "chevron.right")
                                        .foregroundColor(.gray)
                                }
                                .padding()
                                .background(Color.white)
                                .cornerRadius(12)
                                .shadow(color: Color.black.opacity(0.1), radius: 2, x: 0, y: 1)
                            }
                            .buttonStyle(PlainButtonStyle())
                            .padding(.top, 24)
                        }
                    }
                    .padding()
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
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