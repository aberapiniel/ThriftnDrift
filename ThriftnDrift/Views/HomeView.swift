import SwiftUI

struct HomeView: View {
    @EnvironmentObject private var authManager: AuthenticationManager
    @State private var selectedTab = 0
    @State private var isAnimating = false
    @State private var showSubmitStore = false
    @State private var selectedCategory: String?
    @StateObject private var userService = UserService.shared
    
    private let themeColor = Color(red: 0.4, green: 0.5, blue: 0.95)
    
    var body: some View {
        TabView(selection: $selectedTab) {
            homeContent
                .tabItem {
                    Label("Home", systemImage: "house.fill")
                }
                .tag(0)
            
            MapView()
                .tabItem {
                    Label("Map", systemImage: "map")
                }
                .tag(1)
            
            CitiesView()
                .tabItem {
                    Label("Cities", systemImage: "building.2")
                }
                .tag(2)
            
            FavoritesView()
                .tabItem {
                    Label("Favorites", systemImage: "heart")
                }
                .tag(3)
            
            if userService.isAdmin {
                AdminView()
                    .tabItem {
                        Label("Admin", systemImage: "shield")
                    }
                    .tag(4)
            }
            
            ProfileView()
                .tabItem {
                    Label("Profile", systemImage: "person")
                }
                .tag(5)
        }
        .sheet(isPresented: $showSubmitStore) {
            SubmitStoreView()
        }
    }
    
    private var homeContent: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Header with Logo and Greeting
                VStack(alignment: .leading, spacing: 24) {
                    // Logo
                    HStack {
                        Spacer()
                        HStack(spacing: 4) {
                            Text("Thrift")
                                .font(.system(size: 24, weight: .bold, design: .monospaced))
                            Image("ThriftDriftLogo")
                                .resizable()
                                .scaledToFit()
                                .frame(height: 20)
                            Text("Drift")
                                .font(.system(size: 24, weight: .bold, design: .monospaced))
                        }
                        Spacer()
                    }
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Good \(timeOfDay), \(userName)")
                            .font(.system(size: 32, weight: .bold))
                            .foregroundColor(.black)
                        
                        Text("Ready to find your next thrift?")
                            .font(.system(size: 18, weight: .regular))
                            .foregroundColor(.gray)
                    }
                }
                .padding(.top, 16)
                .opacity(isAnimating ? 1 : 0)
                .offset(y: isAnimating ? 0 : 20)
                
                // Today's Top Picks Section
                CategoryCard(
                    title: "Today's Top Picks",
                    color: Color(red: 0.93, green: 0.79, blue: 0.62),
                    icon: "star.fill",
                    subcategories: [
                        "Trending Stores",
                        "Top-rated Stores",
                        "Recently Added",
                        "Local Gems"
                    ]
                )
                .opacity(isAnimating ? 1 : 0)
                .offset(y: isAnimating ? 0 : 20)
                
                // Store Categories Section
                CategoryCard(
                    title: "Store Categories",
                    color: Color(red: 0.7, green: 0.85, blue: 0.9),
                    icon: "tag.fill",
                    subcategories: [
                        "Vintage & Retro",
                        "Budget Friendly",
                        "Designer & High End",
                        "Home Goods",
                        "Sustainable"
                    ]
                )
                .opacity(isAnimating ? 1 : 0)
                .offset(y: isAnimating ? 0 : 20)
                
                // For You Section
                CategoryCard(
                    title: "For You",
                    color: Color(red: 0.9, green: 0.8, blue: 0.9),
                    icon: "heart.fill",
                    subcategories: [
                        "Recommended",
                        "Based on Your Likes",
                        "Similar to Recent Views",
                        "Popular in Your Area"
                    ]
                )
                .opacity(isAnimating ? 1 : 0)
                .offset(y: isAnimating ? 0 : 20)
                
                Spacer()
                
                // Submit Store Button at the bottom
                Button(action: {
                    showSubmitStore = true
                }) {
                    HStack {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 20))
                        Text("Submit a Store")
                            .font(.system(size: 16, weight: .semibold))
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(themeColor)
                    .foregroundColor(.white)
                    .cornerRadius(25)
                }
                .padding(.bottom, 16)
                .opacity(isAnimating ? 1 : 0)
                .offset(y: isAnimating ? 0 : 20)
            }
            .padding(.horizontal, 24)
        }
        .navigationBarHidden(true)
        .onAppear {
            withAnimation(.easeOut(duration: 0.5)) {
                isAnimating = true
            }
        }
        .onDisappear {
            isAnimating = false
        }
    }
    
    private var timeOfDay: String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 0..<12: return "Morning"
        case 12..<17: return "Afternoon"
        case 17..<24: return "Evening"
        default: return "Hello"
        }
    }
    
    private var userName: String {
        authManager.userDisplayName
    }
}

struct CategoryCard: View {
    let title: String
    let color: Color
    let icon: String
    let subcategories: [String]
    
    var body: some View {
        NavigationLink(destination: CategoryDetailView(title: title, color: color, icon: icon, subcategories: subcategories)) {
            ZStack(alignment: .trailing) {
                // Content
                HStack {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Image(systemName: icon)
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(.black)
                            Spacer()
                        }
                        
                        Text(title)
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(.black)
                            .multilineTextAlignment(.leading)
                        
                        HStack {
                            Text("Explore")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.white)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(Color.black)
                                .cornerRadius(15)
                            Spacer()
                            Image(systemName: "chevron.right")
                                .foregroundColor(.black)
                                .font(.system(size: 16, weight: .semibold))
                        }
                    }
                    .padding(20)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    
                    // Decorative Icons
                    ZStack {
                        ForEach(categoryIcons, id: \.self) { iconName in
                            Image(systemName: iconName)
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 30, height: 30)
                                .offset(x: offsetFor(icon: iconName), y: offsetFor(icon: iconName, isVertical: true))
                                .opacity(0.3)
                        }
                    }
                    .frame(width: 120)
                    .padding(.trailing, 20)
                }
            }
            .frame(height: 160)
            .background(color)
            .cornerRadius(20)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private var categoryIcons: [String] {
        switch title {
        case "Today's Top Picks":
            return ["star.fill", "flame.fill", "crown.fill", "sparkles"]
        case "Store Categories":
            return ["tag.fill", "handbag.fill", "tshirt.fill", "house.fill"]
        case "For You":
            return ["heart.fill", "star.fill", "hand.thumbsup.fill", "bookmark.fill"]
        default:
            return ["circle.fill"]
        }
    }
    
    private func offsetFor(icon: String, isVertical: Bool = false) -> CGFloat {
        let index = CGFloat(categoryIcons.firstIndex(of: icon) ?? 0)
        if isVertical {
            return sin(index * .pi / 2) * 20
        } else {
            return cos(index * .pi / 2) * 20
        }
    }
}

struct CategoryDetailView: View {
    let title: String
    let color: Color
    let icon: String
    let subcategories: [String]
    @Environment(\.dismiss) private var dismiss
    
    private let themeColor = Color(red: 0.4, green: 0.5, blue: 0.95)
    
    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Header
                VStack(spacing: 8) {
                    HStack {
                        Image(systemName: icon)
                            .font(.system(size: 28, weight: .semibold))
                        Text(title)
                            .font(.system(size: 28, weight: .bold))
                    }
                    .frame(maxWidth: .infinity)
                    .foregroundColor(.black)
                    
                    Text("Select a category to explore")
                        .font(.system(size: 16))
                        .foregroundColor(.gray)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 20)
                .background(color)
                
                // Subcategories
                VStack(spacing: 12) {
                    ForEach(subcategories, id: \.self) { subcategory in
                        NavigationLink(destination: CategoryStoreListView(category: subcategory)) {
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(subcategory)
                                        .font(.system(size: 18, weight: .semibold))
                                        .foregroundColor(.primary)
                                    
                                    // Add descriptive text based on subcategory
                                    Text(descriptionFor(subcategory))
                                        .font(.system(size: 14))
                                        .foregroundColor(.gray)
                                }
                                
                                Spacer()
                                
                                Image(systemName: "chevron.right")
                                    .foregroundColor(themeColor)
                                    .font(.system(size: 14, weight: .semibold))
                            }
                            .padding(.vertical, 16)
                            .padding(.horizontal, 20)
                            .background(Color.white)
                            .cornerRadius(12)
                            .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
                        }
                    }
                }
                .padding(.horizontal, 16)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .background(Color(UIColor.systemGray6))
    }
    
    private func descriptionFor(_ subcategory: String) -> String {
        switch subcategory {
        // Today's Top Picks descriptions
        case "Trending Stores":
            return "Popular stores in your area"
        case "Top-rated Stores":
            return "Highest rated by the community"
        case "Recently Added":
            return "New stores added this week"
        case "Local Gems":
            return "Hidden treasures near you"
            
        // Store Categories descriptions
        case "Vintage & Retro":
            return "Classic and nostalgic finds"
        case "Budget Friendly":
            return "Great deals and affordable prices"
        case "Designer & High End":
            return "Luxury and premium items"
        case "Home Goods":
            return "Furniture and home accessories"
        case "Sustainable":
            return "Eco-friendly and sustainable shops"
            
        // For You descriptions
        case "Recommended":
            return "Personalized picks for you"
        case "Based on Your Likes":
            return "Similar to stores you love"
        case "Similar to Recent Views":
            return "Matches your browsing history"
        case "Popular in Your Area":
            return "Trending in your location"
            
        default:
            return "Explore this category"
        }
    }
}

struct CategoryStoreListView: View {
    let category: String
    @StateObject private var storeService = StoreService.shared
    
    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                ForEach(storeService.stores.filter { store in
                    store.categories.contains(category)
                }) { store in
                    NavigationLink(destination: StoreDetailView(store: store)) {
                        StoreRow(store: store)
                            .padding(.horizontal)
                    }
                }
            }
            .padding(.vertical)
        }
        .navigationTitle(category)
    }
}

struct CustomTabBar: View {
    @Binding var selectedTab: Int
    
    var body: some View {
        HStack(spacing: 0) {
            ForEach(0..<5) { index in
                Spacer()
                TabBarButton(
                    isSelected: selectedTab == index,
                    icon: tabIcon(for: index),
                    title: tabTitle(for: index)
                ) {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        selectedTab = index
                    }
                }
                Spacer()
            }
        }
        .padding(.vertical, 8)
        .background(Color.white)
        .overlay(
            Rectangle()
                .frame(height: 1)
                .foregroundColor(Color.gray.opacity(0.2)),
            alignment: .top
        )
    }
    
    private func tabIcon(for index: Int) -> String {
        switch index {
        case 0: return "house.fill"
        case 1: return "map.fill"
        case 2: return "building.2.fill"
        case 3: return "bookmark.fill"
        case 4: return "person.fill"
        default: return ""
        }
    }
    
    private func tabTitle(for index: Int) -> String {
        switch index {
        case 0: return "Home"
        case 1: return "Map"
        case 2: return "Cities"
        case 3: return "Favorites"
        case 4: return "Profile"
        default: return ""
        }
    }
}

struct TabBarButton: View {
    let isSelected: Bool
    let icon: String
    let title: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 20))
                Text(title)
                    .font(.system(size: 12))
            }
            .foregroundColor(isSelected ? Color(red: 0.4, green: 0.5, blue: 0.95) : .gray)
            .frame(maxWidth: .infinity)
        }
    }
} 
