import Foundation
import CoreLocation
import FirebaseFirestore
import FirebaseAuth

// Store state data structure
struct StateStores: Codable {
    let name: String
    let stores: [StoreData]
}

// JSON store data structure
struct StoreData: Codable {
    let id: String
    let name: String
    let description: String
    let address: String  // Keep as single field for JSON compatibility
    let latitude: Double
    let longitude: Double
    let rating: Double
    let reviewCount: Int
    let priceRange: String
    let categories: [String]
    let website: String?
    let phoneNumber: String?
    let acceptsDonations: Bool
    let hasClothingSection: Bool
    let hasFurnitureSection: Bool
    let hasElectronicsSection: Bool
    let lastVerified: Date
    let isUserSubmitted: Bool
    let verificationStatus: String
    
    // Convert JSON data to Store model
    func toStore(state: String) -> Store? {
        // Parse address components
        let components = address.components(separatedBy: ", ")
        let streetAddress = components.first ?? ""
        var city = ""
        var zipCode = ""
        
        if components.count >= 3 {
            city = components[1]
            let stateZip = components[2].components(separatedBy: " ")
            if stateZip.count >= 2 {
                zipCode = stateZip[1]
            }
        }
        
        // Ensure this store belongs to the requested state
        let addressComponents = address.components(separatedBy: ", ")
        if addressComponents.count >= 3 {
            let stateZip = addressComponents[2].components(separatedBy: " ")
            let addressState = stateZip[0].uppercased()
            if addressState != state {
                print("📦 WARNING: Store '\(name)' address state (\(addressState)) doesn't match requested state (\(state))")
                return nil
            }
        }
        
        return Store(
            id: id,
            name: name,
            description: description,
            streetAddress: streetAddress,
            city: city,
            state: state,
            zipCode: zipCode,
            latitude: latitude,
            longitude: longitude,
            imageUrls: [],
            rating: rating,
            reviewCount: reviewCount,
            priceRange: priceRange,
            categories: categories,
            website: website,
            phoneNumber: phoneNumber,
            acceptsDonations: acceptsDonations,
            hasClothingSection: hasClothingSection,
            hasFurnitureSection: hasFurnitureSection,
            hasElectronicsSection: hasElectronicsSection,
            lastVerified: lastVerified,
            isUserSubmitted: isUserSubmitted,
            verificationStatus: "verified"
        )
    }
}

// Root JSON structure
struct StoresRoot: Codable {
    var states: [String: StateStores]
}

@MainActor
class StoreService: ObservableObject {
    static let shared = StoreService()
    @Published private(set) var stores: [Store] = []
    @Published private(set) var selectedState: String = "NC"
    @Published private(set) var isLoading = false
    @Published private(set) var error: Error?
    
    private var storesData: StoresRoot?
    private let db = Firestore.firestore()
    private var userSubmittedStoresListener: ListenerRegistration?
    private var verifiedStoresListener: ListenerRegistration?
    private var currentStateCode: String = "NC"  // Track current state
    private var firestoreStores: [Store] = []    // Track Firestore stores
    private var submissions: [Store] = []        // Track submissions
    
    private init() {
        print("📦 StoreService initialized")
        loadStoresFromJSON()
        setupFirestoreListeners()
    }
    
    private func loadStoresFromJSON() {
        print("📦 Attempting to load stores.json")
        
        guard let bundleUrl = Bundle.main.url(forResource: "stores", withExtension: "json") else {
            print("📦 Error: Could not find stores.json in bundle")
            print("📦 Bundle path: \(Bundle.main.bundlePath)")
            print("📦 Resource path: \(Bundle.main.resourcePath ?? "nil")")
            return
        }
        
        do {
            print("📦 Found stores.json at: \(bundleUrl)")
            let data = try Data(contentsOf: bundleUrl)
            let decoder = JSONDecoder()
            
            // Configure date decoding strategy
            let formatter = ISO8601DateFormatter()
            formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
            decoder.dateDecodingStrategy = .custom { decoder in
                let container = try decoder.singleValueContainer()
                let dateStr = try container.decode(String.self)
                
                if let date = formatter.date(from: dateStr) {
                    return date
                }
                
                // Fallback to basic ISO8601 if the first attempt fails
                let fallbackFormatter = ISO8601DateFormatter()
                if let date = fallbackFormatter.date(from: dateStr) {
                    return date
                }
                
                throw DecodingError.dataCorruptedError(in: container, debugDescription: "Invalid date format")
            }
            
            storesData = try decoder.decode(StoresRoot.self, from: data)
            print("📦 Successfully loaded stores data")
            print("📦 Available states: \(storesData?.states.keys.joined(separator: ", ") ?? "none")")
            
            // Load stores for the selected state
            loadStoresForState(selectedState)
            
        } catch {
            print("📦 Error loading stores: \(error)")
        }
    }
    
    private func setupFirestoreListeners() {
        print("📦 Setting up Firestore listeners for state: \(selectedState)")
        setupVerifiedStoresListener()
    }
    
    private func setupVerifiedStoresListener() {
        verifiedStoresListener?.remove()
        
        // Listen for both verified stores and approved submissions
        let storesQuery = db.collection("stores")
            .whereField("state", isEqualTo: selectedState)
            .whereField("verificationStatus", isEqualTo: "verified")
        
        let submissionsQuery = db.collection("store_submissions")
            .whereField("state", isEqualTo: selectedState)
            .whereField("verificationStatus", isEqualTo: "verified")
        
        verifiedStoresListener = storesQuery.addSnapshotListener { [weak self] snapshot, error in
            guard let self = self else { return }
            
            if let error = error {
                print("Error fetching verified stores: \(error)")
                return
            }
            
            // Only process if we're still in the same state
            guard self.selectedState == self.currentStateCode else {
                print("📦 Ignoring Firestore update for old state")
                return
            }
            
            let newFirestoreStores = snapshot?.documents.compactMap { document -> Store? in
                try? document.data(as: Store.self)
            } ?? []
            
            print("📦 Received \(newFirestoreStores.count) verified stores from Firestore")
            self.firestoreStores = newFirestoreStores
            self.updateStoresList()
        }
        
        userSubmittedStoresListener = submissionsQuery.addSnapshotListener { [weak self] snapshot, error in
            guard let self = self else { return }
            
            if let error = error {
                print("Error fetching verified submissions: \(error)")
                return
            }
            
            // Only process if we're still in the same state
            guard self.selectedState == self.currentStateCode else {
                print("📦 Ignoring submissions update for old state")
                return
            }
            
            let newSubmissions = snapshot?.documents.compactMap { document -> Store? in
                try? document.data(as: Store.self)
            } ?? []
            
            print("📦 Received \(newSubmissions.count) verified submissions from Firestore")
            self.submissions = newSubmissions
            self.updateStoresList()
        }
    }
    
    private func updateStoresList() {
        // Get verified stores from JSON for current state only
        let jsonStores = storesData?.states[selectedState]?.stores
            .compactMap { $0.toStore(state: selectedState) }
            ?? []
        
        print("📦 Updating stores list:")
        print("📦 - JSON stores: \(jsonStores.count)")
        print("📦 - Firestore stores: \(firestoreStores.count)")
        print("📦 - Submissions: \(submissions.count)")
        
        // Combine all stores and filter by state
        let allStores = (jsonStores + firestoreStores + submissions)
            .filter { store in
                // Validate coordinates
                guard store.latitude != 0 || store.longitude != 0 else {
                    print("📦 WARNING: Filtering out store '\(store.name)' due to invalid coordinates (0,0)")
                    return false
                }
                return store.state.uppercased() == selectedState.uppercased()
            }
        
        // Update the published stores array
        stores = allStores
        print("📦 Total stores after update: \(stores.count) for state: \(selectedState)")
    }
    
    func submitStore(_ store: Store) async throws {
        // Create store data with separate address components
        var storeData: [String: Any] = [
            "id": store.id,
            "name": store.name,
            "description": store.description,
            "streetAddress": store.streetAddress,
            "city": store.city,
            "state": store.state,
            "zipCode": store.zipCode,
            "latitude": store.latitude,
            "longitude": store.longitude,
            "rating": store.rating,
            "reviewCount": store.reviewCount,
            "priceRange": store.priceRange,
            "categories": store.categories,
            "acceptsDonations": store.acceptsDonations,
            "hasClothingSection": store.hasClothingSection,
            "hasFurnitureSection": store.hasFurnitureSection,
            "hasElectronicsSection": store.hasElectronicsSection,
            "isUserSubmitted": true,
            "verificationStatus": "pending",
            "createdAt": Date(),
            "submittedBy": Auth.auth().currentUser?.uid ?? "anonymous"
        ]
        
        // Add optional fields if they exist
        if let website = store.website {
            storeData["website"] = website
        }
        if let phoneNumber = store.phoneNumber {
            storeData["phoneNumber"] = phoneNumber
        }
        
        try await db.collection("store_submissions").document(store.id).setData(storeData)
        print("Successfully submitted store with ID: \(store.id)")
    }
    
    func switchToState(_ stateCode: String) {
        print("📦 Switching to state: \(stateCode)")
        
        // Remove existing listeners first
        userSubmittedStoresListener?.remove()
        verifiedStoresListener?.remove()
        userSubmittedStoresListener = nil
        verifiedStoresListener = nil
        
        // Clear all stores
        stores = []
        firestoreStores = []
        submissions = []
        
        // Update state tracking
        selectedState = stateCode
        currentStateCode = stateCode
        
        // Load stores for new state
        loadStoresForState(stateCode)
    }
    
    func loadStoresForState(_ stateCode: String) {
        print("📦 Loading stores for state: \(stateCode)")
        
        guard let stateStores = storesData?.states[stateCode]?.stores else {
            print("📦 Error: No stores found for state \(stateCode)")
            return
        }
        
        // Load JSON stores first
        let verifiedStores = stateStores.compactMap { $0.toStore(state: stateCode) }
        print("📦 Loaded \(verifiedStores.count) stores from JSON")
        
        // Update stores with JSON data
        stores = verifiedStores
        
        // Then setup Firebase listeners
        setupFirestoreListeners()
    }
    
    func getAvailableStates() -> [(code: String, name: String)] {
        storesData?.states.map { (code: $0.key, name: $0.value.name) }
            .sorted { $0.name < $1.name } ?? []
    }
    
    func getNearbyStores(latitude: Double, longitude: Double, radiusInMeters: Double = 50000) -> [Store] {
        let location = CLLocation(latitude: latitude, longitude: longitude)
        return stores.filter { store in
            let storeLocation = CLLocation(latitude: store.latitude, longitude: store.longitude)
            return location.distance(from: storeLocation) <= radiusInMeters
        }
    }
    
    func searchStores(query: String) -> [Store] {
        if query.isEmpty { return stores }
        return stores.filter { store in
            store.name.localizedCaseInsensitiveContains(query) ||
            store.address.localizedCaseInsensitiveContains(query) ||
            store.categories.contains { $0.localizedCaseInsensitiveContains(query) }
        }
    }
}

// Helper extension for Store model
extension Store {
    func toDictionary() -> [String: Any] {
        var data: [String: Any] = [
            "id": id,
            "name": name,
            "description": description,
            "address": address,
            "state": state,
            "latitude": latitude,
            "longitude": longitude,
            "rating": rating,
            "reviewCount": reviewCount,
            "priceRange": priceRange,
            "categories": categories,
            "acceptsDonations": acceptsDonations,
            "hasClothingSection": hasClothingSection,
            "hasFurnitureSection": hasFurnitureSection,
            "hasElectronicsSection": hasElectronicsSection,
            "lastVerified": lastVerified ?? Date(),
            "isUserSubmitted": true,
            "verificationStatus": "pending",
            "createdAt": Date(),
            "submittedBy": Auth.auth().currentUser?.uid ?? "anonymous"
        ]
        
        // Add optional fields if they exist
        if let website = website {
            data["website"] = website
        }
        if let phoneNumber = phoneNumber {
            data["phoneNumber"] = phoneNumber
        }
        
        return data
    }
} 