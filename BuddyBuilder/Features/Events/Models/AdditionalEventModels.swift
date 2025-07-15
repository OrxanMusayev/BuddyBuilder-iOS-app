// BuddyBuilder/Features/Events/Models/AdditionalEventModels.swift

import Foundation

// MARK: - Create Event Request Model
struct CreateEventRequest: Codable {
    let name: String
    let description: String
    let eventType: EventType
    let sportId: Int
    let eventDate: Date
    let registrationDeadline: Date
    let maxParticipants: Int
    let location: String
    let entryFee: Double
    let isPrivate: Bool
    let minExperienceLevel: ExperienceLevel?
    let maxExperienceLevel: ExperienceLevel?
    let genderRestriction: Gender?
    
    enum CodingKeys: String, CodingKey {
        case name, description, eventType, sportId, eventDate
        case registrationDeadline, maxParticipants, location, entryFee
        case isPrivate, minExperienceLevel, maxExperienceLevel, genderRestriction
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(name, forKey: .name)
        try container.encode(description, forKey: .description)
        try container.encode(eventType.rawValue, forKey: .eventType)
        try container.encode(sportId, forKey: .sportId)
        try container.encode(ISO8601DateFormatter().string(from: eventDate), forKey: .eventDate)
        try container.encode(ISO8601DateFormatter().string(from: registrationDeadline), forKey: .registrationDeadline)
        try container.encode(maxParticipants, forKey: .maxParticipants)
        try container.encode(location, forKey: .location)
        try container.encode(entryFee, forKey: .entryFee)
        try container.encode(isPrivate, forKey: .isPrivate)
        try container.encodeIfPresent(minExperienceLevel?.rawValue, forKey: .minExperienceLevel)
        try container.encodeIfPresent(maxExperienceLevel?.rawValue, forKey: .maxExperienceLevel)
        try container.encodeIfPresent(genderRestriction?.rawValue, forKey: .genderRestriction)
    }
}

// MARK: - Update Event Request Model
struct UpdateEventRequest: Codable {
    let name: String
    let description: String
    let eventDate: Date
    let registrationDeadline: Date
    let maxParticipants: Int
    let location: String
    let entryFee: Double
    let isPrivate: Bool
    let minExperienceLevel: ExperienceLevel?
    let maxExperienceLevel: ExperienceLevel?
    let genderRestriction: Gender?
    
    enum CodingKeys: String, CodingKey {
        case name, description, eventDate, registrationDeadline
        case maxParticipants, location, entryFee, isPrivate
        case minExperienceLevel, maxExperienceLevel, genderRestriction
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(name, forKey: .name)
        try container.encode(description, forKey: .description)
        try container.encode(ISO8601DateFormatter().string(from: eventDate), forKey: .eventDate)
        try container.encode(ISO8601DateFormatter().string(from: registrationDeadline), forKey: .registrationDeadline)
        try container.encode(maxParticipants, forKey: .maxParticipants)
        try container.encode(location, forKey: .location)
        try container.encode(entryFee, forKey: .entryFee)
        try container.encode(isPrivate, forKey: .isPrivate)
        try container.encodeIfPresent(minExperienceLevel?.rawValue, forKey: .minExperienceLevel)
        try container.encodeIfPresent(maxExperienceLevel?.rawValue, forKey: .maxExperienceLevel)
        try container.encodeIfPresent(genderRestriction?.rawValue, forKey: .genderRestriction)
    }
}

// MARK: - Event Participant Model
struct EventParticipant: Codable, Identifiable {
    let id: Int
    let userId: Int
    let username: String
    let fullName: String
    let profileImageUrl: String?
    let joinedAt: String
    let status: String
    let experienceLevel: Int?
    let experienceLevelName: String?
    
    // Computed properties
    var joinedDate: Date? {
        ISO8601DateFormatter().date(from: joinedAt)
    }
    
    var formattedJoinDate: String {
        guard let date = joinedDate else { return "Unknown" }
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

// MARK: - Event Statistics Model
struct EventStatistics: Codable {
    let totalEvents: Int
    let activeEvents: Int
    let completedEvents: Int
    let cancelledEvents: Int
    let totalParticipants: Int
    let averageParticipantsPerEvent: Double
    let mostPopularSport: String?
    let upcomingEventsCount: Int
}

// MARK: - Event Comment Model
struct EventComment: Codable, Identifiable {
    let id: Int
    let eventId: Int
    let userId: Int
    let username: String
    let userFullName: String
    let userProfileImageUrl: String?
    let comment: String
    let createdAt: String
    let updatedAt: String?
    let isOwner: Bool
    
    var createdDate: Date? {
        ISO8601DateFormatter().date(from: createdAt)
    }
    
    var formattedCreatedDate: String {
        guard let date = createdDate else { return "Unknown" }
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}

// MARK: - Event Invitation Model
struct EventInvitation: Codable, Identifiable {
    let id: Int
    let eventId: Int
    let inviterId: Int
    let inviterUsername: String
    let inviteeId: Int
    let inviteeUsername: String
    let status: InvitationStatus
    let createdAt: String
    let respondedAt: String?
    let event: Event?
    
    enum InvitationStatus: String, Codable, CaseIterable {
        case pending = "pending"
        case accepted = "accepted"
        case declined = "declined"
        case cancelled = "cancelled"
        
        var displayName: String {
            switch self {
            case .pending: return "Pending"
            case .accepted: return "Accepted"
            case .declined: return "Declined"
            case .cancelled: return "Cancelled"
            }
        }
        
        var color: Color {
            switch self {
            case .pending: return .orange
            case .accepted: return .green
            case .declined: return .red
            case .cancelled: return .gray
            }
        }
    }
}

// MARK: - Event Search Result Model
struct EventSearchResult: Codable {
    let events: [Event]
    let totalCount: Int
    let searchTerm: String
    let filters: EventFilter
    let suggestions: [String]
}

// MARK: - Event Category Model
struct EventCategory: Codable, Identifiable {
    let id: Int
    let name: String
    let description: String?
    let iconName: String?
    let color: String?
    let isActive: Bool
    let eventCount: Int
}

// MARK: - Event Location Model
struct EventLocation: Codable, Identifiable {
    let id: Int
    let name: String
    let address: String
    let city: String
    let country: String
    let latitude: Double?
    let longitude: Double?
    let capacity: Int?
    let amenities: [String]?
    let isVerified: Bool
    
    var fullAddress: String {
        return "\(address), \(city), \(country)"
    }
    
    var hasCoordinates: Bool {
        return latitude != nil && longitude != nil
    }
}

// MARK: - Event Rating Model
struct EventRating: Codable, Identifiable {
    let id: Int
    let eventId: Int
    let userId: Int
    let username: String
    let rating: Int // 1-5 stars
    let review: String?
    let createdAt: String
    
    var isValidRating: Bool {
        return rating >= 1 && rating <= 5
    }
    
    var createdDate: Date? {
        ISO8601DateFormatter().date(from: createdAt)
    }
}

// MARK: - Event Notification Model
struct EventNotification: Codable, Identifiable {
    let id: Int
    let eventId: Int
    let userId: Int
    let type: NotificationType
    let title: String
    let message: String
    let isRead: Bool
    let createdAt: String
    let event: Event?
    
    enum NotificationType: String, Codable, CaseIterable {
        case eventReminder = "event_reminder"
        case registrationDeadline = "registration_deadline"
        case eventCancelled = "event_cancelled"
        case eventUpdated = "event_updated"
        case newParticipant = "new_participant"
        case participantLeft = "participant_left"
        case invitationReceived = "invitation_received"
        case invitationAccepted = "invitation_accepted"
        
        var iconName: String {
            switch self {
            case .eventReminder: return "bell.fill"
            case .registrationDeadline: return "clock.fill"
            case .eventCancelled: return "xmark.circle.fill"
            case .eventUpdated: return "pencil.circle.fill"
            case .newParticipant: return "person.badge.plus.fill"
            case .participantLeft: return "person.badge.minus.fill"
            case .invitationReceived: return "envelope.fill"
            case .invitationAccepted: return "checkmark.circle.fill"
            }
        }
        
        var color: Color {
            switch self {
            case .eventReminder: return .blue
            case .registrationDeadline: return .orange
            case .eventCancelled: return .red
            case .eventUpdated: return .purple
            case .newParticipant: return .green
            case .participantLeft: return .yellow
            case .invitationReceived: return .blue
            case .invitationAccepted: return .green
            }
        }
    }
}

// MARK: - Extended Event Model for Details
struct EventDetails: Codable {
    let event: Event
    let participants: [EventParticipant]
    let comments: [EventComment]
    let location: EventLocation?
    let ratings: [EventRating]
    let averageRating: Double
    let weatherForecast: WeatherForecast?
    let relatedEvents: [Event]
    
    var participantCount: Int {
        return participants.count
    }
    
    var hasComments: Bool {
        return !comments.isEmpty
    }
    
    var hasRatings: Bool {
        return !ratings.isEmpty
    }
}

// MARK: - Weather Forecast Model
struct WeatherForecast: Codable {
    let temperature: Double
    let description: String
    let iconCode: String
    let humidity: Int
    let windSpeed: Double
    let precipitation: Double
    let lastUpdated: String
    
    var temperatureFormatted: String {
        return String(format: "%.1f°C", temperature)
    }
    
    var windSpeedFormatted: String {
        return String(format: "%.1f km/h", windSpeed)
    }
}

// MARK: - User Event Preferences Model
struct UserEventPreferences: Codable {
    let userId: Int
    let preferredSports: [Int]
    let preferredLocations: [String]
    let maxTravelDistance: Double?
    let preferredEventTypes: [EventType]
    let preferredDays: [Weekday]
    let preferredTimeSlots: [TimeSlot]
    let notificationSettings: NotificationSettings
    
    enum Weekday: String, Codable, CaseIterable {
        case monday, tuesday, wednesday, thursday, friday, saturday, sunday
        
        var displayName: String {
            return self.rawValue.capitalized
        }
    }
    
    enum TimeSlot: String, Codable, CaseIterable {
        case morning = "morning"     // 06:00 - 12:00
        case afternoon = "afternoon" // 12:00 - 18:00
        case evening = "evening"     // 18:00 - 24:00
        
        var displayName: String {
            switch self {
            case .morning: return "Morning (6AM - 12PM)"
            case .afternoon: return "Afternoon (12PM - 6PM)"
            case .evening: return "Evening (6PM - 12AM)"
            }
        }
    }
}

// MARK: - Notification Settings Model
struct NotificationSettings: Codable {
    let pushNotifications: Bool
    let emailNotifications: Bool
    let smsNotifications: Bool
    let eventReminders: Bool
    let registrationDeadlines: Bool
    let eventUpdates: Bool
    let newParticipants: Bool
    let invitations: Bool
    let reminderHours: [Int] // Hours before event to remind (e.g., [24, 2])
}

import SwiftUI
