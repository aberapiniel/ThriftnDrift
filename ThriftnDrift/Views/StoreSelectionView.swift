import SwiftUI
import CoreLocation

struct StoreSelectionView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var storeService = StoreService.shared
    @State private var searchText = ""
    @State private var userLocation: CLLocationCoordinate2D?
    @State private var showingStateSelector = false
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
                // State selector button
                Button(action: { showingStateSelector = true }) {
                    HStack {
                        Image(systemName: "mappin.and.ellipse")
                            .foregroundColor(ThemeManager.brandPurple)
                        Text(storeService.selectedState ?? "Select State")
                            .foregroundColor(ThemeManager.textColor)
                        Spacer()
                        Image(systemName: "chevron.right")
                            .foregroundColor(ThemeManager.textColor.opacity(0.7))
                    }
                    .padding()
                    .background(ThemeManager.warmOverlay.opacity(0.05))
                    .cornerRadius(12)
                }
                .padding()
                
                // Search bar
                SearchBar(text: $searchText)
                    .padding(.horizontal)
                
                // Store list
                List(filteredStores) { store in
                    Button(action: {
                        selectedStore = store
                        dismiss()
                    }) {
                        StoreSelectionRow(store: store, isSelected: store.id == selectedStore?.id)
                    }
                    .listRowBackground(ThemeManager.warmOverlay.opacity(0.05))
                }
                .listStyle(PlainListStyle())
            }
            .background(ThemeManager.backgroundStyle)
            .navigationTitle("Select Store")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(ThemeManager.brandPurple)
                }
            }
            .sheet(isPresented: $showingStateSelector) {
                StateSelectionSheet(
                    selectedState: storeService.selectedState,
                    states: storeService.getAvailableStates(),
                    onStateSelected: { stateCode in
                        Task {
                            await storeService.switchToState(stateCode)
                        }
                        showingStateSelector = false
                    }
                )
                .presentationDetents([.height(300)])
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
                    .foregroundColor(ThemeManager.textColor)
                Text(store.address)
                    .font(.subheadline)
                    .foregroundColor(ThemeManager.textColor.opacity(0.7))
            }
            
            Spacer()
            
            if isSelected {
                Image(systemName: "checkmark")
                    .foregroundColor(ThemeManager.brandPurple)
            }
        }
        .contentShape(Rectangle())
        .padding(.vertical, 4)
    }
} 
