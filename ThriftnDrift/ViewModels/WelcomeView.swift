import SwiftUI

struct WelcomeView: View {
    @EnvironmentObject private var authManager: AuthenticationManager
    @State private var navigationPath = NavigationPath()
    
    var body: some View {
        NavigationStack(path: $navigationPath) {
            ZStack {
                Color(UIColor.systemGray6)
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Logo and Branding Section
                    VStack(spacing: 24) {
                        Spacer()
                            .frame(height: 60)
                        
                        Image("ThriftDriftLogo")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 100, height: 100)
                        
                        VStack(spacing: 12) {
                            Text("ThriftnDrift")
                                .font(.custom("Futura-Bold", size: 42))  // Modern geometric font
                                .tracking(1.2)  // Increased letter spacing for style
                                .foregroundColor(.black)
                            
                            Text("Explore. Discover. Thrift.")
                                .font(.custom("SF Pro Display", size: 24, relativeTo: .title2))
                                .fontWeight(.medium)
                                .foregroundColor(.gray)
                                .tracking(0.5)
                            
                            Text("New and modern way of thrifting")
                                .font(.custom("SF Pro Display", size: 16, relativeTo: .body))
                                .fontWeight(.regular)
                                .foregroundColor(.gray.opacity(0.8))
                                .tracking(0.3)
                        }
                        
                        Spacer()
                    }
                    .padding(.top, 60)
                    
                    // Action Buttons Section
                    VStack(spacing: 20) {
                        Button(action: { navigationPath.append("signup") }) {
                            Text("SIGN UP")
                                .font(.system(size: 18, weight: .semibold))
                                .frame(maxWidth: .infinity)
                                .frame(height: 56)
                                .background(Color(red: 0.4, green: 0.5, blue: 0.95))
                                .foregroundColor(.white)
                                .cornerRadius(28)
                        }
                        
                        HStack(spacing: 4) {
                            Text("ALREADY HAVE AN ACCOUNT?")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.gray)
                            
                            Button(action: { navigationPath.append("login") }) {
                                Text("LOG IN")
                                    .font(.system(size: 14, weight: .bold))
                                    .foregroundColor(Color(red: 0.4, green: 0.5, blue: 0.95))
                            }
                        }
                    }
                    .padding(.horizontal, 32)
                    .padding(.bottom, 48)
                }
            }
            .navigationDestination(for: String.self) { route in
                switch route {
                case "login":
                    LoginView(navigationPath: $navigationPath)
                case "signup":
                    SignUpView(navigationPath: $navigationPath)
                default:
                    EmptyView()
                }
            }
        }
    }
}

// End of file
