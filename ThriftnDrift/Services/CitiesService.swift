import Foundation
import CoreLocation

// City data structures
struct CityCoordinate: Codable {
    let latitude: Double
    let longitude: Double
    
    var toCLLocationCoordinate2D: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
}

struct CityData: Codable {
    let id: String
    let name: String
    let description: String
    let coordinate: CityCoordinate
    let imageUrl: String
    let tags: [String]
}

struct StateData: Codable {
    let name: String
    let cities: [CityData]
}

struct CitiesRoot: Codable {
    var states: [String: StateData]
}

struct City: Identifiable {
    let id: String
    let name: String
    let state: String
    let description: String
    let coordinate: CLLocationCoordinate2D
    var storeCount: Int
    let imageUrl: String
    var featuredStores: [String]
    let tags: [String]
}

@MainActor
class CitiesService: ObservableObject {
    static let shared = CitiesService()
    @Published private(set) var cities: [City] = []
    @Published private(set) var selectedState: String = "NC" // Default to NC
    
    private let storeService = StoreService.shared
    private var citiesData: CitiesRoot?
    private var citiesCache: [String: [City]] = [:] // Cache cities by state
    private var storeCounts: [String: Int] = [:] // Cache store counts by city ID
    
    private init() {
        loadCitiesFromJSON()
    }
    
    private func loadCitiesFromJSON() {
        guard let url = Bundle.main.url(forResource: "cities", withExtension: "json") else {
            print("Error: Could not find cities.json in bundle")
            return
        }
        
        do {
            let data = try Data(contentsOf: url)
            let decoder = JSONDecoder()
            citiesData = try decoder.decode(CitiesRoot.self, from: data)
            
            // Pre-load all cities into cache
            for (stateCode, stateData) in citiesData?.states ?? [:] {
                let stateCities = stateData.cities.map { cityData in
                    City(
                        id: cityData.id,
                        name: cityData.name,
                        state: stateCode,
                        description: cityData.description,
                        coordinate: cityData.coordinate.toCLLocationCoordinate2D,
                        storeCount: 0,
                        imageUrl: cityData.imageUrl,
                        featuredStores: [],
                        tags: cityData.tags
                    )
                }
                citiesCache[stateCode] = stateCities
            }
            
            // Load initial state
            loadCitiesForState(selectedState)
            
        } catch {
            print("Error loading cities: \(error)")
        }
    }
    
    func loadCitiesForState(_ stateCode: String) {
        guard let cachedCities = citiesCache[stateCode] else {
            print("Error: No data found for state \(stateCode)")
            return
        }
        
        selectedState = stateCode
        cities = cachedCities
        
        // Update store counts
        Task {
            await updateStoreCounts()
        }
    }
    
    func updateStoreCounts() async {
        var updatedCities = cities
        var newStoreCounts: [String: Int] = [:]
        
        // Update each city's store count and featured stores
        for i in 0..<updatedCities.count {
            let cityId = updatedCities[i].id
            let storesInCity = getStoresForCity(cityId)
            
            updatedCities[i].storeCount = storesInCity.count
            updatedCities[i].featuredStores = storesInCity.prefix(5).map { $0.id }
            newStoreCounts[cityId] = storesInCity.count
        }
        
        // Sort cities by store count (most stores first)
        updatedCities.sort { $0.storeCount > $1.storeCount }
        
        // Update the cache
        storeCounts = newStoreCounts
        if let stateCode = updatedCities.first?.state {
            citiesCache[stateCode] = updatedCities
        }
        
        // Update the published property
        await MainActor.run {
            self.cities = updatedCities
        }
    }
    
    func searchCities(query: String) -> [City] {
        if query.isEmpty {
            return cities
        }
        return cities.filter { city in
            city.name.localizedCaseInsensitiveContains(query) ||
            city.state.localizedCaseInsensitiveContains(query) ||
            city.description.localizedCaseInsensitiveContains(query) ||
            city.tags.contains { $0.localizedCaseInsensitiveContains(query) }
        }
    }
    
    func getCityById(_ id: String) -> City? {
        // First check current cities
        if let city = cities.first(where: { $0.id == id }) {
            return city
        }
        
        // If not found, check all cached cities
        for (_, stateCities) in citiesCache {
            if let city = stateCities.first(where: { $0.id == id }) {
                return city
            }
        }
        
        return nil
    }
    
    func getStoresForCity(_ cityId: String) -> [Store] {
        guard let city = getCityById(cityId) else { return [] }
        
        // Filter stores based on proximity to city center and state
        return storeService.getNearbyStores(
            latitude: city.coordinate.latitude,
            longitude: city.coordinate.longitude,
            radiusInMeters: 25000, // 25km radius
            state: city.state // Add state filter
        )
    }
    
    func getAvailableStates() -> [(code: String, name: String)] {
        citiesData?.states.map { (code: $0.key, name: $0.value.name) }
            .sorted { $0.name < $1.name } ?? []
    }
    
    func switchToState(_ stateCode: String) {
        loadCitiesForState(stateCode)
    }
} 