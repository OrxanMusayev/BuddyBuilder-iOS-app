// BuddyBuilder/Features/Sports/Services/MySportsService.swift

import Foundation
import Combine

// MARK: - My Sports Models - UPDATED for correct API response
struct UserSport: Codable, Identifiable {
    let id: Int
    let name: String
    let description: String
    let iconUrl: String?
    let experienceLevel: Int
    let isActive: Bool
    let userCount: Int
    let createdAt: String
    let updatedAt: String?
    
    // Computed properties
    var addedDate: Date? {
        ISO8601DateFormatter().date(from: createdAt)
    }
    
    var formattedAddedDate: String {
        guard let date = addedDate else { return "Unknown" }
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }
    
    var experienceLevelEnum: ExperienceLevel? {
        ExperienceLevel(rawValue: experienceLevel)
    }
    
    var experienceLevelName: String {
        experienceLevelEnum?.displayName ?? "Unknown"
    }
    
    // Convert to Sport model for compatibility
    var sport: Sport {
        Sport(id: id, name: name, description: description, imageUrl: iconUrl, defaultEventImageUrl: nil)
    }
}

struct MySportsResponse: Codable {
    let success: Bool
    let message: String?
    let data: [UserSport]?
    let errors: [String]?
    let timestamp: String
}

// MARK: - My Sports Service Protocol
protocol MySportsServiceProtocol {
    func fetchMySports() -> AnyPublisher<[UserSport], Error>
    func addSport(sportId: Int, experienceLevel: Int, isPreferred: Bool, notes: String?) -> AnyPublisher<UserSport, Error>
    func updateSport(userSportId: Int, experienceLevel: Int, isPreferred: Bool, notes: String?) -> AnyPublisher<UserSport, Error>
    func removeSport(userSportId: Int) -> AnyPublisher<Bool, Error>
}

// MARK: - My Sports Service Implementation
class MySportsService: MySportsServiceProtocol {
    private let networkManager = NetworkManager.shared
    private let baseURL = "http://localhost:5206/api/Sports"
    
    // MARK: - Fetch My Sports
    func fetchMySports() -> AnyPublisher<[UserSport], Error> {
        let headers = getAuthHeaders()
        
        return networkManager.request(
            endpoint: "\(baseURL)/my-sports",
            method: .GET,
            headers: headers,
            type: MySportsResponse.self
        )
        .map { response in
            if response.success {
                return response.data ?? []
            } else {
                print("❌ My sports fetch failed: \(response.message ?? "Unknown error")")
                return []
            }
        }
        .handleEvents(
            receiveOutput: { sports in
                print("✅ Fetched \(sports.count) user sports")
            },
            receiveCompletion: { completion in
                if case .failure(let error) = completion {
                    print("❌ Failed to fetch my sports: \(error)")
                }
            }
        )
        .eraseToAnyPublisher()
    }
    
    // MARK: - Add Sport
    func addSport(sportId: Int, experienceLevel: Int, isPreferred: Bool, notes: String?) -> AnyPublisher<UserSport, Error> {
        let headers = getAuthHeaders()
        let requestData = [
            "sportId": sportId,
            "experienceLevel": experienceLevel,
            "isPreferred": isPreferred,
            "notes": notes as Any
        ] as [String : Any]
        
        guard let requestBody = try? JSONSerialization.data(withJSONObject: requestData) else {
            return Fail(error: NetworkError.decodingError).eraseToAnyPublisher()
        }
        
        return networkManager.request(
            endpoint: "\(baseURL)/add",
            method: .POST,
            body: requestBody,
            headers: headers,
            type: APIResponse<UserSport>.self
        )
        .compactMap { response in
            response.success ? response.data : nil
        }
        .eraseToAnyPublisher()
    }
    
    // MARK: - Update Sport
    func updateSport(userSportId: Int, experienceLevel: Int, isPreferred: Bool, notes: String?) -> AnyPublisher<UserSport, Error> {
        let headers = getAuthHeaders()
        let requestData = [
            "experienceLevel": experienceLevel,
            "isPreferred": isPreferred,
            "notes": notes as Any
        ] as [String : Any]
        
        guard let requestBody = try? JSONSerialization.data(withJSONObject: requestData) else {
            return Fail(error: NetworkError.decodingError).eraseToAnyPublisher()
        }
        
        return networkManager.request(
            endpoint: "\(baseURL)/update/\(userSportId)",
            method: .PUT,
            body: requestBody,
            headers: headers,
            type: APIResponse<UserSport>.self
        )
        .compactMap { response in
            response.success ? response.data : nil
        }
        .eraseToAnyPublisher()
    }
    
    // MARK: - Remove Sport
    func removeSport(userSportId: Int) -> AnyPublisher<Bool, Error> {
        let headers = getAuthHeaders()
        
        return networkManager.request(
            endpoint: "\(baseURL)/remove/\(userSportId)",
            method: .DELETE,
            headers: headers,
            type: APIResponse<Bool>.self
        )
        .map { response in
            response.success
        }
        .eraseToAnyPublisher()
    }
    
    // MARK: - Private Helper Methods
    private func getAuthHeaders() -> [String: String] {
        guard let token = UserDefaults.standard.string(forKey: "auth_token") else {
            print("⚠️ No auth token found")
            return [:]
        }
        
        return [
            "Authorization": "Bearer \(token)"
        ]
    }
}

// MARK: - Mock My Sports Service (for testing)
class MockMySportsService: MySportsServiceProtocol {
    func fetchMySports() -> AnyPublisher<[UserSport], Error> {
        let mockSports = [
            UserSport(
                id: 1,
                name: "Basketball",
                description: "Team sport played on a court",
                iconUrl: nil,
                experienceLevel: 3,
                isActive: true,
                userCount: 125,
                createdAt: "2024-01-15T10:30:00Z",
                updatedAt: nil
            ),
            UserSport(
                id: 2,
                name: "Tennis",
                description: "Racket sport",
                iconUrl: nil,
                experienceLevel: 2,
                isActive: true,
                userCount: 89,
                createdAt: "2024-02-01T14:20:00Z",
                updatedAt: "2024-02-15T16:45:00Z"
            ),
            UserSport(
                id: 3,
                name: "Running",
                description: "Individual endurance sport",
                iconUrl: nil,
                experienceLevel: 4,
                isActive: true,
                userCount: 203,
                createdAt: "2024-01-01T08:00:00Z",
                updatedAt: nil
            )
        ]
        
        return Just(mockSports)
            .setFailureType(to: Error.self)
            .delay(for: .seconds(1), scheduler: RunLoop.main)
            .eraseToAnyPublisher()
    }
    
    func addSport(sportId: Int, experienceLevel: Int, isPreferred: Bool, notes: String?) -> AnyPublisher<UserSport, Error> {
        let newSport = UserSport(
            id: Int.random(in: 100...999),
            name: "New Sport",
            description: "Added sport",
            iconUrl: nil,
            experienceLevel: experienceLevel,
            isActive: true,
            userCount: 0,
            createdAt: ISO8601DateFormatter().string(from: Date()),
            updatedAt: nil
        )
        
        return Just(newSport)
            .setFailureType(to: Error.self)
            .delay(for: .seconds(1), scheduler: RunLoop.main)
            .eraseToAnyPublisher()
    }
    
    func updateSport(userSportId: Int, experienceLevel: Int, isPreferred: Bool, notes: String?) -> AnyPublisher<UserSport, Error> {
        let updatedSport = UserSport(
            id: userSportId,
            name: "Updated Sport",
            description: "Updated sport description",
            iconUrl: nil,
            experienceLevel: experienceLevel,
            isActive: true,
            userCount: 50,
            createdAt: "2024-01-01T08:00:00Z",
            updatedAt: ISO8601DateFormatter().string(from: Date())
        )
        
        return Just(updatedSport)
            .setFailureType(to: Error.self)
            .delay(for: .seconds(1), scheduler: RunLoop.main)
            .eraseToAnyPublisher()
    }
    
    func removeSport(userSportId: Int) -> AnyPublisher<Bool, Error> {
        return Just(true)
            .setFailureType(to: Error.self)
            .delay(for: .seconds(1), scheduler: RunLoop.main)
            .eraseToAnyPublisher()
    }
}
