import SwiftUI

struct ThemeManager {
    // Base colors
    static let mainThemeColor = Color(red: 0.82, green: 0.47, blue: 0.35) // Terracotta
    static let secondaryColor = Color(red: 0.85, green: 0.80, blue: 0.75) // Taupe
    static let backgroundColor = Color(red: 0.96, green: 0.94, blue: 0.92) // Cream
    static let accentColor = Color(red: 0.95, green: 0.85, blue: 0.75) // Warm sand
    static let textColor = Color(red: 0.2, green: 0.2, blue: 0.2).opacity(0.85) // Soft black
    
    // Brand colors
    static let brandPurple = Color(red: 0.40, green: 0.42, blue: 0.97) // Brighter purple
    static let brandLightPurple = Color(red: 0.53, green: 0.55, blue: 0.98) // Light purple
    
    // Warm overlay
    static let warmOverlay = Color(red: 0.98, green: 0.92, blue: 0.87)
    
    // Tab Bar styles
    static func updateTabBarAppearance(forProfile: Bool) {
        let appearance = UITabBarAppearance()
        appearance.configureWithTransparentBackground()
        
        // Create gradient colors
        let gradientLayer = CAGradientLayer()
        gradientLayer.frame = CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width, height: 49) // Standard tab bar height
        gradientLayer.colors = [
            UIColor(backgroundColor).cgColor,
            UIColor(mainThemeColor.opacity(0.95)).cgColor
        ]
        gradientLayer.startPoint = CGPoint(x: 0, y: 0)
        gradientLayer.endPoint = CGPoint(x: 1, y: 0)
        
        // Convert gradient to image
        let renderer = UIGraphicsImageRenderer(bounds: gradientLayer.bounds)
        let gradientImage = renderer.image { ctx in
            gradientLayer.render(in: ctx.cgContext)
        }
        
        // Apply gradient background
        appearance.backgroundImage = gradientImage
        
        // Style the items
        let itemAppearance = UITabBarItemAppearance()
        
        // Selected state
        itemAppearance.selected.iconColor = .white
        itemAppearance.selected.titleTextAttributes = [.foregroundColor: UIColor.white]
        
        // Normal state
        itemAppearance.normal.iconColor = UIColor.white.withAlphaComponent(0.7)
        itemAppearance.normal.titleTextAttributes = [.foregroundColor: UIColor.white.withAlphaComponent(0.7)]
        
        appearance.stackedLayoutAppearance = itemAppearance
        
        UITabBar.appearance().standardAppearance = appearance
        if #available(iOS 15.0, *) {
            UITabBar.appearance().scrollEdgeAppearance = appearance
        }
    }
    
    // Common styles
    static func applyWarmGradient(color: Color) -> some View {
        LinearGradient(
            gradient: Gradient(colors: [
                color.opacity(0.6),
                color.opacity(0.3),
                warmOverlay.opacity(0.4)
            ]),
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
    
    static var backgroundStyle: some View {
        ZStack {
            backgroundColor
            
            LinearGradient(
                gradient: Gradient(colors: [
                    mainThemeColor.opacity(0.1),
                    brandLightPurple.opacity(0.05),
                    accentColor.opacity(0.15),
                    mainThemeColor.opacity(0.08)
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            
            Rectangle()
                .fill(backgroundColor.opacity(0.6))
                .background(.ultraThinMaterial)
        }
    }
}

struct HomeView: View {
    @EnvironmentObject private var authManager: AuthenticationManager
    @EnvironmentObject private var userService: UserService
    @State private var selectedTab = 0
    @State private var isAnimating = false
    @State private var showSubmitStore = false
    @State private var selectedCategory: String?
    @State private var gradientAngle: Double = 0
    
    // Remove the color definitions and use ThemeManager instead
    private let mainThemeColor = ThemeManager.mainThemeColor
    private let secondaryColor = ThemeManager.secondaryColor
    private let backgroundColor = ThemeManager.backgroundColor
    private let accentColor = ThemeManager.accentColor
    private let textColor = ThemeManager.textColor
    private let brandPurple = ThemeManager.brandPurple
    private let brandLightPurple = ThemeManager.brandLightPurple
    
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
            
            NavigationView {
                ProfileView()
            }
            .tabItem {
                Label("Profile", systemImage: "person")
            }
            .tag(4)
        }
        .onChange(of: selectedTab) { _ in
            // Always use the gradient appearance regardless of selected tab
            ThemeManager.updateTabBarAppearance(forProfile: true)
        }
        .sheet(isPresented: $showSubmitStore) {
            SubmitStoreView()
        }
        .onAppear {
            print("🏠 HomeView appeared, isAdmin: \(userService.isAdmin)")
            withAnimation(.easeOut(duration: 0.5)) {
                isAnimating = true
            }
            withAnimation(.linear(duration: 20).repeatForever(autoreverses: false)) {
                gradientAngle = 360
            }
            
            // Set gradient appearance on launch
            ThemeManager.updateTabBarAppearance(forProfile: true)
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
                                .foregroundColor(textColor)
                            Image("ThriftDriftLogo")
                                .resizable()
                                .scaledToFit()
                                .frame(height: 20)
                                .colorMultiply(brandPurple) // Tint logo with brand purple
                            Text("Drift")
                                .font(.system(size: 24, weight: .bold, design: .monospaced))
                                .foregroundColor(textColor)
                        }
                        Spacer()
                    }
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Good \(timeOfDay), \(userName)")
                            .font(.system(size: 32, weight: .bold))
                            .foregroundColor(textColor)
                        
                        Text("Ready to find your next thrift?")
                            .font(.system(size: 18, weight: .regular))
                            .foregroundColor(textColor.opacity(0.7))
                    }
                }
                .padding(.top, 16)
                .opacity(isAnimating ? 1 : 0)
                .offset(y: isAnimating ? 0 : 20)
                
                // Today's Top Picks Section with purple accent
                CategoryCard(
                    title: "Today's Top Picks",
                    color: todaysTopPicksColor,
                    icon: "star.fill",
                    accentColor: brandPurple,
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
                    color: storeCategoriesColor,
                    icon: "tag.fill",
                    accentColor: brandPurple,
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
                    color: forYouColor,
                    icon: "heart.fill",
                    accentColor: brandPurple,
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
                
                // Submit Store Button with purple gradient
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
                    .background(
                        LinearGradient(
                            gradient: Gradient(colors: [brandPurple, brandLightPurple]),
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .foregroundColor(.white)
                    .cornerRadius(25)
                }
                .padding(.bottom, 16)
                .opacity(isAnimating ? 1 : 0)
                .offset(y: isAnimating ? 0 : 20)
            }
            .padding(.horizontal, 24)
        }
        .background(ThemeManager.backgroundStyle)
        .navigationBarHidden(true)
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
    
    // Update CategoryCard colors
    private var todaysTopPicksColor: Color {
        accentColor // Warm sand
    }
    
    private var storeCategoriesColor: Color {
        secondaryColor // Taupe
    }
    
    private var forYouColor: Color {
        Color(red: 0.90, green: 0.82, blue: 0.78) // Dusty rose
    }
}

struct CategoryCard: View {
    let title: String
    let color: Color
    let icon: String
    let accentColor: Color
    let subcategories: [String]
    
    private let exploreButtonColor = Color(red: 0.45, green: 0.45, blue: 0.5) // Muted slate
    
    private var backgroundImage: String {
        switch title {
        case "Today's Top Picks":
            return "TopPicks"
        case "Store Categories":
            return "Categories"
        case "For You":
            return "ForYou"
        default:
            return ""
        }
    }
    
    private var categoryIcons: [String] {
        switch title {
        case "Today's Top Picks":
            return ["star.fill", "crown.fill", "flame.fill", "sparkles"]
        case "Store Categories":
            return ["tshirt.fill", "house.fill", "handbag.fill", "tag.fill"]
        case "For You":
            return ["heart.fill", "star.fill", "hand.thumbsup.fill", "bookmark.fill"]
        default:
            return []
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
    
    var body: some View {
        NavigationLink(destination: CategoryDetailView(title: title, color: color, icon: icon, subcategories: subcategories)) {
            ZStack(alignment: .leading) {
                // Background Image with warm vintage overlay
                ZStack {
                    Image(backgroundImage)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(height: 160)
                        .overlay(
                            // Warmer vintage filter
                            Color(red: 0.98, green: 0.92, blue: 0.87)
                                .opacity(0.25)
                        )
                    
                    // Original color overlay with increased warmth
                    color
                        .opacity(0.4)
                        .blendMode(.overlay)
                    
                    // Theme gradient with warmer tones
                    ThemeManager.applyWarmGradient(color: color)
                    
                    // Decorative Icons
                    HStack {
                        Spacer()
                        ZStack {
                            ForEach(categoryIcons, id: \.self) { iconName in
                                Image(systemName: iconName)
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .frame(width: 24, height: 24)
                                    .offset(
                                        x: offsetFor(icon: iconName),
                                        y: offsetFor(icon: iconName, isVertical: true)
                                    )
                                    .foregroundColor(accentColor)
                                    .opacity(0.3)
                            }
                        }
                        .frame(width: 100)
                        .padding(.trailing, 20)
                    }
                }
                .clipped()
                
                // Content with soft shadows
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Image(systemName: icon)
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(accentColor)
                            .shadow(color: Color.black.opacity(0.1), radius: 1, x: 0, y: 1)
                        Spacer()
                    }
                    
                    Text(title)
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(ThemeManager.textColor)
                        .shadow(color: Color.white.opacity(0.6), radius: 2, x: 0, y: 1)
                        .multilineTextAlignment(.leading)
                    
                    Spacer()
                    
                    HStack {
                        Text("Explore")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.white)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(exploreButtonColor.opacity(0.9))
                            .cornerRadius(15)
                        Spacer()
                        Image(systemName: "chevron.right")
                            .foregroundColor(accentColor)
                            .shadow(color: Color.black.opacity(0.1), radius: 1, x: 0, y: 1)
                            .font(.system(size: 16, weight: .semibold))
                    }
                }
                .padding(20)
            }
            .frame(height: 160)
            .cornerRadius(20)
            .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct CategoryDetailView: View {
    let title: String
    let color: Color
    let icon: String
    let subcategories: [String]
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Header
                VStack(spacing: 8) {
                    HStack {
                        Image(systemName: icon)
                            .font(.system(size: 28, weight: .semibold))
                            .foregroundColor(ThemeManager.brandPurple)
                            .shadow(color: Color.black.opacity(0.1), radius: 1, x: 0, y: 1)
                        Text(title)
                            .font(.system(size: 28, weight: .bold))
                            .foregroundColor(ThemeManager.textColor)
                    }
                    .frame(maxWidth: .infinity)
                    
                    Text("Select a category to explore")
                        .font(.system(size: 16))
                        .foregroundColor(ThemeManager.textColor.opacity(0.7))
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 20)
                .background(
                    ZStack {
                        color
                        ThemeManager.warmOverlay.opacity(0.15)
                        ThemeManager.applyWarmGradient(color: color)
                    }
                )
                
                // Subcategories
                VStack(spacing: 12) {
                    ForEach(subcategories, id: \.self) { subcategory in
                        NavigationLink(destination: CategoryStoreListView(category: subcategory)) {
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(subcategory)
                                        .font(.system(size: 18, weight: .semibold))
                                        .foregroundColor(ThemeManager.textColor)
                                    
                                    Text(descriptionFor(subcategory))
                                        .font(.system(size: 14))
                                        .foregroundColor(ThemeManager.textColor.opacity(0.7))
                                }
                                
                                Spacer()
                                
                                Image(systemName: "chevron.right")
                                    .foregroundColor(ThemeManager.brandPurple)
                                    .font(.system(size: 14, weight: .semibold))
                                    .shadow(color: Color.black.opacity(0.1), radius: 1, x: 0, y: 1)
                            }
                            .padding(.vertical, 16)
                            .padding(.horizontal, 20)
                            .background(
                                ZStack {
                                    Color.white
                                    ThemeManager.warmOverlay.opacity(0.05)
                                }
                            )
                            .cornerRadius(12)
                            .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
                        }
                    }
                }
                .padding(.horizontal, 16)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .background(ThemeManager.backgroundStyle)
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
                            .background(
                                ZStack {
                                    Color.white
                                    ThemeManager.warmOverlay.opacity(0.05)
                                }
                                .cornerRadius(15)
                            )
                            .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
                    }
                }
            }
            .padding(.vertical)
        }
        .navigationTitle(category)
        .background(ThemeManager.backgroundStyle)
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
        .background(
            ZStack {
                Color.white
                ThemeManager.warmOverlay.opacity(0.1)
            }
        )
        .overlay(
            Rectangle()
                .frame(height: 1)
                .foregroundColor(ThemeManager.mainThemeColor.opacity(0.1)),
            alignment: .top
        )
        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: -2)
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
                    .foregroundColor(isSelected ? ThemeManager.brandPurple : ThemeManager.textColor.opacity(0.6))
                    .shadow(color: Color.black.opacity(0.1), radius: 1, x: 0, y: 1)
                Text(title)
                    .font(.system(size: 12))
                    .foregroundColor(isSelected ? ThemeManager.brandPurple : ThemeManager.textColor.opacity(0.6))
            }
            .frame(maxWidth: .infinity)
            .background(
                isSelected ?
                ThemeManager.warmOverlay.opacity(0.15) :
                Color.clear
            )
            .cornerRadius(10)
        }
    }
} 
