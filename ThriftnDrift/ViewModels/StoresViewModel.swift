import Foundation
import Combine
import CoreLocation
import FirebaseFirestore

@MainActor
class StoresViewModel: NSObject, ObservableObject {
    @Published var stores: [Store] = []
    @Published var searchText = ""
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var userLocation: CLLocationCoordinate2D?
    
    private var cancellables = Set<AnyCancellable>()
    private let storeService = StoreService.shared
    private let locationManager = CLLocationManager()
    
    override init() {
        super.init()
        setupSearchObserver()
        setupLocationObserver()
    }
    
    private func setupSearchObserver() {
        $searchText
            .debounce(for: .milliseconds(300), scheduler: RunLoop.main)
            .sink { [weak self] text in
                if !text.isEmpty {
                    Task {
                        await self?.searchStores(query: text)
                    }
                }
            }
            .store(in: &cancellables)
    }
    
    private func setupLocationObserver() {
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.requestWhenInUseAuthorization()
    }
    
    func fetchNearbyStores() async {
        isLoading = true
        errorMessage = nil
        
        if let location = userLocation {
            stores = storeService.getNearbyStores(
                latitude: location.latitude,
                longitude: location.longitude
            )
        } else {
            // Default to Raleigh, NC if no location available
            stores = storeService.getNearbyStores(
                latitude: 35.7796,
                longitude: -78.6382
            )
        }
        
        isLoading = false
    }
    
    func searchStores(query: String) async {
        isLoading = true
        errorMessage = nil
        
        stores = storeService.searchStores(query: query)
        
        isLoading = false
    }
}

extension StoresViewModel: CLLocationManagerDelegate {
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        switch manager.authorizationStatus {
        case .denied, .restricted:
            errorMessage = "Location access is needed to find stores near you. Please enable it in Settings."
        case .authorizedWhenInUse, .authorizedAlways:
            manager.startUpdatingLocation()
        default:
            break
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        userLocation = location.coordinate
        Task {
            await fetchNearbyStores()
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        errorMessage = "Error getting location: \(error.localizedDescription)"
    }
}

