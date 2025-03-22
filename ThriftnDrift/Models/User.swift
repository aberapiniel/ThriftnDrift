import Foundation
import FirebaseAuth
import FirebaseFirestore

struct User: Identifiable, Codable {
    let id: String
    let email: String
    let displayName: String?
    var storeSubmissions: [String] // IDs of submitted stores
    let createdAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id
        case email
        case displayName
        case storeSubmissions
        case createdAt
    }
    
    init(id: String, email: String, displayName: String? = nil, storeSubmissions: [String] = [], createdAt: Date = Date()) {
        self.id = id
        self.email = email
        self.displayName = displayName
        self.storeSubmissions = storeSubmissions
        self.createdAt = createdAt
    }
    
    // Create from Firebase User
    init?(from firebaseUser: FirebaseAuth.User) {
        self.id = firebaseUser.uid
        self.email = firebaseUser.email ?? ""
        self.displayName = firebaseUser.displayName
        self.storeSubmissions = []
        self.createdAt = Date()
    }
    
    // Create from Firestore document
    init?(from document: DocumentSnapshot) {
        guard 
            let data = document.data(),
            let email = data["email"] as? String,
            let createdAt = (data["createdAt"] as? Timestamp)?.dateValue()
        else {
            return nil
        }
        
        self.id = document.documentID
        self.email = email
        self.displayName = data["displayName"] as? String
        self.storeSubmissions = data["storeSubmissions"] as? [String] ?? []
        self.createdAt = createdAt
    }
    
    // Convert to Firestore data
    var firestoreData: [String: Any] {
        [
            "email": email,
            "displayName": displayName ?? "",
            "storeSubmissions": storeSubmissions,
            "createdAt": Timestamp(date: createdAt)
        ]
    }
} 