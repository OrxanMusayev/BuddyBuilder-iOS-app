import Foundation

// MARK: - Events Service Protocol
protocol EventsServiceProtocol {
    func fetchEvents() async throws -> [Event]
    func fetchMyEvents() async throws -> [Event]
    func joinEvent(_ eventId: String) async throws -> Bool
    func leaveEvent(_ eventId: String) async throws -> Bool
    func createEvent(_ event: CreateEventRequest) async throws -> Event
    func updateEvent(_ eventId: String, _ event: UpdateEventRequest) async throws -> Event
    func deleteEvent(_ eventId: String) async throws -> Bool
}

// MARK: - Events Service
class EventsService: EventsServiceProtocol {
    
    // MARK: - API Endpoints (will be used when implementing real API)
    private let baseURL = "https://api.buddybuilder.com/v1"
    private let eventsEndpoint = "/events"
    private let myEventsEndpoint = "/events/my"
    
    // MARK: - Public Methods
    
    func fetchEvents() async throws -> [Event] {
        // TODO: Replace with actual API call
        // let url = URL(string: "\(baseURL)\(eventsEndpoint)")!
        // let (data, _) = try await URLSession.shared.data(from: url)
        // return try JSONDecoder().decode([Event].self, from: data)
        
        // Simulate network delay
        try await Task.sleep(nanoseconds: 1_000_000_000)
        return MockEventData.shared.getAllEvents()
    }
    
    func fetchMyEvents() async throws -> [Event] {
        // TODO: Replace with actual API call
        // let url = URL(string: "\(baseURL)\(myEventsEndpoint)")!
        // let (data, _) = try await URLSession.shared.data(from: url)
        // return try JSONDecoder().decode([Event].self, from: data)
        
        // Simulate network delay
        try await Task.sleep(nanoseconds: 800_000_000)
        return MockEventData.shared.getMyEvents()
    }
    
    func joinEvent(_ eventId: String) async throws -> Bool {
        // TODO: Replace with actual API call
        // let url = URL(string: "\(baseURL)\(eventsEndpoint)/\(eventId)/join")!
        // var request = URLRequest(url: url)
        // request.httpMethod = "POST"
        // let (_, response) = try await URLSession.shared.data(for: request)
        // return (response as? HTTPURLResponse)?.statusCode == 200
        
        // Simulate network delay
        try await Task.sleep(nanoseconds: 500_000_000)
        MockEventData.shared.joinEvent(eventId)
        return true
    }
    
    func leaveEvent(_ eventId: String) async throws -> Bool {
        // TODO: Replace with actual API call
        // let url = URL(string: "\(baseURL)\(eventsEndpoint)/\(eventId)/leave")!
        // var request = URLRequest(url: url)
        // request.httpMethod = "DELETE"
        // let (_, response) = try await URLSession.shared.data(for: request)
        // return (response as? HTTPURLResponse)?.statusCode == 200
        
        // Simulate network delay
        try await Task.sleep(nanoseconds: 500_000_000)
        MockEventData.shared.leaveEvent(eventId)
        return true
    }
    
    func createEvent(_ event: CreateEventRequest) async throws -> Event {
        // TODO: Implement create event
        try await Task.sleep(nanoseconds: 1_000_000_000)
        return MockEventData.shared.createEvent(from: event)
    }
    
    func updateEvent(_ eventId: String, _ event: UpdateEventRequest) async throws -> Event {
        // TODO: Implement update event
        try await Task.sleep(nanoseconds: 800_000_000)
        return MockEventData.shared.updateEvent(eventId, with: event)
    }
    
    func deleteEvent(_ eventId: String) async throws -> Bool {
        // TODO: Implement delete event
        try await Task.sleep(nanoseconds: 500_000_000)
        return MockEventData.shared.deleteEvent(eventId)
    }
}

// MARK: - Request Models
struct CreateEventRequest: Codable {
    let title: String
    let description: String
    let imageUrl: String?
    let date: Date
    let location: String
    let type: EventType
    let sport: Sport
    let maxParticipants: Int
}

struct UpdateEventRequest: Codable {
    let title: String?
    let description: String?
    let imageUrl: String?
    let date: Date?
    let location: String?
    let type: EventType?
    let sport: Sport?
    let maxParticipants: Int?
}

// MARK: - Mock Data Manager
class MockEventData {
    static let shared = MockEventData()
    private init() {}
    
    private var events: [Event] = []
    private var userParticipations: Set<String> = ["1", "3", "5"] // User is participating in these events
    
    func getAllEvents() -> [Event] {
        if events.isEmpty {
            events = generateMockEvents()
        }
        return events.map { event in
            var updatedEvent = event
            return Event(
                id: event.id,
                title: event.title,
                description: event.description,
                imageUrl: event.imageUrl,
                date: event.date,
                location: event.location,
                type: event.type,
                sport: event.sport,
                participants: event.participants,
                maxParticipants: event.maxParticipants,
                isParticipating: userParticipations.contains(event.id),
                createdBy: event.createdBy,
                createdAt: event.createdAt
            )
        }
    }
    
    func getMyEvents() -> [Event] {
        return getAllEvents().filter { userParticipations.contains($0.id) }
    }
    
    func joinEvent(_ eventId: String) {
        userParticipations.insert(eventId)
    }
    
    func leaveEvent(_ eventId: String) {
        userParticipations.remove(eventId)
    }
    
    func createEvent(from request: CreateEventRequest) -> Event {
        let newEvent = Event(
            id: UUID().uuidString,
            title: request.title,
            description: request.description,
            imageUrl: request.imageUrl ?? "https://images.unsplash.com/photo-1571019613454-1cb2f99b2d8b",
            date: request.date,
            location: request.location,
            type: request.type,
            sport: request.sport,
            participants: [mockParticipants[0]], // Creator as first participant
            maxParticipants: request.maxParticipants,
            isParticipating: true,
            createdBy: "current_user",
            createdAt: Date()
        )
        events.append(newEvent)
        userParticipations.insert(newEvent.id)
        return newEvent
    }
    
    func updateEvent(_ eventId: String, with request: UpdateEventRequest) -> Event {
        guard let index = events.firstIndex(where: { $0.id == eventId }) else {
            return events.first! // Should handle error properly
        }
        
        let existingEvent = events[index]
        let updatedEvent = Event(
            id: existingEvent.id,
            title: request.title ?? existingEvent.title,
            description: request.description ?? existingEvent.description,
            imageUrl: request.imageUrl ?? existingEvent.imageUrl,
            date: request.date ?? existingEvent.date,
            location: request.location ?? existingEvent.location,
            type: request.type ?? existingEvent.type,
            sport: request.sport ?? existingEvent.sport,
            participants: existingEvent.participants,
            maxParticipants: request.maxParticipants ?? existingEvent.maxParticipants,
            isParticipating: existingEvent.isParticipating,
            createdBy: existingEvent.createdBy,
            createdAt: existingEvent.createdAt
        )
        
        events[index] = updatedEvent
        return updatedEvent
    }
    
    func deleteEvent(_ eventId: String) -> Bool {
        events.removeAll { $0.id == eventId }
        userParticipations.remove(eventId)
        return true
    }
    
    private func generateMockEvents() -> [Event] {
        let calendar = Calendar.current
        let now = Date()
        
        return [
            Event(
                id: "1",
                title: "Weekend Football Tournament",
                description: "Join us for an exciting football tournament this weekend! All skill levels welcome.",
                imageUrl: "https://images.unsplash.com/photo-1574629810360-7efbbe195018?ixlib=rb-4.0.3&auto=format&fit=crop&w=1000&q=80",
                date: calendar.date(byAdding: .day, value: 2, to: now)!,
                location: "Central Park Stadium",
                type: .tournament,
                sport: .football,
                participants: Array(mockParticipants.prefix(8)),
                maxParticipants: 16,
                isParticipating: false,
                createdBy: "user123",
                createdAt: calendar.date(byAdding: .day, value: -5, to: now)!
            ),
            Event(
                id: "2",
                title: "Morning Running Session",
                description: "Start your day with an energizing morning run along the riverside trail.",
                imageUrl: "https://images.unsplash.com/photo-1544717297-fa95b6ee9643?ixlib=rb-4.0.3&auto=format&fit=crop&w=1000&q=80",
                date: calendar.date(byAdding: .day, value: 1, to: now)!,
                location: "Riverside Trail",
                type: .training,
                sport: .running,
                participants: Array(mockParticipants.prefix(5)),
                maxParticipants: 12,
                isParticipating: false,
                createdBy: "user456",
                createdAt: calendar.date(byAdding: .day, value: -3, to: now)!
            ),
            Event(
                id: "3",
                title: "Basketball Skills Workshop",
                description: "Improve your basketball skills with professional coaches and advanced drills.",
                imageUrl: "https://images.unsplash.com/photo-1546519638-68e109498ffc?ixlib=rb-4.0.3&auto=format&fit=crop&w=1000&q=80",
                date: calendar.date(byAdding: .day, value: 5, to: now)!,
                location: "Downtown Sports Complex",
                type: .workshop,
                sport: .basketball,
                participants: Array(mockParticipants.prefix(12)),
                maxParticipants: 20,
                isParticipating: false,
                createdBy: "user789",
                createdAt: calendar.date(byAdding: .day, value: -7, to: now)!
            ),
            Event(
                id: "4",
                title: "Evening Tennis Match",
                description: "Friendly tennis matches for all skill levels. Come and play!",
                imageUrl: "https://images.unsplash.com/photo-1622279457486-62dcc4a431d6?ixlib=rb-4.0.3&auto=format&fit=crop&w=1000&q=80",
                date: calendar.date(byAdding: .day, value: 3, to: now)!,
                location: "City Tennis Club",
                type: .match,
                sport: .tennis,
                participants: Array(mockParticipants.prefix(4)),
                maxParticipants: 8,
                isParticipating: false,
                createdBy: "user101",
                createdAt: calendar.date(byAdding: .day, value: -2, to: now)!
            ),
            Event(
                id: "5",
                title: "Swimming Training Session",
                description: "Professional swimming training for beginners and intermediate swimmers.",
                imageUrl: "https://images.unsplash.com/photo-1530549387789-4c1017266635?ixlib=rb-4.0.3&auto=format&fit=crop&w=1000&q=80",
                date: calendar.date(byAdding: .day, value: 4, to: now)!,
                location: "Olympic Aquatic Center",
                type: .training,
                sport: .swimming,
                participants: Array(mockParticipants.prefix(6)),
                maxParticipants: 15,
                isParticipating: false,
                createdBy: "user202",
                createdAt: calendar.date(byAdding: .day, value: -4, to: now)!
            ),
            Event(
                id: "6",
                title: "Social Cycling Ride",
                description: "Casual cycling ride through the city parks. Perfect for weekend activity!",
                imageUrl: "https://images.unsplash.com/photo-1558618666-fcd25c85cd64?ixlib=rb-4.0.3&auto=format&fit=crop&w=1000&q=80",
                date: calendar.date(byAdding: .day, value: 6, to: now)!,
                location: "City Park Loop",
                type: .social,
                sport: .cycling,
                participants: Array(mockParticipants.prefix(10)),
                maxParticipants: 25,
                isParticipating: false,
                createdBy: "user303",
                createdAt: calendar.date(byAdding: .day, value: -6, to: now)!
            ),
            Event(
                id: "7",
                title: "Yoga & Meditation Workshop",
                description: "Relax and rejuvenate with our morning yoga and meditation session.",
                imageUrl: "https://images.unsplash.com/photo-1544367567-0f2fcb009e0b?ixlib=rb-4.0.3&auto=format&fit=crop&w=1000&q=80",
                date: calendar.date(byAdding: .hour, value: 26, to: now)!,
                location: "Zen Garden Studio",
                type: .workshop,
                sport: .yoga,
                participants: Array(mockParticipants.prefix(8)),
                maxParticipants: 15,
                isParticipating: false,
                createdBy: "user404",
                createdAt: calendar.date(byAdding: .day, value: -1, to: now)!
            ),
            Event(
                id: "8",
                title: "Hiking Adventure",
                description: "Mountain hiking adventure for nature lovers and fitness enthusiasts.",
                imageUrl: "https://images.unsplash.com/photo-1551632811-561732d1e306?ixlib=rb-4.0.3&auto=format&fit=crop&w=1000&q=80",
                date: calendar.date(byAdding: .day, value: 7, to: now)!,
                location: "Mountain Trail Head",
                type: .social,
                sport: .hiking,
                participants: Array(mockParticipants.prefix(6)),
                maxParticipants: 12,
                isParticipating: false,
                createdBy: "user505",
                createdAt: calendar.date(byAdding: .day, value: -8, to: now)!
            )
        ]
    }
    
    private var mockParticipants: [Participant] {
        return [
            Participant(id: "p1", name: "Alex Johnson", avatarUrl: "https://i.pravatar.cc/150?img=1", isOrganizer: true),
            Participant(id: "p2", name: "Sarah Chen", avatarUrl: "https://i.pravatar.cc/150?img=2", isOrganizer: false),
            Participant(id: "p3", name: "Mike Rodriguez", avatarUrl: "https://i.pravatar.cc/150?img=3", isOrganizer: false),
            Participant(id: "p4", name: "Emma Thompson", avatarUrl: "https://i.pravatar.cc/150?img=4", isOrganizer: false),
            Participant(id: "p5", name: "David Kim", avatarUrl: "https://i.pravatar.cc/150?img=5", isOrganizer: false),
            Participant(id: "p6", name: "Lisa Wang", avatarUrl: "https://i.pravatar.cc/150?img=6", isOrganizer: false),
            Participant(id: "p7", name: "James Wilson", avatarUrl: "https://i.pravatar.cc/150?img=7", isOrganizer: false),
            Participant(id: "p8", name: "Maria Garcia", avatarUrl: "https://i.pravatar.cc/150?img=8", isOrganizer: false),
            Participant(id: "p9", name: "Chris Brown", avatarUrl: "https://i.pravatar.cc/150?img=9", isOrganizer: false),
            Participant(id: "p10", name: "Anna Lee", avatarUrl: "https://i.pravatar.cc/150?img=10", isOrganizer: false),
            Participant(id: "p11", name: "Tom Davis", avatarUrl: "https://i.pravatar.cc/150?img=11", isOrganizer: false),
            Participant(id: "p12", name: "Sophie Miller", avatarUrl: "https://i.pravatar.cc/150?img=12", isOrganizer: false),
            Participant(id: "p13", name: "Ryan Taylor", avatarUrl: "https://i.pravatar.cc/150?img=13", isOrganizer: false),
            Participant(id: "p14", name: "Rachel Green", avatarUrl: "https://i.pravatar.cc/150?img=14", isOrganizer: false),
            Participant(id: "p15", name: "Kevin White", avatarUrl: "https://i.pravatar.cc/150?img=15", isOrganizer: false)
        ]
    }
}
