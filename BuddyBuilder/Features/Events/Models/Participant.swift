import Foundation

// MARK: - Participant Model
struct Participant: Identifiable, Codable {
    let id: String
    let name: String
    let avatarUrl: String
    let isOrganizer: Bool
    let joinedAt: Date?
    
    init(id: String, name: String, avatarUrl: String, isOrganizer: Bool = false, joinedAt: Date? = nil) {
        self.id = id
        self.name = name
        self.avatarUrl = avatarUrl
        self.isOrganizer = isOrganizer
        self.joinedAt = joinedAt ?? Date()
    }
}
