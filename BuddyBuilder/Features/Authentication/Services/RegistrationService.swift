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
    private let baseURL = "http://192.168.100.76:5206/api/Auth"
    private let locationURL = "http://192.168.100.76:5206/api/Location"
    private let sportsURL = "http://192.168.100.76:5206/api/Sports"
    
    // MARK: - Registration
    func register(_ request: RegistrationRequest) -> AnyPublisher<RegistrationResponse, Error> {
        guard let requestData = try? JSONEncoder().encode(request) else {
            print("❌ Failed to encode registration request")
            return Fail(error: NetworkError.decodingError)
                .eraseToAnyPublisher()
        }
        
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
    
    // MARK: - Username Availability Check - FIXED: Direct Boolean Response
    func checkUsernameAvailability(_ username: String) -> AnyPublisher<Bool, Error> {
        let encodedUsername = username.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? username
        let endpoint = "\(baseURL)/check-username?username=\(encodedUsername)"
        
        print("🔍 Checking username availability:")
        print("URL: \(endpoint)")
        
        return networkManager.request(
            endpoint: endpoint,
            method: .GET,
            type: Bool.self // Direct Bool response
        )
        .handleEvents(
            receiveOutput: { apiResponse in
                print("✅ Username API returned: \(apiResponse) (true=taken, false=available)")
            },
            receiveCompletion: { completion in
                if case .failure(let error) = completion {
                    print("❌ Username check failed: \(error)")
                }
            }
        )
        .map { apiResponse in
            // API: true = taken, false = available
            // Function should return: true = available, false = taken
            return !apiResponse
        }
        .catch { error -> AnyPublisher<Bool, Error> in
            print("❌ Username availability check error: \(error)")
            // Network error durumunda false döndür (güvenli side - not available)
            return Just(false)
                .setFailureType(to: Error.self)
                .eraseToAnyPublisher()
        }
        .eraseToAnyPublisher()
    }
    
    // MARK: - Email Availability Check - FIXED: Direct Boolean Response
    func checkEmailAvailability(_ email: String) -> AnyPublisher<Bool, Error> {
        let encodedEmail = email.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? email
        let endpoint = "\(baseURL)/check-email?email=\(encodedEmail)"
        
        print("📧 Checking email availability:")
        print("URL: \(endpoint)")
        
        return networkManager.request(
            endpoint: endpoint,
            method: .GET,
            type: Bool.self // Direct Bool response
        )
        .handleEvents(
            receiveOutput: { apiResponse in
                print("✅ Email API returned: \(apiResponse) (true=taken, false=available)")
            },
            receiveCompletion: { completion in
                if case .failure(let error) = completion {
                    print("❌ Email check failed: \(error)")
                }
            }
        )
        .map { apiResponse in
            // API: true = taken, false = available
            // Function should return: true = available, false = taken
            return !apiResponse
        }
        .catch { error -> AnyPublisher<Bool, Error> in
            print("❌ Email availability check error: \(error)")
            // Network error durumunda false döndür (güvenli side - not available)
            return Just(false)
                .setFailureType(to: Error.self)
                .eraseToAnyPublisher()
        }
        .eraseToAnyPublisher()
    }
    
    // MARK: - Location Data (kept for potential future use)
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
        print("🏃‍♂️ Fetching available sports from: \(sportsURL)")
        
        return networkManager.request(
            endpoint: sportsURL,
            method: .GET,
            type: APIResponse<[Sport]>.self
        )
        .handleEvents(
            receiveOutput: { response in
                print("✅ Sports fetch response: success=\(response.success), count=\(response.data?.count ?? 0)")
            },
            receiveCompletion: { completion in
                if case .failure(let error) = completion {
                    print("❌ Sports fetch failed: \(error)")
                }
            }
        )
        .compactMap { response in
            response.success ? response.data : []
        }
        .eraseToAnyPublisher()
    }
}
