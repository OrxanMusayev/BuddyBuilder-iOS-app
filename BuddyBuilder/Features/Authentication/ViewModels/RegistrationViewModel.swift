// BuddyBuilder/Features/Authentication/ViewModels/RegistrationViewModel.swift

import Foundation
import Combine
import SwiftUI

class RegistrationViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published var currentStep: RegistrationStep = .basicInfo
    @Published var formData = RegistrationFormData()
    @Published var isLoading = false
    @Published var errorMessage: String = ""
    @Published var showError = false
    @Published var showPassword = false
    @Published var showConfirmPassword = false
    
    // Step validation states - SIMPLIFIED
    @Published var usernameError = false
    @Published var emailError = false
    @Published var passwordError = false
    @Published var confirmPasswordError = false
    @Published var sportsError = false
    
    // Username/Email availability
    @Published var usernameAvailability: ValidationState = .idle
    @Published var emailAvailability: ValidationState = .idle
    
    // Data for dropdowns
    @Published var availableSports: [Sport] = []
    
    // Registration success
    @Published var registrationCompleted = false
    
    // MARK: - Private Properties
    private let registrationService: RegistrationServiceProtocol
    private var cancellables = Set<AnyCancellable>()
    private let debounceInterval: TimeInterval = 0.8
    
    // MARK: - Computed Properties
    var currentStepProgress: Double {
        return currentStep.progress
    }
    
    var canProceedToNextStep: Bool {
        return formData.isStepValid(currentStep) && additionalValidationChecks()
    }
    
    var isLastStep: Bool {
        return currentStep == .sportsPreferences
    }
    
    // MARK: - Additional Validation Checks
    private func additionalValidationChecks() -> Bool {
        switch currentStep {
        case .basicInfo:
            // Check password requirements
            let passwordValidation = validatePassword(formData.password)
            let confirmPasswordValidation = validateConfirmPassword(formData.password, formData.confirmPassword)
            
            // Check availability states
            let usernameAvailable = usernameAvailability == .available || usernameAvailability == .idle
            let emailAvailable = emailAvailability == .available || emailAvailability == .idle
            
            // All conditions must be met
            return passwordValidation.isValid &&
                   confirmPasswordValidation.isValid &&
                   usernameAvailable &&
                   emailAvailable &&
                   usernameAvailability != .taken &&
                   emailAvailability != .taken
            
        case .sportsPreferences:
            return !formData.selectedSports.isEmpty
        }
    }
    
    // MARK: - Initialization
    init(registrationService: RegistrationServiceProtocol = RegistrationService()) {
        self.registrationService = registrationService
        setupValidationObservers()
        loadInitialData()
        print("🏗️ RegistrationViewModel initialized with real service")
    }
    
    // MARK: - Setup Methods
    private func setupValidationObservers() {
        // Username availability check
        formData.$userName
            .debounce(for: .seconds(debounceInterval), scheduler: RunLoop.main)
            .removeDuplicates()
            .sink { [weak self] username in
                self?.handleUsernameChange(username)
            }
            .store(in: &cancellables)
        
        // Email availability check
        formData.$email
            .debounce(for: .seconds(debounceInterval), scheduler: RunLoop.main)
            .removeDuplicates()
            .sink { [weak self] email in
                self?.handleEmailChange(email)
            }
            .store(in: &cancellables)
        
        // Clear field errors when user types
        setupFieldErrorClearingObservers()
        
        // ENHANCED: Real-time password validation
        formData.$password
            .combineLatest(formData.$confirmPassword)
            .sink { [weak self] password, confirmPassword in
                self?.validatePasswordFields(password: password, confirmPassword: confirmPassword)
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Real-time Password Validation
    private func validatePasswordFields(password: String, confirmPassword: String) {
        // Validate password requirements
        let passwordValidation = validatePassword(password)
        passwordError = !passwordValidation.isValid && !password.isEmpty
        
        // Validate password confirmation
        let confirmPasswordValidation = validateConfirmPassword(password, confirmPassword)
        confirmPasswordError = !confirmPasswordValidation.isValid && !confirmPassword.isEmpty
        
        // Update error message if needed
        if passwordError {
            errorMessage = passwordValidation.errorMessage
        } else if confirmPasswordError {
            errorMessage = confirmPasswordValidation.errorMessage
        } else if !passwordError && !confirmPasswordError {
            errorMessage = ""
        }
    }
    
    private func handleUsernameChange(_ username: String) {
        if username.isEmpty {
            usernameAvailability = .idle
            return
        }
        
        if username.count < 3 {
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
    
    private func handleEmailChange(_ email: String) {
        if email.isEmpty {
            emailAvailability = .idle
            return
        }
        
        if !email.contains("@") {
            emailAvailability = .idle
            return
        }
        
        if !isValidEmail(email) {
            emailAvailability = .error
            return
        }
        
        checkEmailAvailability(email)
    }
    
    private func isValidUsername(_ username: String) -> Bool {
        // Username should be at least 3 characters, alphanumeric + underscore
        let usernameRegex = "^[a-zA-Z0-9_]{3,20}$"
        let usernameTest = NSPredicate(format:"SELF MATCHES %@", usernameRegex)
        return usernameTest.evaluate(with: username)
    }
    
    private func setupFieldErrorClearingObservers() {
        formData.$userName.sink { [weak self] _ in self?.usernameError = false }.store(in: &cancellables)
        formData.$email.sink { [weak self] _ in self?.emailError = false }.store(in: &cancellables)
        formData.$password.sink { [weak self] _ in self?.passwordError = false }.store(in: &cancellables)
        formData.$confirmPassword.sink { [weak self] _ in self?.confirmPasswordError = false }.store(in: &cancellables)
    }
    
    private func loadInitialData() {
        print("📊 Loading initial data...")
        loadAvailableSports()
    }
    
    // MARK: - Navigation Methods
    func proceedToNextStep() {
        guard canProceedToNextStep else {
            markCurrentStepErrors()
            return
        }
        
        if isLastStep {
            registerUser()
        } else {
            withAnimation(.easeInOut(duration: 0.3)) {
                if let nextStepIndex = RegistrationStep.allCases.firstIndex(of: currentStep),
                   nextStepIndex + 1 < RegistrationStep.allCases.count {
                    currentStep = RegistrationStep.allCases[nextStepIndex + 1]
                }
            }
        }
    }
    
    func goToPreviousStep() {
        guard currentStep != .basicInfo else { return }
        
        withAnimation(.easeInOut(duration: 0.3)) {
            if let currentIndex = RegistrationStep.allCases.firstIndex(of: currentStep),
               currentIndex > 0 {
                currentStep = RegistrationStep.allCases[currentIndex - 1]
            }
        }
    }
    
    func goToStep(_ step: RegistrationStep) {
        withAnimation(.easeInOut(duration: 0.3)) {
            currentStep = step
        }
    }
    
    // MARK: - Validation Methods
    private func markCurrentStepErrors() {
        switch currentStep {
        case .basicInfo:
            usernameError = formData.userName.isEmpty || !isValidUsername(formData.userName)
            emailError = formData.email.isEmpty || !isValidEmail(formData.email)
            
            // Enhanced password validation
            let passwordValidation = validatePassword(formData.password)
            passwordError = !passwordValidation.isValid
            
            let confirmPasswordValidation = validateConfirmPassword(formData.password, formData.confirmPassword)
            confirmPasswordError = !confirmPasswordValidation.isValid
            
            // Check availability states
            if !usernameError && usernameAvailability == .taken {
                usernameError = true
                errorMessage = "Username is already taken"
            }
            
            if !emailError && emailAvailability == .taken {
                emailError = true
                errorMessage = "Email is already taken"
            }
            
            // Password specific error messages
            if passwordError {
                errorMessage = passwordValidation.errorMessage
            } else if confirmPasswordError {
                errorMessage = confirmPasswordValidation.errorMessage
            }
            
        case .sportsPreferences:
            sportsError = formData.selectedSports.isEmpty
        }
        
        if !canProceedToNextStep {
            if errorMessage.isEmpty {
                errorMessage = "Please complete all required fields correctly"
            }
            showError = true
        }
    }
    
    // MARK: - Enhanced Password Validation
    func validatePassword(_ password: String) -> (isValid: Bool, errorMessage: String) {
        if password.isEmpty {
            return (false, "Password is required")
        }
        
        if password.count < 8 {
            return (false, "Password must be at least 8 characters long")
        }
        
        let hasLowercase = password.range(of: "[a-z]", options: .regularExpression) != nil
        let hasUppercase = password.range(of: "[A-Z]", options: .regularExpression) != nil
        let hasNumber = password.range(of: "[0-9]", options: .regularExpression) != nil
        
        if !hasLowercase {
            return (false, "Password must contain at least one lowercase letter")
        }
        
        if !hasUppercase {
            return (false, "Password must contain at least one uppercase letter")
        }
        
        if !hasNumber {
            return (false, "Password must contain at least one number")
        }
        
        return (true, "")
    }
    
    func validateConfirmPassword(_ password: String, _ confirmPassword: String) -> (isValid: Bool, errorMessage: String) {
        if confirmPassword.isEmpty {
            return (false, "Please confirm your password")
        }
        
        if password != confirmPassword {
            return (false, "Passwords do not match")
        }
        
        return (true, "")
    }
    
    private func isValidEmail(_ email: String) -> Bool {
        let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}"
        let emailTest = NSPredicate(format:"SELF MATCHES %@", emailRegex)
        return emailTest.evaluate(with: email)
    }
    
    // MARK: - Availability Checks
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
                }
            )
            .store(in: &cancellables)
    }
    
    private func checkEmailAvailability(_ email: String) {
        print("📧 Checking email availability for: \(email)")
        emailAvailability = .checking
        
        registrationService.checkEmailAvailability(email)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    if case .failure(let error) = completion {
                        print("❌ Email check failed: \(error)")
                        self?.emailAvailability = .error
                    }
                },
                receiveValue: { [weak self] isAvailable in
                    print("✅ Email check result: \(isAvailable ? "available" : "taken")")
                    self?.emailAvailability = isAvailable ? .available : .taken
                }
            )
            .store(in: &cancellables)
    }
    
    // MARK: - Data Loading Methods
    private func loadAvailableSports() {
        print("🏃‍♂️ Loading available sports...")
        
        registrationService.fetchAvailableSports()
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    if case .failure(let error) = completion {
                        print("❌ Sports loading failed: \(error)")
                        self?.handleError(error)
                    }
                },
                receiveValue: { [weak self] sports in
                    print("✅ Loaded \(sports.count) sports")
                    self?.availableSports = sports
                    print("✅ Here are available sports: ", self?.availableSports ?? [])
                }
            )
            .store(in: &cancellables)
    }
    
    // MARK: - Sports Selection Methods
    func toggleSportSelection(_ sport: Sport) {
        if let index = formData.selectedSports.firstIndex(where: { $0.sport.id == sport.id }) {
            formData.selectedSports.remove(at: index)
            print("🏃‍♂️ Removed sport: \(sport.name)")
        } else {
            let sportSelection = SportSelection(sport: sport)
            formData.selectedSports.append(sportSelection)
            print("🏃‍♂️ Added sport: \(sport.name)")
        }
        sportsError = false
    }
    
    func updateSportExperience(_ sport: Sport, experience: RegistrationExperienceLevel) {
        if let index = formData.selectedSports.firstIndex(where: { $0.sport.id == sport.id }) {
            formData.selectedSports[index].experienceLevel = experience
        }
    }
    
    func updateSportPreference(_ sport: Sport, isPreferred: Bool) {
        if let index = formData.selectedSports.firstIndex(where: { $0.sport.id == sport.id }) {
            formData.selectedSports[index].isPreferred = isPreferred
        }
    }
    
    func updateSportNotes(_ sport: Sport, notes: String) {
        if let index = formData.selectedSports.firstIndex(where: { $0.sport.id == sport.id }) {
            formData.selectedSports[index].notes = notes
        }
    }
    
    // MARK: - Registration Method
    private func registerUser() {
        guard canProceedToNextStep else {
            markCurrentStepErrors()
            return
        }
        
        // Final validation check for availability
        if usernameAvailability == .taken {
            usernameError = true
            errorMessage = "Username is already taken"
            showError = true
            return
        }
        
        if emailAvailability == .taken {
            emailError = true
            errorMessage = "Email is already taken"
            showError = true
            return
        }
        
        print("🚀 Starting registration process...")
        isLoading = true
        errorMessage = ""
        
        let request = formData.toRegistrationRequest()
        
        registrationService.register(request)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    self?.isLoading = false
                    switch completion {
                    case .failure(let error):
                        print("❌ Registration failed: \(error)")
                        self?.handleError(error)
                    case .finished:
                        print("✅ Registration request completed")
                        break
                    }
                },
                receiveValue: { [weak self] response in
                    if response.success, let loginData = response.data {
                        print("🎉 Registration successful for user: \(loginData.username)")
                        self?.saveRegistrationData(loginData)
                        withAnimation(.easeInOut(duration: 0.5)) {
                            self?.registrationCompleted = true
                        }
                    } else {
                        let errorMsg = response.message ?? "Registration failed. Please try again."
                        print("❌ Registration response error: \(errorMsg)")
                        self?.errorMessage = errorMsg
                        self?.showError = true
                    }
                }
            )
            .store(in: &cancellables)
    }
    
    private func saveRegistrationData(_ loginData: LoginData) {
        // Save authentication data
        UserDefaults.standard.set(loginData.accessToken, forKey: "auth_token")
        UserDefaults.standard.set(loginData.userId, forKey: "user_id")
        UserDefaults.standard.set(loginData.username, forKey: "username")
        UserDefaults.standard.set(loginData.email, forKey: "user_email")
        UserDefaults.standard.set(loginData.refreshToken, forKey: "refresh_token")
        print("💾 Registration data saved successfully")
    }
    
    // MARK: - Error Handling
    private func handleError(_ error: Error) {
        errorMessage = error.localizedDescription
        showError = true
        print("❌ Registration Error: \(error.localizedDescription)")
    }
    
    // MARK: - Utility Methods
    func resetForm() {
        formData = RegistrationFormData()
        currentStep = .basicInfo
        clearAllErrors()
        usernameAvailability = .idle
        emailAvailability = .idle
        registrationCompleted = false
        print("🔄 Registration form reset")
    }
    
    private func clearAllErrors() {
        usernameError = false
        emailError = false
        passwordError = false
        confirmPasswordError = false
        sportsError = false
        errorMessage = ""
        showError = false
    }
}

// MARK: - Validation State Enum with Localization Support
enum ValidationState {
    case idle
    case checking
    case available
    case taken
    case error
    
    var icon: String {
        switch self {
        case .idle:
            return ""
        case .checking:
            return "hourglass"
        case .available:
            return "checkmark.circle.fill"
        case .taken:
            return "xmark.circle.fill"
        case .error:
            return "exclamationmark.triangle.fill"
        }
    }
    
    var color: Color {
        switch self {
        case .idle:
            return .clear
        case .checking:
            return .orange
        case .available:
            return .green
        case .taken:
            return .red
        case .error:
            return .red
        }
    }
    
    // Username localization keys
    var usernameMessageKey: String {
        switch self {
        case .idle:
            return ""
        case .checking:
            return "registration.validation.username.checking"
        case .available:
            return "registration.validation.username.available"
        case .taken:
            return "registration.validation.username.taken"
        case .error:
            return "registration.validation.username.error"
        }
    }
    
    // Email localization keys
    var emailMessageKey: String {
        switch self {
        case .idle:
            return ""
        case .checking:
            return "registration.validation.email.checking"
        case .available:
            return "registration.validation.email.available"
        case .taken:
            return "registration.validation.email.taken"
        case .error:
            return "registration.validation.email.error"
        }
    }
    
    // Helper methods to get localized messages
    @MainActor
    func usernameMessage(using localizationManager: LocalizationManager) -> String {
        guard !usernameMessageKey.isEmpty else { return "" }
        return usernameMessageKey.localized(using: localizationManager)
    }
    
    @MainActor
    func emailMessage(using localizationManager: LocalizationManager) -> String {
        guard !emailMessageKey.isEmpty else { return "" }
        return emailMessageKey.localized(using: localizationManager)
    }
    
    // Deprecated - for backward compatibility
    var message: String {
        switch self {
        case .idle: return ""
        case .checking: return "Checking..."
        case .available: return "Available"
        case .taken: return "Already taken"
        case .error: return "Check failed"
        }
    }
}
