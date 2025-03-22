//
//  ThriftnDriftApp.swift
//  ThriftnDrift
//
//  Created by Piniel Abera on 3/11/25.
//

import SwiftUI
import FirebaseCore

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication,
                   didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        FirebaseApp.configure()
        return true
    }
}

@main
struct ThriftnDriftApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    @StateObject private var userService = UserService.shared
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(AuthenticationManager())
                .environmentObject(userService)
        }
    }
}
