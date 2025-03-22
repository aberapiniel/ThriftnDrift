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
    
    // Warm vintage colors
    private let terracotta = Color(red: 0.89, green: 0.47, blue: 0.34) // #E37857
    private let taupe = Color(red: 0.78, green: 0.70, blue: 0.62) // #C7B39E
    private let cream = Color(red: 0.96, green: 0.93, blue: 0.86) // #F5EDD9
    
    var body: some View {
        ZStack(alignment: .top) {
            // Background gradient
            LinearGradient(
                colors: [cream, taupe, terracotta],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Profile Header
                VStack(spacing: 20) {
                    // Profile image
                    ZStack {
                        Circle()
                            .fill(.white)
                            .frame(width: 120, height: 120)
                            .shadow(color: Color.black.opacity(0.1), radius: 10)
                        
                        Image(systemName: "person.circle.fill")
                            .font(.system(size: 80))
                            .foregroundColor(terracotta)
                    }
                    .offset(y: 60)
                    .zIndex(1)
                    
                    Spacer()
                        .frame(height: 40)
                }
                .padding(.top, 32)
                
                // White curved overlay
                VStack {
                    // User info
                    Text(authManager.userDisplayName)
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundColor(ThemeManager.textColor)
                        .padding(.top, 60)
                    
                    // Tab Picker
                    Picker("View", selection: $selectedTab) {
                        Text("My Finds").tag(0)
                        Text("Community").tag(1)
                        Text("City Requests").tag(2)
                    }
                    .pickerStyle(.segmented)
                    .padding()
                    .tint(terracotta)
                    
                    // Content
                    TabView(selection: $selectedTab) {
                        MyFindsView()
                            .tag(0)
                        CommunityFindsView()
                            .tag(1)
                        CityRequestsView(showingCityRequest: $showingCityRequest)
                            .tag(2)
                    }
                    .tabViewStyle(.page(indexDisplayMode: .never))
                }
                .frame(maxWidth: .infinity)
                .background(
                    Color.white
                        .clipShape(
                            CurvedShape()
                        )
                )
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: { showingSettings = true }) {
                    Image(systemName: "gearshape.fill")
                        .foregroundColor(.white)
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

// Custom shape for the curved top edge
struct CurvedShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        
        let curveHeight: CGFloat = 30
        let controlPoint1 = CGPoint(x: rect.width * 0.25, y: 0)
        let controlPoint2 = CGPoint(x: rect.width * 0.75, y: 0)
        
        path.move(to: CGPoint(x: 0, y: curveHeight))
        path.addCurve(
            to: CGPoint(x: rect.width, y: curveHeight),
            control1: controlPoint1,
            control2: controlPoint2
        )
        path.addLine(to: CGPoint(x: rect.width, y: rect.height))
        path.addLine(to: CGPoint(x: 0, y: rect.height))
        path.closeSubpath()
        
        return path
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
        .background(ThemeManager.backgroundStyle)
        .overlay(alignment: .bottomTrailing) {
            Button(action: { showingAddFind = true }) {
                Image(systemName: "plus.circle.fill")
                    .font(.system(size: 50))
                    .foregroundColor(ThemeManager.brandPurple)
                    .shadow(color: ThemeManager.warmOverlay.opacity(0.3), radius: 3)
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
        .background(ThemeManager.backgroundStyle)
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
                    .foregroundColor(ThemeManager.brandPurple)
                Text(find.userName)
                    .font(.headline)
                    .foregroundColor(ThemeManager.textColor)
                Spacer()
                Text(find.storeName)
                    .font(.subheadline)
                    .foregroundColor(ThemeManager.textColor.opacity(0.7))
                
                if findsService.isCurrentUserFind(find) {
                    Menu {
                        Button(role: .destructive, action: {
                            showingDeleteAlert = true
                        }) {
                            Label("Delete", systemImage: "trash")
                        }
                    } label: {
                        Image(systemName: "ellipsis")
                            .foregroundColor(ThemeManager.textColor.opacity(0.7))
                    }
                }
            }
            
            // Find Details
            Text(find.description)
                .font(.body)
                .foregroundColor(ThemeManager.textColor)
            
            if !find.imageUrls.isEmpty {
                // Image carousel would go here
                Rectangle()
                    .fill(ThemeManager.warmOverlay.opacity(0.1))
                    .frame(height: 200)
                    .cornerRadius(12)
            }
            
            // Price and Category
            HStack {
                Text("$\(find.price, specifier: "%.2f")")
                    .font(.headline)
                    .foregroundColor(ThemeManager.brandPurple)
                Text("•")
                    .foregroundColor(ThemeManager.textColor.opacity(0.7))
                Text(find.category)
                    .font(.subheadline)
                    .foregroundColor(ThemeManager.textColor.opacity(0.7))
            }
            
            // Location
            HStack {
                Image(systemName: "mappin.circle.fill")
                    .foregroundColor(ThemeManager.brandPurple)
                Text("Found at \(find.storeName)")
            }
            .font(.subheadline)
            .foregroundColor(ThemeManager.textColor.opacity(0.7))
            
            // Actions
            HStack {
                Button(action: { findsService.toggleLike(for: find) }) {
                    HStack {
                        Image(systemName: findsService.isLikedByCurrentUser(find) ? "heart.fill" : "heart")
                            .foregroundColor(findsService.isLikedByCurrentUser(find) ? .red : ThemeManager.textColor.opacity(0.7))
                        Text("\(find.likes)")
                            .foregroundColor(ThemeManager.textColor.opacity(0.7))
                    }
                }
                .animation(.spring(response: 0.3), value: findsService.isLikedByCurrentUser(find))
                
                Spacer()
                
                Button(action: { showingComments = true }) {
                    HStack {
                        Image(systemName: "bubble.left")
                        Text("\(find.comments.count)")
                    }
                    .foregroundColor(ThemeManager.textColor.opacity(0.7))
                }
            }
        }
        .padding()
        .background(ThemeManager.warmOverlay.opacity(0.05))
        .cornerRadius(12)
        .shadow(color: ThemeManager.warmOverlay.opacity(0.1), radius: 5)
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
                                    .foregroundColor(ThemeManager.textColor)
                                Spacer()
                                Text(comment.createdAt, style: .relative)
                                    .font(.caption)
                                    .foregroundColor(ThemeManager.textColor.opacity(0.7))
                            }
                            Text(comment.text)
                                .foregroundColor(ThemeManager.textColor)
                        }
                        .padding(.vertical, 4)
                        .listRowBackground(ThemeManager.warmOverlay.opacity(0.05))
                    }
                }
                .listStyle(.plain)
                
                HStack {
                    TextField("Add a comment...", text: $newComment)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .foregroundColor(ThemeManager.textColor)
                    
                    Button(action: {
                        if !newComment.isEmpty {
                            findsService.addComment(to: find, text: newComment)
                            newComment = ""
                        }
                    }) {
                        Image(systemName: "paperplane.fill")
                            .foregroundColor(ThemeManager.brandPurple)
                    }
                }
                .padding()
                .background(ThemeManager.warmOverlay.opacity(0.05))
            }
            .background(ThemeManager.backgroundStyle)
            .navigationTitle("Comments")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                        .foregroundColor(ThemeManager.brandPurple)
                }
            }
        }
    }
}

struct CityRequestsView: View {
    @StateObject private var cityRequestService = CityRequestService.shared
    @Binding var showingCityRequest: Bool
    
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
                    .background(ThemeManager.brandPurple)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                }
                .padding(.horizontal)
                
                // Your Requests Section
                if !cityRequestService.userRequests.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Your Requests")
                            .font(.headline)
                            .foregroundColor(ThemeManager.textColor)
                            .padding(.horizontal)
                        
                        ForEach(cityRequestService.userRequests) { request in
                            CityRequestCard(request: request)
                        }
                    }
                } else {
                    VStack(spacing: 12) {
                        Image(systemName: "map")
                            .font(.system(size: 50))
                            .foregroundColor(ThemeManager.textColor.opacity(0.7))
                        Text("No city requests yet")
                            .font(.headline)
                            .foregroundColor(ThemeManager.textColor)
                        Text("Request a new city to help us expand our thrift store database")
                            .font(.subheadline)
                            .foregroundColor(ThemeManager.textColor.opacity(0.7))
                            .multilineTextAlignment(.center)
                    }
                    .padding(.top, 40)
                }
            }
            .padding(.vertical)
        }
        .background(ThemeManager.backgroundStyle)
    }
}

struct CityRequestCard: View {
    let request: CityRequest
    @StateObject private var cityRequestService = CityRequestService.shared
    @State private var showingCancelAlert = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("\(request.city), \(request.state)")
                    .font(.headline)
                    .foregroundColor(ThemeManager.textColor)
                Spacer()
                StatusBadge(status: request.status)
            }
            
            Text("Requested: \(request.requestedAt.formatted(date: .abbreviated, time: .shortened))")
                .font(.caption)
                .foregroundColor(ThemeManager.textColor.opacity(0.7))
            
            if let notes = request.notes {
                Text(notes)
                    .font(.subheadline)
                    .foregroundColor(ThemeManager.textColor.opacity(0.7))
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
        .background(ThemeManager.warmOverlay.opacity(0.05))
        .cornerRadius(12)
        .shadow(color: ThemeManager.warmOverlay.opacity(0.1), radius: 5)
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
            return ThemeManager.brandPurple
        case "rejected":
            return .red
        default:
            return ThemeManager.textColor.opacity(0.7)
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