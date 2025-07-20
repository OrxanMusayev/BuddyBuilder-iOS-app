// BuddyBuilder/Features/Profile/Services/ProfilePictureService.swift - BASİLEŞTİRİLMİŞ

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

// MARK: - Profile Photo Service Protocol - SIMPLIFIED
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
    
    // MARK: - Get Profile Photo URL (with auto-refresh)
    func fetchProfilePhotoURL() -> AnyPublisher<String?, Error> {
        let headers = getAuthHeaders()
        
        return networkManager.requestWithAutoRefresh(
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
                print("✅ Profile photo URL fetched with auto-refresh: \(url ?? "nil")")
            },
            receiveCompletion: { completion in
                if case .failure(let error) = completion {
                    print("❌ Failed to fetch profile photo URL with auto-refresh: \(error)")
                    Task { @MainActor in
                        AuthErrorHandler.shared.handleAuthError(error)
                    }
                }
            }
        )
        .eraseToAnyPublisher()
    }
    
    // MARK: - Upload Profile Photo (with auto-refresh)
    func uploadProfilePhoto(_ imageData: Data) -> AnyPublisher<String?, Error> {
        return createMultipartRequestWithAutoRefresh(
            imageData: imageData,
            endpoint: "\(baseURL)/upload",
            method: .POST
        )
    }
    
    // MARK: - Update Profile Photo (with auto-refresh)
    func updateProfilePhoto(_ imageData: Data) -> AnyPublisher<String?, Error> {
        return createMultipartRequestWithAutoRefresh(
            imageData: imageData,
            endpoint: "\(baseURL)/update",
            method: .PUT
        )
    }
    
    // MARK: - Delete Profile Photo (with auto-refresh)
    func deleteProfilePhoto() -> AnyPublisher<Bool, Error> {
        let headers = getAuthHeaders()
        
        return networkManager.requestWithAutoRefresh(
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
                print(success ? "✅ Profile photo deleted successfully with auto-refresh" : "❌ Failed to delete profile photo")
            },
            receiveCompletion: { completion in
                if case .failure(let error) = completion {
                    print("❌ Delete profile photo error with auto-refresh: \(error)")
                    Task { @MainActor in
                        AuthErrorHandler.shared.handleAuthError(error)
                    }
                }
            }
        )
        .eraseToAnyPublisher()
    }
    
    // MARK: - Helper Methods
    private func getAuthHeaders() -> [String: String] {
        guard let token = UserDefaults.standard.string(forKey: "auth_token") else {
            print("⚠️ No auth token found")
            return [:]
        }
        
        return [
            "Authorization": "Bearer \(token)"
        ]
    }
    
    // MARK: - Multipart Request with Auto-Refresh
    private func createMultipartRequestWithAutoRefresh(
        imageData: Data,
        endpoint: String,
        method: HTTPMethod
    ) -> AnyPublisher<String?, Error> {
        
        return Future<String?, Error> { promise in
            // First try with current token
            let headers = self.getAuthHeaders()
            
            self.performMultipartUpload(
                imageData: imageData,
                endpoint: endpoint,
                method: method,
                headers: headers
            ) { result in
                switch result {
                case .success(let url):
                    promise(.success(url))
                    
                case .failure(let error):
                    // Check if it's 401 error
                    if case NetworkError.unauthorized = error {
                        print("🔐 Photo upload received 401, attempting token refresh...")
                        
                        Task {
                            let refreshSuccess = await TokenManager.shared.refreshTokenIfNeeded()
                            
                            if refreshSuccess {
                                print("✅ Token refreshed, retrying photo upload...")
                                // Retry with new token
                                let newHeaders = self.getAuthHeaders()
                                
                                self.performMultipartUpload(
                                    imageData: imageData,
                                    endpoint: endpoint,
                                    method: method,
                                    headers: newHeaders
                                ) { retryResult in
                                    switch retryResult {
                                    case .success(let url):
                                        promise(.success(url))
                                    case .failure(let retryError):
                                        promise(.failure(retryError))
                                    }
                                }
                            } else {
                                print("❌ Token refresh failed for photo upload")
                                await MainActor.run {
                                    AuthErrorHandler.shared.handleAuthError(error)
                                }
                                promise(.failure(NetworkError.unauthorized))
                            }
                        }
                    } else {
                        promise(.failure(error))
                    }
                }
            }
        }
        .eraseToAnyPublisher()
    }
    
    // MARK: - Perform Multipart Upload Helper
    private func performMultipartUpload(
        imageData: Data,
        endpoint: String,
        method: HTTPMethod,
        headers: [String: String],
        completion: @escaping (Result<String?, Error>) -> Void
    ) {
        guard let url = URL(string: endpoint) else {
            completion(.failure(NetworkError.invalidURL))
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
                completion(.failure(error))
                return
            }
            
            // Check for 401 status
            if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 401 {
                print("🔐 Received 401 for photo upload")
                completion(.failure(NetworkError.unauthorized))
                return
            }
            
            guard let data = data else {
                print("❌ No data received")
                completion(.failure(NetworkError.noData))
                return
            }
            
            do {
                let uploadResponse = try JSONDecoder().decode(ProfilePhotoUploadResponse.self, from: data)
                
                if uploadResponse.success {
                    print("✅ Photo upload successful: \(uploadResponse.url ?? "no URL")")
                    completion(.success(uploadResponse.url))
                } else {
                    print("❌ Photo upload failed: \(uploadResponse.message ?? "unknown error")")
                    completion(.failure(NetworkError.serverError(400)))
                }
            } catch {
                print("❌ JSON decode error: \(error)")
                completion(.failure(error))
            }
        }.resume()
    }
}

// MARK: - Mock Profile Photo Service (for testing)
class MockProfilePhotoService: ProfilePhotoServiceProtocol {
    func fetchProfilePhotoURL() -> AnyPublisher<String?, Error> {
        return Just("https://via.placeholder.com/150x150/FF6B35/FFFFFF?text=User")
            .setFailureType(to: Error.self)
            .delay(for: .seconds(1), scheduler: RunLoop.main)
            .eraseToAnyPublisher()
    }
    
    func uploadProfilePhoto(_ imageData: Data) -> AnyPublisher<String?, Error> {
        return Just("https://via.placeholder.com/150x150/FF6B35/FFFFFF?text=NEW")
            .setFailureType(to: Error.self)
            .delay(for: .seconds(2), scheduler: RunLoop.main)
            .eraseToAnyPublisher()
    }
    
    func updateProfilePhoto(_ imageData: Data) -> AnyPublisher<String?, Error> {
        return Just("https://via.placeholder.com/150x150/FF6B35/FFFFFF?text=UPD")
            .setFailureType(to: Error.self)
            .delay(for: .seconds(2), scheduler: RunLoop.main)
            .eraseToAnyPublisher()
    }
    
    func deleteProfilePhoto() -> AnyPublisher<Bool, Error> {
        return Just(true)
            .setFailureType(to: Error.self)
            .delay(for: .seconds(1), scheduler: RunLoop.main)
            .eraseToAnyPublisher()
    }
}
