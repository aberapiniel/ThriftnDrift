//
//  LoginView.swift
//  ThriftnDrift
//
//  Created by Piniel Abera on 3/11/25.
//

import SwiftUI
import FirebaseAuth

struct SocialLoginButton: View {
    let title: String
    let icon: String
    let backgroundColor: Color
    let textColor: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(icon)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 24, height: 24)
                Text(title)
                    .font(.system(size: 16, weight: .medium))
            }
            .frame(maxWidth: .infinity)
            .frame(height: 54)
            .background(backgroundColor)
            .foregroundColor(textColor)
            .cornerRadius(27)
            .overlay(
                RoundedRectangle(cornerRadius: 27)
                    .stroke(Color.gray.opacity(0.3), lineWidth: backgroundColor == .white ? 1 : 0)
            )
        }
    }
}

struct LoginView: View {
    @EnvironmentObject private var authManager: AuthenticationManager
    @Binding var navigationPath: NavigationPath
    @State private var email = ""
    @State private var password = ""
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var isAnimating = false
    
    var body: some View {
        ZStack {
            // Background with warm gradient
            ThemeManager.backgroundStyle
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                Text("Welcome Back!")
                    .font(.system(size: 32, weight: .bold))
                    .foregroundColor(ThemeManager.textColor)
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
                        // Handle Apple login
                    }
                    .opacity(isAnimating ? 1 : 0)
                    .offset(y: isAnimating ? 0 : 20)
                    
                    SocialLoginButton(
                        title: "CONTINUE WITH GOOGLE",
                        icon: "GoogleLogo",
                        backgroundColor: .white,
                        textColor: .black
                    ) {
                        // Handle Google login
                    }
                    .opacity(isAnimating ? 1 : 0)
                    .offset(y: isAnimating ? 0 : 20)
                }
                .padding(.horizontal, 24)
                
                Text("OR LOG IN WITH EMAIL")
                    .font(.system(size: 12))
                    .foregroundColor(ThemeManager.textColor.opacity(0.6))
                    .padding(.top, 32)
                    .padding(.bottom, 24)
                    .opacity(isAnimating ? 1 : 0)
                
                VStack(spacing: 16) {
                    TextField("Email address", text: $email)
                        .textFieldStyle(PlainTextFieldStyle())
                        .autocapitalization(.none)
                        .keyboardType(.emailAddress)
                        .padding()
                        .frame(height: 54)
                        .background(Color.white.opacity(0.8))
                        .cornerRadius(27)
                        .overlay(
                            RoundedRectangle(cornerRadius: 27)
                                .stroke(ThemeManager.mainThemeColor.opacity(0.2), lineWidth: 1)
                        )
                        .opacity(isAnimating ? 1 : 0)
                        .offset(y: isAnimating ? 0 : 20)
                    
                    SecureField("Password", text: $password)
                        .textFieldStyle(PlainTextFieldStyle())
                        .padding()
                        .frame(height: 54)
                        .background(Color.white.opacity(0.8))
                        .cornerRadius(27)
                        .overlay(
                            RoundedRectangle(cornerRadius: 27)
                                .stroke(ThemeManager.mainThemeColor.opacity(0.2), lineWidth: 1)
                        )
                        .opacity(isAnimating ? 1 : 0)
                        .offset(y: isAnimating ? 0 : 20)
                    
                    if !errorMessage.isEmpty {
                        Text(errorMessage)
                            .foregroundColor(.red)
                            .font(.system(size: 12))
                            .transition(.opacity)
                            .padding(.top, 8)
                    }
                    
                    Button(action: login) {
                        Text("LOG IN")
                            .font(.system(size: 16, weight: .semibold))
                            .frame(maxWidth: .infinity)
                            .frame(height: 54)
                            .background(ThemeManager.brandPurple)
                            .foregroundColor(.white)
                            .cornerRadius(27)
                    }
                    .padding(.top, 8)
                    .opacity(isAnimating ? 1 : 0)
                    .offset(y: isAnimating ? 0 : 20)
                    
                    Button(action: { }) {
                        Text("Forgot Password?")
                            .font(.system(size: 14))
                            .foregroundColor(ThemeManager.brandPurple)
                    }
                    .padding(.top, 16)
                    .opacity(isAnimating ? 1 : 0)
                }
                .padding(.horizontal, 24)
                
                Spacer()
                
                HStack(spacing: 4) {
                    Text("DON'T HAVE AN ACCOUNT?")
                        .font(.system(size: 12))
                        .foregroundColor(ThemeManager.textColor.opacity(0.6))
                    
                    Button(action: {
                        withAnimation(.easeOut(duration: 0.2)) {
                            navigationPath.removeLast()
                            navigationPath.append("signup")
                        }
                    }) {
                        Text("SIGN UP")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(ThemeManager.brandPurple)
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
                    .foregroundColor(ThemeManager.brandPurple)
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
    
    private func login() {
        guard !email.isEmpty else {
            errorMessage = "Please enter your email"
            return
        }
        guard !password.isEmpty else {
            errorMessage = "Please enter your password"
            return
        }
        
        Task {
            do {
                try await authManager.signIn(email: email, password: password)
                withAnimation {
                    navigationPath.removeLast(navigationPath.count)
                }
            } catch {
                errorMessage = "Invalid email or password. Please try again."
                print("Login error: \(error)")
            }
        }
    }
}
