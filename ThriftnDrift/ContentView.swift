import SwiftUI
import MapKit

struct ContentView: View {
    // Define a region with a default coordinate (e.g., San Francisco)
    @State private var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194),
        span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
    )
    
    var body: some View {
        // Display the map with the region binding
        Map(coordinateRegion: $region)
            .ignoresSafeArea() // Make the map full screen
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
