import Foundation
import FirebaseFirestore
import FirebaseStorage
import CommonCrypto

@MainActor
class AdminViewModel: ObservableObject {
    @Published var pendingSubmissions: [Store] = []
    @Published var recentlyApproved: [Store] = []
    @Published var pendingPhotoSubmissions: [PhotoSubmission] = []
    @Published var recentlyApprovedPhotos: [PhotoSubmission] = []
    @Published var pendingCityRequests: [CityRequest] = []
    @Published var recentlyCompletedCityRequests: [CityRequest] = []
    @Published var isLoading = false
    @Published var error: Error?
    
    private let userService = UserService.shared
    private let db = Firestore.firestore()
    private var submissionsListener: ListenerRegistration?
    private var approvedListener: ListenerRegistration?
    private var photoSubmissionsListener: ListenerRegistration?
    private var approvedPhotosListener: ListenerRegistration?
    private var cityRequestsListener: ListenerRegistration?
    
    init() {
        setupListeners()
    }
    
    deinit {
        submissionsListener?.remove()
        approvedListener?.remove()
        photoSubmissionsListener?.remove()
        approvedPhotosListener?.remove()
        cityRequestsListener?.remove()
    }
    
    private func setupListeners() {
        print("🔍 Setting up admin listeners")
        
        // Listen for pending submissions
        submissionsListener = db.collection("store_submissions")
            .whereField("verificationStatus", isEqualTo: "pending")
            .addSnapshotListener { [weak self] snapshot, error in
                guard let self = self else { return }
                
                if let error = error {
                    print("❌ Error listening for submissions: \(error)")
                    return
                }
                
                guard let documents = snapshot?.documents else {
                    print("No documents found")
                    return
                }
                
                self.pendingSubmissions = documents.compactMap { document in
                    try? Firestore.Decoder().decode(Store.self, from: document.data())
                }
            }
        
        // Listen for recently approved stores
        approvedListener = db.collection("stores")
            .whereField("verificationStatus", isEqualTo: "verified")
            .order(by: "lastVerified", descending: true)
            .limit(to: 10)
            .addSnapshotListener { [weak self] snapshot, error in
                guard let self = self else { return }
                
                if let error = error {
                    print("❌ Error listening for approved stores: \(error)")
                    return
                }
                
                guard let documents = snapshot?.documents else {
                    print("No documents found")
                    return
                }
                
                self.recentlyApproved = documents.compactMap { document in
                    try? Firestore.Decoder().decode(Store.self, from: document.data())
                }
            }
            
        // Listen for pending photo submissions
        photoSubmissionsListener = db.collection("store_photo_submissions")
            .whereField("status", isEqualTo: "pending")
            .order(by: "submittedAt", descending: true)
            .addSnapshotListener { [weak self] snapshot, error in
                guard let self = self else { return }
                
                if let error = error {
                    print("❌ Error listening for photo submissions: \(error)")
                    return
                }
                
                guard let documents = snapshot?.documents else {
                    print("No photo submissions found")
                    return
                }
                
                self.pendingPhotoSubmissions = documents.compactMap { document in
                    PhotoSubmission(from: document)
                }
            }
            
        // Listen for recently approved photos
        approvedPhotosListener = db.collection("store_photo_submissions")
            .whereField("status", isEqualTo: "approved")
            .order(by: "reviewedAt", descending: true)
            .limit(to: 20)
            .addSnapshotListener { [weak self] snapshot, error in
                guard let self = self else { return }
                
                if let error = error {
                    print("❌ Error listening for approved photos: \(error)")
                    return
                }
                
                guard let documents = snapshot?.documents else {
                    print("No approved photos found")
                    return
                }
                
                self.recentlyApprovedPhotos = documents.compactMap { document in
                    PhotoSubmission(from: document)
                }
            }
        
        setupCityRequestListeners()
    }
    
    private func setupCityRequestListeners() {
        cityRequestsListener?.remove()
        
        cityRequestsListener = db.collection("city_requests")
            .whereField("status", isEqualTo: "pending")
            .order(by: "requestedAt", descending: true)
            .addSnapshotListener { [weak self] snapshot, error in
                guard let self = self else { return }
                
                if let error = error {
                    print("Error listening for city requests: \(error)")
                    return
                }
                
                self.pendingCityRequests = snapshot?.documents.compactMap { document in
                    try? document.data(as: CityRequest.self)
                } ?? []
            }
            
        // Listen for recently completed/rejected requests
        db.collection("city_requests")
            .whereField("status", in: ["completed", "rejected"])
            .order(by: "requestedAt", descending: true)
            .limit(to: 10)
            .addSnapshotListener { [weak self] snapshot, error in
                guard let self = self else { return }
                
                if let error = error {
                    print("Error listening for completed city requests: \(error)")
                    return
                }
                
                self.recentlyCompletedCityRequests = snapshot?.documents.compactMap { document in
                    try? document.data(as: CityRequest.self)
                } ?? []
            }
    }
    
    func loadSubmissions() async {
        guard userService.isAdmin else { return }
        
        isLoading = true
        defer { isLoading = false }
        
        do {
            let pendingSnapshot = try await db.collection("store_submissions")
                .whereField("verificationStatus", isEqualTo: "pending")
                .order(by: "createdAt", descending: true)
                .getDocuments()
            
            pendingSubmissions = pendingSnapshot.documents.compactMap { document in
                try? Firestore.Decoder().decode(Store.self, from: document.data())
            }
            
            let approvedSnapshot = try await db.collection("stores")
                .whereField("verificationStatus", isEqualTo: "verified")
                .order(by: "lastVerified", descending: true)
                .limit(to: 10)
                .getDocuments()
            
            recentlyApproved = approvedSnapshot.documents.compactMap { document in
                try? Firestore.Decoder().decode(Store.self, from: document.data())
            }
            
            let photoSubmissionsSnapshot = try await db.collection("store_photo_submissions")
                .whereField("status", isEqualTo: "pending")
                .order(by: "submittedAt", descending: true)
                .getDocuments()
            
            pendingPhotoSubmissions = photoSubmissionsSnapshot.documents.compactMap { document in
                PhotoSubmission(from: document)
            }
            
        } catch {
            self.error = error
        }
    }
    
    func approveSubmission(_ storeId: String) async throws {
        try await userService.approveSubmission(storeId)
    }
    
    func rejectSubmission(_ storeId: String, reason: String) async throws {
        try await userService.rejectSubmission(storeId, reason: reason)
    }
    
    func approvePhotoSubmission(_ submission: PhotoSubmission) async throws {
        guard userService.isAdmin else { throw UserError.notAuthorized }
        
        // Get the store document
        let storeDoc = try await db.collection("stores").document(submission.storeId).getDocument()
        guard var storeData = storeDoc.data() else { throw UserError.submissionNotFound }
        
        var newUrls: [String] = []
        var duplicateCount = 0
        let storage = Storage.storage()
        
        // Check each submitted URL for duplicates
        for imageUrl in submission.imageUrls {
            let imageRef = storage.reference(forURL: imageUrl)
            
            do {
                // Get the image data
                let data = try await imageRef.data(maxSize: 5 * 1024 * 1024)
                
                // Check if this image is a duplicate in the store's folder
                let storePhotosRef = storage.reference().child("store_photos/\(submission.storeId)")
                let result = try await storePhotosRef.listAll()
                let newImageHash = md5Hash(data)
                var isDuplicate = false
                
                // Check against existing images
                for existingItem in result.items {
                    if existingItem.name == imageRef.name { continue } // Skip comparing with self
                    
                    do {
                        let existingData = try await existingItem.data(maxSize: 5 * 1024 * 1024)
                        let existingHash = md5Hash(existingData)
                        
                        if existingHash == newImageHash {
                            isDuplicate = true
                            break
                        }
                    } catch {
                        print("📸 Error checking existing image \(existingItem.name): \(error)")
                        continue
                    }
                }
                
                if isDuplicate {
                    duplicateCount += 1
                    // Delete duplicate image from storage
                    try? await imageRef.delete()
                } else {
                    // Move the image to the store's folder if it's not already there
                    if !imageRef.fullPath.contains("store_photos/\(submission.storeId)") {
                        let newRef = storePhotosRef.child("\(UUID().uuidString).jpg")
                        let metadata = StorageMetadata()
                        metadata.contentType = "image/jpeg"
                        _ = try await newRef.putData(data, metadata: metadata)
                        let newUrl = try await newRef.downloadURL()
                        newUrls.append(newUrl.absoluteString)
                        // Delete the original image
                        try? await imageRef.delete()
                    } else {
                        newUrls.append(imageUrl)
                    }
                }
            } catch {
                print("📸 Error processing image: \(error)")
                continue
            }
        }
        
        // If all images were duplicates, reject the submission
        if newUrls.isEmpty {
            try await rejectPhotoSubmission(submission)
            throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "All images were duplicates"])
        }
        
        // Get existing URLs
        var existingUrls = storeData["imageUrls"] as? [String] ?? []
        existingUrls.append(contentsOf: newUrls)
        
        // Update store document
        try await db.collection("stores").document(submission.storeId).updateData([
            "imageUrls": existingUrls
        ])
        
        // Update submission status
        try await db.collection("store_photo_submissions").document(submission.id).updateData([
            "status": "approved",
            "reviewedAt": Timestamp(date: Date()),
            "reviewedBy": userService.currentUser?.id ?? "unknown",
            "imageUrls": newUrls  // Update to only include non-duplicate images
        ])
        
        if duplicateCount > 0 {
            print("📸 Approved \(newUrls.count) photos (\(duplicateCount) duplicates skipped)")
        } else {
            print("📸 Approved \(newUrls.count) photos")
        }
    }
    
    // Helper function to generate MD5 hash for image data
    private func md5Hash(_ data: Data) -> String {
        var digest = [UInt8](repeating: 0, count: Int(CC_MD5_DIGEST_LENGTH))
        _ = data.withUnsafeBytes {
            CC_MD5($0.baseAddress, CC_LONG(data.count), &digest)
        }
        return digest.map { String(format: "%02x", $0) }.joined()
    }
    
    func rejectPhotoSubmission(_ submission: PhotoSubmission) async throws {
        guard userService.isAdmin else { throw UserError.notAuthorized }
        
        // Delete images from storage
        let storage = Storage.storage()
        for imageUrl in submission.imageUrls {
            do {
                let imageRef = storage.reference(forURL: imageUrl)
                try await imageRef.delete()
                print("📸 Deleted rejected image: \(imageUrl)")
            } catch {
                print("📸 Error deleting rejected image: \(error)")
            }
        }
        
        // Update submission status
        try await db.collection("store_photo_submissions").document(submission.id).updateData([
            "status": "rejected",
            "reviewedAt": Timestamp(date: Date()),
            "reviewedBy": userService.currentUser?.id ?? "unknown"
        ])
        
        print("📸 Rejected photo submission with \(submission.imageUrls.count) images")
    }
    
    func loadCityRequests() async {
        guard userService.isAdmin else { return }
        
        do {
            let pendingSnapshot = try await db.collection("city_requests")
                .whereField("status", isEqualTo: "pending")
                .order(by: "requestedAt", descending: true)
                .getDocuments()
            
            pendingCityRequests = pendingSnapshot.documents.compactMap { document in
                try? document.data(as: CityRequest.self)
            }
            
            let completedSnapshot = try await db.collection("city_requests")
                .whereField("status", in: ["completed", "rejected"])
                .order(by: "requestedAt", descending: true)
                .limit(to: 10)
                .getDocuments()
            
            recentlyCompletedCityRequests = completedSnapshot.documents.compactMap { document in
                try? document.data(as: CityRequest.self)
            }
        } catch {
            self.error = error
        }
    }
    
    func completeCityRequest(_ requestId: String) async throws {
        guard userService.isAdmin else { throw UserError.notAuthorized }
        
        try await db.collection("city_requests").document(requestId).updateData([
            "status": "completed",
            "completedAt": Timestamp(date: Date()),
            "completedBy": userService.currentUser?.id ?? "unknown"
        ])
    }
    
    func rejectCityRequest(_ requestId: String) async throws {
        guard userService.isAdmin else { throw UserError.notAuthorized }
        
        try await db.collection("city_requests").document(requestId).updateData([
            "status": "rejected",
            "rejectedAt": Timestamp(date: Date()),
            "rejectedBy": userService.currentUser?.id ?? "unknown"
        ])
    }
} 