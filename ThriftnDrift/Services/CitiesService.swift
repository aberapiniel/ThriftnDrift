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
    @Published private(set) var selectedState: String = "NC" // Default to NC, can be changed
    private let storeService = StoreService.shared
    private var citiesData: CitiesRoot?
    
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
            
            // Load cities for the selected state
            loadCitiesForState(selectedState)
            
        } catch {
            print("Error loading cities: \(error)")
        }
    }
    
    func loadCitiesForState(_ stateCode: String) {
        guard let stateData = citiesData?.states[stateCode] else {
            print("Error: No data found for state \(stateCode)")
            return
        }
        
        cities = stateData.cities.map { cityData in
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
        
        // Update store counts immediately after loading cities
        Task {
            await updateStoreCounts()
        }
    }
    
    func updateStoreCounts() async {
        var updatedCities = cities
        
        // Update each city's store count and featured stores
        for i in 0..<updatedCities.count {
            let storesInCity = getStoresForCity(updatedCities[i].id)
            updatedCities[i].storeCount = storesInCity.count
            updatedCities[i].featuredStores = storesInCity.prefix(5).map { $0.id }
        }
        
        // Sort cities by store count (most stores first)
        updatedCities.sort { $0.storeCount > $1.storeCount }
        
        // Update the published property on the main thread
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
        cities.first { $0.id == id }
    }
    
    func getStoresForCity(_ cityId: String) -> [Store] {
        guard let city = getCityById(cityId) else { return [] }
        
        // Filter stores based on proximity to city center
        return storeService.getNearbyStores(
            latitude: city.coordinate.latitude,
            longitude: city.coordinate.longitude,
            radiusInMeters: 25000 // 25km radius
        )
    }
    
    // New method to get available states
    func getAvailableStates() -> [(code: String, name: String)] {
        citiesData?.states.map { (code: $0.key, name: $0.value.name) }
            .sorted { $0.name < $1.name } ?? []
    }
    
    // New method to switch states
    func switchToState(_ stateCode: String) {
        selectedState = stateCode
        loadCitiesForState(stateCode)
    }
} 