// BuddyBuilder/Features/Sports/Views/AddSportView.swift - UPDATED VERSION

import SwiftUI
import Combine

// MARK: - Add Sport Request Model
struct AddSportRequest: Codable {
    let sportId: Int
    let experienceLevel: Int
    let isPreferred: Bool
    let notes: String?
}

// MARK: - Sport Selection With Level Model
struct SportSelectionWithLevel: Identifiable, Hashable, Equatable {
    let id = UUID()
    let sport: Sport
    var experienceLevel: ExperienceLevel = .beginner
    
    static func == (lhs: SportSelectionWithLevel, rhs: SportSelectionWithLevel) -> Bool {
        return lhs.id == rhs.id
    }
}

// MARK: - Add Sport View Model
class AddSportViewModel: ObservableObject {
    @Published var availableSports: [Sport] = []
    @Published var userSports: [UserSport] = [] // Add user's current sports
    @Published var selectedSports: [SportSelectionWithLevel] = []
    @Published var isLoading = false
    @Published var isSaving = false
    @Published var errorMessage: String = ""
    @Published var showError = false
    @Published var searchText: String = ""
    
    private let sportsService: EventsServiceProtocol
    private let mySportsService: MySportsServiceProtocol
    private let profileService: ProfileServiceProtocol // Add ProfileService
    private var cancellables = Set<AnyCancellable>()
    private let debounceInterval: TimeInterval = 0.3
    
    init(sportsService: EventsServiceProtocol = CompleteEventsService(),
         mySportsService: MySportsServiceProtocol = MySportsService(),
         profileService: ProfileServiceProtocol = ProfileService()) { // Add ProfileService
        self.sportsService = sportsService
        self.mySportsService = mySportsService
        self.profileService = profileService
        setupSearchDebounce()
        loadAvailableSports()
        loadUserSports() // Load user's current sports
    }
    
    private func setupSearchDebounce() {
        $searchText
            .debounce(for: .seconds(debounceInterval), scheduler: RunLoop.main)
            .sink { [weak self] _ in
                // Search functionality can be implemented here
            }
            .store(in: &cancellables)
    }
    
    func loadAvailableSports() {
        isLoading = true
        errorMessage = ""
        
        sportsService.fetchAvailableSports()
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    self?.isLoading = false
                    if case .failure(let error) = completion {
                        self?.handleError("Failed to load sports: \(error.localizedDescription)")
                    }
                },
                receiveValue: { [weak self] sports in
                    self?.availableSports = sports
                    print("✅ Loaded \(sports.count) available sports")
                }
            )
            .store(in: &cancellables)
    }
    
    // Load user's current sports to disable them
    func loadUserSports() {
        mySportsService.fetchMySportsWithAutoRefresh()
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { completion in
                    if case .failure(let error) = completion {
                        print("❌ Failed to load user sports: \(error)")
                    }
                },
                receiveValue: { [weak self] userSports in
                    self?.userSports = userSports
                    print("✅ Loaded \(userSports.count) user sports")
                }
            )
            .store(in: &cancellables)
    }
    
    // Check if sport is already added by user
    func isSportAlreadyAdded(_ sport: Sport) -> Bool {
        return userSports.contains { $0.sport.id == sport.id || $0.name.lowercased() == sport.name.lowercased() }
    }
    
    // Get the experience level for an already added sport
    func getExistingSportLevel(_ sport: Sport) -> ExperienceLevel {
        if let userSport = userSports.first(where: { $0.sport.id == sport.id || $0.name.lowercased() == sport.name.lowercased() }) {
            return userSport.experienceLevelEnum ?? .beginner
        }
        return .beginner
    }
    
    func toggleSportSelection(_ sport: Sport) {
        // Don't allow selection if sport is already added
        if isSportAlreadyAdded(sport) {
            return
        }
        
        if let index = selectedSports.firstIndex(where: { $0.sport.id == sport.id }) {
            selectedSports.remove(at: index)
            print("🏃‍♂️ Removed sport: \(sport.name)")
        } else {
            let sportSelection = SportSelectionWithLevel(sport: sport, experienceLevel: .beginner)
            selectedSports.append(sportSelection)
            print("🏃‍♂️ Added sport: \(sport.name)")
        }
    }
    
    func updateSportExperience(_ sport: Sport, experience: ExperienceLevel) {
        // Don't allow level change if sport is already added
        if isSportAlreadyAdded(sport) {
            return
        }
        
        if let index = selectedSports.firstIndex(where: { $0.sport.id == sport.id }) {
            selectedSports[index].experienceLevel = experience
            print("📊 Updated \(sport.name) experience to \(experience.displayName)")
        }
    }
    
    func isSportSelected(_ sport: Sport) -> Bool {
        selectedSports.contains { $0.sport.id == sport.id }
    }
    
    func getSelectedExperience(for sport: Sport) -> ExperienceLevel {
        selectedSports.first { $0.sport.id == sport.id }?.experienceLevel ?? .beginner
    }
    
    func saveSelectedSports(completion: @escaping (Bool) -> Void) {
        guard !selectedSports.isEmpty else {
            handleError("Please select at least one sport")
            completion(false)
            return
        }
        
        isSaving = true
        
        // Prepare the request payload for Profile API
        let sportsToAdd = selectedSports.map { selection in
            AddSportRequest(
                sportId: selection.sport.id,
                experienceLevel: selection.experienceLevel.rawValue,
                isPreferred: true,
                notes: nil
            )
        }
        
        // Use ProfileService to add sports via Profile API
        profileService.addSports(sportsToAdd)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completionResult in
                    self?.isSaving = false
                    if case .failure(let error) = completionResult {
                        self?.handleError("Failed to add sports: \(error.localizedDescription)")
                        completion(false)
                    }
                },
                receiveValue: { [weak self] success in
                    if success {
                        print("🎉 All sports added successfully via Profile API")
                        completion(true)
                    } else {
                        self?.handleError("Failed to add sports. Please try again.")
                        completion(false)
                    }
                }
            )
            .store(in: &cancellables)
    }
    
    var filteredSports: [Sport] {
        if searchText.isEmpty {
            return availableSports
        } else {
            return availableSports.filter { sport in
                sport.name.localizedCaseInsensitiveContains(searchText) ||
                (sport.description?.localizedCaseInsensitiveContains(searchText) ?? false)
            }
        }
    }
    
    var canSave: Bool {
        !selectedSports.isEmpty && !isSaving
    }
    
    private func handleError(_ message: String) {
        errorMessage = message
        showError = true
        print("❌ AddSport Error: \(message)")
    }
}

// MARK: - Add Sport View (MAIN VIEW - Standard Navigation)
struct AddSportView: View {
    @StateObject private var viewModel = AddSportViewModel()
    @EnvironmentObject var localizationManager: LocalizationManager
    @Environment(\.dismiss) var dismiss
    
    let onSportsAdded: (Bool) -> Void
    
    var body: some View {
        ZStack {
            LoginBackgroundView()
            
            VStack(spacing: 0) {
                customHeader
                searchSection
                sportsListSection
            }
        }
        .navigationBarHidden(true)
        .alert("Error", isPresented: $viewModel.showError) {
            Button("OK") { }
        } message: {
            Text(viewModel.errorMessage)
        }
    }
    
    // MARK: - Custom Header (With Back Button to My Sports)
    private var customHeader: some View {
        VStack(spacing: 16) {
            HStack {
                backButton
                Spacer()
                headerTitle
                Spacer()
                // Save button (only visible when sports are selected)
                if !viewModel.selectedSports.isEmpty {
                    saveButton
                } else {
                    // Invisible spacer to maintain layout balance
                    Color.clear
                        .frame(width: 80, height: 44)
                }
            }
            
            // Progress indicator
            if !viewModel.selectedSports.isEmpty {
                HStack {
                    Text("\(viewModel.selectedSports.count) sport\(viewModel.selectedSports.count == 1 ? "" : "s") selected")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.primaryOrange)
                    Spacer()
                    Button("Clear All") {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            viewModel.selectedSports.removeAll()
                        }
                    }
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.red)
                }
                .padding(.horizontal, 4)
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .background(Color.white.opacity(0.95))
    }
    
    private var backButton: some View {
        Button(action: { dismiss() }) {
            HStack(spacing: 8) {
                Image(systemName: "arrow.left")
                    .font(.system(size: 16, weight: .medium))
            }
            .foregroundColor(.primaryOrange)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color.primaryOrange.opacity(0.1))
            )
        }
    }
    
    private var headerTitle: some View {
        Text("Add Sports")
            .font(.system(size: 20, weight: .bold, design: .rounded))
            .foregroundColor(.textPrimary)
    }
    
    private var saveButton: some View {
        Button(action: {
            viewModel.saveSelectedSports { success in
                onSportsAdded(success)
                if success {
                    dismiss()
                }
            }
        }) {
            HStack(spacing: 6) {
                if viewModel.isSaving {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .scaleEffect(0.8)
                } else {
                    Image(systemName: "checkmark")
                        .font(.system(size: 14, weight: .semibold))
                }
                
                Text(viewModel.isSaving ? "Saving..." : "Save")
                    .font(.system(size: 14, weight: .semibold))
            }
            .foregroundColor(.white)
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(viewModel.canSave ? Color.primaryOrange : Color.gray)
            )
            .shadow(color: viewModel.canSave ? .primaryOrange.opacity(0.3) : .clear, radius: 4, x: 0, y: 2)
        }
        .disabled(!viewModel.canSave)
    }
    
    // MARK: - Search Section
    private var searchSection: some View {
        HStack(spacing: 12) {
            HStack(spacing: 10) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.textSecondary)
                
                TextField("Search sports...", text: $viewModel.searchText)
                    .font(.system(size: 16))
                    .foregroundColor(.textPrimary)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                
                if !viewModel.searchText.isEmpty {
                    Button(action: { viewModel.searchText = "" }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 16))
                            .foregroundColor(.textSecondary)
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: 25))
            .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 16)
        .background(Color.white.opacity(0.95))
    }
    
    // MARK: - Sports List Section
    @ViewBuilder
    private var sportsListSection: some View {
        if viewModel.isLoading {
            loadingView
        } else if viewModel.filteredSports.isEmpty {
            emptyStateView
        } else {
            sportsListView
        }
    }
    
    private var loadingView: some View {
        VStack(spacing: 20) {
            Spacer()
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle(tint: .primaryOrange))
                .scaleEffect(1.5)
            Text("Loading sports...")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.textSecondary)
            Spacer()
        }
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Spacer()
            Image(systemName: "magnifyingglass")
                .font(.system(size: 50, weight: .light))
                .foregroundColor(.textSecondary.opacity(0.5))
            Text("No sports found")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.textPrimary)
            Text("Try adjusting your search terms")
                .font(.system(size: 14))
                .foregroundColor(.textSecondary)
            Spacer()
        }
    }
    
    private var sportsListView: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                ForEach(viewModel.filteredSports) { sport in
                    SportRowCard(
                        sport: sport,
                        isSelected: viewModel.isSportSelected(sport),
                        isDisabled: viewModel.isSportAlreadyAdded(sport),
                        // 🔴 FIX: Use the correct level for disabled sports
                        currentLevel: viewModel.isSportAlreadyAdded(sport) ?
                            viewModel.getExistingSportLevel(sport) :
                            viewModel.getSelectedExperience(for: sport),
                        onToggle: {
                            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                                viewModel.toggleSportSelection(sport)
                            }
                        },
                        onLevelChange: { newLevel in
                            viewModel.updateSportExperience(sport, experience: newLevel)
                        }
                    )
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 16)
            .padding(.bottom, 100)
        }
        .refreshable {
            viewModel.loadAvailableSports()
        }
    }
}

// MARK: - Sport Row Card (Single Row Design with Disabled State)
struct SportRowCard: View {
    let sport: Sport
    let isSelected: Bool
    let isDisabled: Bool // Add disabled state
    let currentLevel: ExperienceLevel
    let onToggle: () -> Void
    let onLevelChange: (ExperienceLevel) -> Void
    @State private var imageLoadError = false
    
    var body: some View {
        ZStack {
            // Background image layer
            backgroundImageLayer
            
            // Background overlay (different for disabled state)
            backgroundOverlay
            
            // Main content
            HStack(spacing: 16) {
                // Sport info (no icon anymore)
                sportInfoSection
                
                Spacer()
                
                // Content based on disabled state
                if isDisabled {
                    // Show current level for disabled sports
                    currentLevelDisplay
                } else {
                    // Experience level selector for available sports
                    experienceLevelSelector
                    // Selection checkbox for available sports
                    selectionIndicator
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
        }
        .frame(height: 120)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(cardBorder)
        .scaleEffect(isSelected ? 1.02 : 1.0)
        .opacity(isDisabled ? 0.7 : 1.0)
        .shadow(
            color: isDisabled ? .black.opacity(0.02) : (isSelected ? .primaryOrange.opacity(0.15) : .black.opacity(0.05)),
            radius: isDisabled ? 2 : (isSelected ? 8 : 4),
            x: 0,
            y: isDisabled ? 1 : (isSelected ? 4 : 2)
        )
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: isSelected)
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: isDisabled)
        .onTapGesture {
            if !isDisabled {
                onToggle()
            }
        }
    }
    
    // MARK: - Background Image Layer
    @ViewBuilder
    private var backgroundImageLayer: some View {
        if let iconUrl = sport.imageUrl, !iconUrl.isEmpty, !imageLoadError {
            AsyncImage(url: URL(string: iconUrl)) { phase in
                switch phase {
                case .empty:
                    loadingBackground
                case .success(let image):
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .clipped()
                case .failure(_):
                    defaultSportBackground
                        .onAppear { imageLoadError = true }
                @unknown default:
                    defaultSportBackground
                }
            }
        } else {
            defaultSportBackground
        }
    }
    
    private var loadingBackground: some View {
        ZStack {
            defaultSportBackground
            ZStack {
                Circle()
                    .fill(Color.black.opacity(0.3))
                    .frame(width: 30, height: 30)
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    .scaleEffect(0.6)
            }
        }
    }
    
    private var defaultSportBackground: some View {
        let (colors, _) = getSportTheme(for: sport.name)
        
        return ZStack {
            LinearGradient(
                colors: colors,
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    Image(systemName: getSportIcon(for: sport.name))
                        .font(.system(size: 30, weight: .ultraLight))
                        .foregroundColor(.white.opacity(0.15))
                        .offset(x: 15, y: 5)
                }
            }
        }
    }
    
    private var backgroundOverlay: some View {
        LinearGradient(
            colors: [
                Color.black.opacity(isDisabled ? 0.75 : 0.5),
                Color.black.opacity(isDisabled ? 0.6 : 0.3),
                Color.black.opacity(isDisabled ? 0.8 : 0.6)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
    
    // MARK: - Sport Info Section (No Icon)
    private var sportInfoSection: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(sport.name)
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(isDisabled ? .white.opacity(0.6) : .white)
            
            if let description = sport.description, !description.isEmpty {
                Text(description)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(isDisabled ? .white.opacity(0.4) : .white.opacity(0.8))
                    .lineLimit(1)
            }
        }
    }
    
    // MARK: - Current Level Display (For Disabled Sports - Modern Design)
    private var currentLevelDisplay: some View {
        VStack(spacing: 12) {
            // Modern "Added" badge
            HStack(spacing: 6) {
                ZStack {
                    Circle()
                        .fill(.green.opacity(0.8))
                        .frame(width: 18, height: 18)
                    
                    Image(systemName: "checkmark")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(.white)
                }
                
                Text("Added")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(.green.opacity(0.9))
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(
                Capsule()
                    .fill(.green.opacity(0.15))
                    .overlay(
                        Capsule()
                            .stroke(.green.opacity(0.3), lineWidth: 1)
                    )
            )
            
            // Larger level display
            VStack(spacing: 8) {
                Text("Level")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.white.opacity(0.5))
                
                // Bigger level dots
                HStack(spacing: 6) {
                    ForEach(1...4, id: \.self) { level in
                        Circle()
                            .fill(level <= currentLevel.rawValue ? Color.white.opacity(0.7) : Color.white.opacity(0.2))
                            .frame(width: 12, height: 12)
                    }
                }
                
                // Larger level name
                Text(currentLevel.displayName)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.white.opacity(0.6))
            }
        }
    }
    
    // MARK: - Experience Level Selector (For Available Sports)
    private var experienceLevelSelector: some View {
        VStack(spacing: 8) {
            // Level title
            Text("Level")
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(.white.opacity(0.8))
            
            // Level buttons in horizontal row
            HStack(spacing: 6) {
                ForEach(ExperienceLevel.allCases, id: \.self) { level in
                    Button(action: {
                        // Auto-select sport if level is changed
                        if !isSelected {
                            onToggle()
                        }
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            onLevelChange(level)
                        }
                    }) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 6)
                                .fill(level == currentLevel ? .primaryOrange : Color.white.opacity(0.2))
                                .frame(width: 28, height: 28)
                            
                            Text("\(level.rawValue)")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundColor(level == currentLevel ? .white : .white.opacity(0.7))
                        }
                    }
                    .scaleEffect(level == currentLevel ? 1.1 : 1.0)
                    .animation(.spring(response: 0.3, dampingFraction: 0.7), value: currentLevel)
                }
            }
            
            // Current level name
            Text(currentLevel.displayName)
                .font(.system(size: 10, weight: .semibold))
                .foregroundColor(.white)
        }
    }
    
    // MARK: - Selection Checkbox
    @ViewBuilder
    private var selectionIndicator: some View {
        Button(action: {
            if !isDisabled {
                onToggle()
            }
        }) {
            ZStack {
                Circle()
                    .fill(isSelected ? Color.primaryOrange : .clear)
                    .frame(width: 24, height: 24)
                    .overlay(
                        Circle()
                            .stroke(isSelected ? Color.primaryOrange : .white.opacity(0.6), lineWidth: 2)
                    )
                
                if isSelected {
                    Image(systemName: "checkmark")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.white)
                }
            }
        }
        .buttonStyle(PlainButtonStyle())
        .disabled(isDisabled)
    }
    
    // MARK: - Card Styling
    private var cardBorder: some View {
        RoundedRectangle(cornerRadius: 16)
            .stroke(
                isSelected
                ? LinearGradient(colors: [.primaryOrange, .primaryOrange.opacity(0.8)], startPoint: .topLeading, endPoint: .bottomTrailing)
                : LinearGradient(colors: [.clear, .clear], startPoint: .topLeading, endPoint: .bottomTrailing),
                lineWidth: isSelected ? 3 : 0
            )
    }
    
    private func getSportIcon(for sportName: String) -> String {
        switch sportName.lowercased() {
        case "basketball": return "basketball.fill"
        case "tennis": return "tennis.racket"
        case "soccer", "football": return "soccerball"
        case "swimming": return "figure.pool.swim"
        case "volleyball": return "volleyball.fill"
        case "running", "run": return "figure.run"
        case "cycling", "bicycle", "bike": return "bicycle"
        case "fitness", "gym": return "dumbbell.fill"
        case "golf": return "figure.golf"
        case "baseball": return "baseball.fill"
        case "badminton": return "tennisball.fill"
        case "boxing": return "figure.boxing"
        case "skiing": return "figure.skiing.downhill"
        case "surfing": return "figure.surfing"
        case "climbing": return "figure.climbing"
        case "wrestling": return "figure.wrestling"
        case "martial arts", "karate", "judo": return "figure.martial.arts"
        case "yoga": return "figure.yoga"
        case "dance", "dancing": return "figure.dance"
        case "skating", "ice skating": return "figure.skating"
        case "hockey": return "hockey.puck.fill"
        case "archery": return "figure.archery"
        case "bowling": return "figure.bowling"
        case "fishing": return "figure.fishing"
        case "hiking": return "figure.hiking"
        case "sailing": return "figure.sailing"
        case "table tennis", "ping pong": return "ping.pong.paddle.fill"
        case "water polo": return "figure.water.polo"
        case "snowboarding": return "figure.snowboarding"
        default: return "sportscourt.fill"
        }
    }
    
    private func getSportTheme(for sportName: String) -> ([Color], PatternType) {
        switch sportName.lowercased() {
        case "basketball": return ([.orange, .red.opacity(0.8)], .basketball)
        case "tennis": return ([.green, .yellow.opacity(0.8)], .tennis)
        case "soccer", "football": return ([.green, .blue.opacity(0.8)], .soccer)
        case "swimming": return ([.blue, .cyan.opacity(0.8)], .water)
        case "volleyball": return ([.yellow, .orange.opacity(0.8)], .generic)
        case "running", "run": return ([.red, .pink.opacity(0.8)], .track)
        case "cycling", "bicycle", "bike": return ([.blue, .indigo.opacity(0.8)], .generic)
        case "fitness", "gym": return ([.gray, .black.opacity(0.6)], .generic)
        default: return ([.primaryOrange, .primaryOrange.opacity(0.6)], .generic)
        }
    }
}

// MARK: - Pattern Types
enum PatternType {
    case basketball, tennis, soccer, water, track, generic
}

// MARK: - Preview
#Preview {
    AddSportView { success in
        print("Sports added: \(success)")
    }
    .environmentObject(LocalizationManager(localizationService: MockLocalizationService()))
}
