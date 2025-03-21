import Foundation
import CoreLocation

struct Find: Identifiable, Codable {
    let id: String
    let userId: String
    let userName: String
    let storeId: String
    let storeName: String
    let description: String
    let price: Double
    let category: String
    let imageUrls: [String]
    let location: LocationCoordinate
    let createdAt: Date
    var likes: Int
    var likedByUsers: Set<String>
    var comments: [Comment]
    
    struct LocationCoordinate: Codable {
        let latitude: Double
        let longitude: Double
    }
}

struct Comment: Identifiable, Codable {
    let id: String
    let userId: String
    let userName: String
    let text: String
    let createdAt: Date
} 