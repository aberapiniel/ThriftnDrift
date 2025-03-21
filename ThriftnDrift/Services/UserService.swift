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
            let docSnapshot = try await db.collection("users").document(firebaseUser.uid).getDocument()
            
            if let user = User(from: docSnapshot) {
                currentUser = user
                isAdmin = user.isAdmin
            } else {
                // Create new user document if it doesn't exist
                let newUser = User(from: firebaseUser)
                if let user = newUser {
                    try await createNewUser(user)
                    currentUser = user
                    isAdmin = user.isAdmin
                }
            }
        } catch {
            print("Error fetching user data: \(error)")
        }
    }
    
    private func createNewUser(_ user: User) async throws {
        try await db.collection("users").document(user.id).setData(user.firestoreData)
    }
    
    // MARK: - Admin Functions
    
    func makeUserAdmin(userId: String) async throws {
        guard isAdmin else { throw UserError.notAuthorized }
        try await db.collection("users").document(userId).updateData(["isAdmin": true])
    }
    
    func removeAdminStatus(userId: String) async throws {
        guard isAdmin else { throw UserError.notAuthorized }
        try await db.collection("users").document(userId).updateData(["isAdmin": false])
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