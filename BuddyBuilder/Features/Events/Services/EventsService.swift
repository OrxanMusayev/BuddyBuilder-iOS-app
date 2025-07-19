// BuddyBuilder/Features/Events/Services/CompleteEventsService.swift

import Foundation
import Combine

protocol EventsServiceProtocol {
    func fetchEvents(filter: EventFilter) -> AnyPublisher<EventsResponse, Error>
    func fetchMyEvents(filter: EventFilter) -> AnyPublisher<EventsResponse, Error>
    func joinEvent(eventId: Int) -> AnyPublisher<Bool, Error>
    func leaveEvent(eventId: Int) -> AnyPublisher<Bool, Error>
    func fetchEventDetails(eventId: Int) -> AnyPublisher<Event, Error>
    func fetchEventParticipants(eventId: Int) -> AnyPublisher<[EventParticipant], Error>
    func fetchAvailableSports() -> AnyPublisher<[Sport], Error>
}

// MARK: - Extended Events Service Protocol
protocol CompleteEventsServiceProtocol: EventsServiceProtocol {
    // Additional methods for complete functionality
    func fetchEventComments(eventId: Int) -> AnyPublisher<[EventComment], Error>
    func addEventComment(eventId: Int, comment: String) -> AnyPublisher<EventComment, Error>
    func deleteEventComment(commentId: Int) -> AnyPublisher<Bool, Error>
    func rateEvent(eventId: Int, rating: Int, review: String?) -> AnyPublisher<EventRating, Error>
    func fetchEventRatings(eventId: Int) -> AnyPublisher<[EventRating], Error>
    func inviteToEvent(eventId: Int, username: String) -> AnyPublisher<Bool, Error>
    func respondToInvitation(invitationId: Int, accepted: Bool) -> AnyPublisher<Bool, Error>
    func fetchUserInvitations() -> AnyPublisher<[EventInvitation], Error>
    func fetchEventStatistics() -> AnyPublisher<EventStatistics, Error>
    func fetchUserEventPreferences() -> AnyPublisher<UserEventPreferences, Error>
    func updateUserEventPreferences(_ preferences: UserEventPreferences) -> AnyPublisher<Bool, Error>
    func fetchEventNotifications() -> AnyPublisher<[EventNotification], Error>
    func markNotificationAsRead(notificationId: Int) -> AnyPublisher<Bool, Error>
    func searchEvents(query: String, filters: EventFilter?) -> AnyPublisher<EventSearchResult, Error>
    func fetchNearbyEvents(latitude: Double, longitude: Double, radius: Double) -> AnyPublisher<[Event], Error>
    func fetchEventCategories() -> AnyPublisher<[EventCategory], Error>
    func fetchEventLocations() -> AnyPublisher<[EventLocation], Error>
}

// MARK: - Complete Events Service Implementation
class CompleteEventsService: CompleteEventsServiceProtocol {
    private let networkManager = NetworkManager.shared
    private let baseURL = "http://localhost:5206/api/Events"
    private let commentsURL = "http://localhost:5206/api/EventComments"
    private let ratingsURL = "http://localhost:5206/api/EventRatings"
    private let invitationsURL = "http://localhost:5206/api/EventInvitations"
    private let notificationsURL = "http://localhost:5206/api/Notifications"
    private let preferencesURL = "http://localhost:5206/api/UserPreferences"
    
    // MARK: - Basic Event Operations (inherited from EventsService)
    func fetchEvents(filter: EventFilter) -> AnyPublisher<EventsResponse, Error> {
        let queryParams = filter.toQueryParameters()
        let queryString = buildQueryString(from: queryParams)
        let endpoint = queryString.isEmpty ? baseURL : "\(baseURL)?\(queryString)"
        
        print("🌐 Fetching events from: \(endpoint)")
        
        return networkManager.request(
            endpoint: endpoint,
            method: .GET,
            type: EventsResponse.self
        )
        .handleEvents(
            receiveOutput: { response in
                print("✅ Successfully fetched \(response.events.count) events")
            },
            receiveCompletion: { completion in
                if case .failure(let error) = completion {
                    print("❌ Failed to fetch events: \(error)")
                }
            }
        )
        .eraseToAnyPublisher()
    }
    
    func fetchMyEvents(filter: EventFilter) -> AnyPublisher<EventsResponse, Error> {
        let queryParams = filter.toQueryParameters()
        let queryString = buildQueryString(from: queryParams)
        let endpoint = queryString.isEmpty ? "\(baseURL)/my" : "\(baseURL)/my-events?\(queryString)"
        
        print("🌐 Fetching events from: \(endpoint)")
        
        return networkManager.request(
            endpoint: endpoint,
            method: .GET,
            type: EventsResponse.self
        )
        .handleEvents(
            receiveOutput: { response in
                print("✅ Successfully fetched \(response.events.count)  my events")
            },
            receiveCompletion: { completion in
                if case .failure(let error) = completion {
                    print("❌ Failed to fetch my events: \(error)")
                }
            }
        )
        .eraseToAnyPublisher()
    }
    
    func joinEvent(eventId: Int) -> AnyPublisher<Bool, Error> {
        return networkManager.request(
            endpoint: "\(baseURL)/\(eventId)/join",
            method: .POST,
            type: APIResponse<Bool>.self
        )
        .map { response in
            response.success && (response.data ?? false)
        }
        .eraseToAnyPublisher()
    }
    
    func leaveEvent(eventId: Int) -> AnyPublisher<Bool, Error> {
        return networkManager.request(
            endpoint: "\(baseURL)/\(eventId)/leave",
            method: .POST,
            type: APIResponse<Bool>.self
        )
        .map { response in
            response.success && (response.data ?? false)
        }
        .eraseToAnyPublisher()
    }
    
    func fetchEventDetails(eventId: Int) -> AnyPublisher<Event, Error> {
        return networkManager.request(
            endpoint: "\(baseURL)/\(eventId)",
            method: .GET,
            type: APIResponse<Event>.self
        )
        .compactMap { response in
            response.success ? response.data : nil
        }
        .eraseToAnyPublisher()
    }
    
    func createEvent(_ eventData: CreateEventRequest) -> AnyPublisher<Event, Error> {
        guard let requestBody = try? JSONEncoder().encode(eventData) else {
            return Fail(error: NetworkError.decodingError).eraseToAnyPublisher()
        }
        
        return networkManager.request(
            endpoint: baseURL,
            method: .POST,
            body: requestBody,
            type: APIResponse<Event>.self
        )
        .compactMap { response in
            response.success ? response.data : nil
        }
        .eraseToAnyPublisher()
    }
    
    func updateEvent(eventId: Int, eventData: UpdateEventRequest) -> AnyPublisher<Event, Error> {
        guard let requestBody = try? JSONEncoder().encode(eventData) else {
            return Fail(error: NetworkError.decodingError).eraseToAnyPublisher()
        }
        
        return networkManager.request(
            endpoint: "\(baseURL)/\(eventId)",
            method: .PUT,
            body: requestBody,
            type: APIResponse<Event>.self
        )
        .compactMap { response in
            response.success ? response.data : nil
        }
        .eraseToAnyPublisher()
    }
    
    func deleteEvent(eventId: Int) -> AnyPublisher<Bool, Error> {
        return networkManager.request(
            endpoint: "\(baseURL)/\(eventId)",
            method: .DELETE,
            type: APIResponse<Bool>.self
        )
        .map { response in
            response.success
        }
        .eraseToAnyPublisher()
    }
    
    func fetchEventParticipants(eventId: Int) -> AnyPublisher<[EventParticipant], Error> {
        return networkManager.request(
            endpoint: "\(baseURL)/\(eventId)/participants",
            method: .GET,
            type: APIResponse<[EventParticipant]>.self
        )
        .compactMap { response in
            response.success ? response.data : []
        }
        .eraseToAnyPublisher()
    }
    
    func fetchAvailableSports() -> AnyPublisher<[Sport], Error> {
        return networkManager.request(
            endpoint: "http://localhost:5206/api/Sports",
            method: .GET,
            type: APIResponse<[Sport]>.self
        )
        .compactMap { response in
            response.success ? response.data : []
        }
        .eraseToAnyPublisher()
    }
    
    // MARK: - Comments
    func fetchEventComments(eventId: Int) -> AnyPublisher<[EventComment], Error> {
        return networkManager.request(
            endpoint: "\(commentsURL)/event/\(eventId)",
            method: .GET,
            type: APIResponse<[EventComment]>.self
        )
        .compactMap { response in
            response.success ? response.data : []
        }
        .eraseToAnyPublisher()
    }
    
    func addEventComment(eventId: Int, comment: String) -> AnyPublisher<EventComment, Error> {
        let requestData = ["eventId": eventId, "comment": comment] as [String: Any]
        guard let requestBody = try? JSONSerialization.data(withJSONObject: requestData) else {
            return Fail(error: NetworkError.decodingError).eraseToAnyPublisher()
        }
        
        return networkManager.request(
            endpoint: commentsURL,
            method: .POST,
            body: requestBody,
            type: APIResponse<EventComment>.self
        )
        .compactMap { response in
            response.success ? response.data : nil
        }
        .eraseToAnyPublisher()
    }
    
    func deleteEventComment(commentId: Int) -> AnyPublisher<Bool, Error> {
        return networkManager.request(
            endpoint: "\(commentsURL)/\(commentId)",
            method: .DELETE,
            type: APIResponse<Bool>.self
        )
        .map { response in
            response.success
        }
        .eraseToAnyPublisher()
    }
    
    // MARK: - Ratings
    func rateEvent(eventId: Int, rating: Int, review: String?) -> AnyPublisher<EventRating, Error> {
        var requestData: [String: Any] = ["eventId": eventId, "rating": rating]
        if let review = review {
            requestData["review"] = review
        }
        
        guard let requestBody = try? JSONSerialization.data(withJSONObject: requestData) else {
            return Fail(error: NetworkError.decodingError).eraseToAnyPublisher()
        }
        
        return networkManager.request(
            endpoint: ratingsURL,
            method: .POST,
            body: requestBody,
            type: APIResponse<EventRating>.self
        )
        .compactMap { response in
            response.success ? response.data : nil
        }
        .eraseToAnyPublisher()
    }
    
    func fetchEventRatings(eventId: Int) -> AnyPublisher<[EventRating], Error> {
        return networkManager.request(
            endpoint: "\(ratingsURL)/event/\(eventId)",
            method: .GET,
            type: APIResponse<[EventRating]>.self
        )
        .compactMap { response in
            response.success ? response.data : []
        }
        .eraseToAnyPublisher()
    }
    
    // MARK: - Invitations
    func inviteToEvent(eventId: Int, username: String) -> AnyPublisher<Bool, Error> {
        let requestData = ["eventId": eventId, "username": username] as [String: Any]
        guard let requestBody = try? JSONSerialization.data(withJSONObject: requestData) else {
            return Fail(error: NetworkError.decodingError).eraseToAnyPublisher()
        }
        
        return networkManager.request(
            endpoint: invitationsURL,
            method: .POST,
            body: requestBody,
            type: APIResponse<Bool>.self
        )
        .map { response in
            response.success
        }
        .eraseToAnyPublisher()
    }
    
    func respondToInvitation(invitationId: Int, accepted: Bool) -> AnyPublisher<Bool, Error> {
        let requestData = ["accepted": accepted]
        guard let requestBody = try? JSONSerialization.data(withJSONObject: requestData) else {
            return Fail(error: NetworkError.decodingError).eraseToAnyPublisher()
        }
        
        return networkManager.request(
            endpoint: "\(invitationsURL)/\(invitationId)/respond",
            method: .POST,
            body: requestBody,
            type: APIResponse<Bool>.self
        )
        .map { response in
            response.success
        }
        .eraseToAnyPublisher()
    }
    
    func fetchUserInvitations() -> AnyPublisher<[EventInvitation], Error> {
        return networkManager.request(
            endpoint: "\(invitationsURL)/my",
            method: .GET,
            type: APIResponse<[EventInvitation]>.self
        )
        .compactMap { response in
            response.success ? response.data : []
        }
        .eraseToAnyPublisher()
    }
    
    // MARK: - Statistics & Analytics
    func fetchEventStatistics() -> AnyPublisher<EventStatistics, Error> {
        return networkManager.request(
            endpoint: "\(baseURL)/statistics",
            method: .GET,
            type: APIResponse<EventStatistics>.self
        )
        .compactMap { response in
            response.success ? response.data : nil
        }
        .eraseToAnyPublisher()
    }
    
    // MARK: - User Preferences
    func fetchUserEventPreferences() -> AnyPublisher<UserEventPreferences, Error> {
        return networkManager.request(
            endpoint: "\(preferencesURL)/events",
            method: .GET,
            type: APIResponse<UserEventPreferences>.self
        )
        .compactMap { response in
            response.success ? response.data : nil
        }
        .eraseToAnyPublisher()
    }
    
    func updateUserEventPreferences(_ preferences: UserEventPreferences) -> AnyPublisher<Bool, Error> {
        guard let requestBody = try? JSONEncoder().encode(preferences) else {
            return Fail(error: NetworkError.decodingError).eraseToAnyPublisher()
        }
        
        return networkManager.request(
            endpoint: "\(preferencesURL)/events",
            method: .PUT,
            body: requestBody,
            type: APIResponse<Bool>.self
        )
        .map { response in
            response.success
        }
        .eraseToAnyPublisher()
    }
    
    // MARK: - Notifications
    func fetchEventNotifications() -> AnyPublisher<[EventNotification], Error> {
        return networkManager.request(
            endpoint: "\(notificationsURL)/events",
            method: .GET,
            type: APIResponse<[EventNotification]>.self
        )
        .compactMap { response in
            response.success ? response.data : []
        }
        .eraseToAnyPublisher()
    }
    
    func markNotificationAsRead(notificationId: Int) -> AnyPublisher<Bool, Error> {
        return networkManager.request(
            endpoint: "\(notificationsURL)/\(notificationId)/read",
            method: .POST,
            type: APIResponse<Bool>.self
        )
        .map { response in
            response.success
        }
        .eraseToAnyPublisher()
    }
    
    // MARK: - Search & Discovery
    func searchEvents(query: String, filters: EventFilter?) -> AnyPublisher<EventSearchResult, Error> {
        var params = ["q": query]
        if let filters = filters {
            let filterParams = filters.toQueryParameters()
            params.merge(filterParams) { (_, new) in new }
        }
        
        let queryString = buildQueryString(from: params)
        let endpoint = "\(baseURL)/search?\(queryString)"
        
        return networkManager.request(
            endpoint: endpoint,
            method: .GET,
            type: APIResponse<EventSearchResult>.self
        )
        .compactMap { response in
            response.success ? response.data : nil
        }
        .eraseToAnyPublisher()
    }
    
    func fetchNearbyEvents(latitude: Double, longitude: Double, radius: Double) -> AnyPublisher<[Event], Error> {
        let params = [
            "latitude": String(latitude),
            "longitude": String(longitude),
            "radius": String(radius)
        ]
        let queryString = buildQueryString(from: params)
        let endpoint = "\(baseURL)/nearby?\(queryString)"
        
        return networkManager.request(
            endpoint: endpoint,
            method: .GET,
            type: APIResponse<[Event]>.self
        )
        .compactMap { response in
            response.success ? response.data : []
        }
        .eraseToAnyPublisher()
    }
    
    // MARK: - Categories & Locations
    func fetchEventCategories() -> AnyPublisher<[EventCategory], Error> {
        return networkManager.request(
            endpoint: "http://localhost:5206/api/EventCategories",
            method: .GET,
            type: APIResponse<[EventCategory]>.self
        )
        .compactMap { response in
            response.success ? response.data : []
        }
        .eraseToAnyPublisher()
    }
    
    func fetchEventLocations() -> AnyPublisher<[EventLocation], Error> {
        return networkManager.request(
            endpoint: "http://localhost:5206/api/EventLocations",
            method: .GET,
            type: APIResponse<[EventLocation]>.self
        )
        .compactMap { response in
            response.success ? response.data : []
        }
        .eraseToAnyPublisher()
    }
    
    // MARK: - Private Helper Methods
    private func buildQueryString(from params: [String: String]) -> String {
        return params.compactMap { key, value in
            guard !value.isEmpty else { return nil }
            let encodedValue = value.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? value
            return "\(key)=\(encodedValue)"
        }
        .joined(separator: "&")
    }
}
