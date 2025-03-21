//
//  AuthenticationManager.swift
//  ThriftnDrift
//
//  Created by Piniel Abera on 3/11/25.
//

import Foundation
import FirebaseAuth

@MainActor
class AuthenticationManager: ObservableObject {
    @Published var firebaseUser: FirebaseAuth.User?
    @Published var isAuthenticated = false
    private var handle: AuthStateDidChangeListenerHandle?
    
    init() {
        // Store the listener handle
        handle = Auth.auth().addStateDidChangeListener { [weak self] _, user in
            self?.firebaseUser = user
            self?.isAuthenticated = user != nil
        }
    }
    
    deinit {
        // Remove the listener when the manager is deallocated
        if let handle = handle {
            Auth.auth().removeStateDidChangeListener(handle)
        }
    }
    
    func signIn(email: String, password: String) async throws {
        let authResult = try await Auth.auth().signIn(withEmail: email, password: password)
        self.firebaseUser = authResult.user
        self.isAuthenticated = true
    }
    
    func signUp(email: String, password: String, firstName: String, lastName: String) async throws {
        let authResult = try await Auth.auth().createUser(withEmail: email, password: password)
        
        // Update the user's display name with their full name
        let changeRequest = authResult.user.createProfileChangeRequest()
        changeRequest.displayName = "\(firstName) \(lastName)"
        try await changeRequest.commitChanges()
        
        self.firebaseUser = authResult.user
        self.isAuthenticated = true
    }
    
    func signOut() throws {
        try Auth.auth().signOut()
        self.firebaseUser = nil
        self.isAuthenticated = false
    }
    
    var userDisplayName: String {
        firebaseUser?.displayName ?? "there"
    }
}
