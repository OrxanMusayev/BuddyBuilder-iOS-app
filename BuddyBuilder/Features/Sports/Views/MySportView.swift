// BuddyBuilder/Features/Sports/Views/MySportsView.swift - NAVIGATION ALERT BUG FIXED

import SwiftUI
import Combine

// MARK: - My Sports View Model - ENHANCED WITH ALERT MANAGEMENT
class MySportsViewModel: ObservableObject {
    @Published var userSports: [UserSport] = []
    @Published var isLoading = false
    @Published var errorMessage: String = ""
    @Published var showError = false
    @Published var isUpdating = false
    
    // 🔴 FIX: Centralized alert management in ViewModel
    @Published var showDeleteConfirmation = false
    @Published var sportToDelete: UserSport?
    @Published var showLevelPicker = false
    @Published var sportToEditLevel: UserSport?
    
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
    
    // 🔴 FIX: Centralized delete confirmation method
    func requestDeleteSport(_ userSport: UserSport) {
        print("🗑️ Requesting delete confirmation for: \(userSport.name)")
        sportToDelete = userSport
        showDeleteConfirmation = true
    }
    
    // 🔴 FIX: Actual delete method
    func confirmDeleteSport() {
        guard let sportToDelete = sportToDelete else {
            print("❌ No sport to delete")
            return
        }
        
        print("🗑️ Confirming delete for sport: \(sportToDelete.name) with ID: \(sportToDelete.id)")
        
        // Clear the pending delete state immediately
        self.sportToDelete = nil
        showDeleteConfirmation = false
        
        // Use ProfileService for deleting sport
        profileService.deleteSport(sportId: sportToDelete.id)
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
    
    // 🔴 FIX: Cancel delete method
    func cancelDeleteSport() {
        print("❌ Delete cancelled")
        sportToDelete = nil
        showDeleteConfirmation = false
    }
    
    // 🔴 FIX: Centralized level picker management
    func requestEditLevel(_ userSport: UserSport) {
        print("✏️ Requesting level edit for: \(userSport.name)")
        sportToEditLevel = userSport
        showLevelPicker = true
    }
    
    // 🔴 FIX: Update sport experience method
    func updateSportExperience(newLevel: ExperienceLevel) {
        guard let sportToEdit = sportToEditLevel else {
            print("❌ No sport to edit level")
            return
        }
        
        print("📊 Updating experience level for: \(sportToEdit.name) to: \(newLevel.displayName)")
        
        // Clear the pending edit state
        sportToEditLevel = nil
        showLevelPicker = false
        
        isUpdating = true
        
        // Use ProfileService for updating experience level
        profileService.updateSportExperience(
            sportId: sportToEdit.id,
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
                    // Reload data to reflect changes
                    self?.loadMySports()
                } else {
                    self?.handleError("Failed to update sport experience")
                }
            }
        )
        .store(in: &cancellables)
    }
    
    // 🔴 FIX: Cancel level edit method
    func cancelEditLevel() {
        print("❌ Level edit cancelled")
        sportToEditLevel = nil
        showLevelPicker = false
    }
    
    private func handleError(_ message: String) {
        errorMessage = message
        showError = true
        print("❌ MySports Error: \(message)")
    }
}

// MARK: - My Sports View - CENTRALIZED ALERT MANAGEMENT
struct MySportsView: View {
    @StateObject private var viewModel = MySportsViewModel()
    @EnvironmentObject var localizationManager: LocalizationManager
    @Environment(\.dismiss) var dismiss
    @State private var navigateToAddSport = false
    
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
            // 🔴 FIX: Centralized alerts at view level
            .alert("Error", isPresented: $viewModel.showError) {
                Button("OK") { }
            } message: {
                Text(viewModel.errorMessage)
            }
            // 🔴 FIX: Simple delete confirmation overlay
            .overlay(
                Group {
                    if viewModel.showDeleteConfirmation {
                        CustomDeleteConfirmationOverlay(
                            sport: viewModel.sportToDelete,
                            onConfirm: {
                                viewModel.confirmDeleteSport()
                            },
                            onCancel: {
                                viewModel.cancelDeleteSport()
                            }
                        )
                        .transition(.opacity.combined(with: .scale))
                        .zIndex(1000)
                    }
                }
            )
            // 🔴 FIX: Custom level picker sheet at view level
            .fullScreenCover(isPresented: $viewModel.showLevelPicker) {
                if let sport = viewModel.sportToEditLevel {
                    CustomExperienceLevelPicker(
                        currentLevel: sport.experienceLevelEnum ?? .beginner,
                        sportName: sport.name,
                        onLevelSelected: { newLevel in
                            viewModel.updateSportExperience(newLevel: newLevel)
                        },
                        onCancel: {
                            viewModel.cancelEditLevel()
                        }
                    )
                }
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
                Text("")
                    .font(.system(size: 16, weight: .medium))
            }
            .foregroundColor(.primaryOrange)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
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
        CleanMySportCard(
            userSport: userSport,
            isUpdating: viewModel.isUpdating,
            onRemove: {
                // 🔴 FIX: Direct call to ViewModel method
                viewModel.requestDeleteSport(userSport)
            },
            onEditLevel: {
                // 🔴 FIX: Direct call to ViewModel method
                viewModel.requestEditLevel(userSport)
            }
        )
    }
}

// MARK: - Clean My Sport Card - NO INTERNAL ALERTS
struct CleanMySportCard: View {
    let userSport: UserSport
    let isUpdating: Bool
    let onRemove: () -> Void
    let onEditLevel: () -> Void
    
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
        // 🔴 FIX: No alerts at card level - all managed by parent view
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
            
            Button(action: {
                // 🔴 FIX: Simple callback, no internal state
                print("🎯 Level edit requested for: \(userSport.name)")
                onEditLevel()
            }) {
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
    
    private var deleteButton: some View {
        Button(action: {
            // 🔴 FIX: Simple callback with haptic feedback, no internal state
            print("🗑️ Delete requested for: \(userSport.name)")
            let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
            impactFeedback.impactOccurred()
            onRemove()
        }) {
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

// MARK: - Custom Experience Level Picker - MODERN FULL SCREEN
struct CustomExperienceLevelPicker: View {
    let currentLevel: ExperienceLevel
    let sportName: String
    let onLevelSelected: (ExperienceLevel) -> Void
    let onCancel: () -> Void
    @State private var selectedLevel: ExperienceLevel
    @State private var isAnimating = false
    
    init(currentLevel: ExperienceLevel, sportName: String, onLevelSelected: @escaping (ExperienceLevel) -> Void, onCancel: @escaping () -> Void) {
        self.currentLevel = currentLevel
        self.sportName = sportName
        self.onLevelSelected = onLevelSelected
        self.onCancel = onCancel
        self._selectedLevel = State(initialValue: currentLevel)
    }
    
    var body: some View {
        ZStack {
            // Background
            LinearGradient(
                colors: [
                    Color.primaryOrange.opacity(0.1),
                    Color.blue.opacity(0.1),
                    Color.purple.opacity(0.1)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Custom header
                customHeader
                
                // Main content
                Spacer()
                levelSelectionContent
                Spacer()
                
                // Action buttons
                actionButtons
            }
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 0.5)) {
                isAnimating = true
            }
        }
    }
    
    private var customHeader: some View {
        VStack(spacing: 16) {
            HStack {
                // Close button
                Button(action: {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        onCancel()
                    }
                }) {
                    Image(systemName: "xmark")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.primary)
                        .frame(width: 44, height: 44)
                        .background(Circle().fill(.ultraThinMaterial))
                        .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
                }
                
                Spacer()
                
                // Save button (only if level changed)
                if selectedLevel != currentLevel {
                    Button(action: {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            onLevelSelected(selectedLevel)
                        }
                    }) {
                        HStack(spacing: 6) {
                            Image(systemName: "checkmark")
                                .font(.system(size: 14, weight: .semibold))
                            Text("Save")
                                .font(.system(size: 16, weight: .semibold))
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 12)
                        .background(
                            Capsule()
                                .fill(Color.primaryOrange)
                                .shadow(color: .primaryOrange.opacity(0.3), radius: 8, x: 0, y: 4)
                        )
                    }
                    .transition(.scale.combined(with: .opacity))
                }
            }
            
            // Title section
            VStack(spacing: 8) {
                Text("Experience Level")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundColor(.primary)
                
                Text("Select your experience level for \(sportName)")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 20)
        .padding(.bottom, 32)
    }
    
    private var levelSelectionContent: some View {
        VStack(spacing: 24) {
            ForEach(ExperienceLevel.allCases, id: \.self) { level in
                ModernLevelCard(
                    level: level,
                    isSelected: selectedLevel == level,
                    onSelect: {
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                            selectedLevel = level
                        }
                    }
                )
                .scaleEffect(isAnimating ? 1.0 : 0.8)
                .opacity(isAnimating ? 1.0 : 0.0)
                .animation(
                    .spring(response: 0.5, dampingFraction: 0.8)
                        .delay(Double(level.rawValue - 1) * 0.1),
                    value: isAnimating
                )
            }
        }
        .padding(.horizontal, 20)
    }
    
    private var actionButtons: some View {
        VStack(spacing: 16) {
            if selectedLevel != currentLevel {
                // Confirm button
                Button(action: {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        onLevelSelected(selectedLevel)
                    }
                }) {
                    HStack(spacing: 8) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 18))
                        Text("Update Experience Level")
                            .font(.system(size: 16, weight: .semibold))
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background(
                        LinearGradient(
                            colors: [.primaryOrange, .primaryOrange.opacity(0.8)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 28))
                    .shadow(color: .primaryOrange.opacity(0.3), radius: 12, x: 0, y: 6)
                }
            }
            
            // Cancel button
            Button(action: {
                withAnimation(.easeInOut(duration: 0.3)) {
                    onCancel()
                }
            }) {
                Text("Cancel")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.primary)
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background(
                        RoundedRectangle(cornerRadius: 28)
                            .fill(.ultraThinMaterial)
                            .overlay(
                                RoundedRectangle(cornerRadius: 28)
                                    .stroke(Color.secondary.opacity(0.2), lineWidth: 1)
                            )
                    )
            }
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 40)
    }
}

// MARK: - Modern Level Card
struct ModernLevelCard: View {
    let level: ExperienceLevel
    let isSelected: Bool
    let onSelect: () -> Void
    
    var body: some View {
        Button(action: onSelect) {
            HStack(spacing: 20) {
                // Level indicator
                levelIndicator
                
                // Level info
                VStack(alignment: .leading, spacing: 6) {
                    Text(level.displayName)
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(isSelected ? .white : .primary)
                    
                }
                
                Spacer()
                
                // Selection indicator
                selectionIndicator
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 20)
            .background(cardBackground)
            .overlay(cardBorder)
            .shadow(color: isSelected ? .primaryOrange.opacity(0.2) : .black.opacity(0.05), radius: isSelected ? 12 : 6, x: 0, y: isSelected ? 6 : 3)
        }
        .buttonStyle(PlainButtonStyle())
        .scaleEffect(isSelected ? 1.02 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isSelected)
    }
    
    private var levelIndicator: some View {
        VStack(spacing: 8) {
            // Level dots
            HStack(spacing: 6) {
                ForEach(1...4, id: \.self) { dot in
                    Circle()
                        .fill(dot <= level.rawValue ?
                              (isSelected ? Color.white : Color.primaryOrange) :
                              (isSelected ? Color.white.opacity(0.3) : Color.gray.opacity(0.3)))
                        .frame(width: 12, height: 12)
                }
            }
            
            // Level number
            Text("\(level.rawValue)")
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(isSelected ? .white : .primaryOrange)
                .frame(width: 32, height: 32)
                .background(
                    Circle()
                        .fill(isSelected ? Color.white.opacity(0.2) : Color.primaryOrange.opacity(0.1))
                        .overlay(
                            Circle()
                                .stroke(isSelected ? Color.white.opacity(0.4) : Color.primaryOrange.opacity(0.3), lineWidth: 2)
                        )
                )
        }
    }
    
    private var selectionIndicator: some View {
        Group {
            if isSelected {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 24, weight: .medium))
                    .foregroundColor(.white)
                    .scaleEffect(1.2)
            } else {
                Circle()
                    .stroke(Color.secondary.opacity(0.3), lineWidth: 2)
                    .frame(width: 24, height: 24)
            }
        }
    }
    
    private var cardBackground: some View {
        RoundedRectangle(cornerRadius: 20)
            .fill(isSelected ?
                  LinearGradient(colors: [.primaryOrange, .primaryOrange.opacity(0.8)], startPoint: .topLeading, endPoint: .bottomTrailing) :
                  LinearGradient(colors: [.white, .white], startPoint: .topLeading, endPoint: .bottomTrailing))
    }
    
    private var cardBorder: some View {
        RoundedRectangle(cornerRadius: 20)
            .stroke(isSelected ? Color.primaryOrange : Color.secondary.opacity(0.1), lineWidth: isSelected ? 2 : 1)
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

// MARK: - Simple Delete Confirmation Overlay
struct CustomDeleteConfirmationOverlay: View {
    let sport: UserSport?
    let onConfirm: () -> Void
    let onCancel: () -> Void
    @State private var isAnimating = false
    
    var body: some View {
        ZStack {
            // Background blur
            Color.black.opacity(0.4)
                .ignoresSafeArea()
                .onTapGesture {
                    onCancel()
                }
            
            // Simple confirmation card
            VStack(spacing: 20) {
                // Icon and question
                VStack(spacing: 12) {
                    Image(systemName: "trash.circle.fill")
                        .font(.system(size: 36))
                        .foregroundColor(.red)
                    
                    if let sport = sport {
                        Text("Remove \(sport.name)?")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.primary)
                            .multilineTextAlignment(.center)
                    }
                }
                
                // Action buttons
                HStack(spacing: 12) {
                    // Cancel button
                    Button("Cancel") {
                        onCancel()
                    }
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.primary)
                    .frame(maxWidth: .infinity)
                    .frame(height: 40)
                    .background(Color.secondary.opacity(0.1))
                    .clipShape(Capsule())
                    
                    // Remove button
                    Button("Remove") {
                        onConfirm()
                    }
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 40)
                    .background(Color.red)
                    .clipShape(Capsule())
                }
            }
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(.ultraThinMaterial)
                    .shadow(radius: 15)
            )
            .frame(maxWidth: 240)
            .scaleEffect(isAnimating ? 1.0 : 0.9)
            .opacity(isAnimating ? 1.0 : 0.0)
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.2)) {
                isAnimating = true
            }
        }
    }
}

// MARK: - Preview
#Preview {
    MySportsView()
        .environmentObject(LocalizationManager(localizationService: MockLocalizationService()))
}
