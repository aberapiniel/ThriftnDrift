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
            ScrollView {
                VStack(spacing: 24) {
                    // Basic Information Section
                    VStack(alignment: .leading, spacing: 16) {
                        SectionHeader(title: "Basic Information")
                        
                        VStack(spacing: 12) {
                            CustomTextField(title: "Store Name", text: $name)
                            
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Description")
                                    .font(.subheadline)
                                    .foregroundColor(ThemeManager.textColor)
                                TextEditor(text: $description)
                                    .frame(height: 100)
                                    .padding(8)
                                    .background(Color.white)
                                    .cornerRadius(12)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(ThemeManager.warmOverlay.opacity(0.2), lineWidth: 1)
                                    )
                            }
                        }
                    }
                    .padding(.horizontal, 24)
                    
                    // Address Section
                    VStack(alignment: .leading, spacing: 16) {
                        SectionHeader(title: "Address")
                        
                        VStack(spacing: 12) {
                            CustomTextField(title: "Street Address", text: $streetAddress)
                            CustomTextField(title: "City", text: $city)
                            
                            // State Picker
                            VStack(alignment: .leading, spacing: 8) {
                                Text("State")
                                    .font(.subheadline)
                                    .foregroundColor(ThemeManager.textColor)
                                
                                Menu {
                                    ForEach(states, id: \.self) { stateCode in
                                        Button(stateCode) {
                                            state = stateCode
                                        }
                                    }
                                } label: {
                                    HStack {
                                        Text(state)
                                            .foregroundColor(ThemeManager.textColor)
                                        Spacer()
                                        Image(systemName: "chevron.down")
                                            .foregroundColor(ThemeManager.textColor.opacity(0.6))
                                    }
                                    .padding()
                                    .background(ThemeManager.warmOverlay.opacity(0.05))
                                    .cornerRadius(12)
                                }
                            }
                            
                            CustomTextField(title: "ZIP Code", text: $zipCode)
                                .keyboardType(.numberPad)
                        }
                    }
                    .padding(.horizontal, 24)
                    
                    // Categories Section
                    VStack(alignment: .leading, spacing: 16) {
                        SectionHeader(title: "Categories")
                        
                        LazyVGrid(columns: [
                            GridItem(.flexible()),
                            GridItem(.flexible())
                        ], spacing: 12) {
                            ForEach(availableCategories, id: \.self) { category in
                                CategoryToggle(
                                    title: category,
                                    isSelected: selectedCategories.contains(category)
                                ) {
                                    if selectedCategories.contains(category) {
                                        selectedCategories.remove(category)
                                    } else {
                                        selectedCategories.insert(category)
                                    }
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 24)
                    
                    // Price Range Section
                    VStack(alignment: .leading, spacing: 16) {
                        SectionHeader(title: "Price Range")
                        
                        HStack(spacing: 0) {
                            ForEach(priceRanges, id: \.self) { range in
                                Button(action: {
                                    priceRange = range
                                }) {
                                    Text(range)
                                        .font(.system(size: 16, weight: .medium))
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 12)
                                        .background(
                                            priceRange == range ?
                                            ThemeManager.brandPurple :
                                            ThemeManager.warmOverlay.opacity(0.05)
                                        )
                                        .foregroundColor(
                                            priceRange == range ?
                                            .white :
                                            ThemeManager.textColor
                                        )
                                }
                            }
                        }
                        .cornerRadius(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(ThemeManager.warmOverlay.opacity(0.1), lineWidth: 1)
                        )
                    }
                    .padding(.horizontal, 24)
                    
                    // Contact Information Section
                    VStack(alignment: .leading, spacing: 16) {
                        SectionHeader(title: "Contact Information")
                        
                        VStack(spacing: 12) {
                            CustomTextField(title: "Website (optional)", text: $website)
                                .keyboardType(.URL)
                                .autocapitalization(.none)
                            CustomTextField(title: "Phone Number (optional)", text: $phoneNumber)
                                .keyboardType(.phonePad)
                        }
                    }
                    .padding(.horizontal, 24)
                    
                    // Store Features Section
                    VStack(alignment: .leading, spacing: 16) {
                        SectionHeader(title: "Store Features")
                        
                        VStack(spacing: 12) {
                            FeatureToggle(title: "Has Clothing Section", isOn: $hasClothingSection)
                            FeatureToggle(title: "Has Furniture Section", isOn: $hasFurnitureSection)
                            FeatureToggle(title: "Has Electronics Section", isOn: $hasElectronicsSection)
                        }
                    }
                    .padding(.horizontal, 24)
                    
                    Spacer(minLength: 40)
                }
                .padding(.vertical, 24)
            }
            .background(ThemeManager.backgroundStyle)
            .navigationTitle("Submit Store")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(ThemeManager.brandPurple)
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Submit") {
                        submitStore()
                    }
                    .disabled(!isValid)
                    .foregroundColor(isValid ? ThemeManager.brandPurple : ThemeManager.textColor.opacity(0.3))
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

// MARK: - Supporting Views

struct SectionHeader: View {
    let title: String
    
    var body: some View {
        Text(title)
            .font(.headline)
            .foregroundColor(ThemeManager.brandPurple)
    }
}

struct CustomTextField: View {
    let title: String
    @Binding var text: String
    var keyboardType: UIKeyboardType = .default
    var autocapitalization: TextInputAutocapitalization = .sentences
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.subheadline)
                .foregroundColor(ThemeManager.textColor)
            
            TextField("", text: $text)
                .padding()
                .background(Color.white)
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(ThemeManager.warmOverlay.opacity(0.2), lineWidth: 1)
                )
                .keyboardType(keyboardType)
                .textInputAutocapitalization(autocapitalization)
        }
    }
}

struct CategoryToggle: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Text(title)
                    .font(.subheadline)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                Spacer()
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                isSelected ?
                ThemeManager.brandPurple.opacity(0.1) :
                ThemeManager.warmOverlay.opacity(0.05)
            )
            .foregroundColor(
                isSelected ?
                ThemeManager.brandPurple :
                ThemeManager.textColor
            )
            .cornerRadius(8)
        }
    }
}

struct FeatureToggle: View {
    let title: String
    @Binding var isOn: Bool
    
    var body: some View {
        Toggle(title, isOn: $isOn)
            .toggleStyle(SwitchToggleStyle(tint: ThemeManager.brandPurple))
            .foregroundColor(ThemeManager.textColor)
    }
}

struct SubmitStoreView_Previews: PreviewProvider {
    static var previews: some View {
        SubmitStoreView()
    }
} 
