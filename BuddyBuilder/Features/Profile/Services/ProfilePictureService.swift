// BuddyBuilder/Features/Profile/Services/ProfilePhotoService.swift - FIXED MODELS

import Foundation
import Combine
import UIKit

// MARK: - Profile Photo Cache Manager - FIXED WITH UNIQUE CACHE KEYS
class ProfilePhotoCache {
    static let shared = ProfilePhotoCache()
    
    // FIXED: Unique cache keys for different contexts
    private let profileImageKey = "cached_profile_photo_image"
    private let profileUrlKey = "cached_profile_photo_url"
    private let profileDateKey = "cached_profile_photo_date"
    private let currentUserIdKey = "cached_profile_user_id"
    
    private init() {}
    
    // FIXED: Save with current user ID for validation
    func savePhoto(imageData: Data, url: String) {
        let currentUserId = getCurrentUserId()
        UserDefaults.standard.set(imageData, forKey: profileImageKey)
        UserDefaults.standard.set(url, forKey: profileUrlKey)
        UserDefaults.standard.set(Date(), forKey: profileDateKey)
        UserDefaults.standard.set(currentUserId, forKey: currentUserIdKey)
        print("💾 Cached profile photo for user \(currentUserId): \(imageData.count) bytes")
    }
    
    // FIXED: Get cached image only if it belongs to current user
    func getCachedImage() -> Data? {
        let currentUserId = getCurrentUserId()
        let cachedUserId = UserDefaults.standard.integer(forKey: currentUserIdKey)
        
        // Only return cache if it belongs to current user
        if currentUserId == cachedUserId && currentUserId > 0 {
            return UserDefaults.standard.data(forKey: profileImageKey)
        } else {
            print("🗑️ Cache belongs to different user (\(cachedUserId) vs \(currentUserId)), clearing...")
            clearCache()
            return nil
        }
    }
    
    // FIXED: Get cached URL only if it belongs to current user
    func getCachedURL() -> String? {
        let currentUserId = getCurrentUserId()
        let cachedUserId = UserDefaults.standard.integer(forKey: currentUserIdKey)
        
        if currentUserId == cachedUserId && currentUserId > 0 {
            return UserDefaults.standard.string(forKey: profileUrlKey)
        } else {
            clearCache()
            return nil
        }
    }
    
    // Clear all cache
    func clearCache() {
        UserDefaults.standard.removeObject(forKey: profileImageKey)
        UserDefaults.standard.removeObject(forKey: profileUrlKey)
        UserDefaults.standard.removeObject(forKey: profileDateKey)
        UserDefaults.standard.removeObject(forKey: currentUserIdKey)
        print("🗑️ Cleared profile photo cache")
    }
    
    // FIXED: Clear cache when user changes
    func clearCacheForUserChange() {
        clearCache()
        print("🔄 Cleared profile cache due to user change")
    }
    
    // Check if cache exists and belongs to current user
    var hasCache: Bool {
        let currentUserId = getCurrentUserId()
        let cachedUserId = UserDefaults.standard.integer(forKey: currentUserIdKey)
        return getCachedImage() != nil && getCachedURL() != nil && currentUserId == cachedUserId
    }
    
    // FIXED: Helper to get current user ID
    private func getCurrentUserId() -> Int {
        return UserDefaults.standard.integer(forKey: "user_id")
    }
}

// MARK: - Profile Photo Result
struct ProfilePhotoResult {
    let imageData: Data?
    let url: String?
    
    init(imageData: Data? = nil, url: String? = nil) {
        self.imageData = imageData
        self.url = url
    }
}

// MARK: - FIXED: Profile Photo Models for API Response
// API döndürdüğü format: { "success": true, "data": "https://testimage.jpg", "message": "Profile Picture received." }
struct ProfilePhotoResponse: Codable {
    let success: Bool
    let message: String?
    let data: String? // FIXED: String instead of ProfilePhotoData object
    let errors: [String]?
    let timestamp: String
}

struct ProfilePhotoUploadResponse: Codable {
    let success: Bool
    let message: String?
    let data: ProfilePhotoUploadData? // Different structure for upload response
    let errors: [String]?
    let timestamp: String
}

// For upload responses, if API returns different structure
struct ProfilePhotoUploadData: Codable {
    let photoUrl: String?
    let uploadDate: String?
    let message: String?
}

struct ProfilePhotoDeleteResponse: Codable {
    let success: Bool
    let message: String?
    let data: String?
    let errors: [String]?
    let timestamp: String
}

// MARK: - Profile Photo Service Protocol (Updated)
protocol ProfilePhotoServiceProtocol {
    func fetchProfilePhoto() -> AnyPublisher<ProfilePhotoResult, Error>
    func uploadProfilePhoto(_ imageData: Data) -> AnyPublisher<ProfilePhotoResult, Error>
    func updateProfilePhoto(_ imageData: Data) -> AnyPublisher<ProfilePhotoResult, Error>
    func deleteProfilePhoto() -> AnyPublisher<Bool, Error>
    func refreshProfilePhotoFromAPI() -> AnyPublisher<ProfilePhotoResult, Error>
    func clearCacheOnUserChange() // NEW: Clear cache method
    
    // Legacy methods for compatibility
    func fetchProfilePhotoURL() -> AnyPublisher<String?, Error>
}

// MARK: - Profile Photo Service Implementation - FIXED FOR NEW API FORMAT
class ProfilePhotoService: ProfilePhotoServiceProtocol {
    private let networkManager = NetworkManager.shared
    private let baseURL = "http://192.168.100.74:5206/api/ProfilePhoto"
    private let cache = ProfilePhotoCache.shared
    
    // MARK: - NEW: Clear cache on user change
    func clearCacheOnUserChange() {
        cache.clearCacheForUserChange()
    }
    
    // MARK: - Fetch Profile Photo (Image Data + URL) - CACHE FIRST
    func fetchProfilePhoto() -> AnyPublisher<ProfilePhotoResult, Error> {
        // 1. First check cache for image data (with user validation)
        if let cachedImageData = cache.getCachedImage(),
           let cachedURL = cache.getCachedURL() {
            print("📱 Using cached profile photo: \(cachedImageData.count) bytes")
            return Just(ProfilePhotoResult(imageData: cachedImageData, url: cachedURL))
                .setFailureType(to: Error.self)
                .eraseToAnyPublisher()
        }
        
        // 2. If no cache, fetch from API ONCE
        print("📱 No cached photo found, fetching from API for the first time...")
        return refreshProfilePhotoFromAPI()
    }
    
    // MARK: - Force Refresh from API (downloads actual image) - FIXED FOR NEW RESPONSE FORMAT
    func refreshProfilePhotoFromAPI() -> AnyPublisher<ProfilePhotoResult, Error> {
        let headers = getAuthHeaders()
        
        print("🌐 Fetching profile photo URL from API: \(baseURL)/url")
        
        return networkManager.requestWithAutoRefresh(
            endpoint: "\(baseURL)/url",
            method: .GET,
            headers: headers,
            type: ProfilePhotoResponse.self
        )
        .flatMap { response -> AnyPublisher<ProfilePhotoResult, Error> in
            if response.success,
               let photoUrl = response.data, // FIXED: Direct string access
               !photoUrl.isEmpty {
                print("✅ Got photo URL from API: \(photoUrl)")
                // Now download the actual image
                return self.downloadImage(from: photoUrl)
            } else {
                print("ℹ️ User has no profile photo")
                self.cache.clearCache()
                return Just(ProfilePhotoResult())
                    .setFailureType(to: Error.self)
                    .eraseToAnyPublisher()
            }
        }
        .catch { error -> AnyPublisher<ProfilePhotoResult, Error> in
            print("❌ Error fetching photo: \(error)")
            return Just(ProfilePhotoResult())
                .setFailureType(to: Error.self)
                .eraseToAnyPublisher()
        }
        .eraseToAnyPublisher()
    }
    
    // MARK: - Download Image from URL
    private func downloadImage(from urlString: String) -> AnyPublisher<ProfilePhotoResult, Error> {
        guard let url = URL(string: urlString) else {
            return Fail(error: NetworkError.invalidURL)
                .eraseToAnyPublisher()
        }
        
        print("📥 Downloading image from: \(urlString)")
        
        return URLSession.shared.dataTaskPublisher(for: url)
            .map { data, response -> ProfilePhotoResult in
                print("✅ Downloaded image: \(data.count) bytes")
                // Cache the downloaded image
                self.cache.savePhoto(imageData: data, url: urlString)
                return ProfilePhotoResult(imageData: data, url: urlString)
            }
            .catch { error -> AnyPublisher<ProfilePhotoResult, Error> in
                print("❌ Failed to download image: \(error)")
                return Just(ProfilePhotoResult(url: urlString))
                    .setFailureType(to: Error.self)
                    .eraseToAnyPublisher()
            }
            .eraseToAnyPublisher()
    }
    
    // MARK: - Upload Profile Photo - UPDATES CACHE WITH IMAGE DATA
    func uploadProfilePhoto(_ imageData: Data) -> AnyPublisher<ProfilePhotoResult, Error> {
        print("📤 Uploading new profile photo: \(imageData.count) bytes")
        
        return createMultipartRequestWithAutoRefresh(
            imageData: imageData,
            endpoint: "\(baseURL)/upload",
            method: .POST
        )
        .map { url in
            if let url = url {
                print("✅ Upload successful, caching image data and URL")
                // Cache the uploaded image data immediately
                self.cache.savePhoto(imageData: imageData, url: url)
                return ProfilePhotoResult(imageData: imageData, url: url)
            }
            return ProfilePhotoResult()
        }
        .eraseToAnyPublisher()
    }
    
    // MARK: - Update Profile Photo - UPDATES CACHE WITH IMAGE DATA
    func updateProfilePhoto(_ imageData: Data) -> AnyPublisher<ProfilePhotoResult, Error> {
        print("📤 Updating profile photo: \(imageData.count) bytes")
        
        return createMultipartRequestWithAutoRefresh(
            imageData: imageData,
            endpoint: "\(baseURL)/update",
            method: .PUT
        )
        .map { url in
            if let url = url {
                print("✅ Update successful, caching new image data and URL")
                // Cache the updated image data immediately
                self.cache.savePhoto(imageData: imageData, url: url)
                return ProfilePhotoResult(imageData: imageData, url: url)
            }
            return ProfilePhotoResult()
        }
        .eraseToAnyPublisher()
    }
    
    // MARK: - Delete Profile Photo - CLEARS CACHE
    func deleteProfilePhoto() -> AnyPublisher<Bool, Error> {
        let headers = getAuthHeaders()
        
        print("🗑️ Deleting profile photo...")
        
        return networkManager.requestWithAutoRefresh(
            endpoint: "\(baseURL)/delete",
            method: .DELETE,
            headers: headers,
            type: ProfilePhotoDeleteResponse.self
        )
        .map { response in
            if response.success {
                print("✅ Profile photo deleted - clearing cache")
                self.cache.clearCache()
                return true
            } else {
                print("❌ Profile photo deletion failed")
                return false
            }
        }
        .catch { error in
            print("❌ Delete error: \(error)")
            return Just(false)
                .setFailureType(to: Error.self)
                .eraseToAnyPublisher()
        }
        .eraseToAnyPublisher()
    }
    
    // MARK: - Legacy method for compatibility
    func fetchProfilePhotoURL() -> AnyPublisher<String?, Error> {
        return fetchProfilePhoto()
            .map { $0.url }
            .eraseToAnyPublisher()
    }
    
    // MARK: - Helper Methods
    private func getAuthHeaders() -> [String: String] {
        guard let token = UserDefaults.standard.string(forKey: "auth_token") else {
            print("⚠️ No auth token found")
            return [:]
        }
        
        return ["Authorization": "Bearer \(token)"]
    }
    
    // MARK: - Multipart Request with Auto-Refresh - UPDATED FOR NEW RESPONSE FORMAT
    private func createMultipartRequestWithAutoRefresh(
        imageData: Data,
        endpoint: String,
        method: HTTPMethod
    ) -> AnyPublisher<String?, Error> {
        
        return Future<String?, Error> { promise in
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
                    if case NetworkError.unauthorized = error {
                        print("🔐 Photo upload received 401, attempting token refresh...")
                        
                        Task {
                            let refreshSuccess = await TokenManager.shared.refreshTokenIfNeeded()
                            
                            if refreshSuccess {
                                print("✅ Token refreshed, retrying photo upload...")
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
                                print("❌ Token refresh failed")
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
    
    // MARK: - Perform Multipart Upload - UPDATED FOR NEW RESPONSE FORMAT
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
        
        let boundary = "Boundary-\(UUID().uuidString)"
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        
        for (key, value) in headers {
            request.addValue(value, forHTTPHeaderField: key)
        }
        
        var body = Data()
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"file\"; filename=\"profile-photo.jpg\"\r\n".data(using: .utf8)!)
        body.append("Content-Type: image/jpeg\r\n\r\n".data(using: .utf8)!)
        body.append(imageData)
        body.append("\r\n".data(using: .utf8)!)
        body.append("--\(boundary)--\r\n".data(using: .utf8)!)
        
        request.httpBody = body
        
        print("🌐 \(method.rawValue) request to: \(endpoint)")
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 401 {
                completion(.failure(NetworkError.unauthorized))
                return
            }
            
            guard let data = data else {
                completion(.failure(NetworkError.noData))
                return
            }
            
            do {
                // FIXED: Try both response formats
                if let simpleResponse = try? JSONDecoder().decode(ProfilePhotoResponse.self, from: data) {
                    // Simple string response format
                    if simpleResponse.success {
                        let photoUrl = simpleResponse.data
                        print("✅ Upload response URL (simple): \(photoUrl ?? "nil")")
                        completion(.success(photoUrl))
                    } else {
                        completion(.failure(NetworkError.serverError(400)))
                    }
                } else {
                    // Complex object response format
                    let uploadResponse = try JSONDecoder().decode(ProfilePhotoUploadResponse.self, from: data)
                    
                    if uploadResponse.success {
                        let photoUrl = uploadResponse.data?.photoUrl
                        print("✅ Upload response URL (complex): \(photoUrl ?? "nil")")
                        completion(.success(photoUrl))
                    } else {
                        completion(.failure(NetworkError.serverError(400)))
                    }
                }
            } catch {
                print("❌ Upload response decode error: \(error)")
                completion(.failure(error))
            }
        }.resume()
    }
}

// MARK: - Mock Profile Photo Service
class MockProfilePhotoService: ProfilePhotoServiceProtocol {
    private let cache = ProfilePhotoCache.shared
    
    func clearCacheOnUserChange() {
        cache.clearCacheForUserChange()
    }
    
    func fetchProfilePhoto() -> AnyPublisher<ProfilePhotoResult, Error> {
        if let cachedImage = cache.getCachedImage(),
           let cachedURL = cache.getCachedURL() {
            return Just(ProfilePhotoResult(imageData: cachedImage, url: cachedURL))
                .setFailureType(to: Error.self)
                .eraseToAnyPublisher()
        }
        
        // Create mock image data
        let mockImage = UIImage(systemName: "person.circle.fill")!
        let mockData = mockImage.jpegData(compressionQuality: 0.8)!
        let mockUrl = "https://mock.url/photo.jpg"
        
        cache.savePhoto(imageData: mockData, url: mockUrl)
        
        return Just(ProfilePhotoResult(imageData: mockData, url: mockUrl))
            .setFailureType(to: Error.self)
            .delay(for: .seconds(1), scheduler: RunLoop.main)
            .eraseToAnyPublisher()
    }
    
    func refreshProfilePhotoFromAPI() -> AnyPublisher<ProfilePhotoResult, Error> {
        return fetchProfilePhoto()
    }
    
    func uploadProfilePhoto(_ imageData: Data) -> AnyPublisher<ProfilePhotoResult, Error> {
        let newUrl = "https://mock.url/new-photo.jpg"
        cache.savePhoto(imageData: imageData, url: newUrl)
        
        return Just(ProfilePhotoResult(imageData: imageData, url: newUrl))
            .setFailureType(to: Error.self)
            .delay(for: .seconds(1), scheduler: RunLoop.main)
            .eraseToAnyPublisher()
    }
    
    func updateProfilePhoto(_ imageData: Data) -> AnyPublisher<ProfilePhotoResult, Error> {
        let newUrl = "https://mock.url/updated-photo.jpg"
        cache.savePhoto(imageData: imageData, url: newUrl)
        
        return Just(ProfilePhotoResult(imageData: imageData, url: newUrl))
            .setFailureType(to: Error.self)
            .delay(for: .seconds(1), scheduler: RunLoop.main)
            .eraseToAnyPublisher()
    }
    
    func deleteProfilePhoto() -> AnyPublisher<Bool, Error> {
        cache.clearCache()
        
        return Just(true)
            .setFailureType(to: Error.self)
            .delay(for: .seconds(1), scheduler: RunLoop.main)
            .eraseToAnyPublisher()
    }
    
    func fetchProfilePhotoURL() -> AnyPublisher<String?, Error> {
        return fetchProfilePhoto()
            .map { $0.url }
            .eraseToAnyPublisher()
    }
}
