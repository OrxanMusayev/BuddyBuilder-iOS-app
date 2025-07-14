// BuddyBuilder/Features/Events/Models/EventModels.swift

import Foundation

// MARK: - Event Model
struct Event: Codable, Identifiable {
    let id: Int
    let name: String
    let description: String
    let eventType: Int
    let eventTypeName: String
    let sport: Sport
    let owner: EventOwner
    let eventDate: String
    let registrationDeadline: String
    let maxParticipants: Int
    let currentParticipants: Int
    let location: String
    let entryFee: Double
    let status: Int
    let statusName: String
    let imageUrl: String?
    let isPrivate: Bool
    let createdAt: String
    let isOwner: Bool
    let isParticipant: Bool
    let participantStatus: String?
    let canJoin: Bool
    let daysUntilEvent: Int
    let daysUntilRegistrationDeadline: Int
    
    // Computed properties for UI
    var eventDateTime: Date? {
        ISO8601DateFormatter().date(from: eventDate)
    }
    
    var registrationDeadlineDate: Date? {
        ISO8601DateFormatter().date(from: registrationDeadline)
    }
    
    var isUpcoming: Bool {
        guard let eventDateTime = eventDateTime else { return false }
        return eventDateTime > Date()
    }
    
    var hasAvailableSpots: Bool {
        return currentParticipants < maxParticipants
    }
    
    var availableSpots: Int {
        return max(0, maxParticipants - currentParticipants)
    }
    
    var participationPercentage: Double {
        guard maxParticipants > 0 else { return 0 }
        return Double(currentParticipants) / Double(maxParticipants) * 100
    }
}

// MARK: - Sport Model
struct Sport: Codable {
    let id: Int
    let name: String
    let description: String?
    let imageUrl: String?
    let defaultEventImageUrl: String?
}

// MARK: - Event Owner Model
struct EventOwner: Codable {
    let id: Int
    let username: String
    let firstName: String?
    let lastName: String?
    let fullName: String
    let profileImageUrl: String?
    let experienceLevel: Int?
    let experienceLevelName: String?
}

// MARK: - Events Response Model
struct EventsResponse: Codable {
    let events: [Event]
    let totalCount: Int
    let page: Int
    let pageSize: Int
    let totalPages: Int
}

// MARK: - Event Filter Model
struct EventFilter: Codable {
    var eventType: EventType?
    var sportId: Int?
    var startDate: Date?
    var endDate: Date?
    var location: String?
    var maxEntryFee: Double?
    var minExperienceLevel: ExperienceLevel?
    var maxExperienceLevel: ExperienceLevel?
    var genderRestriction: Gender?
    var isUpcoming: Bool?
    var hasAvailableSpots: Bool?
    var isRegistrationOpen: Bool?
    var searchTerm: String?
    var page: Int = 1
    var pageSize: Int = 10
    var sortBy: String = "EventDate"
    var sortDescending: Bool = false
    
    init() {}
    
    // Helper method to convert to query parameters
    func toQueryParameters() -> [String: String] {
        var params: [String: String] = [:]
        
        if let eventType = eventType {
            params["EventType"] = String(eventType.rawValue)
        }
        if let sportId = sportId {
            params["SportId"] = String(sportId)
        }
        if let startDate = startDate {
            params["StartDate"] = ISO8601DateFormatter().string(from: startDate)
        }
        if let endDate = endDate {
            params["EndDate"] = ISO8601DateFormatter().string(from: endDate)
        }
        if let location = location, !location.isEmpty {
            params["Location"] = location
        }
        if let maxEntryFee = maxEntryFee {
            params["MaxEntryFee"] = String(maxEntryFee)
        }
        if let minExperienceLevel = minExperienceLevel {
            params["MinExperienceLevel"] = String(minExperienceLevel.rawValue)
        }
        if let maxExperienceLevel = maxExperienceLevel {
            params["MaxExperienceLevel"] = String(maxExperienceLevel.rawValue)
        }
        if let genderRestriction = genderRestriction {
            params["GenderRestriction"] = String(genderRestriction.rawValue)
        }
        if let isUpcoming = isUpcoming {
            params["IsUpcoming"] = String(isUpcoming)
        }
        if let hasAvailableSpots = hasAvailableSpots {
            params["HasAvailableSpots"] = String(hasAvailableSpots)
        }
        if let isRegistrationOpen = isRegistrationOpen {
            params["IsRegistrationOpen"] = String(isRegistrationOpen)
        }
        if let searchTerm = searchTerm, !searchTerm.isEmpty {
            params["SearchTerm"] = searchTerm
        }
        
        params["Page"] = String(page)
        params["PageSize"] = String(pageSize)
        params["SortBy"] = sortBy
        params["SortDescending"] = String(sortDescending)
        
        return params
    }
}

// MARK: - Enums
enum EventType: Int, CaseIterable, Codable {
    case normal = 1
    case tournament = 2
    case featured = 3
    
    var displayName: String {
        switch self {
        case .normal: return "Normal"
        case .tournament: return "Tournament"
        case .featured: return "Featured"
        }
    }
}

enum ExperienceLevel: Int, CaseIterable, Codable {
    case beginner = 1
    case intermediate = 2
    case advanced = 3
    case expert = 4
    
    var displayName: String {
        switch self {
        case .beginner: return "Beginner"
        case .intermediate: return "Intermediate"
        case .advanced: return "Advanced"
        case .expert: return "Expert"
        }
    }
}

enum Gender: Int, CaseIterable, Codable {
    case male = 1
    case female = 2
    case other = 3
    
    var displayName: String {
        switch self {
        case .male: return "Male"
        case .female: return "Female"
        case .other: return "Other"
        }
    }
}

// MARK: - Tab Selection
enum EventTab: String, CaseIterable {
    case all = "events.tab.all"
    case my = "events.tab.my"
    
    var title: String {
        return self.rawValue
    }
    
    var displayName: String {
        switch self {
        case .all:
            return "All Events"
        case .my:
            return "My Events"
        }
    }
}
