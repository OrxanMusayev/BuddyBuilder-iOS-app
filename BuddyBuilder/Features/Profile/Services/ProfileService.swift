// BuddyBuilder/Services/ProfileService.swift

import Foundation
import Combine

// MARK: - Profile Service Protocol
protocol ProfileServiceProtocol {
    func addSports(_ sports: [AddSportRequest]) -> AnyPublisher<Bool, Error>
    func updateSportExperience(sportId: Int, experienceLevel: Int) -> AnyPublisher<Bool, Error>
    func deleteSport(sportId: Int) -> AnyPublisher<Bool, Error>
}

// MARK: - Profile Service Implementation
class ProfileService: ProfileServiceProtocol {
    private let networkManager: NetworkManager
    private let tokenManager: TokenManager
    private let baseURL = "http://192.168.100.76:5206/api/Profile";
    
    init(networkManager: NetworkManager = NetworkManager.shared,
         tokenManager: TokenManager = TokenManager.shared) {
        self.networkManager = networkManager
        self.tokenManager = tokenManager
    }
    
    // MARK: - Add Sports to Profile
    func addSports(_ sports: [AddSportRequest]) -> AnyPublisher<Bool, Error> {
        guard let token = UserDefaults.standard.string(forKey: "auth_token") else {
            return Fail(error: ProfileServiceError.unauthorized)
                .eraseToAnyPublisher()
        }
        
        let headers = [
            "Authorization": "Bearer \(token)",
            "Content-Type": "application/json"
        ]
        
        do {
            let body = try JSONEncoder().encode(sports)
            
            return networkManager.request(
                endpoint: "\(baseURL)/add-sports",
                method: .POST,
                body: body,
                headers: headers,
                type: EmptyResponse.self
            )
            .map { _ -> Bool in
                // API call successful
                return true
            }
            .catch { error -> AnyPublisher<Bool, Error> in
                print("❌ ProfileService - Add sports failed: \(error)")
                return Fail(error: error)
                    .eraseToAnyPublisher()
            }
            .eraseToAnyPublisher()
        } catch {
            return Fail(error: ProfileServiceError.encodingFailed)
                .eraseToAnyPublisher()
        }
    }
    
    func updateSportExperience(sportId: Int, experienceLevel: Int) -> AnyPublisher<Bool, Error> {
            guard let token = UserDefaults.standard.string(forKey: "auth_token") else {
                return Fail(error: ProfileServiceError.unauthorized)
                    .eraseToAnyPublisher()
            }
            
            guard let url = URL(string: "\(baseURL)/update-experience") else {
                return Fail(error: ProfileServiceError.invalidURL)
                    .eraseToAnyPublisher()
            }
            
            let requestBody = UpdateExperienceRequest(sportId: sportId, experienceLevel: experienceLevel)
            
            do {
                let body = try JSONEncoder().encode(requestBody)
                
                var request = URLRequest(url: url)
                request.httpMethod = "POST"
                request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
                request.setValue("application/json", forHTTPHeaderField: "Content-Type")
                request.httpBody = body
                
                return URLSession.shared.dataTaskPublisher(for: request)
                    .map { (data, response) -> Bool in
                        guard let httpResponse = response as? HTTPURLResponse else {
                            return false
                        }
                        return httpResponse.statusCode >= 200 && httpResponse.statusCode < 300
                    }
                    .mapError { error -> Error in
                        print("❌ ProfileService - Update experience failed: \(error)")
                        return error
                    }
                    .eraseToAnyPublisher()
            } catch {
                return Fail(error: ProfileServiceError.encodingFailed)
                    .eraseToAnyPublisher()
            }
        }
    
    func deleteSport(sportId: Int) -> AnyPublisher<Bool, Error> {
            guard let token = UserDefaults.standard.string(forKey: "auth_token") else {
                return Fail(error: ProfileServiceError.unauthorized)
                    .eraseToAnyPublisher()
            }
            
            // Query parameter format: /delete-sport?sportId=6
            guard let url = URL(string: "\(baseURL)/delete-sport?sportId=\(sportId)") else {
                return Fail(error: ProfileServiceError.invalidURL)
                    .eraseToAnyPublisher()
            }
            
            // Debug: Print request details
            print("🔍 ProfileService - deleteSport")
            print("📤 URL: \(url)")
            print("📤 SportId: \(sportId)")
            print("📤 Method: DELETE (Query Parameter)")
            
            var request = URLRequest(url: url)
            request.httpMethod = "DELETE"
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            // No body needed for query parameter approach
            
            return URLSession.shared.dataTaskPublisher(for: request)
                .map { (data, response) -> Bool in
                    guard let httpResponse = response as? HTTPURLResponse else {
                        return false
                    }
                    print("📥 Response Status: \(httpResponse.statusCode)")
                    return httpResponse.statusCode >= 200 && httpResponse.statusCode < 300
                }
                .mapError { error -> Error in
                    print("❌ ProfileService - Delete sport failed: \(error)")
                    return error
                }
                .eraseToAnyPublisher()
        }
}


// MARK: - Request Models
struct UpdateExperienceRequest: Codable {
    let sportId: Int
    let experienceLevel: Int
}


struct DeleteSportRequest: Codable {
    let sportId: Int
}

// MARK: - Profile Service Errors
enum ProfileServiceError: Error, LocalizedError {
    case unauthorized
    case encodingFailed
    case invalidResponse
    case invalidURL
    case serverError(statusCode: Int)
    
    var errorDescription: String? {
        switch self {
        case .unauthorized:
            return "User is not authenticated"
        case .encodingFailed:
            return "Failed to encode request data"
        case .invalidResponse:
            return "Invalid response from server"
        case .invalidURL:
            return "Invalid URL"
        case .serverError(let statusCode):
            return "Server error with status code: \(statusCode)"
        }
    }
}
