import Foundation
import FirebaseAuth
import FirebaseFirestore

@MainActor
class UserService: ObservableObject {
    static let shared = UserService()
    private let db = Firestore.firestore()
    
    @Published private(set) var currentUser: User?
    @Published private(set) var isAdmin = false
    
    private init() {
        setupAuthStateListener()
    }
    
    private func setupAuthStateListener() {
        Auth.auth().addStateDidChangeListener { [weak self] _, user in
            Task {
                if let user = user {
                    await self?.fetchUserData(for: user)
                } else {
                    self?.currentUser = nil
                    self?.isAdmin = false
                }
            }
        }
    }
    
    private func fetchUserData(for firebaseUser: FirebaseAuth.User) async {
        do {
            print("🔍 Fetching user data for: \(firebaseUser.email ?? "unknown")")
            
            // Fetch user data
            let docSnapshot = try await db.collection("users").document(firebaseUser.uid).getDocument()
            
            if let user = User(from: docSnapshot) {
                currentUser = user
                print("✅ Found existing user: \(user.email)")
            } else {
                // Create new user document if it doesn't exist
                let newUser = User(from: firebaseUser)
                if let user = newUser {
                    try await createNewUser(user)
                    currentUser = user
                    print("✅ Created new user: \(user.email)")
                }
            }
            
            // Check admin status
            print("🔑 Checking admin status for user ID: \(firebaseUser.uid)")
            do {
                let adminDoc = try await db.collection("admins").document(firebaseUser.uid).getDocument()
                isAdmin = adminDoc.exists
                print(adminDoc.exists ? "👑 User is an admin" : "👤 User is not an admin")
                
                if adminDoc.exists {
                    print("📄 Admin document data: \(adminDoc.data() ?? [:])")
                }
            } catch let error as NSError {
                if error.domain == "FIRFirestoreErrorDomain" && error.code == 7 {
                    print("⚠️ Permission denied accessing admin status. Please update Firestore rules.")
                    print("ℹ️ Required Firestore rules:")
                    print("""
                    match /databases/{database}/documents {
                      match /users/{userId} {
                        allow read, write: if request.auth != null && request.auth.uid == userId;
                      }
                      match /admins/{userId} {
                        allow read: if request.auth != null;
                        allow write: if request.auth != null && exists(/databases/$(database)/documents/admins/$(request.auth.uid));
                      }
                    }
                    """)
                    isAdmin = false
                } else {
                    throw error
                }
            }
            
        } catch {
            print("❌ Error fetching user data: \(error)")
            isAdmin = false
        }
    }
    
    private func createNewUser(_ user: User) async throws {
        try await db.collection("users").document(user.id).setData(user.firestoreData)
    }
    
    // MARK: - Admin Functions
    
    func makeUserAdmin(userId: String) async throws {
        guard isAdmin else { throw UserError.notAuthorized }
        
        // Add user to admins collection
        try await db.collection("admins").document(userId).setData([
            "userId": userId,
            "grantedAt": Timestamp(date: Date()),
            "grantedBy": Auth.auth().currentUser?.uid ?? "unknown",
            "role": "superAdmin"
        ])
    }
    
    func removeAdminStatus(userId: String) async throws {
        guard isAdmin else { throw UserError.notAuthorized }
        try await db.collection("admins").document(userId).delete()
    }
    
    func getSubmissionsByUser(userId: String) async throws -> [Store] {
        let snapshot = try await db.collection("store_submissions")
            .whereField("userId", isEqualTo: userId)
            .getDocuments()
        
        return snapshot.documents.compactMap { doc in
            guard let data = doc.data() as? [String: Any] else { return nil }
            return try? Firestore.Decoder().decode(Store.self, from: data)
        }
    }
    
    // MARK: - Store Submission Management
    
    func approveSubmission(_ storeId: String) async throws {
        guard isAdmin else { throw UserError.notAuthorized }
        
        // Get the submission
        let submissionDoc = try await db.collection("store_submissions").document(storeId).getDocument()
        guard var data = submissionDoc.data() else { throw UserError.submissionNotFound }
        
        // Update verification status and lastVerified
        data["verificationStatus"] = "verified"
        data["lastVerified"] = Timestamp(date: Date())
        
        // Move to verified stores collection
        try await db.collection("stores").document(storeId).setData(data)
        
        // Delete from submissions
        try await db.collection("store_submissions").document(storeId).delete()
    }
    
    func rejectSubmission(_ storeId: String, reason: String) async throws {
        guard isAdmin else { throw UserError.notAuthorized }
        
        try await db.collection("store_submissions").document(storeId).updateData([
            "verificationStatus": "rejected",
            "rejectionReason": reason
        ])
    }
}

enum UserError: LocalizedError {
    case notAuthorized
    case submissionNotFound
    
    var errorDescription: String? {
        switch self {
        case .notAuthorized:
            return "You are not authorized to perform this action"
        case .submissionNotFound:
            return "Store submission not found"
        }
    }
} 