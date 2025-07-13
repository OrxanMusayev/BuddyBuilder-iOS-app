import Foundation

// MARK: - Sport Enum
enum Sport: String, CaseIterable, Codable {
    case football = "sports.football"
    case basketball = "sports.basketball"
    case tennis = "sports.tennis"
    case running = "sports.running"
    case swimming = "sports.swimming"
    case cycling = "sports.cycling"
    case volleyball = "sports.volleyball"
    case badminton = "sports.badminton"
    case pingpong = "sports.pingpong"
    case fitness = "sports.fitness"
    case hiking = "sports.hiking"
    case yoga = "sports.yoga"
    
    var icon: String {
        switch self {
        case .football:
            return "soccerball.circle"
        case .basketball:
            return "basketball.circle"
        case .tennis:
            return "tennis.racket"
        case .running:
            return "figure.run.circle"
        case .swimming:
            return "figure.pool.swim"
        case .cycling:
            return "bicycle.circle"
        case .volleyball:
            return "volleyball.circle"
        case .badminton:
            return "tennis.racket"
        case .pingpong:
            return "ping.pong.paddle"
        case .fitness:
            return "dumbbell.fill"
        case .hiking:
            return "mountain.2.circle"
        case .yoga:
            return "figure.mind.and.body"
        }
    }
    
    var displayName: String {
        switch self {
        case .football:
            return "Football"
        case .basketball:
            return "Basketball"
        case .tennis:
            return "Tennis"
        case .running:
            return "Running"
        case .swimming:
            return "Swimming"
        case .cycling:
            return "Cycling"
        case .volleyball:
            return "Volleyball"
        case .badminton:
            return "Badminton"
        case .pingpong:
            return "Ping Pong"
        case .fitness:
            return "Fitness"
        case .hiking:
            return "Hiking"
        case .yoga:
            return "Yoga"
        }
    }
}
