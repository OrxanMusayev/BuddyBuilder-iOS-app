// BuddyBuilder/Features/Profile/Models/ProfileDetailsModels.swift

import Foundation

// MARK: - Profile Details Response Model
struct ProfileDetailsResponse: Codable {
    let success: Bool
    let message: String?
    let data: ProfileDetails?
    let errors: [String]?
    let timestamp: String
}

// MARK: - Profile Details Model
struct ProfileDetails: Codable {
    let userId: String
    let username: String
    let firstName: String?
    let lastName: String?
    let email: String
    let gender: Int?
    let phoneNumber: String?
    let countryId: Int?
    let cityId: Int?
    let district: String?
    let bio: String?
    let profileImageUrl: String?
    let overallExperienceLevel: Int?
    let isProfileComplete: Bool
    let preferredSports: [PreferredSportDetails]?
    let aboutMe: String?
    let createdAt: String
    let updatedAt: String?
    let dateOfBirth: String?
    
    var genderEnum: GenderType? {
        guard let gender = gender else { return nil }
        return GenderType(rawValue: gender)
    }
    
    var overallExperienceLevelEnum: RegistrationExperienceLevel? {
        guard let level = overallExperienceLevel else { return nil }
        return RegistrationExperienceLevel(rawValue: level)
    }
    
    var fullName: String {
        let first = firstName?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let last = lastName?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        
        if first.isEmpty && last.isEmpty {
            return username
        } else if first.isEmpty {
            return last
        } else if last.isEmpty {
            return first
        } else {
            return "\(first) \(last)"
        }
    }
}

// MARK: - Preferred Sport Details Model
struct PreferredSportDetails: Codable, Identifiable {
    let sportId: Int
    let sportName: String
    let sportIconUrl: String?
    let experienceLevel: Int
    let isPreferred: Bool
    let notes: String?
    
    var id: Int { sportId }
    
    var experienceLevelEnum: RegistrationExperienceLevel? {
        return RegistrationExperienceLevel(rawValue: experienceLevel)
    }
    
    var experienceLevelName: String {
        return experienceLevelEnum?.displayName ?? "Unknown"
    }
}

// MARK: - Profile Update Request Model
struct ProfileUpdateRequest: Codable {
    let username: String?
    let firstName: String?
    let lastName: String?
    let gender: Int?
    let phoneNumber: String?
    let countryId: Int?
    let cityId: Int?
    let district: String?
    let bio: String?
    let profileImageUrl: String?
    let height: Double?
    let weight: Double?
    let overallExperienceLevel: Int?
    let preferredSports: [PreferredSportUpdateRequest]?
    
    init(username: String? = nil,
         firstName: String? = nil,
         lastName: String? = nil,
         dateOfBirth: Date? = nil,
         gender: GenderType? = nil,
         phoneNumber: String? = nil,
         bio: String? = nil,
         profileImageUrl: String? = nil,
         overallExperienceLevel: RegistrationExperienceLevel? = nil) {
        
        self.username = username
        self.firstName = firstName
        self.lastName = lastName
        
        
        self.gender = gender?.rawValue
        self.phoneNumber = phoneNumber
        self.countryId = nil // Ignore for now
        self.cityId = nil // Ignore for now
        self.district = nil // Ignore for now
        self.bio = bio
        self.profileImageUrl = profileImageUrl
        self.height = nil // Not used yet
        self.weight = nil // Not used yet
        self.overallExperienceLevel = overallExperienceLevel?.rawValue
        self.preferredSports = nil // Ignore sports update for now
    }
}

// MARK: - Preferred Sport Update Request Model
struct PreferredSportUpdateRequest: Codable {
    let sportId: Int
    let sportName: String?
    let sportIconUrl: String?
    let experienceLevel: Int
    let isPreferred: Bool
    let notes: String?
}

// MARK: - Profile Update Response Model
struct ProfileUpdateResponse: Codable {
    let success: Bool
    let message: String?
    let data: ProfileDetails?
    let errors: [String]?
    let timestamp: String
}

// MARK: - Profile Service Error
enum ProfileDetailsError: Error, LocalizedError {
    case networkError(String)
    case decodingError(String)
    case unauthorized
    case profileUpdateFailed(String)
    case invalidData
    
    var errorDescription: String? {
        switch self {
        case .networkError(let message):
            return "Network error: \(message)"
        case .decodingError(let message):
            return "Data parsing error: \(message)"
        case .unauthorized:
            return "Authentication required"
        case .profileUpdateFailed(let message):
            return "Profile update failed: \(message)"
        case .invalidData:
            return "Invalid profile data"
        }
    }
}
