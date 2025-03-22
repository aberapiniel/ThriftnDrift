import Foundation
import FirebaseFirestore

struct CityRequest: Identifiable, Codable {
    let id: String
    let city: String
    let state: String
    let requestedBy: String
    let requestedAt: Date
    let status: String // pending, approved, completed, rejected
    let notes: String?
    
    init(id: String = UUID().uuidString,
         city: String,
         state: String,
         requestedBy: String,
         requestedAt: Date = Date(),
         status: String = "pending",
         notes: String? = nil) {
        self.id = id
        self.city = city
        self.state = state
        self.requestedBy = requestedBy
        self.requestedAt = requestedAt
        self.status = status
        self.notes = notes
    }
} 