// BuddyBuilder/Features/Search/Views/SearchView.swift - UPDATED WITH REAL API

import SwiftUI
import Combine

// MARK: - Section Types (Updated)
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

// MARK: - Search View Model (Updated with Real API)
class SearchViewModel: ObservableObject {
    @Published var searchText: String = ""
    @Published var searchSuggestions: [String] = []
    @Published var isSearching: Bool = false
    
    // Real API data
    @Published var popularUsers: [SearchUser] = []
    @Published var newJoiners: [SearchUser] = []
    
    // Loading states for each section
    @Published var isLoadingPopular = false
    @Published var isLoadingNew = false
    
    // Section detail view states
    @Published var currentSection: SectionType? = nil
    @Published var showSectionDetail = false
    
    // Section detail pagination data
    @Published var sectionUsers: [SearchUser] = []
    @Published var sectionTrainers: [SearchTrainer] = []
    @Published var sectionCurrentPage = 1
    @Published var sectionHasMorePages = false
    @Published var isSectionLoading = false
    
    private let searchService: SearchServiceProtocol
    private var cancellables = Set<AnyCancellable>()
    private let debounceInterval: TimeInterval = 0.3
    
    // User location for API calls
    private let userLocation = "" // Empty string instead of "Baku"
    
    init(searchService: SearchServiceProtocol = SearchService()) {
        self.searchService = searchService
        setupSearchSuggestions()
        
        // Load initial data with delays for performance
        loadInitialData()
    }
    
    private func setupSearchSuggestions() {
        $searchText
            .debounce(for: .seconds(debounceInterval), scheduler: RunLoop.main)
            .sink { [weak self] searchText in
                if !searchText.isEmpty {
                    self?.performSearch()
                }
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Load Initial Data with Delays
    private func loadInitialData() {
        // Load popular users immediately
        loadPopularUsers()
        
        // Load new joiners after 0.5 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.loadNewJoiners()
        }
    }
    
    // MARK: - Load Popular Users
    private func loadPopularUsers() {
        guard !isLoadingPopular else { return }
        
        isLoadingPopular = true
        
        searchService.fetchPopularUsers(
            location: userLocation.isEmpty ? nil : userLocation,
            sportId: nil, // Can be updated based on user filter
            page: 1,
            pageSize: 10
        )
        .receive(on: DispatchQueue.main)
        .sink(
            receiveCompletion: { [weak self] completion in
                self?.isLoadingPopular = false
                if case .failure(let error) = completion {
                    print("❌ Failed to load popular users: \(error)")
                    // Handle error - could show error state
                }
            },
            receiveValue: { [weak self] data in
                self?.popularUsers = data.items
                print("✅ Loaded \(data.items.count) popular users")
            }
        )
        .store(in: &cancellables)
    }
    
    // MARK: - Load New Joiners
    private func loadNewJoiners() {
        guard !isLoadingNew else { return }
        
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
                print("✅ Loaded \(data.items.count) new joiners")
            }
        )
        .store(in: &cancellables)
    }
    
    // MARK: - Section Detail Methods
    func showSection(_ section: SectionType) {
        currentSection = section
        sectionCurrentPage = 1
        sectionUsers.removeAll()
        sectionTrainers.removeAll()
        
        // Load first page of section data
        loadSectionData(section: section, page: 1)
        showSectionDetail = true
    }
    
    func loadSectionData(section: SectionType, page: Int) {
        guard !isSectionLoading else { return }
        
        isSectionLoading = true
        
        switch section {
        case .popularUsers:
            loadSectionUsers(endpoint: .popular, page: page)
        case .newJoiners:
            loadSectionUsers(endpoint: .new, page: page)
        case .activeUsers, .topTrainers:
            // These sections are removed but keep for compatibility
            isSectionLoading = false
        }
    }
    
    func loadNextSectionPage() {
        guard let section = currentSection, sectionHasMorePages, !isSectionLoading else { return }
        loadSectionData(section: section, page: sectionCurrentPage + 1)
    }
    
    func hideSectionDetail() {
        showSectionDetail = false
        currentSection = nil
        sectionUsers.removeAll()
        sectionTrainers.removeAll()
    }
    
    func getUsersForSection(_ section: SectionType) -> [SearchUser] {
        return sectionUsers
    }
    
    func getTrainersForSection(_ section: SectionType) -> [SearchTrainer] {
        return sectionTrainers
    }
    
    private enum UserEndpoint {
        case popular, new, active
    }
    
    private func loadSectionUsers(endpoint: UserEndpoint, page: Int) {
        let publisher: AnyPublisher<SearchData<SearchUser>, Error>
        
        switch endpoint {
        case .popular:
            publisher = searchService.fetchPopularUsers(
                location: userLocation.isEmpty ? nil : userLocation,
                sportId: nil,
                page: page,
                pageSize: 20
            )
        case .new:
            publisher = searchService.fetchNewUsers(
                location: userLocation.isEmpty ? nil : userLocation,
                sportId: nil,
                page: page,
                pageSize: 20
            )
        case .active:
            // Not used anymore, but keep for compatibility
            publisher = searchService.fetchPopularUsers(
                location: userLocation.isEmpty ? nil : userLocation,
                sportId: nil,
                page: page,
                pageSize: 20
            )
        }
        
        publisher
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    self?.isSectionLoading = false
                    if case .failure(let error) = completion {
                        print("❌ Failed to load section users: \(error)")
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
                    print("✅ Loaded \(data.items.count) section users (page \(page))")
                }
            )
            .store(in: &cancellables)
    }
    
    // MARK: - Search Methods
    var filteredSuggestions: [String] {
        if searchText.isEmpty {
            return []
        }
        let suggestions = ["Basketball", "Tennis", "Soccer", "Swimming", "Running", "Yoga", "Cycling", "Fitness"]
        return suggestions.filter { $0.localizedCaseInsensitiveContains(searchText) }.prefix(5).map { $0 }
    }
    
    func selectSuggestion(_ suggestion: String) {
        searchText = suggestion
        performSearch()
    }
    
    func performSearch() {
        print("🔍 Searching for: \(searchText)")
        // Implement search functionality here
        isSearching = true
        
        // Simulate search delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            self.isSearching = false
        }
    }
    
    // MARK: - Refresh Methods
    func refreshAllData() {
        popularUsers.removeAll()
        newJoiners.removeAll()
        
        loadInitialData()
    }
}

// MARK: - Main Search View (Updated)
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
                            
                            Spacer(minLength: 100)
                        }
                        .padding(.top, 20)
                    }
                    .refreshable {
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
                // Search TextField
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
                title: "Popular Users Today",
                icon: "flame.fill",
                color: .red,
                isLoading: viewModel.isLoadingPopular
            )
            
            if viewModel.isLoadingPopular && viewModel.popularUsers.isEmpty {
                sectionLoadingView
            } else {
                VStack(spacing: 16) {
                    // Grid of cards (2 columns, max 6 cards)
                    let usersToShow = Array(viewModel.popularUsers.prefix(6))
                    let columns = Array(repeating: GridItem(.flexible(), spacing: 16), count: 2)
                    
                    LazyVGrid(columns: columns, spacing: 16) {
                        ForEach(usersToShow) { user in
                            RealUserCard(
                                user: user,
                                buttonTitle: "Match",
                                buttonIcon: "plus.circle.fill",
                                buttonColor: .primaryOrange,
                                onButtonTap: {
                                    print("👥 Match requested with \(user.name)")
                                }
                            )
                        }
                    }
                    
                    // See More button if there are more than 6 users
                    if viewModel.popularUsers.count > 6 {
                        Button(action: {
                            viewModel.showSection(.popularUsers)
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
        }
    }
    
    // MARK: - New Joiners Section
    private var newJoinersSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            sectionHeader(
                title: "New Joiners Near You",
                icon: "person.badge.plus.fill",
                color: .green,
                isLoading: viewModel.isLoadingNew
            )
            
            if viewModel.isLoadingNew && viewModel.newJoiners.isEmpty {
                sectionLoadingView
            } else {
                VStack(spacing: 16) {
                    // Grid of cards (2 columns, max 6 cards)
                    let usersToShow = Array(viewModel.newJoiners.prefix(6))
                    let columns = Array(repeating: GridItem(.flexible(), spacing: 16), count: 2)
                    
                    LazyVGrid(columns: columns, spacing: 16) {
                        ForEach(usersToShow) { user in
                            RealUserCard(
                                user: user,
                                buttonTitle: "Welcome",
                                buttonIcon: "hand.wave.fill",
                                buttonColor: .green,
                                showNewBadge: true,
                                onButtonTap: {
                                    print("👋 Welcome sent to \(user.name)")
                                }
                            )
                        }
                    }
                    
                    // See More button if there are more than 6 users
                    if viewModel.newJoiners.count > 6 {
                        Button(action: {
                            viewModel.showSection(.newJoiners)
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
        }
    }
    
    // MARK: - Section Loading View
    private var sectionLoadingView: some View {
        VStack(spacing: 16) {
            let columns = Array(repeating: GridItem(.flexible(), spacing: 16), count: 2)
            
            LazyVGrid(columns: columns, spacing: 16) {
                ForEach(0..<4, id: \.self) { _ in
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.gray.opacity(0.2))
                        .frame(width: 140, height: 220)
                        .shimmer()
                }
            }
        }
        .padding(.horizontal, 20)
    }
    
    // MARK: - Helper Methods
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
        let sportIcons = ["Basketball": "basketball.fill", "Tennis": "tennis.racket", "Soccer": "soccerball", "Swimming": "figure.pool.swim", "Running": "figure.run", "Yoga": "figure.yoga", "Cycling": "bicycle", "Fitness": "dumbbell.fill"]
        
        return sportIcons[suggestion] ?? "sportscourt.fill"
    }
}

// MARK: - Real User Card Component (Updated for SearchUser)
struct RealUserCard: View {
    let user: SearchUser
    let buttonTitle: String
    let buttonIcon: String
    let buttonColor: Color
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
                    
                    if let imageUrl = user.profileImageUrl {
                        AsyncImage(url: URL(string: imageUrl)) { image in
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                        } placeholder: {
                            Image(systemName: "person.crop.circle.fill")
                                .font(.system(size: 55))
                                .foregroundColor(.gray.opacity(0.5))
                        }
                        .frame(width: 70, height: 70)
                        .clipShape(Circle())
                    } else {
                        Image(systemName: "person.crop.circle.fill")
                            .font(.system(size: 55))
                            .foregroundColor(.gray.opacity(0.5))
                    }
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
            .frame(height: 70) // Fixed height for profile section
            
            // User Info
            VStack(spacing: 6) {
                Text(user.name)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.textPrimary)
                    .lineLimit(1)
                    .frame(height: 18) // Fixed height
                
                Text("@\(user.username)")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.textSecondary)
                    .lineLimit(1)
                    .frame(height: 16) // Fixed height
                
                Text(user.bio)
                    .font(.system(size: 11))
                    .foregroundColor(.textSecondary)
                    .lineLimit(2)
                    .multilineTextAlignment(.center)
                    .frame(height: 28) // Fixed height for 2 lines
                
                Text(user.location)
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(.primaryOrange)
                    .lineLimit(1)
                    .frame(height: 14) // Fixed height
            }
            .frame(height: 76) // Fixed height for user info section
            
            Spacer() // Push button to bottom
            
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
                .foregroundColor(buttonColor)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(Color.clear)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(buttonColor, lineWidth: 1.5)
                )
            }
            .frame(height: 32) // Fixed button height
            .scaleEffect(isPressed ? 0.95 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: isPressed)
        }
        .frame(width: 140, height: 220) // Fixed card dimensions
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
