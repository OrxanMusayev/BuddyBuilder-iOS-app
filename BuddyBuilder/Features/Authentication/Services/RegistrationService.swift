// BuddyBuilder/Features/Authentication/Services/RegistrationService.swift

import Foundation
import Combine

// MARK: - Registration Service Protocol
protocol RegistrationServiceProtocol {
    func register(_ request: RegistrationRequest) -> AnyPublisher<RegistrationResponse, Error>
    func checkUsernameAvailability(_ username: String) -> AnyPublisher<Bool, Error>
    func checkEmailAvailability(_ email: String) -> AnyPublisher<Bool, Error>
    func fetchCountries() -> AnyPublisher<[Country], Error>
    func fetchCities(countryId: Int) -> AnyPublisher<[City], Error>
    func fetchAvailableSports() -> AnyPublisher<[Sport], Error>
}

// MARK: - Registration Service Implementation
class RegistrationService: RegistrationServiceProtocol {
    private let networkManager = NetworkManager.shared
    private let baseURL = "http://localhost:5206/api/Auth"
    private let locationURL = "http://localhost:5206/api/Location"
    private let sportsURL = "http://localhost:5206/api/Sports"
    
    // MARK: - Registration
    func register(_ request: RegistrationRequest) -> AnyPublisher<RegistrationResponse, Error> {
        guard let requestData = try? JSONEncoder().encode(request) else {
            print("❌ Failed to encode registration request")
            return Fail(error: NetworkError.decodingError)
                .eraseToAnyPublisher()
        }
        
        // Debug: Request'i yazdır
        print("🚀 REGISTRATION REQUEST:")
        print("URL: \(baseURL)/register")
        print("Body: \(String(data: requestData, encoding: .utf8) ?? "nil")")
        
        return networkManager.request(
            endpoint: "\(baseURL)/register",
            method: .POST,
            body: requestData,
            type: RegistrationResponse.self
        )
    }
    
    // MARK: - Username/Email Availability Check
    func checkUsernameAvailability(_ username: String) -> AnyPublisher<Bool, Error> {
        let encodedUsername = username.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? username
        let endpoint = "\(baseURL)/check-username?username=\(encodedUsername)"
        
        return networkManager.request(
            endpoint: endpoint,
            method: .GET,
            type: APIResponse<Bool>.self
        )
        .map { response in
            response.success && (response.data ?? false)
        }
        .eraseToAnyPublisher()
    }
    
    func checkEmailAvailability(_ email: String) -> AnyPublisher<Bool, Error> {
        let encodedEmail = email.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? email
        let endpoint = "\(baseURL)/check-email?email=\(encodedEmail)"
        
        return networkManager.request(
            endpoint: endpoint,
            method: .GET,
            type: APIResponse<Bool>.self
        )
        .map { response in
            response.success && (response.data ?? false)
        }
        .eraseToAnyPublisher()
    }
    
    // MARK: - Location Data
    func fetchCountries() -> AnyPublisher<[Country], Error> {
        return networkManager.request(
            endpoint: "\(locationURL)/countries",
            method: .GET,
            type: APIResponse<[Country]>.self
        )
        .compactMap { response in
            response.success ? response.data : []
        }
        .eraseToAnyPublisher()
    }
    
    func fetchCities(countryId: Int) -> AnyPublisher<[City], Error> {
        return networkManager.request(
            endpoint: "\(locationURL)/cities?countryId=\(countryId)",
            method: .GET,
            type: APIResponse<[City]>.self
        )
        .compactMap { response in
            response.success ? response.data : []
        }
        .eraseToAnyPublisher()
    }
    
    // MARK: - Sports Data
    func fetchAvailableSports() -> AnyPublisher<[Sport], Error> {
        return networkManager.request(
            endpoint: sportsURL,
            method: .GET,
            type: APIResponse<[Sport]>.self
        )
        .compactMap { response in
            response.success ? response.data : []
        }
        .eraseToAnyPublisher()
    }
}

// MARK: - Mock Registration Service
class MockRegistrationService: RegistrationServiceProtocol {
    func register(_ request: RegistrationRequest) -> AnyPublisher<RegistrationResponse, Error> {
        // Simulate network delay
        return Just(
            RegistrationResponse(
                success: true,
                message: "Registration successful",
                data: LoginData(
                    userId: 123,
                    username: request.userName,
                    email: request.email,
                    accessToken: "mock_access_token_12345",
                    refreshToken: "mock_refresh_token_12345",
                    isProfileComplete: true,
                    loginTime: ISO8601DateFormatter().string(from: Date())
                ),
                errors: nil,
                timestamp: ISO8601DateFormatter().string(from: Date())
            )
        )
        .delay(for: .seconds(2), scheduler: RunLoop.main)
        .setFailureType(to: Error.self)
        .eraseToAnyPublisher()
    }
    
    func checkUsernameAvailability(_ username: String) -> AnyPublisher<Bool, Error> {
        // Simulate some usernames as taken
        let takenUsernames = ["admin", "test", "user", "john", "jane"]
        let isAvailable = !takenUsernames.contains(username.lowercased())
        
        return Just(isAvailable)
            .delay(for: .seconds(0.5), scheduler: RunLoop.main)
            .setFailureType(to: Error.self)
            .eraseToAnyPublisher()
    }
    
    func checkEmailAvailability(_ email: String) -> AnyPublisher<Bool, Error> {
        // Simulate some emails as taken
        let takenEmails = ["test@example.com", "admin@example.com", "user@example.com"]
        let isAvailable = !takenEmails.contains(email.lowercased())
        
        return Just(isAvailable)
            .delay(for: .seconds(0.5), scheduler: RunLoop.main)
            .setFailureType(to: Error.self)
            .eraseToAnyPublisher()
    }
    
    func fetchCountries() -> AnyPublisher<[Country], Error> {
        let mockCountries = [
            Country(id: 1, name: "Turkey", code: "TR", cities: nil),
            Country(id: 2, name: "Azerbaijan", code: "AZ", cities: nil),
            Country(id: 3, name: "Georgia", code: "GE", cities: nil),
            Country(id: 4, name: "United States", code: "US", cities: nil),
            Country(id: 5, name: "Germany", code: "DE", cities: nil)
        ]
        
        return Just(mockCountries)
            .delay(for: .seconds(0.5), scheduler: RunLoop.main)
            .setFailureType(to: Error.self)
            .eraseToAnyPublisher()
    }
    
    func fetchCities(countryId: Int) -> AnyPublisher<[City], Error> {
        let mockCities: [City]
        
        switch countryId {
        case 1: // Turkey
            mockCities = [
                City(id: 1, name: "Istanbul", countryId: 1),
                City(id: 2, name: "Ankara", countryId: 1),
                City(id: 3, name: "Izmir", countryId: 1),
                City(id: 4, name: "Antalya", countryId: 1)
            ]
        case 2: // Azerbaijan
            mockCities = [
                City(id: 5, name: "Baku", countryId: 2),
                City(id: 6, name: "Ganja", countryId: 2),
                City(id: 7, name: "Sumqayit", countryId: 2)
            ]
        case 3: // Georgia
            mockCities = [
                City(id: 8, name: "Tbilisi", countryId: 3),
                City(id: 9, name: "Batumi", countryId: 3),
                City(id: 10, name: "Zugdidi", countryId: 3),
                City(id: 11, name: "Kutaisi", countryId: 3)
            ]
        default:
            mockCities = []
        }
        
        return Just(mockCities)
            .delay(for: .seconds(0.3), scheduler: RunLoop.main)
            .setFailureType(to: Error.self)
            .eraseToAnyPublisher()
    }
    
    func fetchAvailableSports() -> AnyPublisher<[Sport], Error> {
        let mockSports = [
            Sport(id: 1, name: "Basketball", description: "Team sport played on a court", imageUrl: nil, defaultEventImageUrl: nil),
            Sport(id: 2, name: "Tennis", description: "Racket sport", imageUrl: nil, defaultEventImageUrl: nil),
            Sport(id: 3, name: "Soccer", description: "Football", imageUrl: nil, defaultEventImageUrl: nil),
            Sport(id: 4, name: "Swimming", description: "Water sport", imageUrl: nil, defaultEventImageUrl: nil),
            Sport(id: 5, name: "Volleyball", description: "Team sport with net", imageUrl: nil, defaultEventImageUrl: nil),
            Sport(id: 6, name: "Running", description: "Individual endurance sport", imageUrl: nil, defaultEventImageUrl: nil),
            Sport(id: 7, name: "Cycling", description: "Bike sport", imageUrl: nil, defaultEventImageUrl: nil),
            Sport(id: 8, name: "Fitness", description: "General fitness activities", imageUrl: nil, defaultEventImageUrl: nil)
        ]
        
        return Just(mockSports)
            .delay(for: .seconds(0.5), scheduler: RunLoop.main)
            .setFailureType(to: Error.self)
            .eraseToAnyPublisher()
    }
}
