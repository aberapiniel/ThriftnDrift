import SwiftUI
import MapKit
import CoreLocation
import Combine

@MainActor
class MapViewModel: NSObject, ObservableObject {
    @Published var region = MKCoordinateRegion(
        // Default to Raleigh, NC
        center: CLLocationCoordinate2D(latitude: 35.7796, longitude: -78.6382),
        span: MKCoordinateSpan(latitudeDelta: 0.5, longitudeDelta: 0.5)
    )
    
    @Published var stores: [Store] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var hasInitializedStores = false
    @Published var userLocation: CLLocation?
    @Published var authorizationStatus: CLAuthorizationStatus = .notDetermined
    @Published var selectedState: String = "NC" // Default to NC
    
    private let locationManager = CLLocationManager()
    private var isRequestingLocation = false
    private let storeService = StoreService.shared
    private var cancellables = Set<AnyCancellable>()
    
    // Add method to get available states
    func getAvailableStates() -> [(code: String, name: String)] {
        storeService.getAvailableStates()
    }
    
    override init() {
        super.init()
        print("🗺 MapViewModel initialized")
        setupLocationManager()
        setupStoreObserver()
        Task {
            await initializeStores()
        }
    }
    
    private func setupLocationManager() {
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.distanceFilter = 10 // Update location only when moved by 10 meters
        
        // Get initial authorization status
        Task {
            await MainActor.run {
                authorizationStatus = locationManager.authorizationStatus
            }
        }
    }
    
    private func setupStoreObserver() {
        storeService.$stores
            .receive(on: RunLoop.main)
            .sink { [weak self] newStores in
                guard let self = self else { return }
                print("🗺 Received store update, count: \(newStores.count)")
                self.stores = newStores
                if !newStores.isEmpty {
                    self.updateRegionToShowAllStores()
                }
            }
            .store(in: &cancellables)
    }
    
    func initializeStores() async {
        print("🗺 Initializing stores...")
        guard !hasInitializedStores else {
            print("🗺 Stores already initialized, count: \(stores.count)")
            return
        }
        
        isLoading = true
        print("🗺 Loading stores for state: \(selectedState)")
        
        // Initialize store service with the current state
        storeService.switchToState(selectedState)
        
        if stores.isEmpty {
            print("🗺 Warning: No stores loaded!")
            print("🗺 Available states in service: \(storeService.getAvailableStates())")
        } else {
            print("🗺 First store: \(stores[0].name)")
            print("🗺 Store coordinates: \(stores[0].coordinate)")
        }
        
        hasInitializedStores = true
        isLoading = false
    }
    
    func switchToState(_ stateCode: String) async {
        print("🗺 Switching to state: \(stateCode)")
        selectedState = stateCode
        isLoading = true
        
        // Clear existing stores first
        stores = []
        
        // Switch state in service and wait for stores to load
        storeService.switchToState(stateCode)
        
        // Add a small delay to ensure UI updates
        try? await Task.sleep(nanoseconds: 300_000_000)
        
        isLoading = false
    }
    
    private func updateRegionToShowAllStores() {
        let coordinates = stores.map { CLLocationCoordinate2D(latitude: $0.latitude, longitude: $0.longitude) }
        guard !coordinates.isEmpty else { return }
        
        var minLat = coordinates[0].latitude
        var maxLat = coordinates[0].latitude
        var minLon = coordinates[0].longitude
        var maxLon = coordinates[0].longitude
        
        for coordinate in coordinates {
            minLat = min(minLat, coordinate.latitude)
            maxLat = max(maxLat, coordinate.latitude)
            minLon = min(minLon, coordinate.longitude)
            maxLon = max(maxLon, coordinate.longitude)
        }
        
        let center = CLLocationCoordinate2D(
            latitude: (minLat + maxLat) / 2,
            longitude: (minLon + maxLon) / 2
        )
        
        let span = MKCoordinateSpan(
            latitudeDelta: (maxLat - minLat) * 1.5,
            longitudeDelta: (maxLon - minLon) * 1.5
        )
        
        withAnimation(.easeInOut(duration: 0.5)) {
            region = MKCoordinateRegion(center: center, span: span)
        }
    }
    
    private func requestLocationPermission() {
        guard !isRequestingLocation else { return }
        
        isRequestingLocation = true
        print("📍 Requesting location permission")
        locationManager.requestWhenInUseAuthorization()
    }
    
    func checkLocationAuthorization() {
        Task {
            await MainActor.run {
                print("📍 Checking location authorization: \(locationManager.authorizationStatus.rawValue)")
                authorizationStatus = locationManager.authorizationStatus
                
                switch locationManager.authorizationStatus {
                case .notDetermined:
                    requestLocationPermission()
                case .restricted:
                    errorMessage = "Location access is restricted. Please check your device settings."
                case .denied:
                    errorMessage = "Location access is required to find nearby stores. Please enable it in Settings > Privacy > Location Services."
                case .authorizedWhenInUse, .authorizedAlways:
                    print("📍 Location authorized, starting updates")
                    locationManager.startUpdatingLocation()
                @unknown default:
                    break
                }
            }
        }
    }
    
    func centerOnUserLocation() {
        Task {
            await MainActor.run {
                print("📍 Attempting to center on user location")
                
                // First check if location services are enabled
                guard CLLocationManager.locationServicesEnabled() else {
                    errorMessage = "Location services are disabled. Please enable them in Settings > Privacy > Location Services."
                    return
                }
                
                // Then check authorization
                switch locationManager.authorizationStatus {
                case .notDetermined:
                    requestLocationPermission()
                case .restricted, .denied:
                    errorMessage = "Location access is required. Please enable it in Settings > Privacy > Location Services > ThriftnDrift."
                case .authorizedWhenInUse, .authorizedAlways:
                    if let location = userLocation {
                        print("📍 Centering on user location: \(location.coordinate)")
                        withAnimation {
                            region = MKCoordinateRegion(
                                center: location.coordinate,
                                span: MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1)
                            )
                        }
                    } else {
                        print("📍 Starting location updates to get user location")
                        locationManager.startUpdatingLocation()
                        errorMessage = "Getting your location..."
                    }
                @unknown default:
                    break
                }
            }
        }
    }
    
    private func updateRegion(with coordinate: CLLocationCoordinate2D) {
        withAnimation {
            region = MKCoordinateRegion(
                center: coordinate,
                span: MKCoordinateSpan(latitudeDelta: 0.5, longitudeDelta: 0.5)
            )
        }
    }
    
    func searchThriftStores(latitude: Double, longitude: Double) async {
        isLoading = true
        errorMessage = nil
        stores = storeService.getNearbyStores(latitude: latitude, longitude: longitude)
        isLoading = false
    }
    
    func searchStores(query: String) async {
        isLoading = true
        errorMessage = nil
        stores = storeService.searchStores(query: query)
        isLoading = false
    }
}

extension MapViewModel: CLLocationManagerDelegate {
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        print("📍 Location authorization changed: \(manager.authorizationStatus.rawValue)")
        
        Task {
            await MainActor.run {
                self.authorizationStatus = manager.authorizationStatus
                self.isRequestingLocation = false
                
                switch manager.authorizationStatus {
                case .authorizedWhenInUse, .authorizedAlways:
                    print("📍 Location authorized, starting updates")
                    self.errorMessage = nil
                    self.locationManager.startUpdatingLocation()
                case .denied:
                    self.errorMessage = "Location access denied. Please enable it in Settings > Privacy > Location Services > ThriftnDrift."
                case .restricted:
                    self.errorMessage = "Location access is restricted. Please check your device settings."
                case .notDetermined:
                    self.requestLocationPermission()
                @unknown default:
                    break
                }
            }
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        print("📍 Location updated: \(location.coordinate)")
        
        // Filter out old locations
        let howRecent = location.timestamp.timeIntervalSinceNow
        guard abs(howRecent) < 15 else { return }
        
        Task {
            await MainActor.run {
                self.userLocation = location
                
                // Center on user location when we first get it
                withAnimation {
                    self.region = MKCoordinateRegion(
                        center: location.coordinate,
                        span: MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1)
                    )
                }
                
                // Clear any location-related error messages
                if self.errorMessage?.contains("location") == true {
                    self.errorMessage = nil
                }
            }
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("📍 Location error: \(error.localizedDescription)")
        
        Task {
            await MainActor.run {
                if let clError = error as? CLError {
                    switch clError.code {
                    case .denied:
                        self.errorMessage = "Location access denied. Please enable it in Settings > Privacy > Location Services > ThriftnDrift."
                    case .locationUnknown:
                        self.errorMessage = "Unable to determine your location. Please try again."
                    default:
                        self.errorMessage = "Error getting location: \(error.localizedDescription)"
                    }
                } else {
                    self.errorMessage = "Error getting location: \(error.localizedDescription)"
                }
            }
        }
    }
} 