import Foundation

// MARK: - Date Filter Enum
enum DateFilter: String, CaseIterable {
    case today = "events.date.today"
    case tomorrow = "events.date.tomorrow"
    case thisWeek = "events.date.this_week"
    case thisMonth = "events.date.this_month"
    case upcoming = "events.date.upcoming"
    
    var dateRange: (start: Date, end: Date) {
        let calendar = Calendar.current
        let now = Date()
        
        switch self {
        case .today:
            let start = calendar.startOfDay(for: now)
            let end = calendar.date(byAdding: .day, value: 1, to: start)!
            return (start, end)
            
        case .tomorrow:
            let tomorrow = calendar.date(byAdding: .day, value: 1, to: now)!
            let start = calendar.startOfDay(for: tomorrow)
            let end = calendar.date(byAdding: .day, value: 1, to: start)!
            return (start, end)
            
        case .thisWeek:
            let start = calendar.dateInterval(of: .weekOfYear, for: now)!.start
            let end = calendar.dateInterval(of: .weekOfYear, for: now)!.end
            return (start, end)
            
        case .thisMonth:
            let start = calendar.dateInterval(of: .month, for: now)!.start
            let end = calendar.dateInterval(of: .month, for: now)!.end
            return (start, end)
            
        case .upcoming:
            let start = now
            let end = calendar.date(byAdding: .year, value: 1, to: now)!
            return (start, end)
        }
    }
    
    var displayName: String {
        switch self {
        case .today:
            return "Today"
        case .tomorrow:
            return "Tomorrow"
        case .thisWeek:
            return "This Week"
        case .thisMonth:
            return "This Month"
        case .upcoming:
            return "Upcoming"
        }
    }
}
