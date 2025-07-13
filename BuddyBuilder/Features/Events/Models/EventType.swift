import Foundation

// MARK: - Event Type Enum
enum EventType: String, CaseIterable, Codable {
    case tournament = "events.type.tournament"
    case training = "events.type.training"
    case match = "events.type.match"
    case social = "events.type.social"
    case workshop = "events.type.workshop"
    
    var icon: String {
        switch self {
        case .tournament:
            return "trophy.circle"
        case .training:
            return "figure.run.circle"
        case .match:
            return "gamecontroller.circle"
        case .social:
            return "person.2.circle"
        case .workshop:
            return "book.circle"
        }
    }
    
    var displayName: String {
        switch self {
        case .tournament:
            return "Tournament"
        case .training:
            return "Training"
        case .match:
            return "Match"
        case .social:
            return "Social"
        case .workshop:
            return "Workshop"
        }
    }
}
