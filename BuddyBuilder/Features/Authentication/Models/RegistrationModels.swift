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
    let dateOfBirth: Date
    let gender: Int
    let phoneNumber: String
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
        case dateOfBirth, gender, phoneNumber, countryId, cityId, district
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
        try container.encode(ISO8601DateFormatter().string(from: dateOfBirth), forKey: .dateOfBirth)
        try container.encode(gender, forKey: .gender)
        try container.encode(phoneNumber, forKey: .phoneNumber)
        try container.encode(countryId, forKey: .countryId)
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

// MARK: - Registration Step Enum
enum RegistrationStep: Int, CaseIterable {
    case basicInfo = 0
    case location = 1
    case sportsPreferences = 2
    case profile = 3
    case verification = 4
    
    var title: String {
        switch self {
        case .basicInfo:
            return "registration.step.basic_info"
        case .location:
            return "registration.step.location"
        case .sportsPreferences:
            return "registration.step.sports_preferences"
        case .profile:
            return "registration.step.profile"
        case .verification:
            return "registration.step.verification"
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
        case .profile:
            return "registration.step.profile.subtitle"
        case .verification:
            return "registration.step.verification.subtitle"
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
        case .profile:
            return "pencil.circle"
        case .verification:
            return "checkmark.circle"
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

// MARK: - Country and City Models
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

// MARK: - Registration Form Data
class RegistrationFormData: ObservableObject {
    // Basic Info
    @Published var userName: String = ""
    @Published var email: String = ""
    @Published var password: String = ""
    @Published var confirmPassword: String = ""
    @Published var firstName: String = ""
    @Published var lastName: String = ""
    @Published var dateOfBirth: Date = Calendar.current.date(byAdding: .year, value: -18, to: Date()) ?? Date()
    @Published var gender: GenderType = .male
    @Published var phoneNumber: String = ""
    
    // Location
    @Published var selectedCountry: Country?
    @Published var selectedCity: City?
    @Published var district: String = ""
    
    // Sports Preferences
    @Published var overallExperienceLevel: RegistrationExperienceLevel = .beginner
    @Published var selectedSports: [SportSelection] = []
    
    // Profile
    @Published var bio: String = ""
    @Published var aboutMe: String = ""
    @Published var profileImageUrl: String? = nil
    @Published var notes: String = ""
    
    // Validation
    func isStepValid(_ step: RegistrationStep) -> Bool {
        switch step {
        case .basicInfo:
            return !userName.isEmpty && !email.isEmpty && !password.isEmpty &&
                   !confirmPassword.isEmpty && password == confirmPassword &&
                   password.count >= 6 && isValidEmail(email) &&
                   !firstName.isEmpty && !lastName.isEmpty && !phoneNumber.isEmpty
            
        case .location:
            return selectedCountry != nil && selectedCity != nil && !district.isEmpty
            
        case .sportsPreferences:
            return !selectedSports.isEmpty
            
        case .profile:
            return !bio.isEmpty && !aboutMe.isEmpty
            
        case .verification:
            return true // Always valid for verification step
        }
    }
    
    private func isValidEmail(_ email: String) -> Bool {
        let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}"
        let emailTest = NSPredicate(format:"SELF MATCHES %@", emailRegex)
        return emailTest.evaluate(with: email)
    }
    
    // Convert to API request
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
            firstName: firstName,
            lastName: lastName,
            email: email,
            password: password,
            confirmPassword: confirmPassword,
            dateOfBirth: dateOfBirth,
            gender: gender.rawValue,
            phoneNumber: phoneNumber,
            countryId: selectedCountry?.id ?? 0,
            cityId: selectedCity?.id ?? 0,
            district: district,
            overallExperienceLevel: overallExperienceLevel.rawValue,
            preferredSports: preferredSports,
            bio: bio,
            profileImageUrl: profileImageUrl,
            notes: notes.isEmpty ? nil : notes,
            aboutMe: aboutMe
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
    case passwordMismatch
    case usernameEmpty
    case nameEmpty
    case phoneEmpty
    case locationMissing
    case noSportsSelected
    case profileIncomplete
    
    var errorDescription: String? {
        switch self {
        case .invalidEmail:
            return "registration.error.invalid_email"
        case .passwordTooShort:
            return "registration.error.password_too_short"
        case .passwordMismatch:
            return "registration.error.password_mismatch"
        case .usernameEmpty:
            return "registration.error.username_empty"
        case .nameEmpty:
            return "registration.error.name_empty"
        case .phoneEmpty:
            return "registration.error.phone_empty"
        case .locationMissing:
            return "registration.error.location_missing"
        case .noSportsSelected:
            return "registration.error.no_sports_selected"
        case .profileIncomplete:
            return "registration.error.profile_incomplete"
        }
    }
}
