import SwiftUI
import Foundation

// MARK: - Event Model
struct Event: Identifiable, Codable {
    let id: String
    let title: String
    let description: String
    let imageUrl: String
    let date: Date
    let location: String
    let type: EventType
    let sport: Sport
    let participants: [Participant]
    let maxParticipants: Int
    let isParticipating: Bool
    let createdBy: String
    let createdAt: Date
    
    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
    
    var isUpcoming: Bool {
        date > Date()
    }
    
    var availableSpots: Int {
        maxParticipants - participants.count
    }
    
    var formattedParticipantCount: String {
        return "\(participants.count)/\(maxParticipants)"
    }
}
