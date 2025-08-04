// BuddyBuilder/Features/Sports/Services/MySportsService.swift - UPDATED

import Foundation
import Combine

// MARK: - My Sports Models - SAME AS BEFORE
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

// MARK: - My Sports Service Protocol - UPDATED
protocol MySportsServiceProtocol {
    func fetchMySportsWithAutoRefresh() -> AnyPublisher<[UserSport], Error>
    func addSportWithAutoRefresh(sportId: Int, experienceLevel: Int, isPreferred: Bool, notes: String?) -> AnyPublisher<UserSport, Error>
    func updateSportWithAutoRefresh(userSportId: Int, experienceLevel: Int, isPreferred: Bool, notes: String?) -> AnyPublisher<UserSport, Error>
    func removeSportWithAutoRefresh(userSportId: Int) -> AnyPublisher<Bool, Error>
    
    // Original methods (for backward compatibility)
    func addSport(sportId: Int, experienceLevel: Int, isPreferred: Bool, notes: String?) -> AnyPublisher<UserSport, Error>
    func updateSport(userSportId: Int, experienceLevel: Int, isPreferred: Bool, notes: String?) -> AnyPublisher<UserSport, Error>
}

// MARK: - My Sports Service Implementation - UPDATED
class MySportsService: MySportsServiceProtocol {
    private let networkManager = NetworkManager.shared
    private let baseURL = "http://192.168.100.74:5206/api/Sports"
    
    // MARK: - Fetch My Sports (with auto-refresh)
    func fetchMySportsWithAutoRefresh() -> AnyPublisher<[UserSport], Error> {
        let headers = getAuthHeaders()
        
        return networkManager.requestWithAutoRefresh(
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
                print("✅ Fetched \(sports.count) user sports with auto-refresh")
            },
            receiveCompletion: { completion in
                if case .failure(let error) = completion {
                    print("❌ Failed to fetch my sports with auto-refresh: \(error)")
                    Task { @MainActor in
                        AuthErrorHandler.shared.handleAuthError(error)
                    }
                }
            }
        )
        .eraseToAnyPublisher()
    }
    
    // MARK: - Add Sport (with auto-refresh)
    func addSportWithAutoRefresh(sportId: Int, experienceLevel: Int, isPreferred: Bool, notes: String?) -> AnyPublisher<UserSport, Error> {
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
        
        return networkManager.requestWithAutoRefresh(
            endpoint: "\(baseURL)/add",
            method: .POST,
            body: requestBody,
            headers: headers,
            type: APIResponse<UserSport>.self
        )
        .compactMap { response in
            response.success ? response.data : nil
        }
        .handleEvents(
            receiveOutput: { userSport in
                print("✅ Added sport with auto-refresh: \(userSport.name)")
            },
            receiveCompletion: { completion in
                if case .failure(let error) = completion {
                    print("❌ Failed to add sport with auto-refresh: \(error)")
                    Task { @MainActor in
                        AuthErrorHandler.shared.handleAuthError(error)
                    }
                }
            }
        )
        .eraseToAnyPublisher()
    }
    
    // MARK: - Update Sport (with auto-refresh)
    func updateSportWithAutoRefresh(userSportId: Int, experienceLevel: Int, isPreferred: Bool, notes: String?) -> AnyPublisher<UserSport, Error> {
        let headers = getAuthHeaders()
        let requestData = [
            "experienceLevel": experienceLevel,
            "isPreferred": isPreferred,
            "notes": notes as Any
        ] as [String : Any]
        
        guard let requestBody = try? JSONSerialization.data(withJSONObject: requestData) else {
            return Fail(error: NetworkError.decodingError).eraseToAnyPublisher()
        }
        
        return networkManager.requestWithAutoRefresh(
            endpoint: "\(baseURL)/update/\(userSportId)",
            method: .PUT,
            body: requestBody,
            headers: headers,
            type: APIResponse<UserSport>.self
        )
        .compactMap { response in
            response.success ? response.data : nil
        }
        .handleEvents(
            receiveOutput: { userSport in
                print("✅ Updated sport with auto-refresh: \(userSport.name)")
            },
            receiveCompletion: { completion in
                if case .failure(let error) = completion {
                    print("❌ Failed to update sport with auto-refresh: \(error)")
                    Task { @MainActor in
                        AuthErrorHandler.shared.handleAuthError(error)
                    }
                }
            }
        )
        .eraseToAnyPublisher()
    }
    
    // MARK: - Remove Sport (with auto-refresh)
    func removeSportWithAutoRefresh(userSportId: Int) -> AnyPublisher<Bool, Error> {
        let headers = getAuthHeaders()
        
        return networkManager.requestWithAutoRefresh(
            endpoint: "\(baseURL)/remove/\(userSportId)",
            method: .DELETE,
            headers: headers,
            type: APIResponse<Bool>.self
        )
        .map { response in
            response.success
        }
        .handleEvents(
            receiveOutput: { success in
                print(success ? "✅ Sport removed successfully with auto-refresh" : "❌ Failed to remove sport")
            },
            receiveCompletion: { completion in
                if case .failure(let error) = completion {
                    print("❌ Failed to remove sport with auto-refresh: \(error)")
                    Task { @MainActor in
                        AuthErrorHandler.shared.handleAuthError(error)
                    }
                }
            }
        )
        .eraseToAnyPublisher()
    }
    
    // MARK: - Original methods (for backward compatibility)
    func addSport(sportId: Int, experienceLevel: Int, isPreferred: Bool, notes: String?) -> AnyPublisher<UserSport, Error> {
        return addSportWithAutoRefresh(sportId: sportId, experienceLevel: experienceLevel, isPreferred: isPreferred, notes: notes)
    }
    
    func updateSport(userSportId: Int, experienceLevel: Int, isPreferred: Bool, notes: String?) -> AnyPublisher<UserSport, Error> {
        return updateSportWithAutoRefresh(userSportId: userSportId, experienceLevel: experienceLevel, isPreferred: isPreferred, notes: notes)
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

// MARK: - Mock Sports Service (for testing)
class MockMySportsService: MySportsServiceProtocol {
    private var mockUserSports: [UserSport] = [
        UserSport(
            id: 1,
            name: "Basketball",
            description: "Team sport played on a court",
            iconUrl: nil,
            experienceLevel: 3,
            isActive: true,
            userCount: 125,
            createdAt: ISO8601DateFormatter().string(from: Date().addingTimeInterval(-86400 * 30)),
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
            createdAt: ISO8601DateFormatter().string(from: Date().addingTimeInterval(-86400 * 15)),
            updatedAt: nil
        )
    ]
    
    func fetchMySportsWithAutoRefresh() -> AnyPublisher<[UserSport], Error> {
        return Just(mockUserSports)
            .setFailureType(to: Error.self)
            .delay(for: .seconds(1), scheduler: RunLoop.main)
            .eraseToAnyPublisher()
    }
    
    func addSportWithAutoRefresh(sportId: Int, experienceLevel: Int, isPreferred: Bool, notes: String?) -> AnyPublisher<UserSport, Error> {
        let newUserSport = UserSport(
            id: Int.random(in: 100...999),
            name: "New Sport \(sportId)",
            description: "Added sport",
            iconUrl: nil,
            experienceLevel: experienceLevel,
            isActive: true,
            userCount: Int.random(in: 10...100),
            createdAt: ISO8601DateFormatter().string(from: Date()),
            updatedAt: nil
        )
        
        mockUserSports.append(newUserSport)
        
        return Just(newUserSport)
            .setFailureType(to: Error.self)
            .delay(for: .seconds(1.5), scheduler: RunLoop.main)
            .eraseToAnyPublisher()
    }
    
    func updateSportWithAutoRefresh(userSportId: Int, experienceLevel: Int, isPreferred: Bool, notes: String?) -> AnyPublisher<UserSport, Error> {
        if let index = mockUserSports.firstIndex(where: { $0.id == userSportId }) {
            let updatedSport = UserSport(
                id: mockUserSports[index].id,
                name: mockUserSports[index].name,
                description: mockUserSports[index].description,
                iconUrl: mockUserSports[index].iconUrl,
                experienceLevel: experienceLevel,
                isActive: mockUserSports[index].isActive,
                userCount: mockUserSports[index].userCount,
                createdAt: mockUserSports[index].createdAt,
                updatedAt: ISO8601DateFormatter().string(from: Date())
            )
            
            mockUserSports[index] = updatedSport
            
            return Just(updatedSport)
                .setFailureType(to: Error.self)
                .delay(for: .seconds(1), scheduler: RunLoop.main)
                .eraseToAnyPublisher()
        }
        
        return Fail(error: NetworkError.noData)
            .eraseToAnyPublisher()
    }
    
    func removeSportWithAutoRefresh(userSportId: Int) -> AnyPublisher<Bool, Error> {
        if let index = mockUserSports.firstIndex(where: { $0.id == userSportId }) {
            mockUserSports.remove(at: index)
            
            return Just(true)
                .setFailureType(to: Error.self)
                .delay(for: .seconds(1), scheduler: RunLoop.main)
                .eraseToAnyPublisher()
        }
        
        return Just(false)
            .setFailureType(to: Error.self)
            .eraseToAnyPublisher()
    }
    
    // MARK: - Backward compatibility methods
    func addSport(sportId: Int, experienceLevel: Int, isPreferred: Bool, notes: String?) -> AnyPublisher<UserSport, Error> {
        return addSportWithAutoRefresh(sportId: sportId, experienceLevel: experienceLevel, isPreferred: isPreferred, notes: notes)
    }
    
    func updateSport(userSportId: Int, experienceLevel: Int, isPreferred: Bool, notes: String?) -> AnyPublisher<UserSport, Error> {
        return updateSportWithAutoRefresh(userSportId: userSportId, experienceLevel: experienceLevel, isPreferred: isPreferred, notes: notes)
    }
}
