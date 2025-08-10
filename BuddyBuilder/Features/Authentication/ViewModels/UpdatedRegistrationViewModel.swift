// BuddyBuilder/Features/Authentication/ViewModels/UpdatedRegistrationViewModel.swift

import Foundation
import Combine
import SwiftUI
import CoreLocation

class UpdatedRegistrationViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published var currentStep: UpdatedRegistrationStep = .basicInfo
    @Published var formData = UpdatedRegistrationFormData()
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
    @Published var locationError = false
    @Published var sportsError = false
    
    // Username/Email availability
    @Published var usernameAvailability: ValidationState = .idle
    @Published var emailAvailability: ValidationState = .idle
    
    // Location specific states
    @Published var locationSearchTerm: String = ""
    @Published var locationSearchResults: [LocationItem] = []
    @Published var isSearchingLocations = false
    @Published var showLocationPermissionAlert = false
    @Published var locationPermissionDenied = false
    @Published var isGettingCurrentLocation = false
    
    // Data
    @Published var availableSports: [Sport] = []
    @Published var registrationCompleted = false
    
    // MARK: - Private Properties
    private let registrationService: RegistrationServiceProtocol
    private let locationService: LocationServiceProtocol
    private var cancellables = Set<AnyCancellable>()
    private let debounceInterval: TimeInterval = 0.8
    private let locationDebounceInterval: TimeInterval = 0.4
    
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
    
    // MARK: - NEW: Location validation helper
    var hasValidCurrentLocation: Bool {
        return formData.useCurrentLocation &&
               formData.currentLocation != nil &&
               !formData.manualCity.isEmpty &&
               !formData.manualCountry.isEmpty
    }
    
    // MARK: - Initialization
    init(registrationService: RegistrationServiceProtocol = RegistrationService(),
         locationService: LocationServiceProtocol = LocationService()) {
        self.registrationService = registrationService
        self.locationService = locationService
        setupValidationObservers()
        setupLocationPermissionObserver()
        setupAppLifecycleObserver()
        setupLanguageChangeObserver() // NEW: Language change observer
        loadInitialData()
        print("🏗️ UpdatedRegistrationViewModel initialized")
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
        
        // Location search
        $locationSearchTerm
            .debounce(for: .seconds(locationDebounceInterval), scheduler: RunLoop.main)
            .removeDuplicates()
            .sink { [weak self] searchTerm in
                self?.searchLocations(searchTerm)
            }
            .store(in: &cancellables)
        
        // Real-time password validation
        formData.$password
            .combineLatest(formData.$confirmPassword)
            .sink { [weak self] password, confirmPassword in
                self?.validatePasswordFields(password: password, confirmPassword: confirmPassword)
            }
            .store(in: &cancellables)
        
        // Clear field errors when user types
        setupFieldErrorClearingObservers()
    }
    
    // MARK: - NEW: Location Permission Observer
    private func setupLocationPermissionObserver() {
        NotificationCenter.default.addObserver(
            forName: .locationPermissionChanged,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            guard let userInfo = notification.userInfo,
                  let status = userInfo["status"] as? CLAuthorizationStatus else { return }
            
            self?.handleLocationPermissionChange(status)
        }
    }
    
    // MARK: - NEW: App Lifecycle Observer (for when user returns from Settings)
    private func setupAppLifecycleObserver() {
        NotificationCenter.default.addObserver(
            forName: UIApplication.willEnterForegroundNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            print("🔄 App entering foreground - checking location permission")
            self?.checkLocationPermissionOnAppForeground()
        }
    }
    
    // MARK: - NEW: Language Change Observer
    private func setupLanguageChangeObserver() {
        NotificationCenter.default.addObserver(
            forName: .languageDidChange,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            print("🌐 Language changed - clearing location data")
            self?.clearLocationDataOnLanguageChange()
        }
    }
    
    // MARK: - NEW: Handle permission changes
    private func handleLocationPermissionChange(_ status: CLAuthorizationStatus) {
        print("🔄 Handling location permission change: \(status.rawValue)")
        
        switch status {
        case .authorizedWhenInUse, .authorizedAlways:
            print("✅ Location permission granted")
            locationPermissionDenied = false
            
            // Auto-enable current location if user just granted permission
            if !formData.useCurrentLocation && formData.selectedLocation == nil {
                print("🔄 Auto-enabling current location after permission grant")
                getCurrentLocation()
            }
            
        case .denied, .restricted:
            print("❌ Location permission denied")
            locationPermissionDenied = true
            clearCurrentLocationSelection()
            
        case .notDetermined:
            print("⏳ Location permission not determined")
            locationPermissionDenied = false
            
        @unknown default:
            print("❓ Unknown location permission status")
            locationPermissionDenied = true
        }
    }
    
    // MARK: - NEW: Check permission when app comes to foreground
    private func checkLocationPermissionOnAppForeground() {
        let currentStatus = locationService.checkCurrentPermissionStatus()
        handleLocationPermissionChange(currentStatus)
    }
    
    // MARK: - NEW: Clear location data when language changes
    private func clearLocationDataOnLanguageChange() {
        print("🌐 Clearing location data due to language change...")
        
        // Clear all location-related data
        formData.selectedLocation = nil
        formData.useCurrentLocation = false
        formData.currentLocation = nil
        formData.manualCity = ""
        formData.manualCountry = ""
        formData.latitude = 0.0
        formData.longitude = 0.0
        
        // Clear UI states
        locationSearchTerm = ""
        locationSearchResults = []
        locationError = false
        isSearchingLocations = false
        isGettingCurrentLocation = false
        
        // Reset permission states
        locationPermissionDenied = false
        showLocationPermissionAlert = false
        
        print("✅ Location data cleared for language change")
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
    
    // MARK: - Validation Methods
    private func additionalValidationChecks() -> Bool {
        switch currentStep {
        case .basicInfo:
            let passwordValidation = validatePassword(formData.password)
            let confirmPasswordValidation = validateConfirmPassword(formData.password, formData.confirmPassword)
            
            let usernameAvailable = usernameAvailability == .available || usernameAvailability == .idle
            let emailAvailable = emailAvailability == .available || emailAvailability == .idle
            
            return passwordValidation.isValid &&
                   confirmPasswordValidation.isValid &&
                   usernameAvailable &&
                   emailAvailable &&
                   usernameAvailability != .taken &&
                   emailAvailability != .taken
            
        case .location:
            return formData.isLocationValid()
            
        case .sportsPreferences:
            return !formData.selectedSports.isEmpty
        }
    }
    
    private func validatePasswordFields(password: String, confirmPassword: String) {
        let passwordValidation = validatePassword(password)
        passwordError = !passwordValidation.isValid && !password.isEmpty
        
        let confirmPasswordValidation = validateConfirmPassword(password, confirmPassword)
        confirmPasswordError = !confirmPasswordValidation.isValid && !confirmPassword.isEmpty
        
        if passwordError {
            errorMessage = passwordValidation.errorMessage
        } else if confirmPasswordError {
            errorMessage = confirmPasswordValidation.errorMessage
        } else if !passwordError && !confirmPasswordError {
            errorMessage = ""
        }
    }
    
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
        let hasSpecialChar = password.range(of: "[!@#$%^&*(),.?\":{}|<>]", options: .regularExpression) != nil
        
        if !hasLowercase {
            return (false, "Password must contain at least one lowercase letter")
        }
        
        if !hasUppercase {
            return (false, "Password must contain at least one uppercase letter")
        }
        
        if !hasNumber {
            return (false, "Password must contain at least one number")
        }
        
        if !hasSpecialChar {
            return (false, "Password must contain at least one special character")
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
    
    // MARK: - Username/Email Validation
    private func handleUsernameChange(_ username: String) {
        if username.isEmpty {
            usernameAvailability = .idle
            return
        }
        
        if username.count < 3 {
            usernameAvailability = .idle
            return
        }
        
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
        let usernameRegex = "^[a-zA-Z0-9_]{3,20}$"
        let usernameTest = NSPredicate(format:"SELF MATCHES %@", usernameRegex)
        return usernameTest.evaluate(with: username)
    }
    
    private func isValidEmail(_ email: String) -> Bool {
        let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}"
        let emailTest = NSPredicate(format:"SELF MATCHES %@", emailRegex)
        return emailTest.evaluate(with: email)
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
    
    // MARK: - Location Methods
    func requestLocationPermission() {
        Task {
            let granted = await locationService.requestLocationPermission()
            
            await MainActor.run {
                if granted {
                    print("✅ Location permission granted")
                    getCurrentLocation()
                } else {
                    print("❌ Location permission denied")
                    locationPermissionDenied = true
                    formData.useCurrentLocation = false
                }
            }
        }
    }
    
    func getCurrentLocation() {
        isGettingCurrentLocation = true
        
        Task {
            let location = await locationService.getCurrentLocation()
            
            await MainActor.run {
                isGettingCurrentLocation = false
                
                if let location = location {
                    print("✅ Current location: \(location.coordinate.latitude), \(location.coordinate.longitude)")
                    formData.currentLocation = location
                    formData.latitude = location.coordinate.latitude
                    formData.longitude = location.coordinate.longitude
                    formData.useCurrentLocation = true
                    
                    // Reverse geocode to get city/country names
                    reverseGeocode(location: location)
                } else {
                    print("❌ Failed to get current location")
                    formData.useCurrentLocation = false
                }
            }
        }
    }
    
    private func reverseGeocode(location: CLLocation) {
        let geocoder = CLGeocoder()
        geocoder.reverseGeocodeLocation(location) { [weak self] placemarks, error in
            DispatchQueue.main.async {
                if let placemark = placemarks?.first {
                    self?.formData.manualCity = placemark.locality ?? ""
                    self?.formData.manualCountry = placemark.country ?? ""
                    print("🌍 Reverse geocoded: \(placemark.locality ?? ""), \(placemark.country ?? "")")
                    
                    // FIXED: Force UI update after reverse geocoding
                    self?.objectWillChange.send()
                }
            }
        }
    }
    
    private func searchLocations(_ searchTerm: String) {
        guard !searchTerm.isEmpty, searchTerm.count >= 3 else {
            locationSearchResults = []
            return
        }
        
        isSearchingLocations = true
        
        let languageCode = UserDefaults.standard.string(forKey: "selectedLanguage") ?? "en"
        
        locationService.searchLocations(searchTerm: searchTerm, languageCode: languageCode)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    self?.isSearchingLocations = false
                    if case .failure(let error) = completion {
                        print("❌ Location search failed: \(error)")
                    }
                },
                receiveValue: { [weak self] locations in
                    self?.locationSearchResults = locations
                    print("✅ Found \(locations.count) locations for '\(searchTerm)'")
                }
            )
            .store(in: &cancellables)
    }
    
    func selectLocation(_ location: LocationItem) {
        formData.selectedLocation = location
        formData.manualCity = location.cityName
        formData.manualCountry = location.countryName
        locationSearchTerm = location.displayText
        locationSearchResults = []
        locationError = false
        print("📍 Selected location: \(location.displayText)")
    }
    
    // MARK: - NEW: Location clearing methods
    func clearCurrentLocationSelection() {
        formData.useCurrentLocation = false
        formData.currentLocation = nil
        formData.manualCity = ""
        formData.manualCountry = ""
        formData.latitude = 0.0
        formData.longitude = 0.0
        locationError = false
        print("🗑️ Cleared current location selection")
    }
    
    func clearManualLocationSelection() {
        formData.selectedLocation = nil
        locationSearchTerm = ""
        locationSearchResults = []
        locationError = false
        print("🗑️ Cleared manual location selection")
    }
    
    // MARK: - Sports Methods
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
                }
            )
            .store(in: &cancellables)
    }
    
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
                if let nextStepIndex = UpdatedRegistrationStep.allCases.firstIndex(of: currentStep),
                   nextStepIndex + 1 < UpdatedRegistrationStep.allCases.count {
                    currentStep = UpdatedRegistrationStep.allCases[nextStepIndex + 1]
                }
            }
        }
    }
    
    func goToPreviousStep() {
        guard currentStep != .basicInfo else { return }
        
        withAnimation(.easeInOut(duration: 0.3)) {
            if let currentIndex = UpdatedRegistrationStep.allCases.firstIndex(of: currentStep),
               currentIndex > 0 {
                currentStep = UpdatedRegistrationStep.allCases[currentIndex - 1]
            }
        }
    }
    
    private func markCurrentStepErrors() {
        switch currentStep {
        case .basicInfo:
            usernameError = formData.userName.isEmpty || !isValidUsername(formData.userName)
            emailError = formData.email.isEmpty || !isValidEmail(formData.email)
            
            let passwordValidation = validatePassword(formData.password)
            passwordError = !passwordValidation.isValid
            
            let confirmPasswordValidation = validateConfirmPassword(formData.password, formData.confirmPassword)
            confirmPasswordError = !confirmPasswordValidation.isValid
            
            if !usernameError && usernameAvailability == .taken {
                usernameError = true
                errorMessage = "Username is already taken"
            }
            
            if !emailError && emailAvailability == .taken {
                emailError = true
                errorMessage = "Email is already taken"
            }
            
            if passwordError {
                errorMessage = passwordValidation.errorMessage
            } else if confirmPasswordError {
                errorMessage = confirmPasswordValidation.errorMessage
            }
            
        case .location:
            locationError = !formData.isLocationValid()
            if locationError {
                errorMessage = "Please select or enter your location"
            }
            
        case .sportsPreferences:
            sportsError = formData.selectedSports.isEmpty
            if sportsError {
                errorMessage = "Please select at least one sport"
            }
        }
        
        if !canProceedToNextStep {
            if errorMessage.isEmpty {
                errorMessage = "Please complete all required fields correctly"
            }
            showError = true
        }
    }
    
    // MARK: - Registration Method
    private func registerUser() {
        guard canProceedToNextStep else {
            markCurrentStepErrors()
            return
        }
        
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
        
        // Use the updated registration endpoint
        let updatedRegistrationService = UpdatedRegistrationService()
        updatedRegistrationService.register(request)
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
        formData = UpdatedRegistrationFormData()
        currentStep = .basicInfo
        clearAllErrors()
        usernameAvailability = .idle
        emailAvailability = .idle
        registrationCompleted = false
        locationSearchTerm = ""
        locationSearchResults = []
        print("🔄 Registration form reset")
    }
    
    private func clearAllErrors() {
        usernameError = false
        emailError = false
        passwordError = false
        confirmPasswordError = false
        locationError = false
        sportsError = false
        errorMessage = ""
        showError = false
    }
    
    // MARK: - NEW: Cleanup observers
    deinit {
        NotificationCenter.default.removeObserver(self)
        print("🧹 UpdatedRegistrationViewModel deinitialized")
    }
}

// MARK: - TEMPORARY: Extension for LocalizationManager notification
// This should ideally be added to the main LocalizationManager.swift file
extension LocalizationManager {
    func changeLanguageWithNotification(to language: Language) async {
        await changeLanguage(to: language)
        
        // Send notification after language change
        DispatchQueue.main.async {
            NotificationCenter.default.post(name: .languageDidChange, object: nil)
            print("🌐 Language change notification sent")
        }
    }
}

// MARK: - Updated Registration Service
class UpdatedRegistrationService {
    private let networkManager = NetworkManager.shared
    private let baseURL = "http://192.168.100.76:5206/api/Auth"
    
    func register(_ request: UpdatedRegistrationRequest) -> AnyPublisher<RegistrationResponse, Error> {
        guard let requestData = try? JSONEncoder().encode(request) else {
            print("❌ Failed to encode updated registration request")
            return Fail(error: NetworkError.decodingError)
                .eraseToAnyPublisher()
        }
        
        print("🚀 UPDATED REGISTRATION REQUEST:")
        print("URL: \(baseURL)/register")
        print("Body: \(String(data: requestData, encoding: .utf8) ?? "nil")")
        
        return networkManager.request(
            endpoint: "\(baseURL)/register",
            method: .POST,
            body: requestData,
            type: RegistrationResponse.self
        )
    }
}
