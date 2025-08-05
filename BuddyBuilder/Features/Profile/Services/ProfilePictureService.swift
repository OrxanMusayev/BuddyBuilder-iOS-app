// BuddyBuilder/Features/Profile/Services/ProfilePictureService.swift - FIXED

import Foundation
import Combine
import UIKit

// MARK: - Profile Photo Models - CORRECTED TO MATCH API
struct ProfilePhotoData: Codable {
    let photoUrl: String?
    let uploadDate: String?
    let message: String?
}

struct ProfilePhotoResponse: Codable {
    let success: Bool
    let message: String?
    let data: ProfilePhotoData?
    let errors: [String]?
    let timestamp: String
}

struct ProfilePhotoUploadResponse: Codable {
    let success: Bool
    let message: String?
    let data: ProfilePhotoData?
    let errors: [String]?
    let timestamp: String
}

// MARK: - Delete Photo Response (different structure)
struct ProfilePhotoDeleteResponse: Codable {
    let success: Bool
    let message: String?
    let data: String?  // Delete API returns "Deleted" as string
    let errors: [String]?
    let timestamp: String
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
    private let baseURL = "http://192.168.100.74:5206/api/ProfilePhoto"
    
    // MARK: - Get Profile Photo URL (with auto-refresh) - FIXED
    func fetchProfilePhotoURL() -> AnyPublisher<String?, Error> {
        let headers = getAuthHeaders()
        
        print("🌐 Fetching profile photo URL from: \(baseURL)/url")
        
        return networkManager.requestWithAutoRefresh(
            endpoint: "\(baseURL)/url",
            method: .GET,
            headers: headers,
            type: ProfilePhotoResponse.self
        )
        .map { response in
            print("📥 Profile photo response:")
            print("   Success: \(response.success)")
            print("   Message: \(response.message ?? "nil")")
            print("   Photo URL: \(response.data?.photoUrl ?? "nil")")
            print("   Upload Date: \(response.data?.uploadDate ?? "nil")")
            
            if response.success, let photoUrl = response.data?.photoUrl, !photoUrl.isEmpty {
                print("✅ Profile photo URL extracted: \(photoUrl)")
                return photoUrl
            } else {
                print("⚠️ No valid photo URL found in response")
                return nil
            }
        }
        .handleEvents(
            receiveOutput: { url in
                print("✅ Final profile photo URL: \(url ?? "nil")")
            },
            receiveCompletion: { completion in
                if case .failure(let error) = completion {
                    print("❌ Failed to fetch profile photo URL: \(error)")
                    Task { @MainActor in
                        AuthErrorHandler.shared.handleAuthError(error)
                    }
                }
            }
        )
        .eraseToAnyPublisher()
    }
    
    // MARK: - Upload Profile Photo (with auto-refresh) - FIXED
    func uploadProfilePhoto(_ imageData: Data) -> AnyPublisher<String?, Error> {
        print("📤 Uploading new profile photo...")
        return createMultipartRequestWithAutoRefresh(
            imageData: imageData,
            endpoint: "\(baseURL)/upload",
            method: .POST
        )
    }
    
    // MARK: - Update Profile Photo (with auto-refresh) - FIXED
    func updateProfilePhoto(_ imageData: Data) -> AnyPublisher<String?, Error> {
        print("📤 Updating existing profile photo...")
        return createMultipartRequestWithAutoRefresh(
            imageData: imageData,
            endpoint: "\(baseURL)/update",
            method: .PUT
        )
    }
    
    // MARK: - Delete Profile Photo (with auto-refresh) - FIXED
    func deleteProfilePhoto() -> AnyPublisher<Bool, Error> {
        let headers = getAuthHeaders()
        
        print("🗑️ Deleting profile photo...")
        
        return networkManager.requestWithAutoRefresh(
            endpoint: "\(baseURL)/delete",
            method: .DELETE,
            headers: headers,
            type: ProfilePhotoDeleteResponse.self  // Use correct delete response model
        )
        .map { response in
            print("📥 Delete photo response:")
            print("   Success: \(response.success)")
            print("   Message: \(response.message ?? "nil")")
            print("   Data: \(response.data ?? "nil")")
            
            if response.success {
                print("✅ Profile photo deleted successfully")
                return true
            } else {
                print("❌ Profile photo deletion failed")
                return false
            }
        }
        .handleEvents(
            receiveCompletion: { completion in
                if case .failure(let error) = completion {
                    print("❌ Delete profile photo error: \(error)")
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
    
    // MARK: - Multipart Request with Auto-Refresh - FIXED RESPONSE PARSING
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
                                    promise(retryResult)
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
    
    // MARK: - Perform Multipart Upload Helper - FIXED RESPONSE PARSING
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
        body.append("Content-Disposition: form-data; name=\"file\"; filename=\"profile-photo.jpg\"\r\n".data(using: .utf8)!)
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
            
            // FIXED: Parse the correct response structure
            do {
                // First, let's see what we actually received
                if let jsonString = String(data: data, encoding: .utf8) {
                    print("📥 Raw response JSON: \(jsonString)")
                }
                
                let uploadResponse = try JSONDecoder().decode(ProfilePhotoUploadResponse.self, from: data)
                
                print("📥 Parsed upload response:")
                print("   Success: \(uploadResponse.success)")
                print("   Message: \(uploadResponse.message ?? "nil")")
                print("   Photo URL: \(uploadResponse.data?.photoUrl ?? "nil")")
                print("   Upload Date: \(uploadResponse.data?.uploadDate ?? "nil")")
                
                if uploadResponse.success {
                    let photoUrl = uploadResponse.data?.photoUrl
                    print("✅ Photo upload successful with URL: \(photoUrl ?? "nil")")
                    completion(.success(photoUrl))
                } else {
                    let errorMsg = uploadResponse.message ?? "unknown error"
                    print("❌ Photo upload failed: \(errorMsg)")
                    completion(.failure(NetworkError.serverError(400)))
                }
            } catch {
                print("❌ JSON decode error: \(error)")
                // Try to print raw response for debugging
                if let jsonString = String(data: data, encoding: .utf8) {
                    print("📥 Failed to decode response: \(jsonString)")
                }
                completion(.failure(error))
            }
        }.resume()
    }
}

// MARK: - Mock Profile Photo Service (for testing) - UPDATED
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
