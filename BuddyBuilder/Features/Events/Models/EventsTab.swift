import Foundation

// MARK: - Events Tab Enum
enum EventsTab: String, CaseIterable {
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
