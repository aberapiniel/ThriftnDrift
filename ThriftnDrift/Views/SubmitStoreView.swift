import SwiftUI
import MapKit

struct SubmitStoreView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var name = ""
    @State private var description = ""
    // Address fields
    @State private var streetAddress = ""
    @State private var city = ""
    @State private var state = "NC"  // Default to NC
    @State private var zipCode = ""
    @State private var selectedCategories: Set<String> = []
    @State private var priceRange = "$"
    @State private var coordinate: CLLocationCoordinate2D?
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var showingSuccess = false
    @State private var showingError = false
    
    // Social media and contact fields
    @State private var instagram = ""
    @State private var tiktok = ""
    @State private var website = ""
    @State private var phoneNumber = ""
    
    // Thrift-specific fields
    @State private var acceptsDonations = false
    @State private var hasClothingSection = true
    @State private var hasFurnitureSection = false
    @State private var hasElectronicsSection = false
    
    private let storeService = StoreService.shared
    
    private let availableCategories = [
        "Clothing", "Furniture", "Electronics", "Books",
        "Home Goods", "Accessories", "Antiques", "Vintage",
        "Children's Clothing", "Pet Supplies", "Household",
        "Decor", "Designer", "Sports Equipment"
    ].sorted()
    
    private let priceRanges = ["$", "$$", "$$$"]
    private let states = [
        "AL", "AK", "AZ", "AR", "CA", "CO", "CT", "DE", "FL", "GA",
        "HI", "ID", "IL", "IN", "IA", "KS", "KY", "LA", "ME", "MD",
        "MA", "MI", "MN", "MS", "MO", "MT", "NE", "NV", "NH", "NJ",
        "NM", "NY", "NC", "ND", "OH", "OK", "OR", "PA", "RI", "SC",
        "SD", "TN", "TX", "UT", "VT", "VA", "WA", "WV", "WI", "WY"
    ]
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Basic Information")) {
                    TextField("Store Name", text: $name)
                    TextEditor(text: $description)
                        .frame(height: 100)
                }
                
                Section(header: Text("Address")) {
                    TextField("Street Address", text: $streetAddress)
                    TextField("City", text: $city)
                    Picker("State", selection: $state) {
                        ForEach(states, id: \.self) { state in
                            Text(state).tag(state)
                        }
                    }
                    TextField("ZIP Code", text: $zipCode)
                        .keyboardType(.numberPad)
                }
                
                Section(header: Text("Categories")) {
                    ForEach(availableCategories, id: \.self) { category in
                        Toggle(category, isOn: Binding(
                            get: { selectedCategories.contains(category) },
                            set: { isSelected in
                                if isSelected {
                                    selectedCategories.insert(category)
                                } else {
                                    selectedCategories.remove(category)
                                }
                            }
                        ))
                    }
                }
                
                Section(header: Text("Price Range")) {
                    Picker("Price Range", selection: $priceRange) {
                        ForEach(priceRanges, id: \.self) { range in
                            Text(range).tag(range)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                }
                
                Section(header: Text("Contact Information")) {
                    TextField("Website (optional)", text: $website)
                        .keyboardType(.URL)
                        .autocapitalization(.none)
                    TextField("Phone Number (optional)", text: $phoneNumber)
                        .keyboardType(.phonePad)
                }
                
                Section(header: Text("Store Features")) {
                    Toggle("Has Clothing Section", isOn: $hasClothingSection)
                    Toggle("Has Furniture Section", isOn: $hasFurnitureSection)
                    Toggle("Has Electronics Section", isOn: $hasElectronicsSection)
                }
            }
            .navigationTitle("Submit Store")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Submit") {
                        submitStore()
                    }
                    .disabled(!isValid)
                }
            }
            .alert("Error", isPresented: $showingError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(errorMessage ?? "An unknown error occurred")
            }
            .alert("Success", isPresented: $showingSuccess) {
                Button("OK") {
                    dismiss()
                }
            } message: {
                Text("Your store has been submitted for review")
            }
            .overlay {
                if isLoading {
                    ProgressView()
                        .scaleEffect(1.5)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(Color.black.opacity(0.2))
                }
            }
        }
    }
    
    private var isValid: Bool {
        !name.isEmpty &&
        !streetAddress.isEmpty &&
        !city.isEmpty &&
        !state.isEmpty &&
        zipCode.count == 5 &&
        !selectedCategories.isEmpty
    }
    
    private func submitStore() {
        Task {
            isLoading = true
            defer { isLoading = false }
            
            do {
                // Get coordinates from address
                let geocoder = CLGeocoder()
                let address = "\(streetAddress), \(city), \(state) \(zipCode)"
                let placemarks = try await geocoder.geocodeAddressString(address)
                
                guard let location = placemarks.first?.location?.coordinate else {
                    errorMessage = "Could not find coordinates for the provided address"
                    showingError = true
                    return
                }
                
                let store = Store(
                    id: UUID().uuidString,
                    name: name,
                    description: description,
                    streetAddress: streetAddress,
                    city: city,
                    state: state,
                    zipCode: zipCode,
                    latitude: location.latitude,
                    longitude: location.longitude,
                    imageUrls: [],
                    rating: 0,
                    reviewCount: 0,
                    priceRange: priceRange,
                    categories: Array(selectedCategories),
                    website: website.isEmpty ? nil : website,
                    phoneNumber: phoneNumber.isEmpty ? nil : phoneNumber,
                    hasClothingSection: hasClothingSection,
                    hasFurnitureSection: hasFurnitureSection,
                    hasElectronicsSection: hasElectronicsSection,
                    isUserSubmitted: true
                )
                
                try await storeService.submitStore(store)
                showingSuccess = true
                
            } catch {
                errorMessage = error.localizedDescription
                showingError = true
            }
        }
    }
}

struct CategoryChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 14, weight: .medium))
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(isSelected ? Color(red: 0.4, green: 0.5, blue: 0.95) : Color.gray.opacity(0.1))
                .foregroundColor(isSelected ? .white : .primary)
                .cornerRadius(16)
        }
        .buttonStyle(PlainButtonStyle())
    }
} 
