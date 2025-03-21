import SwiftUI
import CoreLocation

struct StoreSelectionView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var storeService = StoreService.shared
    @State private var searchText = ""
    @State private var userLocation: CLLocationCoordinate2D?
    @Binding var selectedStore: Store?
    
    private var filteredStores: [Store] {
        if searchText.isEmpty {
            return storeService.stores
        }
        return storeService.searchStores(query: searchText)
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Search bar
                SearchBar(text: $searchText)
                    .padding()
                
                // Store list
                List(filteredStores) { store in
                    Button(action: {
                        selectedStore = store
                        dismiss()
                    }) {
                        StoreSelectionRow(store: store, isSelected: store.id == selectedStore?.id)
                    }
                }
            }
            .navigationTitle("Select Store")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
}

struct StoreSelectionRow: View {
    let store: Store
    let isSelected: Bool
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(store.name)
                    .font(.headline)
                Text(store.address)
                    .font(.subheadline)
                    .foregroundColor(.gray)
            }
            
            Spacer()
            
            if isSelected {
                Image(systemName: "checkmark")
                    .foregroundColor(.blue)
            }
        }
        .contentShape(Rectangle())
    }
} 
