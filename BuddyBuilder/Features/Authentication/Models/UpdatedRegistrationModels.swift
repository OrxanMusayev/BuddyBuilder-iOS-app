// BuddyBuilder/Features/Authentication/Models/UpdatedRegistrationModels.swift

import Foundation
import CoreLocation

// MARK: - Updated Registration Request Model
struct UpdatedRegistrationRequest: Codable {
    let userName: String
    let email: String
    let password: String
    let confirmPassword: String
    let country: String
    let city: String
    let languageCode: String
    let latitude: Double
    let longitude: Double
    let preferredSports: [PreferredSport]
    let bio: String?
    let aboutMe: String?
}

// MARK: - Location Models
struct LocationItem: Codable, Identifiable, Hashable {
    let locationId: String
    let countryCode: String
    let cityCode: String
    let countryName: String
    let cityName: String
    let displayText: String
    
    var id: String { locationId }
}

struct LocationResponse: Codable {
    let success: Bool
    let message: String?
    let data: [LocationItem]?
    let errors: [String]?
    let timestamp: String
}

// MARK: - Updated Registration Step Enum
enum UpdatedRegistrationStep: Int, CaseIterable {
    case basicInfo = 0
    case location = 1
    case sportsPreferences = 2
    
    var title: String {
        switch self {
        case .basicInfo:
            return "registration.step.basic_info"
        case .location:
            return "registration.step.location"
        case .sportsPreferences:
            return "registration.step.sports_preferences"
        }
    }
    
    var subtitle: String {
        switch self {
        case .basicInfo:
            return "registration.step.basic_info.subtitle"
        case .location:
            return "registration.step.location.subtitle"
        case .sportsPreferences:
            return "registration.step.sports_preferences.subtitle"
        }
    }
    
    var icon: String {
        switch self {
        case .basicInfo:
            return "person.circle"
        case .location:
            return "location.circle"
        case .sportsPreferences:
            return "sportscourt"
        }
    }
    
    var progress: Double {
        return Double(self.rawValue + 1) / Double(UpdatedRegistrationStep.allCases.count)
    }
}

// MARK: - Language Change Notification
extension Notification.Name {
    static let languageDidChange = Notification.Name("languageDidChange")
}

// MARK: - Updated Registration Form Data
class UpdatedRegistrationFormData: ObservableObject {
    // Basic Info
    @Published var userName: String = ""
    @Published var email: String = ""
    @Published var password: String = ""
    @Published var confirmPassword: String = ""
    
    // Location
    @Published var selectedLocation: LocationItem?
    @Published var manualCountry: String = ""
    @Published var manualCity: String = ""
    @Published var useCurrentLocation: Bool = false
    @Published var currentLocation: CLLocation?
    @Published var latitude: Double = 0.0
    @Published var longitude: Double = 0.0
    
    // Sports Preferences
    @Published var selectedSports: [SportSelection] = []
    
    // Optional fields
    @Published var bio: String = ""
    @Published var aboutMe: String = ""
    
    // MARK: - Step Validation
    func isStepValid(_ step: UpdatedRegistrationStep) -> Bool {
        switch step {
        case .basicInfo:
            return isBasicInfoValid()
        case .location:
            return isLocationValid()
        case .sportsPreferences:
            return !selectedSports.isEmpty
        }
    }
    
    private func isBasicInfoValid() -> Bool {
        guard !userName.isEmpty,
              !email.isEmpty,
              !password.isEmpty,
              !confirmPassword.isEmpty else {
            return false
        }
        
        guard isValidUsername(userName) else { return false }
        guard isValidEmail(email) else { return false }
        guard isValidPassword(password) else { return false }
        guard password == confirmPassword else { return false }
        
        return true
    }
    
    func isLocationValid() -> Bool {
        if useCurrentLocation && currentLocation != nil {
            return true
        }
        
        if let selectedLocation = selectedLocation {
            return !selectedLocation.cityName.isEmpty && !selectedLocation.countryName.isEmpty
        }
        
        return !manualCity.isEmpty && !manualCountry.isEmpty && manualCity.count >= 2 && manualCountry.count >= 2
    }
    
    // MARK: - Enhanced Password Validation
    private func isValidPassword(_ password: String) -> Bool {
        guard password.count >= 8 else { return false }
        
        let hasLowercase = password.range(of: "[a-z]", options: .regularExpression) != nil
        let hasUppercase = password.range(of: "[A-Z]", options: .regularExpression) != nil
        let hasNumber = password.range(of: "[0-9]", options: .regularExpression) != nil
        let hasSpecialChar = password.range(of: "[!@#$%^&*(),.?\":{}|<>]", options: .regularExpression) != nil
        
        return hasLowercase && hasUppercase && hasNumber && hasSpecialChar
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
    
    // MARK: - Password Requirement Checks
    func passwordHasMinLength() -> Bool {
        return password.count >= 8
    }
    
    func passwordHasLowercase() -> Bool {
        return password.range(of: "[a-z]", options: .regularExpression) != nil
    }
    
    func passwordHasUppercase() -> Bool {
        return password.range(of: "[A-Z]", options: .regularExpression) != nil
    }
    
    func passwordHasNumber() -> Bool {
        return password.range(of: "[0-9]", options: .regularExpression) != nil
    }
    
    func passwordHasSpecialChar() -> Bool {
        return password.range(of: "[!@#$%^&*(),.?\":{}|<>]", options: .regularExpression) != nil
    }
    
    func passwordsMatch() -> Bool {
        return !confirmPassword.isEmpty && password == confirmPassword
    }
    
    // MARK: - Convert to API Request
    func toRegistrationRequest() -> UpdatedRegistrationRequest {
        let preferredSports = selectedSports.map { sport in
            PreferredSport(
                sportId: sport.sport.id,
                experienceLevel: sport.experienceLevel.rawValue,
                isPreferred: sport.isPreferred,
                notes: sport.notes
            )
        }
        
        // Determine final location values
        let finalCountry: String
        let finalCity: String
        let finalLatitude: Double
        let finalLongitude: Double
        
        if let selectedLocation = selectedLocation {
            finalCountry = selectedLocation.countryName
            finalCity = selectedLocation.cityName
            finalLatitude = latitude
            finalLongitude = longitude
        } else {
            finalCountry = manualCountry
            finalCity = manualCity
            finalLatitude = latitude
            finalLongitude = longitude
        }
        
        return UpdatedRegistrationRequest(
            userName: userName,
            email: email,
            password: password,
            confirmPassword: confirmPassword,
            country: finalCountry,
            city: finalCity,
            languageCode: getCurrentLanguageCode(),
            latitude: finalLatitude,
            longitude: finalLongitude,
            preferredSports: preferredSports,
            bio: bio.isEmpty ? nil : bio,
            aboutMe: aboutMe.isEmpty ? nil : aboutMe
        )
    }
    
    private func getCurrentLanguageCode() -> String {
        // Get from LocalizationManager or use default
        return UserDefaults.standard.string(forKey: "selectedLanguage") ?? "en"
    }
}
