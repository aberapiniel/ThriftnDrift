import CoreLocation
import SwiftUI

// Notification names for location updates
extension Notification.Name {
    static let locationDidUpdate = Notification.Name("locationDidUpdate")
    static let locationAuthorizationDidChange = Notification.Name("locationAuthorizationDidChange")
}

@MainActor
class LocationManager: NSObject, ObservableObject {
    static let shared = LocationManager()
    
    @Published var location: CLLocation?
    @Published var authorizationStatus: CLAuthorizationStatus = .notDetermined
    @Published var errorMessage: String?
    
    private let locationManager = CLLocationManager()
    
    private override init() {
        super.init()
        setupLocationManager()
    }
    
    private func setupLocationManager() {
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.distanceFilter = 10 // Update location only when moved by 10 meters
        
        // Check initial authorization status
        authorizationStatus = locationManager.authorizationStatus
        
        // If we're already authorized, start updating location
        if authorizationStatus == .authorizedWhenInUse || authorizationStatus == .authorizedAlways {
            startUpdatingLocation()
        }
    }
    
    func requestLocationPermission() {
        print("📍 Requesting location permission")
        // Only request if we're in not determined state
        if authorizationStatus == .notDetermined {
            locationManager.requestWhenInUseAuthorization()
        } else if authorizationStatus == .denied {
            // If denied, prompt user to enable in settings
            errorMessage = "Please enable location access in Settings to find stores near you."
        }
    }
    
    func startUpdatingLocation() {
        print("📍 Starting location updates")
        if CLLocationManager.locationServicesEnabled() {
            locationManager.startUpdatingLocation()
        } else {
            errorMessage = "Location services are disabled. Please enable them in Settings."
        }
    }
    
    func stopUpdatingLocation() {
        print("📍 Stopping location updates")
        locationManager.stopUpdatingLocation()
    }
}

extension LocationManager: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        
        // Filter out old or invalid locations
        let howRecent = location.timestamp.timeIntervalSinceNow
        guard abs(howRecent) < 15 else { return }
        
        print("📍 Location updated: \(location.coordinate)")
        self.location = location
        self.errorMessage = nil
        
        // Post notification for location update
        NotificationCenter.default.post(
            name: .locationDidUpdate,
            object: self,
            userInfo: ["location": location]
        )
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("📍 Location error: \(error.localizedDescription)")
        
        if let clError = error as? CLError {
            switch clError.code {
            case .denied:
                errorMessage = "Location access denied. Please enable it in Settings."
            case .locationUnknown:
                errorMessage = "Unable to determine your location."
            default:
                errorMessage = "Error getting location: \(error.localizedDescription)"
            }
        } else {
            errorMessage = "Error getting location: \(error.localizedDescription)"
        }
    }
    
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        print("📍 Location authorization changed: \(manager.authorizationStatus.rawValue)")
        withAnimation {
            authorizationStatus = manager.authorizationStatus
        }
        
        // Post notification for authorization change
        NotificationCenter.default.post(
            name: .locationAuthorizationDidChange,
            object: self,
            userInfo: ["status": manager.authorizationStatus]
        )
        
        switch manager.authorizationStatus {
        case .authorizedWhenInUse, .authorizedAlways:
            print("📍 Location authorized, starting updates")
            errorMessage = nil
            startUpdatingLocation()
        case .denied, .restricted:
            print("📍 Location access denied")
            errorMessage = "Location access is needed to find stores near you. Please enable it in Settings."
        case .notDetermined:
            print("📍 Location permission not determined")
            // Don't request here - let the UI trigger the request
        @unknown default:
            break
        }
    }
} 