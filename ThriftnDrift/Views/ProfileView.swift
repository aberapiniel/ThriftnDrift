import SwiftUI

struct ProfileView: View {
    @StateObject private var findsService = FindsService.shared
    @EnvironmentObject private var authManager: AuthenticationManager
    @State private var showingSettings = false
    @State private var selectedTab = 0
    @StateObject private var userService = UserService.shared
    @StateObject private var cityRequestService = CityRequestService.shared
    @State private var showingSignIn = false
    @State private var showingCityRequest = false
    
    private let themeColor = Color(red: 0.4, green: 0.5, blue: 0.95)
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Profile Header
                VStack(spacing: 16) {
                    Image(systemName: "person.circle.fill")
                        .font(.system(size: 80))
                        .foregroundColor(themeColor)
                    
                    Text(authManager.userDisplayName)
                        .font(.title2)
                        .fontWeight(.semibold)
                }
                .padding(.vertical)
                
                // Tab Picker
                Picker("View", selection: $selectedTab) {
                    Text("My Finds").tag(0)
                    Text("Community").tag(1)
                    Text("City Requests").tag(2)
                }
                .pickerStyle(.segmented)
                .padding()
                
                // Content
                TabView(selection: $selectedTab) {
                    // My Finds Tab
                    MyFindsView()
                        .tag(0)
                    
                    // Community Finds Tab
                    CommunityFindsView()
                        .tag(1)
                    
                    // City Requests Tab
                    CityRequestsView(showingCityRequest: $showingCityRequest)
                        .tag(2)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
            }
            .navigationTitle("Profile")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingSettings = true }) {
                        Image(systemName: "line.3.horizontal")
                            .foregroundColor(themeColor)
                    }
                }
            }
            .sheet(isPresented: $showingSettings) {
                SettingsView()
            }
            .sheet(isPresented: $showingCityRequest) {
                RequestCityView()
            }
        }
    }
    
    private func statusColor(_ status: String) -> Color {
        switch status {
        case "pending":
            return .orange
        case "completed":
            return .green
        case "rejected":
            return .red
        default:
            return .gray
        }
    }
}

struct MyFindsView: View {
    @StateObject private var findsService = FindsService.shared
    @State private var showingAddFind = false
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                ForEach(findsService.userFinds) { find in
                    FindCard(find: find)
                }
            }
            .padding()
        }
        .overlay(alignment: .bottomTrailing) {
            Button(action: { showingAddFind = true }) {
                Image(systemName: "plus.circle.fill")
                    .font(.system(size: 50))
                    .foregroundColor(Color(red: 0.4, green: 0.5, blue: 0.95))
                    .shadow(radius: 3)
            }
            .padding()
        }
        .sheet(isPresented: $showingAddFind) {
            AddFindView()
        }
    }
}

struct CommunityFindsView: View {
    @StateObject private var findsService = FindsService.shared
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                ForEach(findsService.allFinds) { find in
                    FindCard(find: find)
                }
            }
            .padding()
        }
    }
}

struct FindCard: View {
    let find: Find
    @StateObject private var findsService = FindsService.shared
    @State private var showingComments = false
    @State private var showingDeleteAlert = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // User Info
            HStack {
                Image(systemName: "person.circle.fill")
                    .font(.title2)
                Text(find.userName)
                    .font(.headline)
                Spacer()
                Text(find.storeName)
                    .font(.subheadline)
                    .foregroundColor(.gray)
                
                if findsService.isCurrentUserFind(find) {
                    Menu {
                        Button(role: .destructive, action: {
                            showingDeleteAlert = true
                        }) {
                            Label("Delete", systemImage: "trash")
                        }
                    } label: {
                        Image(systemName: "ellipsis")
                            .foregroundColor(.gray)
                    }
                }
            }
            
            // Find Details
            Text(find.description)
                .font(.body)
            
            if !find.imageUrls.isEmpty {
                // Image carousel would go here
                Rectangle()
                    .fill(Color.gray.opacity(0.2))
                    .frame(height: 200)
                    .cornerRadius(12)
            }
            
            // Price and Category
            HStack {
                Text("$\(find.price, specifier: "%.2f")")
                    .font(.headline)
                    .foregroundColor(.green)
                Text("•")
                Text(find.category)
                    .font(.subheadline)
            }
            
            // Location
            HStack {
                Image(systemName: "mappin.circle.fill")
                Text("Found at \(find.storeName)")
            }
            .font(.subheadline)
            .foregroundColor(.gray)
            
            // Actions
            HStack {
                Button(action: { findsService.toggleLike(for: find) }) {
                    HStack {
                        Image(systemName: findsService.isLikedByCurrentUser(find) ? "heart.fill" : "heart")
                            .foregroundColor(findsService.isLikedByCurrentUser(find) ? .red : .gray)
                        Text("\(find.likes)")
                    }
                }
                .animation(.spring(response: 0.3), value: findsService.isLikedByCurrentUser(find))
                
                Spacer()
                
                Button(action: { showingComments = true }) {
                    HStack {
                        Image(systemName: "bubble.left")
                        Text("\(find.comments.count)")
                    }
                }
            }
            .foregroundColor(.gray)
        }
        .padding()
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.1), radius: 5)
        .sheet(isPresented: $showingComments) {
            CommentsView(find: find)
        }
        .alert("Delete Post", isPresented: $showingDeleteAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                findsService.deleteFind(find)
            }
        } message: {
            Text("Are you sure you want to delete this post? This action cannot be undone.")
        }
    }
}

struct CommentsView: View {
    let find: Find
    @StateObject private var findsService = FindsService.shared
    @State private var newComment = ""
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack {
                List {
                    ForEach(find.comments) { comment in
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text(comment.userName)
                                    .font(.headline)
                                Spacer()
                                Text(comment.createdAt, style: .relative)
                                    .font(.caption)
                                    .foregroundColor(.gray)
                            }
                            Text(comment.text)
                        }
                        .padding(.vertical, 4)
                    }
                }
                
                HStack {
                    TextField("Add a comment...", text: $newComment)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                    
                    Button(action: {
                        if !newComment.isEmpty {
                            findsService.addComment(to: find, text: newComment)
                            newComment = ""
                        }
                    }) {
                        Image(systemName: "paperplane.fill")
                    }
                }
                .padding()
            }
            .navigationTitle("Comments")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}

// New view for City Requests tab
struct CityRequestsView: View {
    @StateObject private var cityRequestService = CityRequestService.shared
    @Binding var showingCityRequest: Bool
    
    private let themeColor = Color(red: 0.4, green: 0.5, blue: 0.95)
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Request New City Button
                Button(action: { showingCityRequest = true }) {
                    HStack {
                        Image(systemName: "plus.circle.fill")
                        Text("Request New City")
                    }
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(themeColor)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                }
                .padding(.horizontal)
                
                // Your Requests Section
                if !cityRequestService.userRequests.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Your Requests")
                            .font(.headline)
                            .padding(.horizontal)
                        
                        ForEach(cityRequestService.userRequests) { request in
                            CityRequestCard(request: request)
                        }
                    }
                } else {
                    VStack(spacing: 12) {
                        Image(systemName: "map")
                            .font(.system(size: 50))
                            .foregroundColor(.gray)
                        Text("No city requests yet")
                            .font(.headline)
                        Text("Request a new city to help us expand our thrift store database")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.top, 40)
                }
            }
            .padding(.vertical)
        }
    }
}

struct CityRequestCard: View {
    let request: CityRequest
    @StateObject private var cityRequestService = CityRequestService.shared
    @State private var showingCancelAlert = false
    
    private let themeColor = Color(red: 0.4, green: 0.5, blue: 0.95)
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("\(request.city), \(request.state)")
                    .font(.headline)
                Spacer()
                StatusBadge(status: request.status)
            }
            
            Text("Requested: \(request.requestedAt.formatted(date: .abbreviated, time: .shortened))")
                .font(.caption)
                .foregroundColor(.gray)
            
            if let notes = request.notes {
                Text(notes)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            if request.status == "pending" {
                Button(role: .destructive, action: { showingCancelAlert = true }) {
                    Text("Cancel Request")
                        .font(.subheadline)
                }
                .padding(.top, 4)
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.1), radius: 5)
        .padding(.horizontal)
        .alert("Cancel Request", isPresented: $showingCancelAlert) {
            Button("Keep", role: .cancel) { }
            Button("Cancel Request", role: .destructive) {
                Task {
                    try? await cityRequestService.cancelRequest(request.id)
                }
            }
        } message: {
            Text("Are you sure you want to cancel this city request?")
        }
    }
}

struct StatusBadge: View {
    let status: String
    
    var color: Color {
        switch status {
        case "pending":
            return .orange
        case "completed":
            return .green
        case "rejected":
            return .red
        default:
            return .gray
        }
    }
    
    var body: some View {
        Text(status.capitalized)
            .font(.caption)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(color.opacity(0.2))
            .foregroundColor(color)
            .cornerRadius(8)
    }
}

struct ProfileView_Previews: PreviewProvider {
    static var previews: some View {
        ProfileView()
            .environmentObject(AuthenticationManager())
    }
} 