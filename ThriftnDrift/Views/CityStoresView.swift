import SwiftUI

struct CityStoresView: View {
    let city: City
    @StateObject private var citiesService = CitiesService.shared
    @State private var searchText = ""
    
    private var filteredStores: [Store] {
        let stores = citiesService.getStoresForCity(city.id)
        if searchText.isEmpty {
            return stores
        }
        return stores.filter { store in
            store.name.localizedCaseInsensitiveContains(searchText) ||
            store.address.localizedCaseInsensitiveContains(searchText) ||
            store.categories.contains { $0.localizedCaseInsensitiveContains(searchText) }
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Search Bar
            SearchBar(text: $searchText)
                .padding()
            
            List {
                ForEach(filteredStores) { store in
                    NavigationLink(destination: StoreDetailView(store: store)) {
                        StoreRow(store: store)
                    }
                }
            }
            .listStyle(PlainListStyle())
        }
        .navigationTitle("\(city.name) Stores")
        .navigationBarTitleDisplayMode(.inline)
    }
} 