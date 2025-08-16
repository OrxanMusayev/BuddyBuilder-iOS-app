// BuddyBuilder/Features/Profile/Views/ProfileDetailsView.swift

import SwiftUI
import Combine

// MARK: - Profile Details View Model - REDESIGNED FOR DIRECT EDITING
class ProfileDetailsViewModel: ObservableObject {
    @Published var profileDetails: ProfileDetails?
    @Published var isLoading = false
    @Published var isSaving = false
    @Published var errorMessage: String = ""
    @Published var showError = false
    
    // Direct edit fields (always editable)
    @Published var editUsername: String = ""
    @Published var editFirstName: String = ""
    @Published var editLastName: String = ""
    @Published var editBio: String = ""
    @Published var editGender: GenderType = .male
    @Published var editOverallExperience: RegistrationExperienceLevel = .beginner
    
    // Username validation (from registration)
    @Published var usernameAvailability: ValidationState = .idle
    @Published var usernameError = false
    
    private let profileDetailsService: ProfileDetailsServiceProtocol
    private let registrationService: RegistrationServiceProtocol
    private var cancellables = Set<AnyCancellable>()
    private let debounceInterval: TimeInterval = 0.8
    
    // Store dismiss action
    private var dismissAction: (() -> Void)?
    
    init(profileDetailsService: ProfileDetailsServiceProtocol = ProfileDetailsService(),
         registrationService: RegistrationServiceProtocol = RegistrationService()) {
        self.profileDetailsService = profileDetailsService
        self.registrationService = registrationService
        setupUsernameValidation()
        loadProfileDetails()
    }
    
    // Set dismiss action
    func setDismissAction(_ action: @escaping () -> Void) {
        self.dismissAction = action
    }
    
    // Get dismiss action
    func getDismissAction() -> (() -> Void)? {
        return dismissAction
    }
    
    // MARK: - Username Validation Setup
    private func setupUsernameValidation() {
        $editUsername
            .debounce(for: .seconds(debounceInterval), scheduler: RunLoop.main)
            .removeDuplicates()
            .sink { [weak self] username in
                self?.handleUsernameChange(username)
            }
            .store(in: &cancellables)
    }
    
    private func handleUsernameChange(_ username: String) {
        // Don't check if it's the current username
        if username == profileDetails?.username {
            usernameAvailability = .idle
            return
        }
        
        if username.isEmpty || username.count < 3 {
            usernameAvailability = .idle
            return
        }
        
        // Basic validation first
        if !isValidUsername(username) {
            usernameAvailability = .error
            return
        }
        
        checkUsernameAvailability(username)
    }
    
    private func isValidUsername(_ username: String) -> Bool {
        // Username should be at least 3 characters, alphanumeric + underscore
        let usernameRegex = "^[a-zA-Z0-9_]{3,20}$"
        let usernameTest = NSPredicate(format:"SELF MATCHES %@", usernameRegex)
        return usernameTest.evaluate(with: username)
    }
    
    private func checkUsernameAvailability(_ username: String) {
        print("🔍 Checking username availability for: \(username)")
        usernameAvailability = .checking
        
        registrationService.checkUsernameAvailability(username)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    if case .failure(let error) = completion {
                        print("❌ Username check failed: \(error)")
                        self?.usernameAvailability = .error
                    }
                },
                receiveValue: { [weak self] isAvailable in
                    print("✅ Username check result: \(isAvailable ? "available" : "taken")")
                    self?.usernameAvailability = isAvailable ? .available : .taken
                    self?.usernameError = !isAvailable
                }
            )
            .store(in: &cancellables)
    }
    
    // MARK: - Load Profile Details
    func loadProfileDetails() {
        isLoading = true
        errorMessage = ""
        
        profileDetailsService.fetchProfileDetailsWithAutoRefresh()
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    self?.isLoading = false
                    if case .failure(let error) = completion {
                        self?.handleError("Failed to load profile: \(error.localizedDescription)")
                    }
                },
                receiveValue: { [weak self] profile in
                    self?.profileDetails = profile
                    self?.populateEditFields(from: profile)
                    print("✅ Profile details loaded successfully")
                }
            )
            .store(in: &cancellables)
    }
    
    // MARK: - Save Profile Changes - EXTENDED DURATION (NO SUCCESS ALERT)
    func saveProfileChanges() {
        guard let currentProfile = profileDetails else {
            handleError("No profile data available")
            return
        }
        
        // Username validation check
        if editUsername != currentProfile.username && (usernameAvailability == .taken || usernameAvailability == .error) {
            handleError("Please choose a valid and available username")
            return
        }
        
        isSaving = true
        errorMessage = ""
        
        let updateRequest = ProfileUpdateRequest(
            username: editUsername != currentProfile.username ? editUsername : nil,
            firstName: editFirstName.isEmpty ? nil : editFirstName,
            lastName: editLastName.isEmpty ? nil : editLastName,
            gender: editGender,
            phoneNumber: currentProfile.phoneNumber, // Keep existing phone number
            bio: editBio.isEmpty ? nil : editBio,
            profileImageUrl: currentProfile.profileImageUrl,
            overallExperienceLevel: editOverallExperience
        )
        
        // Extended saving duration - Add minimum loading time of 2.5 seconds
        let startTime = Date()
        let minimumLoadingDuration: TimeInterval = 2.5
        
        profileDetailsService.updateProfileWithAutoRefresh(updateRequest)
            .receive(on: DispatchQueue.main)
            .delay(for: .seconds(0.5), scheduler: RunLoop.main) // Additional delay before processing
            .sink(
                receiveCompletion: { [weak self] completion in
                    let elapsedTime = Date().timeIntervalSince(startTime)
                    let remainingTime = max(0, minimumLoadingDuration - elapsedTime)
                    
                    DispatchQueue.main.asyncAfter(deadline: .now() + remainingTime) {
                        self?.isSaving = false
                        if case .failure(let error) = completion {
                            self?.handleError("Failed to update profile: \(error.localizedDescription)")
                        }
                    }
                },
                receiveValue: { [weak self] updatedProfile in
                    let elapsedTime = Date().timeIntervalSince(startTime)
                    let remainingTime = max(0, minimumLoadingDuration - elapsedTime)
                    
                    DispatchQueue.main.asyncAfter(deadline: .now() + remainingTime) {
                        self?.profileDetails = updatedProfile
                        print("✅ Profile updated successfully - preparing smooth navigation")
                        
                        // Smooth navigation: Trigger dismiss with fade transition
                        withAnimation(.easeInOut(duration: 0.4)) {
                            if let dismiss = self?.getDismissAction() {
                                dismiss()
                            }
                        }
                    }
                }
            )
            .store(in: &cancellables)
    }
    
    // MARK: - Helper Methods
    private func populateEditFields(from profile: ProfileDetails) {
        editUsername = profile.username
        editFirstName = profile.firstName ?? ""
        editLastName = profile.lastName ?? ""
        editBio = profile.bio ?? ""
        editGender = profile.genderEnum ?? .male
        editOverallExperience = profile.overallExperienceLevelEnum ?? .beginner
    }
    
    // Check if any field has been modified
    var hasUnsavedChanges: Bool {
        guard let profile = profileDetails else { return false }
        
        return editUsername != profile.username ||
               editFirstName != (profile.firstName ?? "") ||
               editLastName != (profile.lastName ?? "") ||
               editBio != (profile.bio ?? "") ||
               editGender != (profile.genderEnum ?? .male) ||
               editOverallExperience != (profile.overallExperienceLevelEnum ?? .beginner)
    }
    
    private func handleError(_ message: String) {
        errorMessage = message
        showError = true
        print("❌ ProfileDetails Error: \(message)")
    }
}

// MARK: - Profile Details View - SINGLE PAGE WITH DIRECT EDITING & FULL LOCALIZATION
struct ProfileDetailsView: View {
    @StateObject private var viewModel = ProfileDetailsViewModel()
    @EnvironmentObject var localizationManager: LocalizationManager
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Background
                LoginBackgroundView()
                
                VStack(spacing: 0) {
                    // Custom Header
                    customHeader
                    
                    // Content
                    if viewModel.isLoading && viewModel.profileDetails == nil {
                        loadingView
                    } else if viewModel.profileDetails != nil {
                        profileContentView
                    } else {
                        errorStateView
                    }
                }
            }
        }
        .navigationBarHidden(true)
        .onAppear {
            // Set dismiss action when view appears
            viewModel.setDismissAction {
                dismiss()
            }
        }
        .alert("profile.error.title".localized(using: localizationManager), isPresented: $viewModel.showError) {
            Button("common.ok".localized(using: localizationManager)) { }
        } message: {
            Text(viewModel.errorMessage)
        }
    }
    
    // MARK: - Custom Header
    private var customHeader: some View {
        VStack(spacing: 16) {
            HStack {
                // Back button - Fixed width
                Button(action: { dismiss() }) {
                    HStack(spacing: 8) {
                        Image(systemName: "arrow.left")
                            .font(.system(size: 16, weight: .medium))
                        Text("".localized(using: localizationManager))
                            .font(.system(size: 16, weight: .medium))
                    }
                    .foregroundColor(.primaryOrange)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                }
                .frame(width: 80, alignment: .leading) // Fixed width for back button
                
                Spacer()
                
                // Title - Always centered
                Text("profile.details.title".localized(using: localizationManager))
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundColor(.textPrimary)
                
                Spacer()
                
                // Save button area - Fixed width to match back button
                HStack {
                    if viewModel.hasUnsavedChanges {
                        Button(action: {
                            viewModel.saveProfileChanges()
                        }) {
                            HStack(spacing: 4) {
                                if viewModel.isSaving {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                        .scaleEffect(0.8)
                                } else {
                                    Image(systemName: "checkmark")
                                        .font(.system(size: 12, weight: .semibold))
                                    
                                    Text("common.save".localized(using: localizationManager))
                                        .font(.system(size: 14, weight: .semibold))
                                }
                            }
                            .foregroundColor(.white)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(
                                RoundedRectangle(cornerRadius: 20)
                                    .fill(Color.primaryOrange)
                            )
                        }
                        .disabled(viewModel.isSaving)
                        .transition(.scale.combined(with: .opacity))
                        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: viewModel.hasUnsavedChanges)
                    }
                }
                .frame(width: 80, alignment: .trailing) // Fixed width for save button area
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .background(Color.cardBackground.opacity(0.95))
    }
    
    // MARK: - Loading View
    private var loadingView: some View {
        VStack(spacing: 20) {
            Spacer()
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle(tint: .primaryOrange))
                .scaleEffect(1.5)
            Text("profile.loading".localized(using: localizationManager))
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.textSecondary)
            Spacer()
        }
    }
    
    // MARK: - Error State View
    private var errorStateView: some View {
        VStack(spacing: 20) {
            Spacer()
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 50, weight: .light))
                .foregroundColor(.red.opacity(0.6))
            Text("profile.error.load_failed".localized(using: localizationManager))
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.textPrimary)
            Button("common.try_again".localized(using: localizationManager)) {
                viewModel.loadProfileDetails()
            }
            .font(.system(size: 16, weight: .medium))
            .foregroundColor(.primaryOrange)
            .padding(.horizontal, 20)
            .padding(.vertical, 10)
            .background(
                Capsule()
                    .stroke(Color.primaryOrange, lineWidth: 1)
            )
            Spacer()
        }
    }
    
    // MARK: - Profile Content View - DIRECT EDITING
    private var profileContentView: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Personal Information Card
                personalInformationCard
                
                // Experience Level Card
                experienceLevelCard
                
                // Bio Card
                bioCard
                
                Spacer(minLength: 100)
            }
            .padding(.horizontal, 20)
            .padding(.top, 20)
        }
        .refreshable {
            viewModel.loadProfileDetails()
        }
    }
    
    // MARK: - Personal Information Card
    private var personalInformationCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            sectionHeader(
                title: "profile.section.personal_info".localized(using: localizationManager),
                icon: "person.text.rectangle"
            )
            
            VStack(spacing: 16) {
                // Username with validation
                VStack(alignment: .leading, spacing: 8) {
                    CustomTextFieldNoTitle(
                        text: $viewModel.editUsername,
                        icon: "at",
                        placeholder: "profile.field.username".localized(using: localizationManager),
                        hasError: viewModel.usernameError
                    )
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    
                    // Username availability indicator
                    if !viewModel.editUsername.isEmpty && viewModel.editUsername.count >= 3 && viewModel.editUsername != viewModel.profileDetails?.username {
                        HStack(spacing: 6) {
                            if viewModel.usernameAvailability == .checking {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .orange))
                                    .scaleEffect(0.6)
                            } else {
                                Image(systemName: viewModel.usernameAvailability.icon)
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundColor(viewModel.usernameAvailability.color)
                            }
                            
                            Text(viewModel.usernameAvailability.usernameMessage(using: localizationManager))
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(viewModel.usernameAvailability.color)
                        }
                        .padding(.leading, 16)
                    }
                }
                
                // First Name Field
                CustomTextFieldNoTitle(
                    text: $viewModel.editFirstName,
                    icon: "person",
                    placeholder: "profile.field.first_name".localized(using: localizationManager)
                )
                
                // Last Name Field
                CustomTextFieldNoTitle(
                    text: $viewModel.editLastName,
                    icon: "person.2",
                    placeholder: "profile.field.last_name".localized(using: localizationManager)
                )
                
                // Gender Picker
                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 10) {
                        Image(systemName: "person.2.circle")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.textSecondary)
                            .frame(width: 20)
                        
                        Text("profile.field.gender".localized(using: localizationManager))
                            .font(.system(size: 16))
                            .foregroundColor(.textSecondary)
                    }
                    .padding(.leading, 16)
                    
                    Picker("profile.field.gender".localized(using: localizationManager), selection: $viewModel.editGender) {
                        ForEach(GenderType.allCases, id: \.self) { gender in
                            Text(gender.displayName.localized(using: localizationManager)).tag(gender)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    .padding(.horizontal, 16)
                }
            }
        }
        .padding(20)
        .background(Color.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(Color.dynamicBorder.opacity(0.1), lineWidth: 1)
        )
        .shadow(color: .dynamicShadow, radius: 8, x: 0, y: 2)
    }
    
    // MARK: - Experience Level Card - FIXED: Broken into smaller expressions
    private var experienceLevelCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            sectionHeader(
                title: "profile.section.experience".localized(using: localizationManager),
                icon: "chart.bar"
            )
            
            VStack(alignment: .leading, spacing: 16) {
                Text("profile.field.overall_experience".localized(using: localizationManager))
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.textPrimary)
                
                experienceGrid
            }
        }
        .padding(20)
        .background(Color.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(Color.dynamicBorder.opacity(0.1), lineWidth: 1)
        )
        .shadow(color: .dynamicShadow, radius: 8, x: 0, y: 2)
    }
    
    // MARK: - Experience Grid (Broken out to fix compiler issue)
    private var experienceGrid: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: 2), spacing: 12) {
            ForEach(RegistrationExperienceLevel.allCases, id: \.self) { level in
                experienceButton(for: level)
            }
        }
    }
    
    // MARK: - Individual Experience Button (Broken out to fix compiler issue)
    private func experienceButton(for level: RegistrationExperienceLevel) -> some View {
        Button(action: {
            withAnimation(.easeInOut(duration: 0.2)) {
                viewModel.editOverallExperience = level
            }
        }) {
            experienceButtonContent(for: level)
        }
        .buttonStyle(PlainButtonStyle())
        .animation(.easeInOut(duration: 0.2), value: viewModel.editOverallExperience)
    }
    
    // MARK: - Experience Button Content (Broken out to fix compiler issue)
    private func experienceButtonContent(for level: RegistrationExperienceLevel) -> some View {
        let isSelected = viewModel.editOverallExperience == level
        
        return VStack(spacing: 12) {
            // Experience icon
            experienceIconView(for: level, isSelected: isSelected)
            
            // Experience details
            experienceDetailsView(for: level, isSelected: isSelected)
            
            // Selection indicator
            if isSelected {
                selectionIndicator
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 20)
        .frame(maxWidth: .infinity, minHeight: 150, maxHeight: 150)
        .background(experienceBackground(isSelected: isSelected))
        .overlay(experienceBorder(isSelected: isSelected))
    }
    
    // MARK: - Experience Icon View
    private func experienceIconView(for level: RegistrationExperienceLevel, isSelected: Bool) -> some View {
        ZStack {
            Circle()
                .fill(isSelected ? Color.white.opacity(0.2) : Color.primaryOrange.opacity(0.1))
                .frame(width: 50, height: 50)
            
            Image(systemName: experienceIcon(for: level))
                .font(.system(size: 22, weight: .medium))
                .foregroundColor(isSelected ? .white : .primaryOrange)
        }
    }
    
    // MARK: - Experience Details View
    private func experienceDetailsView(for level: RegistrationExperienceLevel, isSelected: Bool) -> some View {
        VStack(spacing: 4) {
            Text(level.displayName.localized(using: localizationManager))
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(isSelected ? .white : .textPrimary)
                .lineLimit(1)
                .minimumScaleFactor(0.9)
            
            Text(level.description.localized(using: localizationManager))
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(isSelected ? .white.opacity(0.8) : .textSecondary)
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .minimumScaleFactor(0.9)
        }
    }
    
    // MARK: - Selection Indicator
    private var selectionIndicator: some View {
        Image(systemName: "checkmark.circle.fill")
            .font(.system(size: 16, weight: .medium))
            .foregroundColor(.white)
            .opacity(0.9)
    }
    
    // MARK: - Experience Background
    private func experienceBackground(isSelected: Bool) -> some View {
        RoundedRectangle(cornerRadius: 16)
            .fill(isSelected ?
                  LinearGradient(colors: [.primaryOrange, .primaryOrange.opacity(0.8)], startPoint: .topLeading, endPoint: .bottomTrailing) :
                  LinearGradient(colors: [.formBackground, .formBackground], startPoint: .topLeading, endPoint: .bottomTrailing))
    }
    
    // MARK: - Experience Border
    private func experienceBorder(isSelected: Bool) -> some View {
        RoundedRectangle(cornerRadius: 16)
            .stroke(isSelected ? Color.primaryOrange : Color.formBorder, lineWidth: 1)
    }
    
    // MARK: - Bio Card - ENHANCED: Fixed styling with white background and proper borders
    private var bioCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            sectionHeader(
                title: "profile.section.bio".localized(using: localizationManager),
                icon: "text.quote"
            )
            
            VStack(alignment: .leading, spacing: 8) {

                
                // ENHANCED: TextEditor with proper white background and consistent border
                ZStack(alignment: .topLeading) {
                    // Background with consistent styling
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.formBackground)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.formBorder, lineWidth: 1)
                        )
                        .frame(minHeight: 120)
                    
                    // TextEditor
                    TextEditor(text: $viewModel.editBio)
                        .font(.system(size: 16))
                        .foregroundColor(.textPrimary)
                        .padding(14)
                        .background(Color.clear)
                        .scrollContentBackground(.hidden) // Hide default TextEditor background
                        .frame(minHeight: 120)
                    
                    // Placeholder text
                    if viewModel.editBio.isEmpty {
                        Text("profile.field.bio_placeholder".localized(using: localizationManager))
                            .font(.system(size: 16))
                            .foregroundColor(.textSecondary.opacity(0.6))
                            .padding(.horizontal, 18)
                            .padding(.vertical, 22)
                            .allowsHitTesting(false)
                    }
                }
            }
        }
        .padding(20)
        .background(Color.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(Color.dynamicBorder.opacity(0.1), lineWidth: 1)
        )
        .shadow(color: .dynamicShadow, radius: 8, x: 0, y: 2)
    }
    
    // MARK: - Helper function for experience icons
    private func experienceIcon(for level: RegistrationExperienceLevel) -> String {
        switch level {
        case .beginner:
            return "star"
        case .intermediate:
            return "star.leadinghalf.filled"
        case .advanced:
            return "star.fill"
        case .expert:
            return "crown.fill"
        }
    }
    
    // MARK: - Helper Views and Methods
    private func sectionHeader(title: String, icon: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 18, weight: .medium))
                .foregroundColor(.primaryOrange)
            
            Text(title)
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(.textPrimary)
            
            Spacer()
        }
    }
}

// MARK: - Localization Keys Extension - NEW: For better organization
extension String {
    // Common Keys
    static let commonOk = "common.ok"
    static let commonSave = "common.save"
    static let commonBack = "common.back"
    static let commonTryAgain = "common.try_again"
    
    // Profile Details Keys
    static let profileDetailsTitle = "profile.details.title"
    static let profileLoading = "profile.loading"
    static let profileErrorTitle = "profile.error.title"
    static let profileErrorLoadFailed = "profile.error.load_failed"
    
    // Profile Sections
    static let profileSectionPersonalInfo = "profile.section.personal_info"
    static let profileSectionExperience = "profile.section.experience"
    static let profileSectionBio = "profile.section.bio"
    
    // Profile Fields
    static let profileFieldUsername = "profile.field.username"
    static let profileFieldFirstName = "profile.field.first_name"
    static let profileFieldLastName = "profile.field.last_name"
    static let profileFieldGender = "profile.field.gender"
    static let profileFieldOverallExperience = "profile.field.overall_experience"
    static let profileFieldBioDescription = "profile.field.bio_description"
    static let profileFieldBioPlaceholder = "profile.field.bio_placeholder"
}

// MARK: - Preview
#Preview {
    ProfileDetailsView()
        .environmentObject(LocalizationManager())
}
