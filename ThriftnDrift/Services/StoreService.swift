import Foundation
import CoreLocation
import FirebaseFirestore
import FirebaseAuth
import FirebaseStorage
import CommonCrypto

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
    let hasClothingSection: Bool
    let hasFurnitureSection: Bool
    let hasElectronicsSection: Bool
    let lastVerified: Date
    let isUserSubmitted: Bool
    let verificationStatus: String
    let imageAttribution: String?  // Add imageAttribution field
    
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
            imageAttribution: imageAttribution,
            rating: rating,
            reviewCount: reviewCount,
            priceRange: priceRange,
            categories: categories,
            website: website,
            phoneNumber: phoneNumber,
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
            
            Task {
                var newFirestoreStores: [Store] = []
                
                // Process each document sequentially
                for document in snapshot?.documents ?? [] {
                    if var store = try? document.data(as: Store.self) {
                        // Verify image URLs exist in storage
                        if !store.imageUrls.isEmpty {
                            do {
                                let validUrls = try await self.verifyImageUrls(store.imageUrls, forStore: store.id)
                                store.imageUrls = validUrls
                                newFirestoreStores.append(store)
                            } catch {
                                print("📦 Error verifying image URLs for store \(store.id): \(error)")
                            }
                        } else {
                            newFirestoreStores.append(store)
                        }
                    }
                }
                
                await MainActor.run {
                    print("📦 Received \(newFirestoreStores.count) verified stores from Firestore")
                    self.firestoreStores = newFirestoreStores
                    self.updateStoresList()
                }
            }
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
            
            Task {
                var newSubmissions: [Store] = []
                
                // Process each document sequentially
                for document in snapshot?.documents ?? [] {
                    if var store = try? document.data(as: Store.self) {
                        // Verify image URLs exist in storage
                        if !store.imageUrls.isEmpty {
                            do {
                                let validUrls = try await self.verifyImageUrls(store.imageUrls, forStore: store.id)
                                store.imageUrls = validUrls
                                newSubmissions.append(store)
                            } catch {
                                print("📦 Error verifying image URLs for store \(store.id): \(error)")
                            }
                        } else {
                            newSubmissions.append(store)
                        }
                    }
                }
                
                await MainActor.run {
                    print("📦 Received \(newSubmissions.count) verified submissions from Firestore")
                    self.submissions = newSubmissions
                    self.updateStoresList()
                }
            }
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
        
        // Combine all stores and filter by state and validate coordinates
        let allStores = (jsonStores + firestoreStores + submissions)
            .filter { store in
                // Validate coordinates
                guard store.latitude != 0 && store.longitude != 0 &&
                      !store.latitude.isNaN && !store.longitude.isNaN &&
                      store.latitude >= -90 && store.latitude <= 90 &&
                      store.longitude >= -180 && store.longitude <= 180 else {
                    print("📦 WARNING: Filtering out store '\(store.name)' due to invalid coordinates (\(store.latitude),\(store.longitude))")
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
    
    // Helper function to check if an image URL already exists for a store
    private func isDuplicateImage(_ imageUrl: String, forStore storeId: String) async throws -> Bool {
        // Check in store document
        let storeDoc = try await db.collection("stores").document(storeId).getDocument()
        if let existingUrls = storeDoc.data()?["imageUrls"] as? [String],
           existingUrls.contains(imageUrl) {
            return true
        }
        
        // Check in pending submissions
        let pendingSubmissions = try await db.collection("store_photo_submissions")
            .whereField("storeId", isEqualTo: storeId)
            .whereField("status", isEqualTo: "pending")
            .getDocuments()
        
        for doc in pendingSubmissions.documents {
            if let submissionUrls = doc.data()["imageUrls"] as? [String],
               submissionUrls.contains(imageUrl) {
                return true
            }
        }
        
        return false
    }
    
    // Helper function to verify image URLs exist in storage
    private func verifyImageUrls(_ urls: [String], forStore storeId: String) async throws -> [String] {
        var validUrls: [String] = []
        
        for url in urls {
            let imageRef = Storage.storage().reference(forURL: url)
            do {
                _ = try await imageRef.getMetadata()
                validUrls.append(url)
            } catch {
                print("📦 Image no longer exists in storage: \(url)")
            }
        }
        
        // If we found any invalid URLs, update the store document
        if validUrls.count != urls.count {
            try await db.collection("stores").document(storeId).updateData([
                "imageUrls": validUrls
            ])
            print("📦 Updated store \(storeId) to remove \(urls.count - validUrls.count) deleted images")
        }
        
        return validUrls
    }
    
    // Helper function to generate MD5 hash for image data
    private func md5Hash(_ data: Data) -> String {
        var digest = [UInt8](repeating: 0, count: Int(CC_MD5_DIGEST_LENGTH))
        _ = data.withUnsafeBytes {
            CC_MD5($0.baseAddress, CC_LONG(data.count), &digest)
        }
        return digest.map { String(format: "%02x", $0) }.joined()
    }
    
    // Helper function to check if an image is a duplicate in storage
    private func isDuplicateImageInStorage(_ imageData: Data, forStore storeId: String) async throws -> Bool {
        let storage = Storage.storage()
        let storageRef = storage.reference()
        let storePhotosRef = storageRef.child("store_photos/\(storeId)")
        
        // Get hash of the new image
        let newImageHash = md5Hash(imageData)
        
        // List all images in the store's folder
        let result = try await storePhotosRef.listAll()
        
        // Check each existing image
        for item in result.items {
            do {
                let data = try await item.data(maxSize: 5 * 1024 * 1024) // 5MB max
                let existingHash = md5Hash(data)
                
                if existingHash == newImageHash {
                    print("📦 Found duplicate image in storage")
                    return true
                }
            } catch {
                print("📦 Error checking image \(item.name): \(error)")
                continue
            }
        }
        
        return false
    }
    
    func submitStorePhotos(storeId: String, images: [UIImage]) async throws {
        guard !images.isEmpty else {
            throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "No images provided"])
        }
        
        let storage = Storage.storage()
        let storageRef = storage.reference()
        
        var imageUrls: [String] = []
        var uploadErrors: [Error] = []
        var duplicateCount = 0
        
        // Upload each image
        for (index, image) in images.enumerated() {
            guard let imageData = image.jpegData(compressionQuality: 0.7) else {
                print("📦 Error: Could not compress image \(index)")
                continue
            }
            
            // Check if this image is a duplicate in storage
            if try await isDuplicateImageInStorage(imageData, forStore: storeId) {
                print("📦 Skipping duplicate image \(index + 1)")
                duplicateCount += 1
                continue
            }
            
            let imageName = "\(UUID().uuidString)_\(index).jpg"
            let imageRef = storageRef.child("store_photos/\(storeId)/\(imageName)")
            
            do {
                let metadata = StorageMetadata()
                metadata.contentType = "image/jpeg"
                
                // Upload image and get URL
                _ = try await imageRef.putDataAsync(imageData, metadata: metadata)
                let downloadURL = try await imageRef.downloadURL()
                
                imageUrls.append(downloadURL.absoluteString)
                print("📦 Successfully uploaded image \(index + 1) of \(images.count)")
            } catch {
                print("📦 Error uploading image \(index): \(error)")
                uploadErrors.append(error)
            }
        }
        
        // If no images were successfully uploaded (all were duplicates or errors)
        if imageUrls.isEmpty {
            if duplicateCount > 0 {
                throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "All images were duplicates of existing photos"])
            } else if !uploadErrors.isEmpty {
                throw uploadErrors[0]
            }
            return
        }
        
        // Get the store name
        let storeDoc = try await db.collection("stores").document(storeId).getDocument()
        let storeName = storeDoc.data()?["name"] as? String ?? "Unknown Store"
        
        // Get the user's display name
        let currentUser = Auth.auth().currentUser
        let userDoc = try? await db.collection("users").document(currentUser?.uid ?? "").getDocument()
        let submitterName = userDoc?.data()?["displayName"] as? String ?? currentUser?.displayName
        
        // Create photo submission document
        let submission = [
            "storeId": storeId,
            "storeName": storeName,
            "imageUrls": imageUrls,
            "status": "pending",
            "submittedBy": currentUser?.uid ?? "anonymous",
            "submitterName": submitterName,
            "submittedAt": Timestamp(date: Date()),
            "reviewedAt": nil as Timestamp?,
            "reviewedBy": nil as String?
        ] as [String : Any]
        
        // Only create submission if we have non-duplicate images
        if !imageUrls.isEmpty {
            try await db.collection("store_photo_submissions").document().setData(submission)
            
            if duplicateCount > 0 {
                print("📦 Successfully submitted \(imageUrls.count) photos for store \(storeId) (\(duplicateCount) duplicates skipped)")
            } else {
                print("📦 Successfully submitted \(imageUrls.count) photos for store \(storeId)")
            }
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