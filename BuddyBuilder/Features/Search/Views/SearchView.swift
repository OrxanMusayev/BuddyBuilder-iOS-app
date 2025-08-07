// BuddyBuilder/Features/Search/Views/SearchView.swift - CLEAN VERSION, ALWAYS API CALLS

import SwiftUI
import Combine

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
        case .popularUsers: return "flame.fill"
        case .newJoiners: return "person.badge.plus.fill"
        case .activeUsers: return "circle.fill"
        case .topTrainers: return "person.crop.circle.badge.checkmark.fill"
        }
    }
}

// MARK: - Search View Model - ALWAYS API, NO USER DATA CACHE
class SearchViewModel: ObservableObject {
    @Published var searchText: String = ""
    @Published var isSearching: Bool = false
    
    // API data - NEVER CACHED, ALWAYS FROM API
    @Published var popularUsers: [SearchUser] = []
    @Published var newJoiners: [SearchUser] = []
    
    // Loading states
    @Published var isLoadingPopular = false
    @Published var isLoadingNew = false
    
    // Section detail
    @Published var currentSection: SectionType? = nil
    @Published var showSectionDetail = false
    @Published var sectionUsers: [SearchUser] = []
    @Published var sectionCurrentPage = 1
    @Published var sectionHasMorePages = false
    @Published var isSectionLoading = false
    
    private let searchService: SearchServiceProtocol
    private var cancellables = Set<AnyCancellable>()
    
    private let userLocation = ""
    
    init(searchService: SearchServiceProtocol = SearchService()) {
        self.searchService = searchService
        
        // IMMEDIATE API CALLS ON INIT
        loadDataFromAPI()
        
        setupSearchSuggestions()
    }
    
    // MARK: - ALWAYS LOAD FROM API (NO CACHE CHECKS)
    private func loadDataFromAPI() {
        // IMMEDIATE API calls - no delays, no cache checks
        loadPopularUsersFromAPI()
        loadNewJoinersFromAPI()
    }
    
    // MARK: - Load Popular Users FROM API
    private func loadPopularUsersFromAPI() {
        isLoadingPopular = true
        
        searchService.fetchPopularUsers(
            location: userLocation.isEmpty ? nil : userLocation,
            sportId: nil,
            page: 1,
            pageSize: 10
        )
        .receive(on: DispatchQueue.main)
        .sink(
            receiveCompletion: { [weak self] completion in
                self?.isLoadingPopular = false
                if case .failure(let error) = completion {
                    print("❌ Failed to load popular users: \(error)")
                }
            },
            receiveValue: { [weak self] data in
                self?.popularUsers = data.items
                print("✅ Loaded \(data.items.count) popular users FROM API")
            }
        )
        .store(in: &cancellables)
    }
    
    // MARK: - Load New Joiners FROM API
    private func loadNewJoinersFromAPI() {
        isLoadingNew = true
        
        searchService.fetchNewUsers(
            location: userLocation.isEmpty ? nil : userLocation,
            sportId: nil,
            page: 1,
            pageSize: 10
        )
        .receive(on: DispatchQueue.main)
        .sink(
            receiveCompletion: { [weak self] completion in
                self?.isLoadingNew = false
                if case .failure(let error) = completion {
                    print("❌ Failed to load new joiners: \(error)")
                }
            },
            receiveValue: { [weak self] data in
                self?.newJoiners = data.items
                print("✅ Loaded \(data.items.count) new joiners FROM API")
            }
        )
        .store(in: &cancellables)
    }
    
    // MARK: - Public Methods - ALWAYS API
    func refreshAllData() {
        print("🔄 Refreshing ALL data FROM API...")
        
        // Clear existing data
        popularUsers.removeAll()
        newJoiners.removeAll()
        
        // Load fresh from API
        loadDataFromAPI()
    }
    
    func onViewAppear() {
        print("👁️ SearchView appeared - Loading fresh data FROM API...")
        refreshAllData()
    }
    
    func onUserLogin() {
        print("🔔 User login - Loading fresh data FROM API...")
        refreshAllData()
    }
    
    func onUserLogout() {
        print("🔔 User logout - Clearing data...")
        popularUsers.removeAll()
        newJoiners.removeAll()
        sectionUsers.removeAll()
        
        // Clear only image caches, not data
        CentralCacheManager.shared.clearSearchImageCache()
    }
    
    // MARK: - Section Methods
    func showSection(_ section: SectionType) {
        currentSection = section
        sectionCurrentPage = 1
        sectionUsers.removeAll()
        
        loadSectionDataFromAPI(section: section, page: 1)
        showSectionDetail = true
    }
    
    func loadSectionDataFromAPI(section: SectionType, page: Int) {
        guard !isSectionLoading else { return }
        
        isSectionLoading = true
        
        let publisher: AnyPublisher<SearchData<SearchUser>, Error>
        
        switch section {
        case .popularUsers:
            publisher = searchService.fetchPopularUsers(
                location: userLocation.isEmpty ? nil : userLocation,
                sportId: nil,
                page: page,
                pageSize: 20
            )
        case .newJoiners:
            publisher = searchService.fetchNewUsers(
                location: userLocation.isEmpty ? nil : userLocation,
                sportId: nil,
                page: page,
                pageSize: 20
            )
        case .activeUsers, .topTrainers:
            isSectionLoading = false
            return
        }
        
        publisher
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    self?.isSectionLoading = false
                    if case .failure(let error) = completion {
                        print("❌ Failed to load section data: \(error)")
                    }
                },
                receiveValue: { [weak self] data in
                    if page == 1 {
                        self?.sectionUsers = data.items
                    } else {
                        self?.sectionUsers.append(contentsOf: data.items)
                    }
                    self?.sectionCurrentPage = data.page
                    self?.sectionHasMorePages = data.hasNextPage
                }
            )
            .store(in: &cancellables)
    }
    
    func loadNextSectionPage() {
        guard let section = currentSection, sectionHasMorePages else { return }
        loadSectionDataFromAPI(section: section, page: sectionCurrentPage + 1)
    }
    
    func hideSectionDetail() {
        showSectionDetail = false
        currentSection = nil
        sectionUsers.removeAll()
    }
    
    func getUsersForSection(_ section: SectionType) -> [SearchUser] {
        return sectionUsers
    }
    
    func getTrainersForSection(_ section: SectionType) -> [SearchTrainer] {
        return []
    }
    
    // MARK: - Search Methods
    private func setupSearchSuggestions() {
        $searchText
            .debounce(for: .seconds(0.3), scheduler: RunLoop.main)
            .sink { [weak self] searchText in
                if !searchText.isEmpty {
                    self?.performSearch()
                }
            }
            .store(in: &cancellables)
    }
    
    var filteredSuggestions: [String] {
        if searchText.isEmpty { return [] }
        let suggestions = ["Basketball", "Tennis", "Soccer", "Swimming", "Running", "Yoga", "Cycling", "Fitness"]
        return suggestions.filter { $0.localizedCaseInsensitiveContains(searchText) }.prefix(5).map { $0 }
    }
    
    func selectSuggestion(_ suggestion: String) {
        searchText = suggestion
        performSearch()
    }
    
    func performSearch() {
        isSearching = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            self.isSearching = false
        }
    }
}

// MARK: - Main Search View - CLEAN, ALWAYS API
struct SearchView: View {
    @StateObject private var viewModel = SearchViewModel()
    @EnvironmentObject var localizationManager: LocalizationManager
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Background
                LoginBackgroundView()
                
                VStack(spacing: 0) {
                    // Search Bar
                    searchBarSection
                    
                    // Main Content
                    ScrollView {
                        LazyVStack(spacing: 32) {
                            // Popular Users Section - ALWAYS FROM API
                            popularUsersSection
                            
                            // New Joiners Section - ALWAYS FROM API
                            newJoinersSection
                            
                            Spacer(minLength: 100)
                        }
                        .padding(.top, 20)
                    }
                    .refreshable {
                        // ALWAYS API REFRESH
                        viewModel.refreshAllData()
                    }
                }
                
                // Search Suggestions Overlay
                if !viewModel.filteredSuggestions.isEmpty {
                    searchSuggestionsOverlay
                }
            }
        }
        .navigationBarHidden(true)
        .onAppear {
            // ALWAYS LOAD FROM API ON APPEAR
            viewModel.onViewAppear()
        }
        .onReceive(NotificationCenter.default.publisher(for: .userDidLogin)) { _ in
            viewModel.onUserLogin()
        }
        .onReceive(NotificationCenter.default.publisher(for: .userDidLogout)) { _ in
            viewModel.onUserLogout()
        }
        .fullScreenCover(isPresented: $viewModel.showSectionDetail) {
            if let section = viewModel.currentSection {
                SectionDetailView(
                    section: section,
                    users: viewModel.getUsersForSection(section),
                    trainers: viewModel.getTrainersForSection(section),
                    hasMorePages: viewModel.sectionHasMorePages,
                    isLoading: viewModel.isSectionLoading,
                    onDismiss: {
                        viewModel.hideSectionDetail()
                    },
                    onLoadMore: {
                        viewModel.loadNextSectionPage()
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
                HStack(spacing: 10) {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.textSecondary)
                    
                    TextField("Search sports, users, locations...", text: $viewModel.searchText)
                        .font(.system(size: 16))
                        .foregroundColor(.textPrimary)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .onSubmit {
                            viewModel.performSearch()
                        }
                    
                    if !viewModel.searchText.isEmpty {
                        Button(action: { viewModel.searchText = "" }) {
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
            Spacer(minLength: 80)
            
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
    
    // MARK: - Popular Users Section - FROM API
    private var popularUsersSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            sectionHeader(
                title: "Popular Users Today",
                icon: "flame.fill",
                color: .red,
                isLoading: viewModel.isLoadingPopular
            )
            
            if viewModel.isLoadingPopular && viewModel.popularUsers.isEmpty {
                SkeletonLoadingGrid(count: 6)
            } else if viewModel.popularUsers.isEmpty {
                emptyStateView(message: "No popular users found")
            } else {
                usersGrid(users: Array(viewModel.popularUsers.prefix(6)), section: .popularUsers)
            }
        }
    }
    
    // MARK: - New Joiners Section - FROM API
    private var newJoinersSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            sectionHeader(
                title: "New Joiners Near You",
                icon: "person.badge.plus.fill",
                color: .green,
                isLoading: viewModel.isLoadingNew
            )
            
            if viewModel.isLoadingNew && viewModel.newJoiners.isEmpty {
                SkeletonLoadingGrid(count: 6)
            } else if viewModel.newJoiners.isEmpty {
                emptyStateView(message: "No new joiners found")
            } else {
                usersGrid(users: Array(viewModel.newJoiners.prefix(6)), section: .newJoiners)
            }
        }
    }
    
    private func emptyStateView(message: String) -> some View {
        HStack {
            Spacer()
            VStack(spacing: 12) {
                Image(systemName: "person.3")
                    .font(.system(size: 40))
                    .foregroundColor(.gray.opacity(0.5))
                Text(message)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.textSecondary)
            }
            .padding(40)
            Spacer()
        }
    }
    
    private func usersGrid(users: [SearchUser], section: SectionType) -> some View {
        VStack(spacing: 16) {
            let columns = Array(repeating: GridItem(.flexible(), spacing: 16), count: 2)
            
            LazyVGrid(columns: columns, spacing: 16) {
                ForEach(users) { user in
                    UserCard(
                        user: user,
                        buttonTitle: "Match",
                        buttonIcon: "plus.circle.fill",
                        buttonColor: .primaryOrange,
                        showNewBadge: section == .newJoiners,
                        onButtonTap: {
                            print("Action for \(user.name)")
                        }
                    )
                }
            }
            
            // See More button
            if users.count >= 6 {
                Button(action: {
                    viewModel.showSection(section)
                }) {
                    HStack(spacing: 4) {
                        Text("See More")
                            .font(.system(size: 12, weight: .medium))
                        Image(systemName: "chevron.right")
                            .font(.system(size: 10, weight: .medium))
                    }
                    .foregroundColor(.gray)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.gray.opacity(0.08))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .padding(.top, 6)
            }
        }
        .padding(.horizontal, 20)
    }
    
    private func sectionHeader(title: String, icon: String, color: Color, isLoading: Bool = false) -> some View {
        HStack(spacing: 12) {
            Text(title)
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(.textPrimary)
            
            if isLoading {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: color))
                    .scaleEffect(0.8)
            }
            
            Spacer()
        }
        .padding(.horizontal, 20)
    }
    
    private func getSuggestionIcon(for suggestion: String) -> String {
        let sportIcons = [
            "Basketball": "basketball.fill",
            "Tennis": "tennis.racket",
            "Soccer": "soccerball",
            "Swimming": "figure.pool.swim",
            "Running": "figure.run",
            "Yoga": "figure.yoga",
            "Cycling": "bicycle",
            "Fitness": "dumbbell.fill"
        ]
        
        return sportIcons[suggestion] ?? "sportscourt.fill"
    }
}

// MARK: - User Card Component - ONLY IMAGE CACHING
struct UserCard: View {
    let user: SearchUser
    let buttonTitle: String
    let buttonIcon: String
    let buttonColor: Color
    var showNewBadge: Bool = false
    let onButtonTap: () -> Void
    
    @State private var isPressed = false
    
    var body: some View {
        VStack(spacing: 12) {
            // Profile Image - ONLY IMAGE CACHED
            ZStack {
                // Profile image or placeholder - fills the circle completely
                SearchAsyncImage(
                    url: user.profileImageUrl,
                    placeholder: "person.crop.circle.fill"
                )
                .frame(width: 90, height: 90)
                .clipShape(Circle())
                
                // New Badge
                if showNewBadge || user.isNew {
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
                                .offset(x: 10, y: -5)
                        }
                        Spacer()
                    }
                }
            }
            .frame(height: 100)
            
            // User Info - ALWAYS FRESH FROM API
            VStack(spacing: 6) {
                Text(user.name)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.textPrimary)
                    .lineLimit(1)
                    .frame(height: 18)
                
                Text("@\(user.username)")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.textSecondary)
                    .lineLimit(1)
                    .frame(height: 16)
                
                Text(user.bio)
                    .font(.system(size: 11))
                    .foregroundColor(.textSecondary)
                    .lineLimit(2)
                    .multilineTextAlignment(.center)
                    .frame(height: 28)
                
                Text(user.location)
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(.primaryOrange)
                    .lineLimit(1)
                    .frame(height: 14)
            }
            .frame(height: 80)
            
            Spacer()
            
            // Action Button
            Button(action: onButtonTap) {
                HStack(spacing: 6) {
                    Image(systemName: buttonIcon)
                        .font(.system(size: 12, weight: .medium))
                    Text(buttonTitle)
                        .font(.system(size: 12, weight: .semibold))
                }
                .foregroundColor(buttonColor)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(Color.clear)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(buttonColor, lineWidth: 1.5)
                )
            }
            .frame(height: 32)
            .scaleEffect(isPressed ? 0.95 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: isPressed)
        }
        .frame(width: 140, height: 240)
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
        }
    }
}
// MARK: - Skeleton User Card Component
struct SkeletonUserCard: View {
    @State private var isAnimating = false
    
    var body: some View {
        VStack(spacing: 12) {
            // Profile Image Skeleton
            ZStack {
                RoundedRectangle(cornerRadius: 45)
                    .fill(Color.gray.opacity(0.2))
                    .frame(width: 90, height: 90)
                    .overlay(
                        RoundedRectangle(cornerRadius: 45)
                            .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                    )
                
                // Shimmer effect
                RoundedRectangle(cornerRadius: 45)
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                Color.clear,
                                Color.white.opacity(0.3),
                                Color.clear
                            ]),
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: 90, height: 90)
                    .offset(x: isAnimating ? 90 : -90)
                    .animation(
                        Animation.linear(duration: 1.5)
                            .repeatForever(autoreverses: false),
                        value: isAnimating
                    )
            }
            .frame(height: 100)
            
            // User Info Skeleton
            VStack(spacing: 6) {
                // Name skeleton
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.gray.opacity(0.2))
                    .frame(width: 80, height: 14)
                    .overlay(
                        RoundedRectangle(cornerRadius: 4)
                            .stroke(Color.gray.opacity(0.3), lineWidth: 0.5)
                    )
                
                // Username skeleton
                RoundedRectangle(cornerRadius: 3)
                    .fill(Color.gray.opacity(0.15))
                    .frame(width: 60, height: 12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 3)
                            .stroke(Color.gray.opacity(0.2), lineWidth: 0.5)
                    )
                
                // Bio skeleton (2 lines)
                VStack(spacing: 3) {
                    RoundedRectangle(cornerRadius: 3)
                        .fill(Color.gray.opacity(0.15))
                        .frame(width: 100, height: 10)
                        .overlay(
                            RoundedRectangle(cornerRadius: 3)
                                .stroke(Color.gray.opacity(0.2), lineWidth: 0.5)
                        )
                    
                    RoundedRectangle(cornerRadius: 3)
                        .fill(Color.gray.opacity(0.15))
                        .frame(width: 70, height: 10)
                        .overlay(
                            RoundedRectangle(cornerRadius: 3)
                                .stroke(Color.gray.opacity(0.2), lineWidth: 0.5)
                        )
                }
                
                // Location skeleton
                RoundedRectangle(cornerRadius: 3)
                    .fill(Color.gray.opacity(0.1))
                    .frame(width: 50, height: 10)
                    .overlay(
                        RoundedRectangle(cornerRadius: 3)
                            .stroke(Color.gray.opacity(0.15), lineWidth: 0.5)
                    )
            }
            .frame(height: 80)
            
            Spacer()
            
            // Button skeleton
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.gray.opacity(0.1))
                .frame(height: 32)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                )
        }
        .frame(width: 140, height: 240)
        .padding(16)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 4)
        .onAppear {
            isAnimating = true
        }
    }
}

// MARK: - Skeleton Loading Grid
struct SkeletonLoadingGrid: View {
    let count: Int
    
    var body: some View {
        VStack(spacing: 16) {
            let columns = Array(repeating: GridItem(.flexible(), spacing: 16), count: 2)
            
            LazyVGrid(columns: columns, spacing: 16) {
                ForEach(0..<count, id: \.self) { _ in
                    SkeletonUserCard()
                }
            }
        }
        .padding(.horizontal, 20)
    }
}

// ... existing code ...

// MARK: - Notification Extensions
extension Notification.Name {
    static let userDidLogin = Notification.Name("userDidLogin")
    static let userDidLogout = Notification.Name("userDidLogout")
}

// MARK: - Preview
#Preview {
    SearchView()
        .environmentObject(LocalizationManager())
}
