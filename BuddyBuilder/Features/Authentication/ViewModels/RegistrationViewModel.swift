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
    
    // Step validation states
    @Published var usernameError = false
    @Published var emailError = false
    @Published var passwordError = false
    @Published var confirmPasswordError = false
    @Published var firstNameError = false
    @Published var lastNameError = false
    @Published var phoneError = false
    @Published var locationError = false
    @Published var sportsError = false
    @Published var profileError = false
    
    // Username/Email availability
    @Published var usernameAvailability: ValidationState = .idle
    @Published var emailAvailability: ValidationState = .idle
    
    // Data for dropdowns
    @Published var availableCountries: [Country] = []
    @Published var availableCities: [City] = []
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
        return formData.isStepValid(currentStep)
    }
    
    var isLastStep: Bool {
        return currentStep == .verification
    }
    
    // MARK: - Initialization
    init(registrationService: RegistrationServiceProtocol = MockRegistrationService()) {
        self.registrationService = registrationService
        setupValidationObservers()
        loadInitialData()
    }
    
    // MARK: - Setup Methods
    private func setupValidationObservers() {
        // Username availability check
        formData.$userName
            .debounce(for: .seconds(debounceInterval), scheduler: RunLoop.main)
            .removeDuplicates()
            .sink { [weak self] username in
                if !username.isEmpty && username.count >= 3 {
                    self?.checkUsernameAvailability(username)
                } else {
                    self?.usernameAvailability = .idle
                }
            }
            .store(in: &cancellables)
        
        // Email availability check
        formData.$email
            .debounce(for: .seconds(debounceInterval), scheduler: RunLoop.main)
            .removeDuplicates()
            .sink { [weak self] email in
                if !email.isEmpty && self?.isValidEmail(email) == true {
                    self?.checkEmailAvailability(email)
                } else {
                    self?.emailAvailability = .idle
                }
            }
            .store(in: &cancellables)
        
        // Country selection observer
        formData.$selectedCountry
            .sink { [weak self] country in
                if let country = country {
                    self?.loadCities(for: country.id)
                } else {
                    self?.availableCities = []
                    self?.formData.selectedCity = nil
                }
            }
            .store(in: &cancellables)
        
        // Clear field errors when user types
        setupFieldErrorClearingObservers()
    }
    
    private func setupFieldErrorClearingObservers() {
        formData.$userName.sink { [weak self] _ in self?.usernameError = false }.store(in: &cancellables)
        formData.$email.sink { [weak self] _ in self?.emailError = false }.store(in: &cancellables)
        formData.$password.sink { [weak self] _ in self?.passwordError = false }.store(in: &cancellables)
        formData.$confirmPassword.sink { [weak self] _ in self?.confirmPasswordError = false }.store(in: &cancellables)
        formData.$firstName.sink { [weak self] _ in self?.firstNameError = false }.store(in: &cancellables)
        formData.$lastName.sink { [weak self] _ in self?.lastNameError = false }.store(in: &cancellables)
        formData.$phoneNumber.sink { [weak self] _ in self?.phoneError = false }.store(in: &cancellables)
    }
    
    private func loadInitialData() {
        loadCountries()
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
            usernameError = formData.userName.isEmpty
            emailError = formData.email.isEmpty || !isValidEmail(formData.email)
            passwordError = formData.password.isEmpty || formData.password.count < 6
            confirmPasswordError = formData.confirmPassword.isEmpty || formData.password != formData.confirmPassword
            firstNameError = formData.firstName.isEmpty
            lastNameError = formData.lastName.isEmpty
            phoneError = formData.phoneNumber.isEmpty
            
        case .location:
            locationError = formData.selectedCountry == nil || formData.selectedCity == nil || formData.district.isEmpty
            
        case .sportsPreferences:
            sportsError = formData.selectedSports.isEmpty
            
        case .profile:
            profileError = formData.bio.isEmpty || formData.aboutMe.isEmpty
            
        case .verification:
            break
        }
        
        if !canProceedToNextStep {
            errorMessage = "registration.error.complete_required_fields"
            showError = true
        }
    }
    
    private func isValidEmail(_ email: String) -> Bool {
        let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}"
        let emailTest = NSPredicate(format:"SELF MATCHES %@", emailRegex)
        return emailTest.evaluate(with: email)
    }
    
    // MARK: - Availability Checks
    private func checkUsernameAvailability(_ username: String) {
        usernameAvailability = .checking
        
        registrationService.checkUsernameAvailability(username)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    if case .failure = completion {
                        self?.usernameAvailability = .error
                    }
                },
                receiveValue: { [weak self] isAvailable in
                    self?.usernameAvailability = isAvailable ? .available : .taken
                }
            )
            .store(in: &cancellables)
    }
    
    private func checkEmailAvailability(_ email: String) {
        emailAvailability = .checking
        
        registrationService.checkEmailAvailability(email)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    if case .failure = completion {
                        self?.emailAvailability = .error
                    }
                },
                receiveValue: { [weak self] isAvailable in
                    self?.emailAvailability = isAvailable ? .available : .taken
                }
            )
            .store(in: &cancellables)
    }
    
    // MARK: - Data Loading Methods
    private func loadCountries() {
        registrationService.fetchCountries()
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    if case .failure(let error) = completion {
                        self?.handleError(error)
                    }
                },
                receiveValue: { [weak self] countries in
                    self?.availableCountries = countries
                }
            )
            .store(in: &cancellables)
    }
    
    private func loadCities(for countryId: Int) {
        registrationService.fetchCities(countryId: countryId)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    if case .failure(let error) = completion {
                        self?.handleError(error)
                    }
                },
                receiveValue: { [weak self] cities in
                    self?.availableCities = cities
                    // Reset selected city when country changes
                    if self?.formData.selectedCity?.countryId != countryId {
                        self?.formData.selectedCity = nil
                    }
                }
            )
            .store(in: &cancellables)
    }
    
    private func loadAvailableSports() {
        registrationService.fetchAvailableSports()
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    if case .failure(let error) = completion {
                        self?.handleError(error)
                    }
                },
                receiveValue: { [weak self] sports in
                    self?.availableSports = sports
                }
            )
            .store(in: &cancellables)
    }
    
    // MARK: - Sports Selection Methods
    func toggleSportSelection(_ sport: Sport) {
        if let index = formData.selectedSports.firstIndex(where: { $0.sport.id == sport.id }) {
            formData.selectedSports.remove(at: index)
        } else {
            let sportSelection = SportSelection(sport: sport)
            formData.selectedSports.append(sportSelection)
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
                        self?.handleError(error)
                    case .finished:
                        break
                    }
                },
                receiveValue: { [weak self] response in
                    if response.success, let loginData = response.data {
                        print("🎉 Registration successful!")
                        self?.saveRegistrationData(loginData)
                        withAnimation(.easeInOut(duration: 0.5)) {
                            self?.registrationCompleted = true
                        }
                    } else {
                        let errorMsg = response.message ?? "registration.error.unknown"
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
        UserDefaults.standard.set(loginData.isProfileComplete, forKey: "is_profile_complete")
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
    }
    
    private func clearAllErrors() {
        usernameError = false
        emailError = false
        passwordError = false
        confirmPasswordError = false
        firstNameError = false
        lastNameError = false
        phoneError = false
        locationError = false
        sportsError = false
        profileError = false
        errorMessage = ""
        showError = false
    }
}

// MARK: - Validation State Enum
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
    
    var message: String {
        switch self {
        case .idle:
            return ""
        case .checking:
            return "registration.validation.checking"
        case .available:
            return "registration.validation.available"
        case .taken:
            return "registration.validation.taken"
        case .error:
            return "registration.validation.error"
        }
    }
}
