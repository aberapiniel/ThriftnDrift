import SwiftUI
import MapKit
import FirebaseAuth

struct ContentView: View {
    @StateObject private var authManager = AuthenticationManager()
    @State private var isAnimating = false
    
    var body: some View {
        NavigationView {
            Group {
                if authManager.isAuthenticated {
                    HomeView()
                        .environmentObject(authManager)
                } else {
                    WelcomeView()
                        .environmentObject(authManager)
                }
            }
            .transition(.opacity)
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
