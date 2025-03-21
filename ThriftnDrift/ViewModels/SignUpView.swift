import SwiftUI
import FirebaseAuth

struct SignUpView: View {
    @EnvironmentObject private var authManager: AuthenticationManager
    @Binding var navigationPath: NavigationPath
    @State private var firstName = ""
    @State private var lastName = ""
    @State private var email = ""
    @State private var password = ""
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var isAnimating = false
    
    var body: some View {
        ZStack {
            Color(UIColor.systemGray6)
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                Text("Create your account")
                    .font(.system(size: 32, weight: .bold))
                    .padding(.top, 60)
                    .padding(.bottom, 40)
                    .opacity(isAnimating ? 1 : 0)
                    .offset(x: isAnimating ? 0 : -20)
                
                VStack(spacing: 16) {
                    SocialLoginButton(
                        title: "CONTINUE WITH APPLE",
                        icon: "AppleLogo",
                        backgroundColor: .black,
                        textColor: .white
                    ) {
                        // Handle Apple signup
                    }
                    .opacity(isAnimating ? 1 : 0)
                    .offset(y: isAnimating ? 0 : 20)
                    
                    SocialLoginButton(
                        title: "CONTINUE WITH GOOGLE",
                        icon: "GoogleLogo",
                        backgroundColor: .white,
                        textColor: .black
                    ) {
                        // Handle Google signup
                    }
                    .overlay(
                        RoundedRectangle(cornerRadius: 27)
                            .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                    )
                    .opacity(isAnimating ? 1 : 0)
                    .offset(y: isAnimating ? 0 : 20)
                }
                .padding(.horizontal, 24)
                
                Text("OR SIGN UP WITH EMAIL")
                    .font(.system(size: 12))
                    .foregroundColor(.gray)
                    .padding(.top, 32)
                    .padding(.bottom, 24)
                    .opacity(isAnimating ? 1 : 0)
                
                VStack(spacing: 16) {
                    TextField("First Name", text: $firstName)
                        .textFieldStyle(PlainTextFieldStyle())
                        .autocapitalization(.words)
                        .padding()
                        .frame(height: 54)
                        .background(Color.white)
                        .cornerRadius(27)
                        .overlay(
                            RoundedRectangle(cornerRadius: 27)
                                .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                        )
                        .opacity(isAnimating ? 1 : 0)
                        .offset(y: isAnimating ? 0 : 20)
                    
                    TextField("Last Name", text: $lastName)
                        .textFieldStyle(PlainTextFieldStyle())
                        .autocapitalization(.words)
                        .padding()
                        .frame(height: 54)
                        .background(Color.white)
                        .cornerRadius(27)
                        .overlay(
                            RoundedRectangle(cornerRadius: 27)
                                .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                        )
                        .opacity(isAnimating ? 1 : 0)
                        .offset(y: isAnimating ? 0 : 20)
                    
                    TextField("Email address", text: $email)
                        .textFieldStyle(PlainTextFieldStyle())
                        .autocapitalization(.none)
                        .keyboardType(.emailAddress)
                        .padding()
                        .frame(height: 54)
                        .background(Color.white)
                        .cornerRadius(27)
                        .overlay(
                            RoundedRectangle(cornerRadius: 27)
                                .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                        )
                        .opacity(isAnimating ? 1 : 0)
                        .offset(y: isAnimating ? 0 : 20)
                    
                    SecureField("Password", text: $password)
                        .textFieldStyle(PlainTextFieldStyle())
                        .padding()
                        .frame(height: 54)
                        .background(Color.white)
                        .cornerRadius(27)
                        .overlay(
                            RoundedRectangle(cornerRadius: 27)
                                .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                        )
                        .opacity(isAnimating ? 1 : 0)
                        .offset(y: isAnimating ? 0 : 20)
                    
                    if showError {
                        Text(errorMessage)
                            .foregroundColor(.red)
                            .font(.system(size: 12))
                            .transition(.opacity)
                            .padding(.top, 8)
                    }
                    
                    Button(action: signUp) {
                        Text("GET STARTED")
                            .font(.system(size: 16, weight: .semibold))
                            .frame(maxWidth: .infinity)
                            .frame(height: 54)
                            .background(Color(red: 0.4, green: 0.5, blue: 0.95))
                            .foregroundColor(.white)
                            .cornerRadius(27)
                    }
                    .padding(.top, 8)
                    .opacity(isAnimating ? 1 : 0)
                    .offset(y: isAnimating ? 0 : 20)
                }
                .padding(.horizontal, 24)
                
                Spacer()
                
                HStack(spacing: 4) {
                    Text("ALREADY HAVE AN ACCOUNT?")
                        .font(.system(size: 12))
                        .foregroundColor(.gray)
                    
                    Button(action: {
                        withAnimation(.easeOut(duration: 0.2)) {
                            navigationPath.removeLast()
                            navigationPath.append("login")
                        }
                    }) {
                        Text("LOG IN")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(Color(red: 0.4, green: 0.5, blue: 0.95))
                    }
                }
                .padding(.bottom, 48)
                .opacity(isAnimating ? 1 : 0)
            }
        }
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button(action: {
                    withAnimation(.easeOut(duration: 0.2)) {
                        navigationPath.removeLast()
                    }
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 16, weight: .semibold))
                        Text("Back")
                            .font(.system(size: 16, weight: .regular))
                    }
                    .foregroundColor(Color(red: 0.4, green: 0.5, blue: 0.95))
                }
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            withAnimation(.easeOut(duration: 0.3)) {
                isAnimating = true
            }
        }
        .onDisappear {
            isAnimating = false
        }
    }
    
    private func signUp() {
        Task {
            do {
                guard !firstName.isEmpty, !lastName.isEmpty, !email.isEmpty, !password.isEmpty else {
                    errorMessage = "Please fill in all fields"
                    showError = true
                    return
                }
                
                try await authManager.signUp(
                    email: email,
                    password: password,
                    firstName: firstName,
                    lastName: lastName
                )
                withAnimation {
                    navigationPath.removeLast(navigationPath.count)
                }
            } catch {
                errorMessage = error.localizedDescription
                showError = true
                print("Sign up error: \(error)")
            }
        }
    }
}
