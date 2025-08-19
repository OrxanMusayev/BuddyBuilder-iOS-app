// BuddyBuilder/Features/Events/Models/EventModels.swift

import Foundation

// MARK: - Event Model - Updated for API Compatibility
struct Event: Codable, Identifiable, Equatable {
    let id: Int
    let name: String
    let description: String
    let eventType: Int
    let eventTypeName: String
    let sport: Sport
    let owner: EventOwner
    let participants: [ParticipantDto]
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
    let participantStatus: ParticipantStatus?
    let canJoin: Bool
    let daysUntilEvent: Int
    let daysUntilRegistrationDeadline: Int
    
    // Custom CodingKeys for participantStatus
    enum CodingKeys: String, CodingKey {
        case id, name, description, eventType, eventTypeName, sport, owner
        case participants, eventDate, registrationDeadline, maxParticipants
        case currentParticipants, location, entryFee, status, statusName
        case imageUrl, isPrivate, createdAt, isOwner, isParticipant
        case participantStatus, canJoin, daysUntilEvent, daysUntilRegistrationDeadline
    }
    
    // Custom decoder for participantStatus
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        id = try container.decode(Int.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        description = try container.decode(String.self, forKey: .description)
        eventType = try container.decode(Int.self, forKey: .eventType)
        eventTypeName = try container.decode(String.self, forKey: .eventTypeName)
        sport = try container.decode(Sport.self, forKey: .sport)
        owner = try container.decode(EventOwner.self, forKey: .owner)
        participants = try container.decode([ParticipantDto].self, forKey: .participants)
        eventDate = try container.decode(String.self, forKey: .eventDate)
        registrationDeadline = try container.decode(String.self, forKey: .registrationDeadline)
        maxParticipants = try container.decode(Int.self, forKey: .maxParticipants)
        currentParticipants = try container.decode(Int.self, forKey: .currentParticipants)
        location = try container.decode(String.self, forKey: .location)
        entryFee = try container.decode(Double.self, forKey: .entryFee)
        status = try container.decode(Int.self, forKey: .status)
        statusName = try container.decode(String.self, forKey: .statusName)
        imageUrl = try container.decodeIfPresent(String.self, forKey: .imageUrl)
        isPrivate = try container.decode(Bool.self, forKey: .isPrivate)
        createdAt = try container.decode(String.self, forKey: .createdAt)
        isOwner = try container.decode(Bool.self, forKey: .isOwner)
        isParticipant = try container.decode(Bool.self, forKey: .isParticipant)
        canJoin = try container.decode(Bool.self, forKey: .canJoin)
        daysUntilEvent = try container.decode(Int.self, forKey: .daysUntilEvent)
        daysUntilRegistrationDeadline = try container.decode(Int.self, forKey: .daysUntilRegistrationDeadline)
        
        // Handle participantStatus - can be null, number, or string
        if let statusInt = try? container.decodeIfPresent(Int.self, forKey: .participantStatus) {
            participantStatus = ParticipantStatus(rawValue: statusInt)
        } else if let statusString = try? container.decodeIfPresent(String.self, forKey: .participantStatus) {
            // If it comes as string, try to parse to int or handle special cases
            if let statusInt = Int(statusString) {
                participantStatus = ParticipantStatus(rawValue: statusInt)
            } else {
                participantStatus = nil
            }
        } else {
            participantStatus = nil
        }
    }
    
    // Computed properties for UI
    var eventDateTime: Date? {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter.date(from: eventDate) ?? ISO8601DateFormatter().date(from: eventDate)
    }
    
    var registrationDeadlineDate: Date? {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter.date(from: registrationDeadline) ?? ISO8601DateFormatter().date(from: registrationDeadline)
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
    
    // Formatted date for UI display
    var formattedEventDate: String {
        guard let date = eventDateTime else { return "TBD" }
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d, HH:mm"
        return formatter.string(from: date)
    }
    
    var formattedEventDay: String {
        guard let date = eventDateTime else { return "TBD" }
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return formatter.string(from: date)
    }
    
    var formattedEventTime: String {
        guard let date = eventDateTime else { return "TBD" }
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: date)
    }
}

// MARK: - Sport Model - Updated
struct Sport: Codable, Identifiable, Equatable, Hashable {
    let id: Int
    let name: String
    let description: String?
    let imageUrl: String?
    let defaultEventImageUrl: String?
    
    // Equatable conformance
    static func == (lhs: Sport, rhs: Sport) -> Bool {
        return lhs.id == rhs.id
    }
    
    // Hash function for Hashable
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

// MARK: - Participant DTO - Updated
struct ParticipantDto: Codable, Identifiable {
    let id: String
    let username: String
    let firstName: String?
    let lastName: String?
    let profileImageUrl: String?
    
    // Computed property for display name
    var displayName: String {
        let first = firstName ?? ""
        let last = lastName ?? ""
        let fullName = "\(first) \(last)".trimmingCharacters(in: .whitespaces)
        return fullName.isEmpty ? username : fullName
    }
}

// MARK: - Event Owner Model - Updated
struct EventOwner: Codable, Identifiable {
    let id: String
    let username: String
    let firstName: String?
    let lastName: String?
    let fullName: String
    let profileImageUrl: String?
    
    // Computed property for display name
    var displayName: String {
        let trimmedFullName = fullName.trimmingCharacters(in: .whitespaces)
        return trimmedFullName.isEmpty ? username : trimmedFullName
    }
    
    // CodingKeys to handle missing fields
    enum CodingKeys: String, CodingKey {
        case id, username, firstName, lastName, fullName, profileImageUrl
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        username = try container.decode(String.self, forKey: .username)
        firstName = try container.decodeIfPresent(String.self, forKey: .firstName)
        lastName = try container.decodeIfPresent(String.self, forKey: .lastName)
        fullName = try container.decode(String.self, forKey: .fullName)
        profileImageUrl = try container.decodeIfPresent(String.self, forKey: .profileImageUrl)
    }
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

// MARK: - Participant Status Enum
enum ParticipantStatus: Int, Codable, CaseIterable {
    case pending = 1
    case approved = 2
    case rejected = 3
    case cancelled = 4
    
    var displayName: String {
        switch self {
        case .pending: return "Pending"
        case .approved: return "Approved"
        case .rejected: return "Rejected"
        case .cancelled: return "Cancelled"
        }
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

extension Event: Hashable {
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    static func == (lhs: Event, rhs: Event) -> Bool {
        return lhs.id == rhs.id
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

struct JoinEventRequest: Codable {
    let note: String?
}

// MARK: - Event Extensions for Updating
extension Event {
    /// Create a new Event instance with updated participation status
    func withUpdatedParticipation(isParticipant: Bool, currentParticipants: Int? = nil, updatedParticipants: [ParticipantDto]? = nil) -> Event {
        let newCurrentParticipants = currentParticipants ?? self.currentParticipants
        
        // Update participants list based on join/leave action
        let newParticipants: [ParticipantDto]
        if let providedParticipants = updatedParticipants {
            newParticipants = providedParticipants
        } else {
            // Try to update participants list automatically
            newParticipants = updateParticipantsList(joined: isParticipant)
        }
        
        return Event(
            id: self.id,
            name: self.name,
            description: self.description,
            eventType: self.eventType,
            eventTypeName: self.eventTypeName,
            sport: self.sport,
            owner: self.owner,
            participants: newParticipants,
            eventDate: self.eventDate,
            registrationDeadline: self.registrationDeadline,
            maxParticipants: self.maxParticipants,
            currentParticipants: newCurrentParticipants,
            location: self.location,
            entryFee: self.entryFee,
            status: self.status,
            statusName: self.statusName,
            imageUrl: self.imageUrl,
            isPrivate: self.isPrivate,
            createdAt: self.createdAt,
            isOwner: self.isOwner,
            isParticipant: isParticipant,
            participantStatus: self.participantStatus,
            canJoin: !isParticipant && newCurrentParticipants < self.maxParticipants,
            daysUntilEvent: self.daysUntilEvent,
            daysUntilRegistrationDeadline: self.daysUntilRegistrationDeadline
        )
    }
    
    /// Update participants list based on current user's join/leave action
    private func updateParticipantsList(joined: Bool) -> [ParticipantDto] {
        guard let currentUserId = UserDefaults.standard.string(forKey: "user_id"),
              !currentUserId.isEmpty else {
            print("⚠️ No current user ID found, keeping original participants list")
            return self.participants
        }
        
        
        if joined {
            // User joined - add them to participants if not already there
            let alreadyExists = self.participants.contains { participant in
                return participant.id == currentUserId
            }
            
            if !alreadyExists {
                // Create a placeholder participant for current user
                let currentUser = createCurrentUserParticipant(userId: currentUserId)
                var updatedParticipants = self.participants
                updatedParticipants.append(currentUser)
                print("✅ Added current user to participants list")
                return updatedParticipants
            }
        } else {
            // User left - remove them from participants
            let filteredParticipants = self.participants.filter { participant in
                return participant.id != currentUserId
            }
            print("✅ Removed current user from participants list")
            return filteredParticipants
        }
        
        return self.participants
    }
    
    /// Create a placeholder participant for current user
    private func createCurrentUserParticipant(userId: String) -> ParticipantDto {
        let username = UserDefaults.standard.string(forKey: "username") ?? "You"
        
        return ParticipantDto(
            id: userId,
            username: username,
            firstName: username,
            lastName: nil,
            profileImageUrl: nil
        )
    }
    
    // Manual initializer for creating updated events
    init(id: Int, name: String, description: String, eventType: Int, eventTypeName: String, sport: Sport, owner: EventOwner, participants: [ParticipantDto], eventDate: String, registrationDeadline: String, maxParticipants: Int, currentParticipants: Int, location: String, entryFee: Double, status: Int, statusName: String, imageUrl: String?, isPrivate: Bool, createdAt: String, isOwner: Bool, isParticipant: Bool, participantStatus: ParticipantStatus?, canJoin: Bool, daysUntilEvent: Int, daysUntilRegistrationDeadline: Int) {
        self.id = id
        self.name = name
        self.description = description
        self.eventType = eventType
        self.eventTypeName = eventTypeName
        self.sport = sport
        self.owner = owner
        self.participants = participants
        self.eventDate = eventDate
        self.registrationDeadline = registrationDeadline
        self.maxParticipants = maxParticipants
        self.currentParticipants = currentParticipants
        self.location = location
        self.entryFee = entryFee
        self.status = status
        self.statusName = statusName
        self.imageUrl = imageUrl
        self.isPrivate = isPrivate
        self.createdAt = createdAt
        self.isOwner = isOwner
        self.isParticipant = isParticipant
        self.participantStatus = participantStatus
        self.canJoin = canJoin
        self.daysUntilEvent = daysUntilEvent
        self.daysUntilRegistrationDeadline = daysUntilRegistrationDeadline
    }
}
