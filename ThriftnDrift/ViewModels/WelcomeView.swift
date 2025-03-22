import SwiftUI

struct WelcomeView: View {
    @EnvironmentObject private var authManager: AuthenticationManager
    @State private var navigationPath = NavigationPath()
    @State private var isAnimating = false
    
    var body: some View {
        NavigationStack(path: $navigationPath) {
            ZStack {
                // Background with warm gradient
                ThemeManager.backgroundStyle
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
                            .colorMultiply(ThemeManager.brandPurple)
                        
                        VStack(spacing: 12) {
                            Text("ThriftnDrift")
                                .font(.system(size: 42, weight: .bold))
                                .tracking(1.2)
                                .foregroundColor(ThemeManager.textColor)
                                .opacity(isAnimating ? 1 : 0)
                                .offset(y: isAnimating ? 0 : 20)
                            
                            Text("Explore. Discover. Thrift.")
                                .font(.system(size: 24, weight: .medium))
                                .foregroundColor(ThemeManager.textColor.opacity(0.7))
                                .tracking(0.5)
                                .opacity(isAnimating ? 1 : 0)
                                .offset(y: isAnimating ? 0 : 20)
                            
                            Text("New and modern way of thrifting")
                                .font(.system(size: 16, weight: .regular))
                                .foregroundColor(ThemeManager.textColor.opacity(0.5))
                                .tracking(0.3)
                                .opacity(isAnimating ? 1 : 0)
                                .offset(y: isAnimating ? 0 : 20)
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
                                .background(ThemeManager.brandPurple)
                                .foregroundColor(.white)
                                .cornerRadius(28)
                        }
                        .opacity(isAnimating ? 1 : 0)
                        .offset(y: isAnimating ? 0 : 20)
                        
                        HStack(spacing: 4) {
                            Text("ALREADY HAVE AN ACCOUNT?")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(ThemeManager.textColor.opacity(0.6))
                            
                            Button(action: { navigationPath.append("login") }) {
                                Text("LOG IN")
                                    .font(.system(size: 14, weight: .bold))
                                    .foregroundColor(ThemeManager.brandPurple)
                            }
                        }
                        .opacity(isAnimating ? 1 : 0)
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
        .onAppear {
            withAnimation(.easeOut(duration: 0.5)) {
                isAnimating = true
            }
        }
        .onDisappear {
            isAnimating = false
        }
    }
}

// End of file
