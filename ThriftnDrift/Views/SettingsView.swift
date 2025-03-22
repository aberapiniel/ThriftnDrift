import SwiftUI

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var authManager: AuthenticationManager
    @StateObject private var userService = UserService.shared
    @State private var showingLogoutAlert = false
    @State private var showingErrorAlert = false
    @State private var errorMessage = ""
    
    var body: some View {
        NavigationView {
            ZStack {
                ThemeManager.backgroundStyle
                    .ignoresSafeArea()
                
                List {
                    if userService.isAdmin {
                        Section {
                            NavigationLink(destination: AdminView()) {
                                Label("Admin", systemImage: "shield.fill")
                                    .foregroundColor(ThemeManager.textColor)
                            }
                            .listRowBackground(ThemeManager.warmOverlay.opacity(0.05))
                        }
                    }
                    
                    Section(header: Text("Account").foregroundColor(ThemeManager.textColor)) {
                        NavigationLink(destination: EditProfileView()) {
                            Label("Edit Profile", systemImage: "person.circle")
                                .foregroundColor(ThemeManager.textColor)
                        }
                        .listRowBackground(ThemeManager.warmOverlay.opacity(0.05))
                        
                        NavigationLink(destination: NotificationSettingsView()) {
                            Label("Notifications", systemImage: "bell")
                                .foregroundColor(ThemeManager.textColor)
                        }
                        .listRowBackground(ThemeManager.warmOverlay.opacity(0.05))
                        
                        NavigationLink(destination: PrivacySettingsView()) {
                            Label("Privacy", systemImage: "lock")
                                .foregroundColor(ThemeManager.textColor)
                        }
                        .listRowBackground(ThemeManager.warmOverlay.opacity(0.05))
                    }
                    
                    Section(header: Text("App").foregroundColor(ThemeManager.textColor)) {
                        NavigationLink(destination: AppearanceSettingsView()) {
                            Label("Appearance", systemImage: "paintbrush")
                                .foregroundColor(ThemeManager.textColor)
                        }
                        .listRowBackground(ThemeManager.warmOverlay.opacity(0.05))
                        
                        NavigationLink(destination: Text("Help & Support").foregroundColor(ThemeManager.textColor)) {
                            Label("Help & Support", systemImage: "questionmark.circle")
                                .foregroundColor(ThemeManager.textColor)
                        }
                        .listRowBackground(ThemeManager.warmOverlay.opacity(0.05))
                        
                        NavigationLink(destination: Text("About").foregroundColor(ThemeManager.textColor)) {
                            Label("About", systemImage: "info.circle")
                                .foregroundColor(ThemeManager.textColor)
                        }
                        .listRowBackground(ThemeManager.warmOverlay.opacity(0.05))
                    }
                    
                    Section {
                        Button(action: { showingLogoutAlert = true }) {
                            Label("Log Out", systemImage: "arrow.right.square")
                                .foregroundColor(.red)
                        }
                        .listRowBackground(ThemeManager.warmOverlay.opacity(0.05))
                    }
                }
                .listStyle(.insetGrouped)
                .scrollContentBackground(.hidden)
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                        .foregroundColor(ThemeManager.brandPurple)
                }
            }
            .alert("Log Out", isPresented: $showingLogoutAlert) {
                Button("Cancel", role: .cancel) { }
                Button("Log Out", role: .destructive) {
                    do {
                        try authManager.signOut()
                    } catch {
                        showingErrorAlert = true
                        errorMessage = error.localizedDescription
                    }
                }
            } message: {
                Text("Are you sure you want to log out?")
            }
            .alert("Error", isPresented: $showingErrorAlert) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(errorMessage)
            }
        }
    }
}

struct EditProfileView: View {
    @State private var name = ""
    @State private var bio = ""
    @State private var email = ""
    @State private var showingImagePicker = false
    
    var body: some View {
        Form {
            Section {
                Button(action: { showingImagePicker = true }) {
                    HStack {
                        Image(systemName: "person.circle.fill")
                            .font(.system(size: 60))
                            .foregroundColor(ThemeManager.brandPurple)
                        
                        VStack(alignment: .leading) {
                            Text("Change Profile Photo")
                                .font(.headline)
                                .foregroundColor(ThemeManager.textColor)
                        }
                    }
                }
                .listRowBackground(ThemeManager.warmOverlay.opacity(0.05))
            }
            
            Section(header: Text("Profile Information").foregroundColor(ThemeManager.textColor)) {
                TextField("Name", text: $name)
                    .foregroundColor(ThemeManager.textColor)
                TextField("Bio", text: $bio)
                    .foregroundColor(ThemeManager.textColor)
                TextField("Email", text: $email)
                    .textContentType(.emailAddress)
                    .autocapitalization(.none)
                    .foregroundColor(ThemeManager.textColor)
            }
            .listRowBackground(ThemeManager.warmOverlay.opacity(0.05))
        }
        .scrollContentBackground(.hidden)
        .background(ThemeManager.backgroundStyle)
        .navigationTitle("Edit Profile")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct NotificationSettingsView: View {
    @State private var pushEnabled = true
    @State private var emailEnabled = true
    @State private var newFindsEnabled = true
    @State private var commentsEnabled = true
    @State private var likesEnabled = true
    
    var body: some View {
        Form {
            Section(header: Text("Notification Methods").foregroundColor(ThemeManager.textColor)) {
                Toggle("Push Notifications", isOn: $pushEnabled)
                    .foregroundColor(ThemeManager.textColor)
                    .tint(ThemeManager.brandPurple)
                Toggle("Email Notifications", isOn: $emailEnabled)
                    .foregroundColor(ThemeManager.textColor)
                    .tint(ThemeManager.brandPurple)
            }
            .listRowBackground(ThemeManager.warmOverlay.opacity(0.05))
            
            Section(header: Text("Notify Me About").foregroundColor(ThemeManager.textColor)) {
                Toggle("New Finds", isOn: $newFindsEnabled)
                    .foregroundColor(ThemeManager.textColor)
                    .tint(ThemeManager.brandPurple)
                Toggle("Comments", isOn: $commentsEnabled)
                    .foregroundColor(ThemeManager.textColor)
                    .tint(ThemeManager.brandPurple)
                Toggle("Likes", isOn: $likesEnabled)
                    .foregroundColor(ThemeManager.textColor)
                    .tint(ThemeManager.brandPurple)
            }
            .listRowBackground(ThemeManager.warmOverlay.opacity(0.05))
        }
        .scrollContentBackground(.hidden)
        .background(ThemeManager.backgroundStyle)
        .navigationTitle("Notifications")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct PrivacySettingsView: View {
    @State private var accountPrivate = false
    @State private var showLocation = true
    @State private var allowComments = true
    
    var body: some View {
        Form {
            Section(header: Text("Privacy").foregroundColor(ThemeManager.textColor)) {
                Toggle("Private Account", isOn: $accountPrivate)
                    .foregroundColor(ThemeManager.textColor)
                    .tint(ThemeManager.brandPurple)
                Toggle("Show Location", isOn: $showLocation)
                    .foregroundColor(ThemeManager.textColor)
                    .tint(ThemeManager.brandPurple)
                Toggle("Allow Comments", isOn: $allowComments)
                    .foregroundColor(ThemeManager.textColor)
                    .tint(ThemeManager.brandPurple)
            }
            .listRowBackground(ThemeManager.warmOverlay.opacity(0.05))
            
            Section(header: Text("Data").foregroundColor(ThemeManager.textColor)) {
                Button("Download My Data") {
                    // TODO: Implement data download
                }
                .foregroundColor(ThemeManager.brandPurple)
                .listRowBackground(ThemeManager.warmOverlay.opacity(0.05))
                
                Button("Delete Account") {
                    // TODO: Implement account deletion
                }
                .foregroundColor(.red)
                .listRowBackground(ThemeManager.warmOverlay.opacity(0.05))
            }
        }
        .scrollContentBackground(.hidden)
        .background(ThemeManager.backgroundStyle)
        .navigationTitle("Privacy")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct AppearanceSettingsView: View {
    @State private var isDarkMode = false
    @State private var useSystemSettings = true
    
    var body: some View {
        Form {
            Section(header: Text("Theme")) {
                Toggle("Use System Settings", isOn: $useSystemSettings)
                if !useSystemSettings {
                    Toggle("Dark Mode", isOn: $isDarkMode)
                }
            }
        }
        .navigationTitle("Appearance")
        .navigationBarTitleDisplayMode(.inline)
    }
} 