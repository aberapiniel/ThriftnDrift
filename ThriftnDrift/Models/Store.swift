//
//  Store.swift
//  ThriftnDrift
//
//  Created by Piniel Abera on 3/11/25.
//

// First, create the Models folder inside your project's main folder (ThriftnDrift)
// Then create Store.swift inside it with this content
import Foundation
import CoreLocation
import MapKit
import FirebaseFirestore

struct Store: Identifiable, Codable, Equatable {
    let id: String
    let name: String
    let description: String
    // Address components
    let streetAddress: String
    let city: String
    let state: String
    let zipCode: String
    let latitude: Double
    let longitude: Double
    var imageUrls: [String]
    var imageAttribution: String?
    var rating: Double
    var reviewCount: Int
    let priceRange: String
    let categories: [String]
    
    // Computed property for full address
    var address: String {
        "\(streetAddress), \(city), \(state) \(zipCode)"
    }
    
    // Social media and contact
    var instagram: String?
    var tiktok: String?
    var facebook: String?
    var website: String?
    var phoneNumber: String?
    var isFeatured: Bool
    var featuredRank: Int?
    var featuredUntil: Date?
    
    // Thrift-specific properties
    let acceptsDonations: Bool
    let hasClothingSection: Bool
    let hasFurnitureSection: Bool
    let hasElectronicsSection: Bool
    let lastVerified: Date?
    let isUserSubmitted: Bool
    let verificationStatus: String
    let createdAt: Date
    let submittedBy: String?
    
    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
    
    enum CodingKeys: String, CodingKey {
        case id, name, description
        case streetAddress, city, state, zipCode, address
        case latitude, longitude, imageUrls, imageAttribution
        case rating, reviewCount, priceRange
        case categories, instagram, tiktok, facebook, website, phoneNumber
        case isFeatured, featuredRank, featuredUntil
        case acceptsDonations, hasClothingSection, hasFurnitureSection
        case hasElectronicsSection, lastVerified, isUserSubmitted
        case verificationStatus, createdAt, submittedBy
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        // Required fields
        id = try container.decode(String.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        description = try container.decode(String.self, forKey: .description)
        
        // First try to get the state directly - this is the authoritative source
        let providedState = try container.decode(String.self, forKey: .state)
        
        // Handle address - try individual components first, fall back to combined address
        if let street = try? container.decode(String.self, forKey: .streetAddress),
           let cityVal = try? container.decode(String.self, forKey: .city),
           let zip = try? container.decode(String.self, forKey: .zipCode) {
            // Use individual components
            streetAddress = street
            city = cityVal
            state = providedState // Always use the provided state
            zipCode = zip
        } else if let address = try? container.decode(String.self, forKey: .address) {
            // Parse combined address
            let components = address.components(separatedBy: ", ")
            streetAddress = components.first ?? ""
            
            if components.count >= 3 {
                city = components[1]
                let stateZip = components[2].components(separatedBy: " ")
                // Always use the provided state, not the one from the address
                state = providedState
                zipCode = stateZip.count > 1 ? stateZip[1] : ""
            } else {
                city = components.count > 1 ? components[1] : ""
                state = providedState
                zipCode = ""
            }
        } else {
            // If neither format is available
            streetAddress = ""
            city = ""
            state = providedState
            zipCode = ""
        }
        
        latitude = try container.decode(Double.self, forKey: .latitude)
        longitude = try container.decode(Double.self, forKey: .longitude)
        imageUrls = try container.decodeIfPresent([String].self, forKey: .imageUrls) ?? []
        imageAttribution = try container.decodeIfPresent(String.self, forKey: .imageAttribution)
        rating = try container.decodeIfPresent(Double.self, forKey: .rating) ?? 0
        reviewCount = try container.decodeIfPresent(Int.self, forKey: .reviewCount) ?? 0
        priceRange = try container.decodeIfPresent(String.self, forKey: .priceRange) ?? "$"
        categories = try container.decodeIfPresent([String].self, forKey: .categories) ?? []
        
        // Optional fields
        instagram = try container.decodeIfPresent(String.self, forKey: .instagram)
        tiktok = try container.decodeIfPresent(String.self, forKey: .tiktok)
        facebook = try container.decodeIfPresent(String.self, forKey: .facebook)
        website = try container.decodeIfPresent(String.self, forKey: .website)
        phoneNumber = try container.decodeIfPresent(String.self, forKey: .phoneNumber)
        isFeatured = try container.decodeIfPresent(Bool.self, forKey: .isFeatured) ?? false
        featuredRank = try container.decodeIfPresent(Int.self, forKey: .featuredRank)
        featuredUntil = try container.decodeIfPresent(Date.self, forKey: .featuredUntil)
        
        // Store features
        acceptsDonations = try container.decodeIfPresent(Bool.self, forKey: .acceptsDonations) ?? false
        hasClothingSection = try container.decodeIfPresent(Bool.self, forKey: .hasClothingSection) ?? false
        hasFurnitureSection = try container.decodeIfPresent(Bool.self, forKey: .hasFurnitureSection) ?? false
        hasElectronicsSection = try container.decodeIfPresent(Bool.self, forKey: .hasElectronicsSection) ?? false
        
        // Verification fields
        lastVerified = try container.decodeIfPresent(Date.self, forKey: .lastVerified)
        isUserSubmitted = try container.decodeIfPresent(Bool.self, forKey: .isUserSubmitted) ?? false
        verificationStatus = try container.decodeIfPresent(String.self, forKey: .verificationStatus) ?? "pending"
        createdAt = try container.decodeIfPresent(Date.self, forKey: .createdAt) ?? Date()
        submittedBy = try container.decodeIfPresent(String.self, forKey: .submittedBy)
    }
    
    // Default initializer with required fields
    init(id: String, name: String, description: String, 
         streetAddress: String, city: String, state: String, zipCode: String,
         latitude: Double, longitude: Double, imageUrls: [String],
         imageAttribution: String? = nil,
         rating: Double, reviewCount: Int, priceRange: String, categories: [String],
         instagram: String? = nil, tiktok: String? = nil, facebook: String? = nil,
         website: String? = nil, phoneNumber: String? = nil, isFeatured: Bool = false,
         featuredRank: Int? = nil, featuredUntil: Date? = nil,
         hasClothingSection: Bool = true,
         hasFurnitureSection: Bool = false, hasElectronicsSection: Bool = false,
         lastVerified: Date? = nil, isUserSubmitted: Bool = false,
         verificationStatus: String = "pending", createdAt: Date = Date(),
         submittedBy: String? = nil) {
        self.id = id
        self.name = name
        self.description = description
        self.streetAddress = streetAddress
        self.city = city
        self.state = state
        self.zipCode = zipCode
        self.latitude = latitude
        self.longitude = longitude
        self.imageUrls = imageUrls
        self.imageAttribution = imageAttribution
        self.rating = rating
        self.reviewCount = reviewCount
        self.priceRange = priceRange
        self.categories = categories
        self.instagram = instagram
        self.tiktok = tiktok
        self.facebook = facebook
        self.website = website
        self.phoneNumber = phoneNumber
        self.isFeatured = isFeatured
        self.featuredRank = featuredRank
        self.featuredUntil = featuredUntil
        self.acceptsDonations = false
        self.hasClothingSection = hasClothingSection
        self.hasFurnitureSection = hasFurnitureSection
        self.hasElectronicsSection = hasElectronicsSection
        self.lastVerified = lastVerified
        self.isUserSubmitted = isUserSubmitted
        self.verificationStatus = verificationStatus
        self.createdAt = createdAt
        self.submittedBy = submittedBy
    }
    
    static func == (lhs: Store, rhs: Store) -> Bool {
        lhs.id == rhs.id
    }
    
    // Add encoding support
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        // Required fields
        try container.encode(id, forKey: .id)
        try container.encode(name, forKey: .name)
        try container.encode(description, forKey: .description)
        
        // Address components
        try container.encode(streetAddress, forKey: .streetAddress)
        try container.encode(city, forKey: .city)
        try container.encode(state, forKey: .state)
        try container.encode(zipCode, forKey: .zipCode)
        try container.encode(address, forKey: .address)
        
        // Location and basic info
        try container.encode(latitude, forKey: .latitude)
        try container.encode(longitude, forKey: .longitude)
        try container.encode(imageUrls, forKey: .imageUrls)
        try container.encodeIfPresent(imageAttribution, forKey: .imageAttribution)
        try container.encode(rating, forKey: .rating)
        try container.encode(reviewCount, forKey: .reviewCount)
        try container.encode(priceRange, forKey: .priceRange)
        try container.encode(categories, forKey: .categories)
        
        // Optional social media and contact
        try container.encodeIfPresent(instagram, forKey: .instagram)
        try container.encodeIfPresent(tiktok, forKey: .tiktok)
        try container.encodeIfPresent(facebook, forKey: .facebook)
        try container.encodeIfPresent(website, forKey: .website)
        try container.encodeIfPresent(phoneNumber, forKey: .phoneNumber)
        
        // Featured status
        try container.encode(isFeatured, forKey: .isFeatured)
        try container.encodeIfPresent(featuredRank, forKey: .featuredRank)
        try container.encodeIfPresent(featuredUntil, forKey: .featuredUntil)
        
        // Store features
        try container.encode(acceptsDonations, forKey: .acceptsDonations)
        try container.encode(hasClothingSection, forKey: .hasClothingSection)
        try container.encode(hasFurnitureSection, forKey: .hasFurnitureSection)
        try container.encode(hasElectronicsSection, forKey: .hasElectronicsSection)
        
        // Verification fields
        try container.encodeIfPresent(lastVerified, forKey: .lastVerified)
        try container.encode(isUserSubmitted, forKey: .isUserSubmitted)
        try container.encode(verificationStatus, forKey: .verificationStatus)
        try container.encode(createdAt, forKey: .createdAt)
        try container.encodeIfPresent(submittedBy, forKey: .submittedBy)
    }
}

extension Store {
    static var preview: Store {
        Store(
            id: "1",
            name: "Goodwill SF",
            description: "Your local Goodwill store with a wide selection of second-hand items.",
            streetAddress: "1500 Mission St",
            city: "San Francisco",
            state: "CA",
            zipCode: "94103",
            latitude: 37.7749,
            longitude: -122.4194,
            imageUrls: [],
            imageAttribution: nil,
            rating: 4.2,
            reviewCount: 156,
            priceRange: "$$",
            categories: ["Clothing", "Furniture", "Books", "Electronics"],
            hasClothingSection: true,
            hasFurnitureSection: true,
            hasElectronicsSection: true,
            lastVerified: Date(),
            isUserSubmitted: false,
            verificationStatus: "verified",
            createdAt: Date(),
            submittedBy: nil
        )
    }
}

// End of file
