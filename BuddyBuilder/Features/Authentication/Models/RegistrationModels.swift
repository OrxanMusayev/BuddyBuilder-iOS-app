// BuddyBuilder/Features/Authentication/Models/RegistrationModels.swift

import Foundation

// MARK: - Registration Request Model
struct RegistrationRequest: Codable {
    let userName: String
    let firstName: String
    let lastName: String
    let email: String
    let password: String
    let confirmPassword: String
    let countryId: Int
    let cityId: Int
    let district: String
    let overallExperienceLevel: Int
    let preferredSports: [PreferredSport]
    let bio: String
    let profileImageUrl: String?
    let notes: String?
    let aboutMe: String
    
    enum CodingKeys: String, CodingKey {
        case userName, firstName, lastName, email, password, confirmPassword
        case countryId, cityId, district
        case overallExperienceLevel, preferredSports, bio, profileImageUrl, notes, aboutMe
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(userName, forKey: .userName)
        try container.encode(firstName, forKey: .firstName)
        try container.encode(lastName, forKey: .lastName)
        try container.encode(email, forKey: .email)
        try container.encode(password, forKey: .password)
        try container.encode(confirmPassword, forKey: .confirmPassword)
        try container.encode(cityId, forKey: .cityId)
        try container.encode(district, forKey: .district)
        try container.encode(overallExperienceLevel, forKey: .overallExperienceLevel)
        try container.encode(preferredSports, forKey: .preferredSports)
        try container.encode(bio, forKey: .bio)
        try container.encodeIfPresent(profileImageUrl, forKey: .profileImageUrl)
        try container.encodeIfPresent(notes, forKey: .notes)
        try container.encode(aboutMe, forKey: .aboutMe)
    }
}

// MARK: - Preferred Sport Model
struct PreferredSport: Codable {
    let sportId: Int
    let experienceLevel: Int
    let isPreferred: Bool
    let notes: String?
}

// MARK: - Registration Response Model
typealias RegistrationResponse = APIResponse<LoginData>

// MARK: - Registration Step Enum - UPDATED: Only 2 steps now
enum RegistrationStep: Int, CaseIterable {
    case basicInfo = 0
    case sportsPreferences = 1
    
    var title: String {
        switch self {
        case .basicInfo:
            return "registration.step.basic_info"
        case .sportsPreferences:
            return "registration.step.sports_preferences"
        }
    }
    
    var subtitle: String {
        switch self {
        case .basicInfo:
            return "registration.step.basic_info.subtitle"
        case .sportsPreferences:
            return "registration.step.sports_preferences.subtitle"
        }
    }
    
    var icon: String {
        switch self {
        case .basicInfo:
            return "person.circle"
        case .sportsPreferences:
            return "sportscourt"
        }
    }
    
    var progress: Double {
        return Double(self.rawValue + 1) / Double(RegistrationStep.allCases.count)
    }
}

// MARK: - Gender Enum
enum GenderType: Int, CaseIterable {
    case male = 1
    case female = 2
    case other = 3
    case preferNotToSay = 4
    
    var displayName: String {
        switch self {
        case .male:
            return "registration.gender.male"
        case .female:
            return "registration.gender.female"
        case .other:
            return "registration.gender.other"
        case .preferNotToSay:
            return "registration.gender.prefer_not_to_say"
        }
    }
}

// MARK: - Experience Level Enum
enum RegistrationExperienceLevel: Int, CaseIterable {
    case beginner = 1
    case intermediate = 2
    case advanced = 3
    case expert = 4
    
    var displayName: String {
        switch self {
        case .beginner:
            return "registration.experience.beginner"
        case .intermediate:
            return "registration.experience.intermediate"
        case .advanced:
            return "registration.experience.advanced"
        case .expert:
            return "registration.experience.expert"
        }
    }
    
    var description: String {
        switch self {
        case .beginner:
            return "registration.experience.beginner.description"
        case .intermediate:
            return "registration.experience.intermediate.description"
        case .advanced:
            return "registration.experience.advanced.description"
        case .expert:
            return "registration.experience.expert.description"
        }
    }
}

// MARK: - Country and City Models - Keep for API compatibility but set defaults
struct Country: Codable, Identifiable, Hashable {
    let id: Int
    let name: String
    let code: String
    let cities: [City]?
}

struct City: Codable, Identifiable, Hashable {
    let id: Int
    let name: String
    let countryId: Int
}

// MARK: - Registration Form Data - ENHANCED VALIDATION
class RegistrationFormData: ObservableObject {
    // Basic Info (only essential fields)
    @Published var userName: String = ""
    @Published var email: String = ""
    @Published var password: String = ""
    @Published var confirmPassword: String = ""
    
    // Sports Preferences
    @Published var overallExperienceLevel: RegistrationExperienceLevel = .beginner
    @Published var selectedSports: [SportSelection] = []
    
    // ENHANCED: Step validation with detailed password requirements
    func isStepValid(_ step: RegistrationStep) -> Bool {
        switch step {
        case .basicInfo:
            return isBasicInfoValid()
        case .sportsPreferences:
            return !selectedSports.isEmpty
        }
    }
    
    // MARK: - Enhanced Basic Info Validation
    private func isBasicInfoValid() -> Bool {
        // Check all required fields are filled
        guard !userName.isEmpty,
              !email.isEmpty,
              !password.isEmpty,
              !confirmPassword.isEmpty else {
            return false
        }
        
        // Username validation
        guard isValidUsername(userName) else {
            return false
        }
        
        // Email validation
        guard isValidEmail(email) else {
            return false
        }
        
        // Password validation
        guard isValidPassword(password) else {
            return false
        }
        
        // Password confirmation
        guard password == confirmPassword else {
            return false
        }
        
        return true
    }
    
    // MARK: - Individual Field Validations
    private func isValidUsername(_ username: String) -> Bool {
        // Username: 3-20 characters, alphanumeric + underscore
        let usernameRegex = "^[a-zA-Z0-9_]{3,20}$"
        let usernameTest = NSPredicate(format:"SELF MATCHES %@", usernameRegex)
        return usernameTest.evaluate(with: username)
    }
    
    private func isValidEmail(_ email: String) -> Bool {
        let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}"
        let emailTest = NSPredicate(format:"SELF MATCHES %@", emailRegex)
        return emailTest.evaluate(with: email)
    }
    
    private func isValidPassword(_ password: String) -> Bool {
        // Password requirements:
        // - At least 8 characters
        // - At least one lowercase letter
        // - At least one uppercase letter
        // - At least one number
        
        guard password.count >= 8 else { return false }
        
        let hasLowercase = password.range(of: "[a-z]", options: .regularExpression) != nil
        let hasUppercase = password.range(of: "[A-Z]", options: .regularExpression) != nil
        let hasNumber = password.range(of: "[0-9]", options: .regularExpression) != nil
        
        return hasLowercase && hasUppercase && hasNumber
    }
    
    // MARK: - Password Requirement Checks (for UI indicators)
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
    
    func passwordsMatch() -> Bool {
        return !confirmPassword.isEmpty && password == confirmPassword
    }
    
    // Convert to API request - WITH DEFAULT VALUES for removed fields
    func toRegistrationRequest() -> RegistrationRequest {
        let preferredSports = selectedSports.map { sport in
            PreferredSport(
                sportId: sport.sport.id,
                experienceLevel: sport.experienceLevel.rawValue,
                isPreferred: sport.isPreferred,
                notes: sport.notes
            )
        }
        
        return RegistrationRequest(
            userName: userName,
            firstName: "", // Default empty
            lastName: "", // Default empty
            email: email,
            password: password,
            confirmPassword: confirmPassword,
            countryId: 1, // Default country ID
            cityId: 1, // Default city ID
            district: "", // Default empty
            overallExperienceLevel: overallExperienceLevel.rawValue,
            preferredSports: preferredSports,
            bio: "", // Default empty
            profileImageUrl: nil,
            notes: nil,
            aboutMe: "" // Default empty
        )
    }
}

// MARK: - Sport Selection Model
struct SportSelection: Identifiable, Hashable, Equatable {
    let id = UUID()
    let sport: Sport
    var experienceLevel: RegistrationExperienceLevel = .beginner
    var isPreferred: Bool = false
    var notes: String = ""
    
    // Equatable conformance
    static func == (lhs: SportSelection, rhs: SportSelection) -> Bool {
        return lhs.id == rhs.id
    }
    
    // Hash function for Hashable
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

// MARK: - Validation Errors
enum RegistrationValidationError: Error, LocalizedError {
    case invalidEmail
    case passwordTooShort
    case passwordMissingLowercase
    case passwordMissingUppercase
    case passwordMissingNumber
    case passwordMismatch
    case usernameEmpty
    case usernameInvalid
    case noSportsSelected
    case usernameTaken
    case emailTaken
    
    var errorDescription: String? {
        switch self {
        case .invalidEmail:
            return "registration.error.invalid_email"
        case .passwordTooShort:
            return "registration.error.password_too_short"
        case .passwordMissingLowercase:
            return "registration.error.password_missing_lowercase"
        case .passwordMissingUppercase:
            return "registration.error.password_missing_uppercase"
        case .passwordMissingNumber:
            return "registration.error.password_missing_number"
        case .passwordMismatch:
            return "registration.error.password_mismatch"
        case .usernameEmpty:
            return "registration.error.username_empty"
        case .usernameInvalid:
            return "registration.error.username_invalid"
        case .noSportsSelected:
            return "registration.error.no_sports_selected"
        case .usernameTaken:
            return "registration.error.username_taken"
        case .emailTaken:
            return "registration.error.email_taken"
        }
    }
}
