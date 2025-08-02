// MARK: - Section Detail View
struct SectionDetailView: View {
    let section: SectionType
    let users: [MockUser]
    let trainers: [MockTrainer]
    let onDismiss: () -> Void
    @EnvironmentObject var localizationManager: LocalizationManager
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Background
                Color(.systemGroupedBackground)
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Header
                    headerView
                    
                    // Content
                    ScrollView {
                        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 16), count: 2), spacing: 16) {
                            if section == .topTrainers {
                                ForEach(trainers) { trainer in
                                    DetailTrainerCard(trainer: trainer)
                                }
                            } else {
                                ForEach(users) { user in
                                    DetailUserCard(
                                        user: user,
                                        section: section
                                    )
                                }
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 20)
                        .padding(.bottom, 100)
                    }
                }
            }
        }
        .navigationBarHidden(true)
    }
    
    private var headerView: some View {
        HStack {
            Button(action: onDismiss) {
                HStack(spacing: 8) {
                    Image(systemName: "arrow.left")
                        .font(.system(size: 16, weight: .medium))
                    Text("Back")
                        .font(.system(size: 16, weight: .medium))
                }
                .foregroundColor(.primary)
            }
            
            Spacer()
            
            VStack(spacing: 4) {
                Image(systemName: section.icon)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.gray.opacity(0.8))
                
                Text(section.title)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.primary)
            }
            
            Spacer()
            
            // Placeholder for balance
            HStack(spacing: 8) {
                Text("Back")
                    .font(.system(size: 16, weight: .medium))
                    .opacity(0)
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .background(Color(.systemBackground))
    }
}

// MARK: - Detail User Card
struct DetailUserCard: View {
    let user: MockUser
    let section: SectionType
    @State private var isPressed = false
    
    var body: some View {
        VStack(spacing: 12) {
            // Profile Image - Standardized
                ZStack {
                    Circle()
                        .fill(Color.gray.opacity(0.12))
                        .frame(width: 70, height: 70)
                    
                    // Always use SF Symbol - no AsyncImage
                    Image(systemName: "person.crop.circle.fill")
                        .font(.system(size: 55))
                        .foregroundColor(.gray.opacity(0.5))
                    
                    // Status indicators - NO STROKE
                    if section == .newJoiners {
                        VStack {
                            HStack {
                                Spacer()
                                Circle()
                                    .fill(Color.red)
                                    .frame(width: 14, height: 14)
                                    .offset(x: 5, y: -5)
                            }
                            Spacer()
                        }
                    } else if section == .activeUsers && user.isOnline {
                        VStack {
                            Spacer()
                            HStack {
                                Spacer()
                                Circle()
                                    .fill(Color.green)
                                    .frame(width: 14, height: 14)
                                    .offset(x: 5, y: 5)
                            }
                        }
                    }
                }
            
            // User Info - Fixed Heights
            VStack(spacing: 6) {
                Text(user.name)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.textPrimary)
                    .lineLimit(1)
                    .frame(height: 18) // Fixed height
                
                Text(user.username)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.textSecondary)
                    .lineLimit(1)
                    .frame(height: 16) // Fixed height
                
                Text(user.bio)
                    .font(.system(size: 11))
                    .foregroundColor(.textSecondary)
                    .lineLimit(3)
                    .multilineTextAlignment(.center)
                    .frame(height: 42) // Fixed height for 3 lines
                
                Text(user.location)
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(.gray.opacity(0.8))
                    .lineLimit(1)
                    .frame(height: 14) // Fixed height
            }
            
            Spacer() // Push button to bottom
            
            // Action Button - Fixed Height
            Button(action: {
                print("Action for \(user.name)")
            }) {
                HStack(spacing: 6) {
                    Image(systemName: getButtonIcon())
                        .font(.system(size: 12, weight: .medium))
                    
                    Text(getButtonTitle())
                        .font(.system(size: 12, weight: .semibold))
                }
                .foregroundColor(getButtonColor())
                .frame(maxWidth: .infinity)
                .frame(height: 32) // Fixed button height
                .background(Color.clear)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(getButtonColor(), lineWidth: 1.5)
                )
            }
            .scaleEffect(isPressed ? 0.95 : 1.0)
        }
        .frame(maxWidth: .infinity, minHeight: 280, maxHeight: 280) // Fixed card size
        .padding(16)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
        .scaleEffect(isPressed ? 0.98 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isPressed)
        .onTapGesture {
            withAnimation {
                isPressed = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                withAnimation {
                    isPressed = false
                }
            }
        }
    }
    
    private func getButtonColor() -> Color {
        switch section {
        case .popularUsers: return Color.red
        case .newJoiners: return Color.green
        case .activeUsers: return Color.blue
        case .topTrainers: return Color.purple
        }
    }
    
    private func getButtonIcon() -> String {
        switch section {
        case .popularUsers: return "plus.circle.fill"
        case .newJoiners: return "hand.wave.fill"
        case .activeUsers: return "message.circle.fill"
        case .topTrainers: return "person.fill"
        }
    }
    
    private func getButtonTitle() -> String {
        switch section {
        case .popularUsers: return "Match"
        case .newJoiners: return "Welcome"
        case .activeUsers: return "Message"
        case .topTrainers: return "Contact"
        }
    }
}

// MARK: - Detail Trainer Card
struct DetailTrainerCard: View {
    let trainer: MockTrainer
    @State private var isPressed = false
    
    var body: some View {
        VStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(Color.gray.opacity(0.12))
                    .frame(width: 70, height: 70)
                
                // Always use SF Symbol - no AsyncImage
                Image(systemName: "person.crop.circle.badge.checkmark.fill")
                    .font(.system(size: 55))
                    .foregroundColor(.gray.opacity(0.5))
                
                // Verified badge - NO STROKE
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        Image(systemName: "checkmark.seal.fill")
                            .font(.system(size: 16))
                            .foregroundColor(.blue)
                            .offset(x: 5, y: 5)
                    }
                }
            }
            
            // Trainer Info - Fixed Heights
            VStack(spacing: 6) {
                Text(trainer.name)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.textPrimary)
                    .lineLimit(1)
                    .frame(height: 18) // Fixed height
                
                Text(trainer.specialty)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.purple)
                    .lineLimit(1)
                    .frame(height: 16) // Fixed height
                
                Text(trainer.gym)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.textSecondary)
                    .lineLimit(2)
                    .multilineTextAlignment(.center)
                    .frame(height: 28) // Fixed height for 2 lines
                
                HStack(spacing: 4) {
                    Image(systemName: "star.fill")
                        .font(.system(size: 12))
                        .foregroundColor(.yellow)
                    
                    Text(trainer.formattedRating)
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.textPrimary)
                    
                    Text("(\(trainer.experience))")
                        .font(.system(size: 10))
                        .foregroundColor(.textSecondary)
                }
                .frame(height: 28) // Fixed height
            }
            
            Spacer() // Push buttons to bottom
            
            // Action Buttons - Fixed Heights
            VStack(spacing: 8) {
                Button(action: {
                    print("View events for \(trainer.name)")
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: "calendar.circle")
                            .font(.system(size: 12))
                        Text("Events")
                            .font(.system(size: 12, weight: .semibold))
                    }
                    .foregroundColor(.purple)
                    .frame(maxWidth: .infinity)
                    .frame(height: 32) // Fixed button height
                    .background(Color.clear)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color.purple, lineWidth: 1.5)
                    )
                }
            }
        }
        .frame(maxWidth: .infinity, minHeight: 280, maxHeight: 280) // Same as user cards
        .padding(16)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
        .scaleEffect(isPressed ? 0.98 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isPressed)
        .onTapGesture {
            withAnimation {
                isPressed = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                withAnimation {
                    isPressed = false
                }
            }
        }
    }
}// BuddyBuilder/Features/Search/Views/SearchView.swift

import SwiftUI

// MARK: - Mock Data Models
struct MockUser: Identifiable, Hashable {
    let id = UUID()
    let name: String
    let username: String
    let bio: String
    let location: String
    let profileImageUrl: String?
    let sports: [String]
    let isOnline: Bool
    let isNew: Bool
    let joinedDate: Date
    
    var sportEmojis: [String] {
        sports.compactMap { sport in
            switch sport.lowercased() {
            case "basketball": return "🏀"
            case "tennis": return "🎾"
            case "soccer", "football": return "⚽"
            case "swimming": return "🏊‍♂️"
            case "running": return "🏃‍♂️"
            case "yoga": return "🧘‍♀️"
            case "cycling": return "🚴‍♂️"
            case "fitness", "gym": return "🏋️‍♂️"
            case "volleyball": return "🏐"
            case "golf": return "⛳"
            default: return "🏃‍♂️"
            }
        }
    }
}

struct MockTrainer: Identifiable, Hashable {
    let id = UUID()
    let name: String
    let specialty: String
    let gym: String
    let rating: Double
    let profileImageUrl: String?
    let experience: String
    
    var formattedRating: String {
        return String(format: "%.1f", rating)
    }
}

// MARK: - Section Types
enum SectionType {
    case popularUsers
    case newJoiners
    case activeUsers
    case topTrainers
    
    var title: String {
        switch self {
        case .popularUsers: return "Popular Users Today"
        case .newJoiners: return "New Joiners Near You"
        case .activeUsers: return "Active Now"
        case .topTrainers: return "Top Trainers Near You"
        }
    }
    
    var icon: String {
        switch self {
        case .popularUsers: return "star.fill"
        case .newJoiners: return "person.badge.plus.fill"
        case .activeUsers: return "circle.fill"
        case .topTrainers: return "person.crop.circle.badge.checkmark.fill"
        }
    }
}

// MARK: - Search View Model
class SearchViewModel: ObservableObject {
    @Published var searchText: String = ""
    @Published var searchSuggestions: [String] = []
    @Published var isSearching: Bool = false
    @Published var popularUsers: [MockUser] = []
    @Published var newJoiners: [MockUser] = []
    @Published var activeUsers: [MockUser] = []
    @Published var topTrainers: [MockTrainer] = []
    @Published var currentSection: SectionType? = nil
    @Published var showSectionDetail = false
    
    init() {
        loadMockData()
        setupSearchSuggestions()
    }
    
    private func setupSearchSuggestions() {
        // Mock search suggestions
        let allSuggestions = [
            "Basketball", "Tennis", "Soccer", "Swimming", "Running", "Yoga", "Cycling", "Fitness",
            "Downtown", "Central Park", "Gym Zone", "Sports Complex",
            "John Doe", "Sarah Smith", "Mike Johnson", "Anna Wilson"
        ]
        
        searchSuggestions = allSuggestions
    }
    
    var filteredSuggestions: [String] {
        if searchText.isEmpty {
            return []
        }
        return searchSuggestions.filter { $0.localizedCaseInsensitiveContains(searchText) }.prefix(5).map { $0 }
    }
    
    func selectSuggestion(_ suggestion: String) {
        searchText = suggestion
        performSearch()
    }
    
    func performSearch() {
        print("🔍 Searching for: \(searchText)")
        // In a real app, this would make API calls
        isSearching = true
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            self.isSearching = false
            // Mock search results would be updated here
        }
    }
    
    func showSection(_ section: SectionType) {
        currentSection = section
        showSectionDetail = true
    }
    
    func hideSectionDetail() {
        showSectionDetail = false
        currentSection = nil
    }
    
    func getUsersForSection(_ section: SectionType) -> [MockUser] {
        switch section {
        case .popularUsers: return popularUsers
        case .newJoiners: return newJoiners
        case .activeUsers: return activeUsers
        case .topTrainers: return []
        }
    }
    
    func getTrainersForSection(_ section: SectionType) -> [MockTrainer] {
        switch section {
        case .topTrainers: return topTrainers
        default: return []
        }
    }
    
    func loadMockData() {
        // Load Popular Users
        popularUsers = [
            MockUser(name: "Alex Johnson", username: "@alexj", bio: "Tennis enthusiast & coach", location: "Downtown", profileImageUrl: nil, sports: ["Tennis", "Swimming"], isOnline: true, isNew: false, joinedDate: Date()),
            MockUser(name: "Sara Williams", username: "@saraw", bio: "Yoga instructor & runner", location: "Central Park", profileImageUrl: nil, sports: ["Yoga", "Running"], isOnline: false, isNew: false, joinedDate: Date()),
            MockUser(name: "Mike Chen", username: "@mikec", bio: "Basketball player", location: "Sports Complex", profileImageUrl: nil, sports: ["Basketball"], isOnline: true, isNew: false, joinedDate: Date()),
            MockUser(name: "Emma Davis", username: "@emmad", bio: "Fitness trainer", location: "Gym Zone", profileImageUrl: nil, sports: ["Fitness", "Cycling"], isOnline: false, isNew: false, joinedDate: Date()),
            MockUser(name: "Tom Wilson", username: "@tomw", bio: "Soccer coach", location: "Sports Field", profileImageUrl: nil, sports: ["Soccer", "Running"], isOnline: true, isNew: false, joinedDate: Date())
        ]
        
        // Load New Joiners
        newJoiners = [
            MockUser(name: "Lisa Park", username: "@lisap", bio: "New to tennis", location: "Nearby", profileImageUrl: nil, sports: ["Tennis"], isOnline: false, isNew: true, joinedDate: Calendar.current.date(byAdding: .day, value: -2, to: Date()) ?? Date()),
            MockUser(name: "David Kim", username: "@davidk", bio: "Swimming newbie", location: "Pool Center", profileImageUrl: nil, sports: ["Swimming"], isOnline: true, isNew: true, joinedDate: Calendar.current.date(byAdding: .day, value: -1, to: Date()) ?? Date()),
            MockUser(name: "Anna Rodriguez", username: "@annar", bio: "Yoga beginner", location: "Wellness Studio", profileImageUrl: nil, sports: ["Yoga"], isOnline: false, isNew: true, joinedDate: Date()),
            MockUser(name: "Chris Brown", username: "@chrisb", bio: "Running starter", location: "Park Trail", profileImageUrl: nil, sports: ["Running"], isOnline: true, isNew: true, joinedDate: Date()),
            MockUser(name: "Maya Singh", username: "@mayas", bio: "Cycling enthusiast", location: "Bike Path", profileImageUrl: nil, sports: ["Cycling"], isOnline: false, isNew: true, joinedDate: Date())
        ]
        
        // Load Active Users (same as popular but marked online)
        activeUsers = popularUsers.filter { $0.isOnline }
        
        // Load Top Trainers
        topTrainers = [
            MockTrainer(name: "Coach Johnson", specialty: "Tennis & Fitness", gym: "Elite Sports Center", rating: 4.9, profileImageUrl: nil, experience: "10+ years"),
            MockTrainer(name: "Master Chen", specialty: "Basketball", gym: "Urban Court", rating: 4.8, profileImageUrl: nil, experience: "8+ years"),
            MockTrainer(name: "Yogi Sara", specialty: "Yoga & Meditation", gym: "Zen Studio", rating: 4.9, profileImageUrl: nil, experience: "12+ years"),
            MockTrainer(name: "Trainer Mike", specialty: "HIIT & Strength", gym: "Power Gym", rating: 4.7, profileImageUrl: nil, experience: "6+ years"),
            MockTrainer(name: "Coach Emma", specialty: "Cycling & Cardio", gym: "Fitness Plus", rating: 4.8, profileImageUrl: nil, experience: "7+ years")
        ]
    }
}

// MARK: - Main Search View
struct SearchView: View {
    @StateObject private var viewModel = SearchViewModel()
    @EnvironmentObject var localizationManager: LocalizationManager
    @State private var isRefreshing = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Background
                LoginBackgroundView()
                
                VStack(spacing: 0) {
                    // Sticky Search Bar
                    searchBarSection
                    
                    // Main Content
                    ScrollView {
                        LazyVStack(spacing: 32) {
                            // Popular Users Section
                            popularUsersSection
                            
                            // New Joiners Section
                            newJoinersSection
                            
                            // Active Users Section
                            activeUsersSection
                            
                            // Top Trainers Section
                            topTrainersSection
                            
                            Spacer(minLength: 100)
                        }
                        .padding(.top, 20)
                    }
                    .refreshable {
                        // Direct data reload without any method calls
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                            print("🔄 Refreshing search data...")
                            viewModel.loadMockData()
                        }
                    }
                }
                
                // Search Suggestions Overlay
                if !viewModel.filteredSuggestions.isEmpty {
                    searchSuggestionsOverlay
                }
            }
        }
        .navigationBarHidden(true)
        .fullScreenCover(isPresented: $viewModel.showSectionDetail) {
            if let section = viewModel.currentSection {
                SectionDetailView(
                    section: section,
                    users: viewModel.getUsersForSection(section),
                    trainers: viewModel.getTrainersForSection(section),
                    onDismiss: {
                        viewModel.hideSectionDetail()
                    }
                )
                .environmentObject(localizationManager)
            }
        }
    }
    
    // MARK: - Search Bar Section
    private var searchBarSection: some View {
        VStack(spacing: 0) {
            HStack(spacing: 12) {
                // Search TextField
                HStack(spacing: 10) {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.textSecondary)
                    
                    TextField("search.placeholder".localized(using: localizationManager), text: $viewModel.searchText)
                        .font(.system(size: 16))
                        .foregroundColor(.textPrimary)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .onSubmit {
                            viewModel.performSearch()
                        }
                    
                    if !viewModel.searchText.isEmpty {
                        Button(action: {
                            viewModel.searchText = ""
                        }) {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 16))
                                .foregroundColor(.textSecondary)
                        }
                    }
                    
                    if viewModel.isSearching {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .primaryOrange))
                            .scaleEffect(0.8)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(Color.white)
                .clipShape(RoundedRectangle(cornerRadius: 25))
                .shadow(color: .black.opacity(0.05), radius: 3, x: 0, y: 2)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            .background(Color.white.opacity(0.95))
        }
    }
    
    // MARK: - Search Suggestions Overlay
    private var searchSuggestionsOverlay: some View {
        VStack {
            Spacer(minLength: 80) // Account for search bar height
            
            VStack(spacing: 0) {
                ForEach(viewModel.filteredSuggestions, id: \.self) { suggestion in
                    Button(action: {
                        viewModel.selectSuggestion(suggestion)
                    }) {
                        HStack {
                            Image(systemName: getSuggestionIcon(for: suggestion))
                                .font(.system(size: 14))
                                .foregroundColor(.textSecondary)
                                .frame(width: 20)
                            
                            Text(suggestion)
                                .font(.system(size: 15))
                                .foregroundColor(.textPrimary)
                            
                            Spacer()
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                    }
                    .buttonStyle(PlainButtonStyle())
                    
                    if suggestion != viewModel.filteredSuggestions.last {
                        Divider()
                            .padding(.leading, 36)
                    }
                }
            }
            .background(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
            .padding(.horizontal, 20)
            
            Spacer()
        }
        .background(
            Color.black.opacity(0.1)
                .ignoresSafeArea()
                .onTapGesture {
                    viewModel.searchText = ""
                }
        )
        .zIndex(1000)
    }
    
    // MARK: - Popular Users Section
    private var popularUsersSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            sectionHeader(
                title: "search.popular_users".localized(using: localizationManager),
                icon: "flame.fill",
                color: .red,
                onSeeMore: {
                    viewModel.showSection(.popularUsers)
                }
            )
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 16) {
                    ForEach(viewModel.popularUsers.prefix(5)) { user in
                        UserCard(
                            user: user,
                            buttonTitle: "search.match".localized(using: localizationManager),
                            buttonIcon: "plus.circle.fill",
                            onButtonTap: {
                                print("👥 Match requested with \(user.name)")
                            }
                        )
                    }
                }
                .padding(.horizontal, 20)
            }
        }
    }
    
    // MARK: - New Joiners Section
    private var newJoinersSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            sectionHeader(
                title: "search.new_joiners".localized(using: localizationManager),
                icon: "person.badge.plus.fill",
                color: .green,
                onSeeMore: {
                    viewModel.showSection(.newJoiners)
                }
            )
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 16) {
                    ForEach(viewModel.newJoiners.prefix(5)) { user in
                        UserCard(
                            user: user,
                            buttonTitle: "search.welcome".localized(using: localizationManager),
                            buttonIcon: "hand.wave.fill",
                            showNewBadge: true,
                            onButtonTap: {
                                print("👋 Welcome sent to \(user.name)")
                            }
                        )
                    }
                }
                .padding(.horizontal, 20)
            }
        }
    }
    
    // MARK: - Active Users Section
    private var activeUsersSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            sectionHeader(
                title: "search.active_now".localized(using: localizationManager),
                icon: "circle.fill",
                color: .green,
                onSeeMore: {
                    viewModel.showSection(.activeUsers)
                }
            )
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 16) {
                    ForEach(viewModel.activeUsers.prefix(5)) { user in
                        UserCard(
                            user: user,
                            buttonTitle: "search.message".localized(using: localizationManager),
                            buttonIcon: "message.circle.fill",
                            showOnlineIndicator: true,
                            onButtonTap: {
                                print("💬 Message sent to \(user.name)")
                            }
                        )
                    }
                }
                .padding(.horizontal, 20)
            }
        }
    }
    
    // MARK: - Top Trainers Section
    private var topTrainersSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            sectionHeader(
                title: "search.top_trainers".localized(using: localizationManager),
                icon: "person.crop.circle.badge.checkmark.fill",
                color: .purple,
                onSeeMore: {
                    viewModel.showSection(.topTrainers)
                }
            )
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 16) {
                    ForEach(viewModel.topTrainers.prefix(5)) { trainer in
                        TrainerCard(
                            trainer: trainer,
                            onViewEvents: {
                                print("📅 View events for \(trainer.name)")
                            },
                            onContact: {
                                print("📞 Contact \(trainer.name)")
                            }
                        )
                    }
                }
                .padding(.horizontal, 20)
            }
        }
    }
    
    // MARK: - Helper Methods
    private func sectionHeader(title: String, icon: String, color: Color, onSeeMore: @escaping () -> Void) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(color)
            
            Text(title)
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(.textPrimary)
            
            Spacer()
            
            Button(action: onSeeMore) {
                HStack(spacing: 4) {
                    Text("See More")
                        .font(.system(size: 14, weight: .medium))
                    Image(systemName: "chevron.right")
                        .font(.system(size: 12, weight: .medium))
                }
                .foregroundColor(.primaryOrange)
            }
        }
        .padding(.horizontal, 20)
    }
    
    private func getSuggestionIcon(for suggestion: String) -> String {
        let sportIcons = ["Basketball": "basketball.fill", "Tennis": "tennis.racket", "Soccer": "soccerball", "Swimming": "figure.pool.swim", "Running": "figure.run", "Yoga": "figure.yoga", "Cycling": "bicycle", "Fitness": "dumbbell.fill"]
        
        if sportIcons.keys.contains(suggestion) {
            return sportIcons[suggestion] ?? "sportscourt.fill"
        } else if suggestion.contains("Park") || suggestion.contains("Downtown") || suggestion.contains("Center") {
            return "location.fill"
        } else {
            return "person.fill"
        }
    }
}

// MARK: - User Card Component
struct UserCard: View {
    let user: MockUser
    let buttonTitle: String
    let buttonIcon: String
    var showNewBadge: Bool = false
    var showOnlineIndicator: Bool = false
    let onButtonTap: () -> Void
    
    @State private var isPressed = false
    
    var body: some View {
        VStack(spacing: 12) {
            // Profile Image with Indicators
            ZStack {
                // Profile Image
                ZStack {
                    Circle()
                        .fill(Color.gray.opacity(0.12))
                        .frame(width: 70, height: 70)
                    
                    // Always use SF Symbol - no AsyncImage
                    Image(systemName: "person.crop.circle.fill")
                        .font(.system(size: 55))
                        .foregroundColor(.gray.opacity(0.5))
                }
                
                // New Badge
                if showNewBadge {
                    VStack {
                        HStack {
                            Spacer()
                            Text("NEW")
                                .font(.system(size: 8, weight: .bold))
                                .foregroundColor(.white)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.red)
                                .clipShape(RoundedRectangle(cornerRadius: 6))
                                .offset(x: 10, y: -10)
                        }
                        Spacer()
                    }
                }
                
                // Online Indicator
                if showOnlineIndicator && user.isOnline {
                    VStack {
                        Spacer()
                        HStack {
                            Spacer()
                            Circle()
                                .fill(Color.green)
                                .frame(width: 14, height: 14)
                                .overlay(
                                    Circle()
                                        .stroke(Color.white, lineWidth: 2)
                                )
                                .offset(x: 5, y: 5)
                        }
                    }
                }
            }
            
            // User Info
            VStack(spacing: 6) {
                Text(user.name)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.textPrimary)
                    .lineLimit(1)
                
                Text(user.username)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.textSecondary)
                    .lineLimit(1)
                
                Text(user.bio)
                    .font(.system(size: 11))
                    .foregroundColor(.textSecondary)
                    .lineLimit(2)
                    .multilineTextAlignment(.center)
                
                Text(user.location)
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(.primaryOrange)
                    .lineLimit(1)
            }
            
            // Action Button
            Button(action: {
                onButtonTap()
            }) {
                HStack(spacing: 6) {
                    Image(systemName: buttonIcon)
                        .font(.system(size: 12, weight: .medium))
                    Text(buttonTitle)
                        .font(.system(size: 12, weight: .semibold))
                }
                .foregroundColor(.primaryOrange)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(Color.clear)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.primaryOrange, lineWidth: 1.5)
                )
            }
            .scaleEffect(isPressed ? 0.95 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: isPressed)
        }
        .frame(width: 140)
        .padding(16)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 4)
        .scaleEffect(isPressed ? 0.97 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isPressed)
        .onTapGesture {
            withAnimation {
                isPressed = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                withAnimation {
                    isPressed = false
                }
            }
            print("👤 Tapped on user: \(user.name)")
        }
    }
}

// MARK: - Trainer Card Component
struct TrainerCard: View {
    let trainer: MockTrainer
    let onViewEvents: () -> Void
    let onContact: () -> Void
    
    @State private var isPressed = false
    
    var body: some View {
        VStack(spacing: 16) {
            // Trainer Profile
            VStack(spacing: 12) {
                // Profile Image
                ZStack {
                    Circle()
                        .fill(Color.gray.opacity(0.12))
                        .frame(width: 70, height: 70)
                    
                    if let imageUrl = trainer.profileImageUrl {
                        AsyncImage(url: URL(string: imageUrl)) { image in
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                        } placeholder: {
                            Image(systemName: "person.crop.circle.badge.checkmark.fill")
                                .font(.system(size: 55))
                                .foregroundColor(.gray.opacity(0.5))
                        }
                        .frame(width: 70, height: 70)
                        .clipShape(Circle())
                    } else {
                        Image(systemName: "person.crop.circle.badge.checkmark.fill")
                            .font(.system(size: 55))
                            .foregroundColor(.gray.opacity(0.5))
                    }
                    
                    // Verified badge
                    VStack {
                        Spacer()
                        HStack {
                            Spacer()
                            Image(systemName: "checkmark.seal.fill")
                                .font(.system(size: 16))
                                .foregroundColor(.blue)
                                .offset(x: 5, y: 5)
                        }
                    }
                }
                
                // Trainer Info
                VStack(spacing: 6) {
                    Text(trainer.name)
                        .font(.system(size: 15, weight: .bold))
                        .foregroundColor(.textPrimary)
                        .lineLimit(1)
                    
                    Text(trainer.specialty)
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.purple)
                        .lineLimit(1)
                    
                    Text(trainer.gym)
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.textSecondary)
                        .lineLimit(1)
                    
                    // Rating
                    HStack(spacing: 4) {
                        Image(systemName: "star.fill")
                            .font(.system(size: 12))
                            .foregroundColor(.yellow)
                        
                        Text(trainer.formattedRating)
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(.textPrimary)
                        
                        Text("(\(trainer.experience))")
                            .font(.system(size: 10))
                            .foregroundColor(.textSecondary)
                    }
                }
            }
            
            // Action Buttons
            VStack(spacing: 8) {
                Button(action: onViewEvents) {
                    HStack(spacing: 6) {
                        Image(systemName: "calendar.circle")
                            .font(.system(size: 14))
                        Text("View Events")
                            .font(.system(size: 12, weight: .semibold))
                    }
                    .foregroundColor(.purple)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .background(Color.clear)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.purple, lineWidth: 1.5)
                    )
                }
                
                Button(action: onContact) {
                    HStack(spacing: 6) {
                        Image(systemName: "message.circle.fill")
                            .font(.system(size: 14))
                        Text("Contact")
                            .font(.system(size: 12, weight: .semibold))
                    }
                    .foregroundColor(.purple)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .background(Color.clear)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.purple, lineWidth: 1.5)
                    )
                }
            }
        }
        .frame(width: 160)
        .padding(16)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 4)
        .scaleEffect(isPressed ? 0.97 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isPressed)
        .onTapGesture {
            withAnimation {
                isPressed = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                withAnimation {
                    isPressed = false
                }
            }
            print("🏃‍♂️ Tapped on trainer: \(trainer.name)")
        }
    }
}

// MARK: - Preview
#Preview {
    SearchView()
        .environmentObject(LocalizationManager(localizationService: MockLocalizationService()))
}
