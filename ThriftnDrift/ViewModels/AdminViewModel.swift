import Foundation
import FirebaseFirestore

@MainActor
class AdminViewModel: ObservableObject {
    @Published var pendingSubmissions: [Store] = []
    @Published var recentlyApproved: [Store] = []
    @Published var isLoading = false
    @Published var error: Error?
    
    private let userService = UserService.shared
    private let db = Firestore.firestore()
    private var submissionsListener: ListenerRegistration?
    private var approvedListener: ListenerRegistration?
    
    init() {
        setupListeners()
    }
    
    deinit {
        submissionsListener?.remove()
        approvedListener?.remove()
    }
    
    private func setupListeners() {
        print("🔍 Setting up admin listeners")
        // Listen for pending submissions
        submissionsListener = db.collection("store_submissions")
            .whereField("verificationStatus", isEqualTo: "pending")
            .addSnapshotListener { [weak self] snapshot, error in
                guard let self = self else { return }
                
                if let error = error {
                    print("❌ Error fetching submissions: \(error)")
                    self.error = error
                    return
                }
                
                guard let documents = snapshot?.documents else {
                    print("⚠️ No documents in snapshot")
                    return
                }
                
                print("📝 Found \(documents.count) pending submissions")
                for doc in documents {
                    print("📄 Document ID: \(doc.documentID)")
                    print("📄 Data: \(doc.data())")
                }
                
                self.pendingSubmissions = documents.compactMap { document in
                    do {
                        return try Firestore.Decoder().decode(Store.self, from: document.data())
                    } catch {
                        print("❌ Error decoding store: \(error)")
                        return nil
                    }
                }
                print("✅ Successfully loaded \(self.pendingSubmissions.count) pending submissions")
            }
        
        // Listen for recently approved stores
        approvedListener = db.collection("stores")
            .whereField("verificationStatus", isEqualTo: "verified")
            .order(by: "lastVerified", descending: true)
            .limit(to: 10)
            .addSnapshotListener { [weak self] snapshot, error in
                guard let self = self else { return }
                
                if let error = error {
                    print("❌ Error fetching approved stores: \(error)")
                    self.error = error
                    return
                }
                
                guard let documents = snapshot?.documents else {
                    print("⚠️ No approved stores found")
                    return
                }
                
                print("📝 Found \(documents.count) approved stores")
                self.recentlyApproved = documents.compactMap { document in
                    do {
                        return try Firestore.Decoder().decode(Store.self, from: document.data())
                    } catch {
                        print("❌ Error decoding approved store: \(error)")
                        return nil
                    }
                }
                print("✅ Successfully loaded \(self.recentlyApproved.count) approved stores")
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
} 