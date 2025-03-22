import Foundation
import FirebaseFirestore
import FirebaseAuth

@MainActor
class CityRequestService: ObservableObject {
    static let shared = CityRequestService()
    
    @Published private(set) var userRequests: [CityRequest] = []
    @Published private(set) var isLoading = false
    @Published private(set) var error: Error?
    
    private let db = Firestore.firestore()
    private var requestsListener: ListenerRegistration?
    
    private init() {
        print("[CityRequestService] Initializing service")
        setupAuthListener()
    }
    
    private func setupAuthListener() {
        Auth.auth().addStateDidChangeListener { [weak self] (auth, user) in
            print("[CityRequestService] Auth state changed - User: \(user?.uid ?? "nil")")
            if let user = user {
                self?.listenForUserRequests(userId: user.uid)
            } else {
                print("[CityRequestService] No authenticated user")
                self?.userRequests = []
            }
        }
    }
    
    private func listenForUserRequests(userId: String) {
        print("[CityRequestService] Setting up listener for user: \(userId)")
        
        requestsListener?.remove()
        requestsListener = db.collection("city_requests")
            .whereField("requestedBy", isEqualTo: userId)
            .order(by: "requestedAt", descending: true)
            .addSnapshotListener { [weak self] snapshot, error in
                guard let self = self else { return }
                
                if let error = error {
                    print("[CityRequestService] Error listening for requests: \(error.localizedDescription)")
                    self.error = error
                    return
                }
                
                guard let documents = snapshot?.documents else {
                    print("[CityRequestService] No documents in snapshot")
                    return
                }
                
                print("[CityRequestService] Received \(documents.count) documents")
                
                self.userRequests = documents.compactMap { document in
                    do {
                        let request = try document.data(as: CityRequest.self)
                        print("[CityRequestService] Successfully parsed request: \(request.city), \(request.state)")
                        return request
                    } catch {
                        print("[CityRequestService] Error parsing document: \(error)")
                        return nil
                    }
                }
                
                print("[CityRequestService] Updated userRequests count: \(self.userRequests.count)")
            }
    }
    
    func submitRequest(city: String, state: String, notes: String?) async throws {
        guard let userId = Auth.auth().currentUser?.uid else {
            print("[CityRequestService] No authenticated user for submission")
            throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "User not authenticated"])
        }
        
        print("[CityRequestService] Submitting request for \(city), \(state)")
        
        // Check if a similar request already exists
        let existingRequests = try await db.collection("city_requests")
            .whereField("city", isEqualTo: city)
            .whereField("state", isEqualTo: state)
            .whereField("status", isEqualTo: "pending")
            .getDocuments()
        
        if !existingRequests.documents.isEmpty {
            print("[CityRequestService] Found existing request for \(city), \(state)")
            throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "A request for this city is already pending"])
        }
        
        let request = CityRequest(
            city: city,
            state: state,
            requestedBy: userId,
            notes: notes
        )
        
        print("[CityRequestService] Creating new request with ID: \(request.id)")
        
        do {
            try await db.collection("city_requests").document(request.id).setData(from: request)
            print("[CityRequestService] Successfully submitted request")
        } catch {
            print("[CityRequestService] Error submitting request: \(error)")
            throw error
        }
    }
    
    func cancelRequest(_ requestId: String) async throws {
        guard let userId = Auth.auth().currentUser?.uid else {
            print("🌆 Cannot cancel request - no authenticated user")
            throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "User must be logged in"])
        }
        
        print("🌆 Attempting to cancel request: \(requestId)")
        
        let document = try await db.collection("city_requests").document(requestId).getDocument()
        guard let request = try? document.data(as: CityRequest.self),
              request.requestedBy == userId else {
            print("🌆 User not authorized to cancel request")
            throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Not authorized to cancel this request"])
        }
        
        print("🌆 Deleting request: \(requestId)")
        try await db.collection("city_requests").document(requestId).delete()
        print("🌆 Successfully cancelled request")
    }
} 