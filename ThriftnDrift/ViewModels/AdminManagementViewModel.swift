import Foundation
import FirebaseFirestore
import FirebaseAuth

@MainActor
class AdminManagementViewModel: ObservableObject {
    @Published private(set) var admins: [Admin] = []
    @Published private(set) var isLoading = false
    
    private let db = Firestore.firestore()
    private let userService = UserService.shared
    private var adminsListener: ListenerRegistration?
    
    init() {
        setupListener()
    }
    
    deinit {
        adminsListener?.remove()
    }
    
    private func setupListener() {
        adminsListener = db.collection("admins")
            .addSnapshotListener { [weak self] snapshot, error in
                guard let self = self else { return }
                
                if let error = error {
                    print("❌ Error listening for admin updates: \(error)")
                    return
                }
                
                guard let documents = snapshot?.documents else {
                    print("⚠️ No admin documents found")
                    return
                }
                
                Task {
                    do {
                        let adminDocs = try await withThrowingTaskGroup(of: Admin?.self) { group in
                            for document in documents {
                                group.addTask {
                                    // Get the user document to get the email
                                    let userDoc = try await self.db.collection("users").document(document.documentID).getDocument()
                                    guard let userData = userDoc.data(),
                                          let email = userData["email"] as? String else { return nil }
                                    
                                    // Get the granter's email
                                    let data = document.data()
                                    let grantedByUserId = data["grantedBy"] as? String ?? "unknown"
                                    let granterDoc = try await self.db.collection("users").document(grantedByUserId).getDocument()
                                    let granterData = granterDoc.data()
                                    let grantedByEmail = granterData?["email"] as? String ?? "unknown"
                                    
                                    return Admin(from: document, id: document.documentID, email: email, grantedByEmail: grantedByEmail)
                                }
                            }
                            
                            var admins: [Admin] = []
                            for try await admin in group {
                                if let admin = admin {
                                    admins.append(admin)
                                }
                            }
                            return admins
                        }
                        
                        await MainActor.run {
                            self.admins = adminDocs.sorted { $0.grantedAt > $1.grantedAt }
                        }
                    } catch {
                        print("❌ Error processing admin documents: \(error)")
                    }
                }
            }
    }
    
    func addAdmin(email: String) async throws {
        guard userService.isAdmin else { throw UserError.notAuthorized }
        
        // Find user with this email
        let userSnapshot = try await db.collection("users")
            .whereField("email", isEqualTo: email)
            .getDocuments()
        
        guard let userDoc = userSnapshot.documents.first else {
            throw AdminError.userNotFound
        }
        
        // Check if already admin
        let adminDoc = try await db.collection("admins").document(userDoc.documentID).getDocument()
        guard !adminDoc.exists else {
            throw AdminError.alreadyAdmin
        }
        
        // Get current user's email
        let currentUserId = Auth.auth().currentUser?.uid ?? "unknown"
        let currentUserDoc = try await db.collection("users").document(currentUserId).getDocument()
        let currentUserEmail = currentUserDoc.data()?["email"] as? String ?? "unknown"
        
        // Add to admins collection
        try await db.collection("admins").document(userDoc.documentID).setData([
            "email": email,  // Store the email
            "role": "admin",
            "grantedAt": Timestamp(date: Date()),
            "grantedBy": currentUserId,
            "grantedByEmail": currentUserEmail,
            "userId": userDoc.documentID  // Store the user ID
        ])
    }
    
    func removeAdmin(_ adminId: String) async throws {
        guard userService.isAdmin else { throw UserError.notAuthorized }
        
        // Cannot remove yourself
        guard adminId != Auth.auth().currentUser?.uid else {
            throw AdminError.cannotRemoveSelf
        }
        
        try await db.collection("admins").document(adminId).delete()
    }
}

enum AdminError: LocalizedError {
    case userNotFound
    case alreadyAdmin
    case cannotRemoveSelf
    
    var errorDescription: String? {
        switch self {
        case .userNotFound:
            return "No user found with this email"
        case .alreadyAdmin:
            return "This user is already an admin"
        case .cannotRemoveSelf:
            return "You cannot remove your own admin privileges"
        }
    }
} 