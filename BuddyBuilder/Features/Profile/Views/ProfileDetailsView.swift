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
    
    // 🔴 NEW: Store dismiss action
    private var dismissAction: (() -> Void)?
    
    init(profileDetailsService: ProfileDetailsServiceProtocol = ProfileDetailsService(),
         registrationService: RegistrationServiceProtocol = RegistrationService()) {
        self.profileDetailsService = profileDetailsService
        self.registrationService = registrationService
        setupUsernameValidation()
        loadProfileDetails()
    }
    
    // 🔴 NEW: Set dismiss action
    func setDismissAction(_ action: @escaping () -> Void) {
        self.dismissAction = action
    }
    
    // 🔴 NEW: Get dismiss action
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
        
        // 🔴 EXTENDED SAVING DURATION - Add minimum loading time of 2.5 seconds
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
                        
                        // 🔴 SMOOTH NAVIGATION: Trigger dismiss with fade transition
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

// MARK: - Profile Details View - SINGLE PAGE WITH DIRECT EDITING
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
                
                // 🔴 REMOVED: Success message overlay
            }
        }
        .navigationBarHidden(true)
        .onAppear {
            // 🔴 NEW: Set dismiss action when view appears
            viewModel.setDismissAction {
                dismiss()
            }
        }
        .alert(localizationManager.translate("error", defaultValue: "Error"), isPresented: $viewModel.showError) {
            Button(localizationManager.translate("ok", defaultValue: "OK")) { }
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
                        Text(localizationManager.translate("back", defaultValue: ""))
                            .font(.system(size: 16, weight: .medium))
                    }
                    .foregroundColor(.primaryOrange)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                }
                .frame(width: 80, alignment: .leading) // 🔴 FIXED WIDTH for back button
                
                Spacer()
                
                // Title - Always centered (no HStack wrapper needed)
                Text(localizationManager.translate("profile_details_title", defaultValue: "Profile Details"))
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
                                    
                                    Text(localizationManager.translate("save", defaultValue: "Save"))
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
                .frame(width: 80, alignment: .trailing) // 🔴 FIXED WIDTH for save button area
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .background(Color.white.opacity(0.95))
    }
    
    // MARK: - Loading View
    private var loadingView: some View {
        VStack(spacing: 20) {
            Spacer()
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle(tint: .primaryOrange))
                .scaleEffect(1.5)
            Text(localizationManager.translate("loading_profile", defaultValue: "Loading profile..."))
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
            Text(localizationManager.translate("failed_to_load_profile", defaultValue: "Failed to load profile"))
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.textPrimary)
            Button(localizationManager.translate("try_again", defaultValue: "Try Again")) {
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
            sectionHeader(title: localizationManager.translate("personal_information", defaultValue: "Personal Information"), icon: "person.badge.plus")
            
            VStack(spacing: 16) {
                // Username with validation
                VStack(alignment: .leading, spacing: 8) {
                    CustomTextFieldNoTitle(
                        text: $viewModel.editUsername,
                        icon: "person.fill",
                        placeholder: localizationManager.translate("username", defaultValue: "Username"),
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
                
                CustomTextFieldNoTitle(
                    text: $viewModel.editFirstName,
                    icon: "person.fill",
                    placeholder: localizationManager.translate("first_name", defaultValue: "First Name")
                )
                
                CustomTextFieldNoTitle(
                    text: $viewModel.editLastName,
                    icon: "person.fill",
                    placeholder: localizationManager.translate("last_name", defaultValue: "Last Name")
                )
                
                // Gender Picker
                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 10) {
                        Image(systemName: "person.2.fill")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.textSecondary)
                            .frame(width: 20)
                        
                        Text(localizationManager.translate("gender", defaultValue: "Gender"))
                            .font(.system(size: 16))
                            .foregroundColor(.textSecondary)
                    }
                    .padding(.leading, 16)
                    
                    Picker(localizationManager.translate("gender", defaultValue: "Gender"), selection: $viewModel.editGender) {
                        ForEach(GenderType.allCases, id: \.self) { gender in
                            Text(gender.displayName).tag(gender)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    .padding(.horizontal, 16)
                }
            }
        }
        .padding(20)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .shadow(color: .black.opacity(0.05), radius: 10, x: 0, y: 4)
    }
    
    // MARK: - Experience Level Card
    private var experienceLevelCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            sectionHeader(title: localizationManager.translate("experience_level", defaultValue: "Experience Level"), icon: "star.circle")
            
            VStack(alignment: .leading, spacing: 12) {
                Text(localizationManager.translate("overall_experience_level", defaultValue: "Overall Experience Level"))
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.textPrimary)
                
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 8) {
                    ForEach(RegistrationExperienceLevel.allCases, id: \.self) { level in
                        Button(action: {
                            viewModel.editOverallExperience = level
                        }) {
                            VStack(spacing: 8) {
                                Text(level.displayName)
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(viewModel.editOverallExperience == level ? .white : .textPrimary)
                                
                                Text(level.description)
                                    .font(.system(size: 11))
                                    .foregroundColor(viewModel.editOverallExperience == level ? .white.opacity(0.8) : .textSecondary)
                                    .multilineTextAlignment(.center)
                                    .lineLimit(2)
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 12)
                            .frame(minHeight: 80)
                            .background(viewModel.editOverallExperience == level ? Color.primaryOrange : Color.formBackground)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(viewModel.editOverallExperience == level ? Color.primaryOrange : Color.formBorder, lineWidth: 1)
                            )
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
            }
        }
        .padding(20)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .shadow(color: .black.opacity(0.05), radius: 10, x: 0, y: 4)
    }
    
    // MARK: - Bio Card
    private var bioCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            sectionHeader(title: localizationManager.translate("bio", defaultValue: "Bio"), icon: "text.quote")
            
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 10) {
                    Image(systemName: "text.quote")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.textSecondary)
                        .frame(width: 20)
                    
                    Text(localizationManager.translate("tell_others_about_yourself", defaultValue: "Tell others about yourself"))
                        .font(.system(size: 16))
                        .foregroundColor(.textSecondary)
                }
                .padding(.leading, 16)
                .padding(.top, 2)
                
                TextEditor(text: $viewModel.editBio)
                    .font(.system(size: 14))
                    .foregroundColor(Color.formBackground)
                    .padding(12)
                    .frame(minHeight: 100)
                    .background(Color.formBackground)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.formBorder, lineWidth: 1)
                    )
            }
        }
        .padding(20)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .shadow(color: .black.opacity(0.05), radius: 10, x: 0, y: 4)
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

// MARK: - Preview
#Preview {
    ProfileDetailsView()
        .environmentObject(LocalizationManager())
}
