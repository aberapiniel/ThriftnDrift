import Foundation
import CoreLocation
import Firebase
import FirebaseAuth

enum FindError: Error {
    case notAuthenticated
    case invalidData
    case uploadFailed
    case deleteFailed
}

@MainActor
class FindsService: ObservableObject {
    static let shared = FindsService()
    @Published private(set) var allFinds: [Find] = []
    @Published private(set) var userFinds: [Find] = []
    
    private let authManager = AuthenticationManager()
    
    private init() {
        // Initialize empty arrays
        allFinds = []
        userFinds = []
    }
    
    func addFind(
        description: String,
        price: Double,
        category: String,
        store: Store,
        images: [UIImage] = []
    ) throws {
        guard let userId = Auth.auth().currentUser?.uid,
              let userName = Auth.auth().currentUser?.displayName else {
            throw FindError.notAuthenticated
        }
        
        // TODO: Upload images and get URLs
        let imageUrls: [String] = []
        
        let find = Find(
            id: UUID().uuidString,
            userId: userId,
            userName: userName,
            storeId: store.id,
            storeName: store.name,
            description: description,
            price: price,
            category: category,
            imageUrls: imageUrls,
            location: Find.LocationCoordinate(
                latitude: store.latitude,
                longitude: store.longitude
            ),
            createdAt: Date(),
            likes: 0,
            likedByUsers: [],
            comments: []
        )
        
        allFinds.insert(find, at: 0)
        userFinds.insert(find, at: 0)
        
        // TODO: Save to Firestore
    }
    
    func addComment(to find: Find, text: String) {
        guard let userId = Auth.auth().currentUser?.uid,
              let userName = Auth.auth().currentUser?.displayName else { return }
        
        let comment = Comment(
            id: UUID().uuidString,
            userId: userId,
            userName: userName,
            text: text,
            createdAt: Date()
        )
        
        if let index = allFinds.firstIndex(where: { $0.id == find.id }) {
            allFinds[index].comments.append(comment)
            
            // Update in userFinds if present
            if let userIndex = userFinds.firstIndex(where: { $0.id == find.id }) {
                userFinds[userIndex].comments.append(comment)
            }
        }
        // TODO: Update in Firestore
    }
    
    func toggleLike(for find: Find) {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        
        if let index = allFinds.firstIndex(where: { $0.id == find.id }) {
            var updatedFind = allFinds[index]
            if updatedFind.likedByUsers.contains(userId) {
                updatedFind.likedByUsers.remove(userId)
                updatedFind.likes -= 1
            } else {
                updatedFind.likedByUsers.insert(userId)
                updatedFind.likes += 1
            }
            allFinds[index] = updatedFind
            
            // Update in userFinds if present
            if let userIndex = userFinds.firstIndex(where: { $0.id == find.id }) {
                userFinds[userIndex] = updatedFind
            }
        }
        // TODO: Update in Firestore
    }
    
    func isLikedByCurrentUser(_ find: Find) -> Bool {
        guard let userId = Auth.auth().currentUser?.uid else { return false }
        return find.likedByUsers.contains(userId)
    }
    
    func deleteFind(_ find: Find) {
        allFinds.removeAll { $0.id == find.id }
        userFinds.removeAll { $0.id == find.id }
        // TODO: Delete from Firestore
    }
    
    func isCurrentUserFind(_ find: Find) -> Bool {
        guard let userId = Auth.auth().currentUser?.uid else { return false }
        return find.userId == userId
    }
} 