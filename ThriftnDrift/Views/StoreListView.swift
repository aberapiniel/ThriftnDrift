import SwiftUI

struct StoreListView: View {
    @StateObject private var storeService = StoreService.shared
    @State private var searchText = ""
    @State private var selectedCategory: String?
    @State private var showingFilters = false
    @State private var showingAddStore = false
    @State private var showingError = false
    @State private var errorMessage = ""
    
    private let categories = ["All", "Clothing", "Furniture", "Electronics", "Books", "Vintage", "Collectibles"]
    
    var filteredStores: [Store] {
        var stores = storeService.stores
        
        // Apply search filter
        if !searchText.isEmpty {
            stores = stores.filter { store in
                store.name.localizedCaseInsensitiveContains(searchText) ||
                store.address.localizedCaseInsensitiveContains(searchText) ||
                store.categories.contains { $0.localizedCaseInsensitiveContains(searchText) }
            }
        }
        
        // Apply category filter
        if let category = selectedCategory, category != "All" {
            stores = stores.filter { $0.categories.contains(category) }
        }
        
        return stores
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Search and Filter Bar
                HStack {
                    SearchBar(text: $searchText)
                        .frame(maxWidth: .infinity)
                    
                    Button(action: { showingFilters.toggle() }) {
                        Image(systemName: "line.3.horizontal.decrease.circle")
                            .font(.system(size: 24))
                            .foregroundColor(.gray)
                    }
                }
                .padding()
                
                // Category ScrollView
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(categories, id: \.self) { category in
                            CategoryButton(
                                title: category,
                                isSelected: selectedCategory == category,
                                action: { selectedCategory = category }
                            )
                        }
                    }
                    .padding(.horizontal)
                }
                .padding(.vertical, 8)
                
                // Store List
                List(filteredStores) { store in
                    NavigationLink(destination: StoreDetailView(store: store)) {
                        StoreRow(store: store)
                    }
                }
                .listStyle(PlainListStyle())
            }
            .navigationTitle("Thrift Stores")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingAddStore = true }) {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 24))
                    }
                }
            }
            .sheet(isPresented: $showingAddStore) {
                SubmitStoreView()
            }
            .alert("Error", isPresented: $showingError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(errorMessage)
            }
        }
    }
}

struct CategoryButton: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline)
                .fontWeight(isSelected ? .bold : .regular)
                .foregroundColor(isSelected ? .white : .gray)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(isSelected ? Color(red: 0.4, green: 0.5, blue: 0.95) : Color.gray.opacity(0.1))
                .cornerRadius(20)
        }
    }
}

struct StoreRow: View {
    let store: Store
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Store name
            Text(store.name)
                .font(.title3)
                .fontWeight(.semibold)
                .foregroundColor(ThemeManager.textColor)
            
            // Address
            Text(store.address)
                .font(.subheadline)
                .foregroundColor(ThemeManager.textColor.opacity(0.7))
            
            // Rating and Price
            HStack {
                if store.rating > 0 {
                    HStack(spacing: 4) {
                        Image(systemName: "star.fill")
                            .foregroundColor(.yellow)
                        Text(String(format: "%.1f", store.rating))
                            .foregroundColor(ThemeManager.textColor)
                        Text("(\(store.reviewCount))")
                            .foregroundColor(ThemeManager.textColor.opacity(0.7))
                    }
                }
                
                Spacer()
                
                Text(store.priceRange)
                    .foregroundColor(ThemeManager.textColor.opacity(0.7))
            }
            .font(.subheadline)
            
            // Categories
            if !store.categories.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(store.categories, id: \.self) { category in
                            Text(category)
                                .font(.caption)
                                .foregroundColor(ThemeManager.textColor.opacity(0.8))
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(ThemeManager.warmOverlay.opacity(0.1))
                                .cornerRadius(12)
                        }
                    }
                    .padding(.horizontal, 2) // Prevent categories from touching the edges
                }
            }
        }
        .padding(.vertical, 16)
        .padding(.horizontal, 20)
    }
}

struct StoreListView_Previews: PreviewProvider {
    static var previews: some View {
        StoreListView()
    }
} 

