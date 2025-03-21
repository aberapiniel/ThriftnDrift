import SwiftUI

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var authManager: AuthenticationManager
    @State private var showingLogoutAlert = false
    @State private var showingErrorAlert = false
    @State private var errorMessage = ""
    
    private let themeColor = Color(red: 0.4, green: 0.5, blue: 0.95)
    
    var body: some View {
        NavigationView {
            List {
                Section(header: Text("Account")) {
                    NavigationLink(destination: EditProfileView()) {
                        Label("Edit Profile", systemImage: "person.circle")
                    }
                    
                    NavigationLink(destination: NotificationSettingsView()) {
                        Label("Notifications", systemImage: "bell")
                    }
                    
                    NavigationLink(destination: PrivacySettingsView()) {
                        Label("Privacy", systemImage: "lock")
                    }
                }
                
                Section(header: Text("App")) {
                    NavigationLink(destination: AppearanceSettingsView()) {
                        Label("Appearance", systemImage: "paintbrush")
                    }
                    
                    NavigationLink(destination: Text("Help & Support")) {
                        Label("Help & Support", systemImage: "questionmark.circle")
                    }
                    
                    NavigationLink(destination: Text("About")) {
                        Label("About", systemImage: "info.circle")
                    }
                }
                
                Section {
                    Button(action: { showingLogoutAlert = true }) {
                        Label("Log Out", systemImage: "arrow.right.square")
                            .foregroundColor(.red)
                    }
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
            .alert("Log Out", isPresented: $showingLogoutAlert) {
                Button("Cancel", role: .cancel) { }
                Button("Log Out", role: .destructive) {
                    Task {
                        do {
                            try await authManager.signOut()
                        } catch {
                            errorMessage = error.localizedDescription
                            showingErrorAlert = true
                        }
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
        .accentColor(themeColor)
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
                        
                        VStack(alignment: .leading) {
                            Text("Change Profile Photo")
                                .font(.headline)
                        }
                    }
                    .foregroundColor(.primary)
                }
            }
            
            Section(header: Text("Profile Information")) {
                TextField("Name", text: $name)
                TextField("Bio", text: $bio)
                TextField("Email", text: $email)
                    .textContentType(.emailAddress)
                    .autocapitalization(.none)
            }
        }
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
            Section(header: Text("Notification Methods")) {
                Toggle("Push Notifications", isOn: $pushEnabled)
                Toggle("Email Notifications", isOn: $emailEnabled)
            }
            
            Section(header: Text("Notify Me About")) {
                Toggle("New Finds", isOn: $newFindsEnabled)
                Toggle("Comments", isOn: $commentsEnabled)
                Toggle("Likes", isOn: $likesEnabled)
            }
        }
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
            Section(header: Text("Privacy")) {
                Toggle("Private Account", isOn: $accountPrivate)
                Toggle("Show Location", isOn: $showLocation)
                Toggle("Allow Comments", isOn: $allowComments)
            }
            
            Section(header: Text("Data")) {
                Button("Download My Data") {
                    // TODO: Implement data download
                }
                
                Button("Delete Account") {
                    // TODO: Implement account deletion
                }
                .foregroundColor(.red)
            }
        }
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