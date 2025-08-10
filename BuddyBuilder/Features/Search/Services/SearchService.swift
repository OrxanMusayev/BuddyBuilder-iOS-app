// BuddyBuilder/Features/Search/Services/SearchService.swift

import Foundation
import Combine

// MARK: - Search API Models
struct SearchUser: Codable, Identifiable {
    let id: Int
    let username: String
    let firstName: String
    let lastName: String
    let fullName: String
    let profileImageUrl: String?
    let overallExperienceLevel: Int
    let city: String?
    let country: String?
    let sports: [UserSport]
    let joinedAt: String
    
    // Optional fields that may not exist in all endpoints
    let eventsAttended: Int?
    let eventsOrganized: Int?
    let popularityScore: Double?
    let daysSinceJoined: Int?
    
    struct UserSport: Codable {
        let sportId: Int
        let sportName: String
        let sportIconUrl: String?
        let experienceLevel: Int
        let experienceLevelName: String
    }
    
    // Computed properties for compatibility
    var name: String {
        if !fullName.isEmpty {
            return fullName
        } else if !firstName.isEmpty || !lastName.isEmpty {
            return "\(firstName) \(lastName)".trimmingCharacters(in: .whitespaces)
        } else {
            return username
        }
    }
    
    var bio: String {
        if sports.count > 0 {
            return sports.map { $0.sportName }.joined(separator: ", ")
        }
        return "Sports enthusiast"
    }
    
    var location: String {
        let components = [city, country].compactMap { $0?.isEmpty == false ? $0 : nil }
        return components.isEmpty ? "Location not set" : components.joined(separator: ", ")
    }
    
    var isOnline: Bool {
        // Use daysSinceJoined if available, otherwise use joinedAt
        if let daysSinceJoined = daysSinceJoined {
            return daysSinceJoined == 0 || (popularityScore ?? 0) > 5 || (eventsOrganized ?? 0) > 0
        }
        
        // Fallback to joinedAt calculation
        guard let joinDate = ISO8601DateFormatter().date(from: joinedAt) else { return false }
        let daysSinceJoin = Date().timeIntervalSince(joinDate) / 86400
        return daysSinceJoin < 1 || (popularityScore ?? 0) > 5 || (eventsOrganized ?? 0) > 0
    }
    
    var isNew: Bool {
        // Use daysSinceJoined if available, otherwise use joinedAt
        if let daysSinceJoined = daysSinceJoined {
            return daysSinceJoined <= 7
        }
        
        // Fallback to joinedAt calculation
        guard let joinDate = ISO8601DateFormatter().date(from: joinedAt) else { return false }
        let daysSinceJoin = Date().timeIntervalSince(joinDate) / 86400
        return daysSinceJoin <= 7
    }
    
    // For backward compatibility with old properties
    var recentEventsCount: Int { (eventsAttended ?? 0) + (eventsOrganized ?? 0) }
    var activityScore: Double { popularityScore ?? Double(daysSinceJoined ?? 0) }
    var lastEventDate: String? { joinedAt }
}

struct SearchTrainer: Codable, Identifiable {
    let id: Int
    let username: String
    let firstName: String
    let lastName: String
    let fullName: String
    let profileImageUrl: String?
    let overallExperienceLevel: Int
    let city: String?
    let country: String?
    let sports: [TrainerSport]
    let joinedAt: String
    
    // Optional fields that may not exist in all endpoints
    let eventsAttended: Int?
    let eventsOrganized: Int?
    let popularityScore: Double?
    let daysSinceJoined: Int?
    
    struct TrainerSport: Codable {
        let sportId: Int
        let sportName: String
        let sportIconUrl: String?
        let experienceLevel: Int
        let experienceLevelName: String
    }
    
    // Computed properties for compatibility
    var name: String {
        if !fullName.isEmpty {
            return fullName
        } else if !firstName.isEmpty || !lastName.isEmpty {
            return "\(firstName) \(lastName)".trimmingCharacters(in: .whitespaces)
        } else {
            return username
        }
    }
    
    var specialty: String {
        if sports.count > 0 {
            return sports.map { $0.sportName }.joined(separator: " & ")
        }
        return "Multi-Sport Trainer"
    }
    
    var gym: String {
        let components = [city, country].compactMap { $0?.isEmpty == false ? $0 : nil }
        return components.isEmpty ? "Location not set" : components.joined(separator: ", ")
    }
    
    var rating: Double {
        // Convert popularity score to rating (0-10 -> 3.0-5.0)
        let score = popularityScore ?? Double(max(0, 10 - (daysSinceJoined ?? 1)))
        let normalizedScore = min(max(score, 0), 10)
        return 3.0 + (normalizedScore / 10.0) * 2.0
    }
    
    var experience: String {
        if overallExperienceLevel >= 4 {
            return "10+ years"
        } else if overallExperienceLevel >= 3 {
            return "5+ years"
        } else if overallExperienceLevel >= 2 {
            return "2+ years"
        } else {
            return "1+ year"
        }
    }
    
    var formattedRating: String {
        return String(format: "%.1f", rating)
    }
    
    // For backward compatibility
    var recentEventsCount: Int { (eventsAttended ?? 0) + (eventsOrganized ?? 0) }
    var activityScore: Double { popularityScore ?? Double(daysSinceJoined ?? 0) }
    var lastEventDate: String? { joinedAt }
}

struct SearchResponse<T: Codable>: Codable {
    let success: Bool
    let message: String?
    let data: SearchData<T>?
    let errors: [String]?
    let timestamp: String
}

struct SearchData<T: Codable>: Codable {
    let items: [T]
    let totalCount: Int
    let page: Int
    let pageSize: Int
    let totalPages: Int
    let hasNextPage: Bool
    let hasPreviousPage: Bool
}

// MARK: - Search Service Protocol
protocol SearchServiceProtocol {
    func fetchPopularUsers(location: String?, sportId: Int?, page: Int, pageSize: Int) -> AnyPublisher<SearchData<SearchUser>, Error>
    func fetchNewUsers(location: String?, sportId: Int?, page: Int, pageSize: Int) -> AnyPublisher<SearchData<SearchUser>, Error>
    func fetchActiveUsers(location: String?, sportId: Int?, page: Int, pageSize: Int) -> AnyPublisher<SearchData<SearchUser>, Error>
    func fetchTopTrainers(location: String?, sportId: Int?, page: Int, pageSize: Int) -> AnyPublisher<SearchData<SearchTrainer>, Error>
}

// MARK: - Search Service Implementation
class SearchService: SearchServiceProtocol {
    private let networkManager = NetworkManager.shared
    private let baseURL = "http://192.168.100.76:5206/api/Search"
    
    // MARK: - Popular Users
    func fetchPopularUsers(location: String?, sportId: Int?, page: Int = 1, pageSize: Int = 10) -> AnyPublisher<SearchData<SearchUser>, Error> {
        var queryItems: [URLQueryItem] = [
            URLQueryItem(name: "page", value: "\(page)"),
            URLQueryItem(name: "pageSize", value: "\(pageSize)")
        ]
        
        if let location = location {
            queryItems.append(URLQueryItem(name: "location", value: location))
        }
        
        if let sportId = sportId {
            queryItems.append(URLQueryItem(name: "sportId", value: "\(sportId)"))
        }
        
        let endpoint = buildEndpoint(path: "/popular-users", queryItems: queryItems)
        let headers = getAuthHeaders()
        
        return networkManager.requestWithAutoRefresh(
            endpoint: endpoint,
            method: .GET,
            headers: headers,
            type: SearchResponse<SearchUser>.self
        )
        .compactMap { response in
            if response.success {
                return response.data
            } else {
                print("❌ Popular users fetch failed: \(response.message ?? "Unknown error")")
                return nil
            }
        }
        .handleEvents(
            receiveOutput: { data in
                print("✅ Fetched \(data.items.count) popular users (page \(data.page))")
            },
            receiveCompletion: { completion in
                if case .failure(let error) = completion {
                    print("❌ Failed to fetch popular users: \(error)")
                }
            }
        )
        .eraseToAnyPublisher()
    }
    
    // MARK: - New Users
    func fetchNewUsers(location: String?, sportId: Int?, page: Int = 1, pageSize: Int = 10) -> AnyPublisher<SearchData<SearchUser>, Error> {
        var queryItems: [URLQueryItem] = [
            URLQueryItem(name: "page", value: "\(page)"),
            URLQueryItem(name: "pageSize", value: "\(pageSize)")
        ]
        
        if let location = location {
            queryItems.append(URLQueryItem(name: "location", value: location))
        }
        
        if let sportId = sportId {
            queryItems.append(URLQueryItem(name: "sportId", value: "\(sportId)"))
        }
        
        let endpoint = buildEndpoint(path: "/new-users", queryItems: queryItems)
        let headers = getAuthHeaders()
        
        return networkManager.requestWithAutoRefresh(
            endpoint: endpoint,
            method: .GET,
            headers: headers,
            type: SearchResponse<SearchUser>.self
        )
        .compactMap { response in
            if response.success {
                return response.data
            } else {
                print("❌ New users fetch failed: \(response.message ?? "Unknown error")")
                return nil
            }
        }
        .handleEvents(
            receiveOutput: { data in
                print("✅ Fetched \(data.items.count) new users (page \(data.page))")
            },
            receiveCompletion: { completion in
                if case .failure(let error) = completion {
                    print("❌ Failed to fetch new users: \(error)")
                }
            }
        )
        .eraseToAnyPublisher()
    }
    
    // MARK: - Active Users
    func fetchActiveUsers(location: String?, sportId: Int?, page: Int = 1, pageSize: Int = 10) -> AnyPublisher<SearchData<SearchUser>, Error> {
        var queryItems: [URLQueryItem] = [
            URLQueryItem(name: "page", value: "\(page)"),
            URLQueryItem(name: "pageSize", value: "\(pageSize)")
        ]
        
        if let location = location {
            queryItems.append(URLQueryItem(name: "location", value: location))
        }
        
        if let sportId = sportId {
            queryItems.append(URLQueryItem(name: "sportId", value: "\(sportId)"))
        }
        
        let endpoint = buildEndpoint(path: "/active-users", queryItems: queryItems)
        let headers = getAuthHeaders()
        
        return networkManager.requestWithAutoRefresh(
            endpoint: endpoint,
            method: .GET,
            headers: headers,
            type: SearchResponse<SearchUser>.self
        )
        .compactMap { response in
            if response.success {
                return response.data
            } else {
                print("❌ Active users fetch failed: \(response.message ?? "Unknown error")")
                return nil
            }
        }
        .handleEvents(
            receiveOutput: { data in
                print("✅ Fetched \(data.items.count) active users (page \(data.page))")
            },
            receiveCompletion: { completion in
                if case .failure(let error) = completion {
                    print("❌ Failed to fetch active users: \(error)")
                }
            }
        )
        .eraseToAnyPublisher()
    }
    
    // MARK: - Top Trainers
    func fetchTopTrainers(location: String?, sportId: Int?, page: Int = 1, pageSize: Int = 10) -> AnyPublisher<SearchData<SearchTrainer>, Error> {
        var queryItems: [URLQueryItem] = [
            URLQueryItem(name: "page", value: "\(page)"),
            URLQueryItem(name: "pageSize", value: "\(pageSize)")
        ]
        
        if let location = location {
            queryItems.append(URLQueryItem(name: "location", value: location))
        }
        
        if let sportId = sportId {
            queryItems.append(URLQueryItem(name: "sportId", value: "\(sportId)"))
        }
        
        let endpoint = buildEndpoint(path: "/top-trainers", queryItems: queryItems)
        let headers = getAuthHeaders()
        
        return networkManager.requestWithAutoRefresh(
            endpoint: endpoint,
            method: .GET,
            headers: headers,
            type: SearchResponse<SearchTrainer>.self
        )
        .compactMap { response in
            if response.success {
                return response.data
            } else {
                print("❌ Top trainers fetch failed: \(response.message ?? "Unknown error")")
                return nil
            }
        }
        .handleEvents(
            receiveOutput: { data in
                print("✅ Fetched \(data.items.count) top trainers (page \(data.page))")
            },
            receiveCompletion: { completion in
                if case .failure(let error) = completion {
                    print("❌ Failed to fetch top trainers: \(error)")
                }
            }
        )
        .eraseToAnyPublisher()
    }
    
    // MARK: - Private Helper Methods
    private func buildEndpoint(path: String, queryItems: [URLQueryItem]) -> String {
        var components = URLComponents(string: baseURL + path)
        components?.queryItems = queryItems
        return components?.url?.absoluteString ?? (baseURL + path)
    }
    
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

