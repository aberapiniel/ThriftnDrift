import Foundation
import FirebaseFirestore

struct Admin: Identifiable {
    let id: String
    let email: String
    let role: String
    let grantedAt: Date
    let grantedBy: String
    let grantedByEmail: String
    let userId: String
    
    init(id: String, email: String, role: String, grantedAt: Date, grantedBy: String, grantedByEmail: String, userId: String) {
        self.id = id
        self.email = email
        self.role = role
        self.grantedAt = grantedAt
        self.grantedBy = grantedBy
        self.grantedByEmail = grantedByEmail
        self.userId = userId
    }
    
    init?(from document: DocumentSnapshot, id: String, email: String, grantedByEmail: String) {
        guard 
            let data = document.data(),
            let role = data["role"] as? String,
            let grantedAt = (data["grantedAt"] as? Timestamp)?.dateValue(),
            let grantedBy = data["grantedBy"] as? String
        else {
            return nil
        }
        
        self.id = id
        self.email = email
        self.role = role
        self.grantedAt = grantedAt
        self.grantedBy = grantedBy
        self.grantedByEmail = grantedByEmail
        self.userId = data["userId"] as? String ?? id
    }
    
    var firestoreData: [String: Any] {
        [
            "email": email,
            "role": role,
            "grantedAt": Timestamp(date: grantedAt),
            "grantedBy": grantedBy,
            "grantedByEmail": grantedByEmail,
            "userId": userId
        ]
    }
} 