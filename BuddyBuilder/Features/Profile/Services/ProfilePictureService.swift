// BuddyBuilder/Features/Profile/Services/ProfilePhotoService.swift

import Foundation
import Combine
import UIKit

// MARK: - Profile Photo Models
struct ProfilePhotoResponse: Codable {
    let url: String?
    let message: String?
    let success: Bool
}

struct ProfilePhotoUploadResponse: Codable {
    let success: Bool
    let message: String?
    let url: String?
}

// MARK: - Profile Photo Service Protocol
protocol ProfilePhotoServiceProtocol {
    func fetchProfilePhotoURL() -> AnyPublisher<String?, Error>
    func uploadProfilePhoto(_ imageData: Data) -> AnyPublisher<String?, Error>
    func updateProfilePhoto(_ imageData: Data) -> AnyPublisher<String?, Error>
    func deleteProfilePhoto() -> AnyPublisher<Bool, Error>
}

// MARK: - Profile Photo Service Implementation
class ProfilePhotoService: ProfilePhotoServiceProtocol {
    private let networkManager = NetworkManager.shared
    private let baseURL = "http://localhost:5206/api/ProfilePhoto"
    
    // MARK: - Get Profile Photo URL
    func fetchProfilePhotoURL() -> AnyPublisher<String?, Error> {
        let headers = getAuthHeaders()
        
        return networkManager.request(
            endpoint: "\(baseURL)/url",
            method: .GET,
            headers: headers,
            type: ProfilePhotoResponse.self
        )
        .map { response in
            return response.success ? response.url : nil
        }
        .handleEvents(
            receiveOutput: { url in
                print("✅ Profile photo URL fetched: \(url ?? "nil")")
            },
            receiveCompletion: { completion in
                if case .failure(let error) = completion {
                    print("❌ Failed to fetch profile photo URL: \(error)")
                }
            }
        )
        .eraseToAnyPublisher()
    }
    
    // MARK: - Upload Profile Photo (POST)
    func uploadProfilePhoto(_ imageData: Data) -> AnyPublisher<String?, Error> {
        let headers = getAuthHeaders()
        
        return createMultipartRequest(imageData: imageData, endpoint: "\(baseURL)/upload", method: .POST, headers: headers)
    }
    
    // MARK: - Update Profile Photo (PUT)
    func updateProfilePhoto(_ imageData: Data) -> AnyPublisher<String?, Error> {
        let headers = getAuthHeaders()
        
        return createMultipartRequest(imageData: imageData, endpoint: "\(baseURL)/update", method: .PUT, headers: headers)
    }
    
    // MARK: - Delete Profile Photo
    func deleteProfilePhoto() -> AnyPublisher<Bool, Error> {
        let headers = getAuthHeaders()
        
        return networkManager.request(
            endpoint: "\(baseURL)/delete",
            method: .DELETE,
            headers: headers,
            type: ProfilePhotoResponse.self
        )
        .map { response in
            return response.success
        }
        .handleEvents(
            receiveOutput: { success in
                print(success ? "✅ Profile photo deleted successfully" : "❌ Failed to delete profile photo")
            },
            receiveCompletion: { completion in
                if case .failure(let error) = completion {
                    print("❌ Delete profile photo error: \(error)")
                }
            }
        )
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
    
    private func createMultipartRequest(imageData: Data, endpoint: String, method: HTTPMethod, headers: [String: String]) -> AnyPublisher<String?, Error> {
        return Future<String?, Error> { promise in
            guard let url = URL(string: endpoint) else {
                promise(.failure(NetworkError.invalidURL))
                return
            }
            
            var request = URLRequest(url: url)
            request.httpMethod = method.rawValue
            request.timeoutInterval = 30
            
            // Create multipart boundary
            let boundary = "Boundary-\(UUID().uuidString)"
            request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
            
            // Add auth headers
            for (key, value) in headers {
                request.addValue(value, forHTTPHeaderField: key)
            }
            
            // Create multipart body
            var body = Data()
            
            // Add image data
            body.append("--\(boundary)\r\n".data(using: .utf8)!)
            body.append("Content-Disposition: form-data; name=\"file\"; filename=\"profile.jpg\"\r\n".data(using: .utf8)!)
            body.append("Content-Type: image/jpeg\r\n\r\n".data(using: .utf8)!)
            body.append(imageData)
            body.append("\r\n".data(using: .utf8)!)
            body.append("--\(boundary)--\r\n".data(using: .utf8)!)
            
            request.httpBody = body
            
            print("🌐 \(method.rawValue) request to: \(endpoint)")
            print("📦 Image data size: \(imageData.count) bytes")
            
            URLSession.shared.dataTask(with: request) { data, response, error in
                if let error = error {
                    print("❌ Network error: \(error)")
                    promise(.failure(error))
                    return
                }
                
                guard let data = data else {
                    print("❌ No data received")
                    promise(.failure(NetworkError.noData))
                    return
                }
                
                do {
                    let uploadResponse = try JSONDecoder().decode(ProfilePhotoUploadResponse.self, from: data)
                    
                    if uploadResponse.success {
                        print("✅ Photo upload successful: \(uploadResponse.url ?? "no URL")")
                        promise(.success(uploadResponse.url))
                    } else {
                        print("❌ Photo upload failed: \(uploadResponse.message ?? "unknown error")")
                        promise(.failure(NetworkError.serverError(400)))
                    }
                } catch {
                    print("❌ JSON decode error: \(error)")
                    promise(.failure(error))
                }
            }.resume()
        }
        .eraseToAnyPublisher()
    }
}

// MARK: - Mock Profile Photo Service (for testing)
class MockProfilePhotoService: ProfilePhotoServiceProtocol {
    func fetchProfilePhotoURL() -> AnyPublisher<String?, Error> {
        // Mock response with delay
        return Just("https://via.placeholder.com/150x150/FF6B35/FFFFFF?text=User")
            .setFailureType(to: Error.self)
            .delay(for: .seconds(1), scheduler: RunLoop.main)
            .eraseToAnyPublisher()
    }
    
    func uploadProfilePhoto(_ imageData: Data) -> AnyPublisher<String?, Error> {
        // Mock upload success
        return Just("https://via.placeholder.com/150x150/FF6B35/FFFFFF?text=NEW")
            .setFailureType(to: Error.self)
            .delay(for: .seconds(2), scheduler: RunLoop.main)
            .eraseToAnyPublisher()
    }
    
    func updateProfilePhoto(_ imageData: Data) -> AnyPublisher<String?, Error> {
        // Mock update success
        return Just("https://via.placeholder.com/150x150/FF6B35/FFFFFF?text=UPD")
            .setFailureType(to: Error.self)
            .delay(for: .seconds(2), scheduler: RunLoop.main)
            .eraseToAnyPublisher()
    }
    
    func deleteProfilePhoto() -> AnyPublisher<Bool, Error> {
        // Mock delete success
        return Just(true)
            .setFailureType(to: Error.self)
            .delay(for: .seconds(1), scheduler: RunLoop.main)
            .eraseToAnyPublisher()
    }
}
