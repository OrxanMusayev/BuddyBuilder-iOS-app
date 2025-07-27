// BuddyBuilder/Features/Sports/Views/MySportsView.swift - COMPLETE FILE

import SwiftUI
import Combine

// MARK: - My Sports View Model
class MySportsViewModel: ObservableObject {
    @Published var userSports: [UserSport] = []
    @Published var isLoading = false
    @Published var errorMessage: String = ""
    @Published var showError = false
    @Published var isUpdating = false
    
    private let mySportsService: MySportsServiceProtocol
    private let profileService: ProfileServiceProtocol
    private var cancellables = Set<AnyCancellable>()
    
    init(mySportsService: MySportsServiceProtocol = MySportsService(),
         profileService: ProfileServiceProtocol = ProfileService()) {
        self.mySportsService = mySportsService
        self.profileService = profileService
        loadMySports()
    }
    
    func loadMySports() {
        isLoading = true
        errorMessage = ""
        
        mySportsService.fetchMySportsWithAutoRefresh()
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    self?.isLoading = false
                    if case .failure(let error) = completion {
                        self?.handleError("Failed to load sports: \(error.localizedDescription)")
                    }
                },
                receiveValue: { [weak self] sports in
                    self?.userSports = sports
                    print("✅ Loaded \(sports.count) user sports with auto-refresh")
                }
            )
            .store(in: &cancellables)
    }
    
    func removeSport(_ userSport: UserSport) {
        print(userSport.id)
        // Use ProfileService for deleting sport
        profileService.deleteSport(sportId: userSport.id)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    if case .failure(let error) = completion {
                        self?.handleError("Failed to remove sport: \(error.localizedDescription)")
                    }
                },
                receiveValue: { [weak self] success in
                    if success {
                        print("✅ Sport removed successfully via Profile API")
                        // Reload fresh data from server
                        self?.loadMySports()
                    } else {
                        self?.handleError("Failed to remove sport")
                    }
                }
            )
            .store(in: &cancellables)
    }
    
    func updateSportExperience(_ userSport: UserSport, newLevel: ExperienceLevel) {
        isUpdating = true
        
        // Use ProfileService for updating experience level
        profileService.updateSportExperience(
            sportId: userSport.id,
            experienceLevel: newLevel.rawValue
        )
        .receive(on: DispatchQueue.main)
        .sink(
            receiveCompletion: { [weak self] completion in
                self?.isUpdating = false
                if case .failure(let error) = completion {
                    self?.handleError("Failed to update sport experience: \(error.localizedDescription)")
                }
            },
            receiveValue: { [weak self] success in
                if success {
                    print("✅ Sport experience updated successfully via Profile API")
                    // UI will be updated when MySports is refreshed
                    // For immediate UI feedback, we could reload MySports:
                    self?.loadMySports()
                } else {
                    self?.handleError("Failed to update sport experience")
                }
            }
        )
        .store(in: &cancellables)
    }
    
    private func handleError(_ message: String) {
        errorMessage = message
        showError = true
        print("❌ MySports Error: \(message)")
    }
}

// MARK: - My Sports View
struct MySportsView: View {
    @StateObject private var viewModel = MySportsViewModel()
    @EnvironmentObject var localizationManager: LocalizationManager
    @Environment(\.dismiss) var dismiss
    @State private var navigateToAddSport = false // For animated navigation
    
    var body: some View {
        mainContent
            .navigationDestination(isPresented: $navigateToAddSport) {
                AddSportView { success in
                    if success {
                        viewModel.loadMySports()
                    }
                }
                .environmentObject(localizationManager)
            }
            .navigationBarHidden(true)
            .alert("Error", isPresented: $viewModel.showError) {
                Button("OK") { }
            } message: {
                Text(viewModel.errorMessage)
            }
    }
    
    // MARK: - Main Content
    private var mainContent: some View {
        ZStack {
            LoginBackgroundView()
            
            VStack(spacing: 0) {
                customHeader
                contentBasedOnState
            }
        }
    }
    
    // MARK: - Content Based on State
    @ViewBuilder
    private var contentBasedOnState: some View {
        if viewModel.isLoading && viewModel.userSports.isEmpty {
            loadingView
        } else if viewModel.userSports.isEmpty {
            emptyStateView
        } else {
            sportsListView
        }
    }
    
    // MARK: - Custom Header
    private var customHeader: some View {
        HStack {
            backButton
            Spacer()
            headerTitle
            Spacer()
            addButton
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .background(Color.white.opacity(0.9))
    }
    
    private var backButton: some View {
        Button(action: { dismiss() }) {
            HStack(spacing: 8) {
                Image(systemName: "arrow.left")
                    .font(.system(size: 16, weight: .medium))
                Text("Back")
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
        Text("My Sports")
            .font(.system(size: 20, weight: .bold, design: .rounded))
            .foregroundColor(.textPrimary)
    }
    
    private var addButton: some View {
        Button(action: { navigateToAddSport = true }) {
            Image(systemName: "plus")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.white)
                .frame(width: 36, height: 36)
                .background(Color.primaryOrange)
                .clipShape(Circle())
                .shadow(color: .primaryOrange.opacity(0.3), radius: 4, x: 0, y: 2)
        }
    }
    
    // MARK: - Loading View
    private var loadingView: some View {
        VStack(spacing: 20) {
            Spacer()
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle(tint: .primaryOrange))
                .scaleEffect(1.5)
            Text("Loading your sports...")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.textSecondary)
            Spacer()
        }
    }
    
    // MARK: - Empty State View
    private var emptyStateView: some View {
        VStack(spacing: 24) {
            Spacer()
            
            ZStack {
                Circle()
                    .fill(Color.primaryOrange.opacity(0.1))
                    .frame(width: 100, height: 100)
                Image(systemName: "figure.run.circle")
                    .font(.system(size: 50, weight: .light))
                    .foregroundColor(.primaryOrange.opacity(0.6))
            }
            
            VStack(spacing: 12) {
                Text("No Sports Added Yet")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundColor(.textPrimary)
                
                Text("Add your favorite sports to connect with other players and join events")
                    .font(.system(size: 16))
                    .foregroundColor(.textSecondary)
                    .multilineTextAlignment(.center)
                    .lineLimit(nil)
            }
            .padding(.horizontal, 40)
            
            Button(action: { navigateToAddSport = true }) {
                HStack(spacing: 8) {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 16))
                    Text("Add Your First Sport")
                        .font(.system(size: 16, weight: .semibold))
                }
                .foregroundColor(.white)
                .padding(.horizontal, 24)
                .padding(.vertical, 14)
                .background(Color.primaryOrange)
                .clipShape(RoundedRectangle(cornerRadius: 25))
                .shadow(color: .primaryOrange.opacity(0.3), radius: 8, x: 0, y: 4)
            }
            
            Spacer()
        }
        .padding(.horizontal, 20)
    }
    
    // MARK: - Sports List View
    private var sportsListView: some View {
        ScrollView {
            sportsListContent
        }
        .refreshable {
            viewModel.loadMySports()
        }
    }
    
    private var sportsListContent: some View {
        LazyVStack(spacing: 20) {
            ForEach(viewModel.userSports) { userSport in
                sportCardView(for: userSport)
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 24)
        .padding(.bottom, 120)
    }
    
    private func sportCardView(for userSport: UserSport) -> some View {
        EnhancedMySportCard(
            userSport: userSport,
            isUpdating: viewModel.isUpdating,
            onRemove: { viewModel.removeSport(userSport) },
            onUpdateExperience: { newLevel in
                viewModel.updateSportExperience(userSport, newLevel: newLevel)
            }
        )
    }
}

// MARK: - Enhanced My Sport Card
struct EnhancedMySportCard: View {
    let userSport: UserSport
    let isUpdating: Bool
    let onRemove: () -> Void
    let onUpdateExperience: (ExperienceLevel) -> Void
    
    @State private var showRemoveConfirmation = false
    @State private var showLevelPicker = false
    @State private var imageLoadError = false
    
    var body: some View {
        ZStack {
            backgroundImageLayer
            backgroundOverlay
            cardContent
        }
        .frame(height: 140)
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .shadow(color: .black.opacity(0.06), radius: 12, x: 0, y: 6)
        .opacity(isUpdating ? 0.7 : 1.0)
        .animation(.easeInOut(duration: 0.2), value: isUpdating)
        .confirmationDialog("Remove Sport", isPresented: $showRemoveConfirmation) {
            Button("Remove", role: .destructive) { onRemove() }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("Are you sure you want to remove \(userSport.name) from your sports?")
        }
        .sheet(isPresented: $showLevelPicker) {
            ExperienceLevelPickerSheet(
                currentLevel: userSport.experienceLevelEnum ?? .beginner,
                sportName: userSport.name,
                onLevelSelected: onUpdateExperience
            )
        }
    }
    
    private var backgroundOverlay: some View {
        LinearGradient(
            colors: [
                Color.black.opacity(0.6),
                Color.black.opacity(0.3),
                Color.black.opacity(0.7)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
    
    private var cardContent: some View {
        VStack(spacing: 18) {
            topRow
            middleRow
        }
        .padding(.horizontal, 32)
        .padding(.vertical, 28)
    }
    
    private var topRow: some View {
        HStack(alignment: .center) {
            Text(userSport.name)
                .font(.system(size: 22, weight: .bold))
                .foregroundColor(.white)
                .lineLimit(1)
            
            Spacer()
            
            // Modern delete button in top right
            deleteButton
        }
    }
    
    private var userCountBadge: some View {
        Text("\(userSport.userCount) users")
            .font(.system(size: 11, weight: .semibold))
            .foregroundColor(.white.opacity(0.9))
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(Capsule().fill(Color.white.opacity(0.2)))
    }
    
    private var middleRow: some View {
        HStack(alignment: .bottom) {
            experienceLevelSection
            Spacer()
            userCountBadge
        }
    }
    
    private var experienceLevelSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Experience Level")
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(.white.opacity(0.8))
            
            Button(action: { showLevelPicker = true }) {
                experienceLevelContent
            }
            .disabled(isUpdating)
        }
    }
    
    private var experienceLevelContent: some View {
        HStack(spacing: 12) {
            experienceDots
            Text(userSport.experienceLevelName)
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.white)
            Image(systemName: "chevron.down")
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.white.opacity(0.8))
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 12)
        .background(RoundedRectangle(cornerRadius: 22).fill(Color.white.opacity(0.2)))
    }
    
    private var experienceDots: some View {
        HStack(spacing: 5) {
            ForEach(1...4, id: \.self) { level in
                Circle()
                    .fill(level <= userSport.experienceLevel ? Color.white : Color.white.opacity(0.3))
                    .frame(width: 10, height: 10)
            }
        }
    }
    
    private var bottomRow: some View {
        HStack(alignment: .bottom) {
            descriptionSection
            Spacer(minLength: 24)
            actionButtons
        }
    }
    
    private var actionButtons: some View {
        HStack(spacing: 16) {
            if isUpdating {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    .scaleEffect(0.9)
                    .frame(width: 44, height: 44)
            }
            
            Button(action: { showRemoveConfirmation = true }) {
                ZStack {
                    // Modern glassmorphism background
                    RoundedRectangle(cornerRadius: 12)
                        .fill(.ultraThinMaterial)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.red.opacity(0.15))
                        )
                        .frame(width: 44, height: 44)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.red.opacity(0.3), lineWidth: 1)
                        )
                    
                    // Modern trash icon
                    Image(systemName: "trash.fill")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.red.opacity(0.9), .red],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                }
                .scaleEffect(isUpdating ? 0.8 : 1.0)
                .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isUpdating)
                .shadow(color: .red.opacity(0.2), radius: 8, x: 0, y: 4)
            }
            .disabled(isUpdating)
            .buttonStyle(ModernButtonStyle())
        }
    }
    
    private var descriptionSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            if !userSport.description.isEmpty {
                Text(userSport.description)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white.opacity(0.8))
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Text("Added \(userSport.formattedAddedDate)")
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.white.opacity(0.6))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    private var deleteButton: some View {
        Button(action: { showRemoveConfirmation = true }) {
            if isUpdating {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    .scaleEffect(0.8)
                    .frame(width: 32, height: 32)
            } else {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 28, weight: .medium))
                    .foregroundStyle(
                        Color.white.opacity(0.8),
                        Color.red.opacity(0.7)
                    )
                    .shadow(color: .black.opacity(0.2), radius: 2, x: 0, y: 1)
            }
        }
        .disabled(isUpdating)
        .buttonStyle(PlainButtonStyle())
    }
    
    @ViewBuilder
    private var backgroundImageLayer: some View {
        if let iconUrl = userSport.iconUrl, !iconUrl.isEmpty, !imageLoadError {
            AsyncImage(url: URL(string: iconUrl)) { phase in
                switch phase {
                case .empty:
                    loadingBackground
                case .success(let image):
                    image.resizable().aspectRatio(contentMode: .fill).clipped()
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
                    .frame(width: 40, height: 40)
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    .scaleEffect(0.8)
            }
        }
    }
    
    private var defaultSportBackground: some View {
        let (colors, _) = getSportTheme(for: userSport.name)
        
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
                    Image(systemName: getSportIcon(for: userSport.name))
                        .font(.system(size: 40, weight: .ultraLight))
                        .foregroundColor(.white.opacity(0.15))
                        .offset(x: 20, y: 10)
                }
            }
        }
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

// MARK: - Experience Level Picker Sheet
struct ExperienceLevelPickerSheet: View {
    let currentLevel: ExperienceLevel
    let sportName: String
    let onLevelSelected: (ExperienceLevel) -> Void
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        VStack(spacing: 0) {
            sheetHeader
            levelOptionsSection
            cancelButton
        }
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .presentationDetents([.height(400)])
        .presentationDragIndicator(.hidden)
    }
    
    private var sheetHeader: some View {
        VStack(spacing: 12) {
            RoundedRectangle(cornerRadius: 2.5)
                .fill(Color.gray.opacity(0.3))
                .frame(width: 40, height: 5)
                .padding(.top, 8)
            
            Text("Experience Level")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.textPrimary)
            
            Text("Select your experience level for \(sportName)")
                .font(.system(size: 14))
                .foregroundColor(.textSecondary)
                .multilineTextAlignment(.center)
        }
        .padding(.bottom, 24)
    }
    
    private var levelOptionsSection: some View {
        VStack(spacing: 12) {
            ForEach(ExperienceLevel.allCases, id: \.self) { level in
                ExperienceLevelRow(
                    level: level,
                    isSelected: level == currentLevel,
                    onSelect: {
                        onLevelSelected(level)
                        dismiss()
                    }
                )
            }
        }
        .padding(.horizontal, 20)
    }
    
    private var cancelButton: some View {
        Button(action: { dismiss() }) {
            Text("Cancel")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.textSecondary)
                .frame(maxWidth: .infinity)
                .frame(height: 44)
                .background(Color.formBackground)
                .clipShape(RoundedRectangle(cornerRadius: 22))
        }
        .padding(.horizontal, 20)
        .padding(.top, 20)
        .padding(.bottom, 20)
    }
}

// MARK: - Experience Level Row
struct ExperienceLevelRow: View {
    let level: ExperienceLevel
    let isSelected: Bool
    let onSelect: () -> Void
    
    var body: some View {
        Button(action: onSelect) {
            HStack(spacing: 16) {
                levelDots
                levelInfo
                Spacer()
                selectionIndicator
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(rowBackground)
            .overlay(rowBorder)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private var levelDots: some View {
        HStack(spacing: 4) {
            ForEach(1...4, id: \.self) { dot in
                Circle()
                    .fill(dot <= level.rawValue ? Color.primaryOrange : Color.gray.opacity(0.3))
                    .frame(width: 8, height: 8)
            }
        }
        .frame(width: 60)
    }
    
    private var levelInfo: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(level.displayName)
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.textPrimary)
            
        }
    }
    
    private var selectionIndicator: some View {
        Group {
            if isSelected {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 20))
                    .foregroundColor(.primaryOrange)
            }
        }
    }
    
    private var rowBackground: some View {
        RoundedRectangle(cornerRadius: 12)
            .fill(isSelected ? Color.primaryOrange.opacity(0.1) : Color.formBackground.opacity(0.5))
    }
    
    private var rowBorder: some View {
        RoundedRectangle(cornerRadius: 12)
            .stroke(isSelected ? Color.primaryOrange : Color.clear, lineWidth: 1.5)
    }
}

// MARK: - Modern Button Style
struct ModernButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .opacity(configuration.isPressed ? 0.8 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

// MARK: - Preview
#Preview {
    MySportsView()
        .environmentObject(LocalizationManager(localizationService: MockLocalizationService()))
}
