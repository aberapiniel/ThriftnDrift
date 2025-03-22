import Foundation
import FirebaseFirestore

struct PhotoSubmission: Identifiable {
    let id: String
    let storeId: String
    let storeName: String
    let imageUrls: [String]
    let status: String // "pending", "approved", "rejected"
    let submittedBy: String
    let submitterName: String?
    let submittedAt: Date
    let reviewedAt: Date?
    let reviewedBy: String?
    let rejectionReason: String?
    
    init(id: String, storeId: String, storeName: String, imageUrls: [String], status: String, submittedBy: String, 
         submitterName: String?, submittedAt: Date, reviewedAt: Date? = nil, reviewedBy: String? = nil, rejectionReason: String? = nil) {
        self.id = id
        self.storeId = storeId
        self.storeName = storeName
        self.imageUrls = imageUrls
        self.status = status
        self.submittedBy = submittedBy
        self.submitterName = submitterName
        self.submittedAt = submittedAt
        self.reviewedAt = reviewedAt
        self.reviewedBy = reviewedBy
        self.rejectionReason = rejectionReason
    }
    
    init?(from document: DocumentSnapshot) {
        guard
            let data = document.data(),
            let storeId = data["storeId"] as? String,
            let storeName = data["storeName"] as? String,
            let imageUrls = data["imageUrls"] as? [String],
            let status = data["status"] as? String,
            let submittedBy = data["submittedBy"] as? String,
            let submittedAt = (data["submittedAt"] as? Timestamp)?.dateValue()
        else {
            return nil
        }
        
        self.id = document.documentID
        self.storeId = storeId
        self.storeName = storeName
        self.imageUrls = imageUrls
        self.status = status
        self.submittedBy = submittedBy
        self.submitterName = data["submitterName"] as? String
        self.submittedAt = submittedAt
        self.reviewedAt = (data["reviewedAt"] as? Timestamp)?.dateValue()
        self.reviewedBy = data["reviewedBy"] as? String
        self.rejectionReason = data["rejectionReason"] as? String
    }
    
    var firestoreData: [String: Any] {
        var data: [String: Any] = [
            "storeId": storeId,
            "storeName": storeName,
            "imageUrls": imageUrls,
            "status": status,
            "submittedBy": submittedBy,
            "submittedAt": Timestamp(date: submittedAt)
        ]
        
        if let submitterName = submitterName {
            data["submitterName"] = submitterName
        }
        if let reviewedAt = reviewedAt {
            data["reviewedAt"] = Timestamp(date: reviewedAt)
        }
        if let reviewedBy = reviewedBy {
            data["reviewedBy"] = reviewedBy
        }
        if let rejectionReason = rejectionReason {
            data["rejectionReason"] = rejectionReason
        }
        
        return data
    }
} 