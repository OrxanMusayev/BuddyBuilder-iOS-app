// BuddyBuilder/Core/Cache/CentralCacheManager.swift

import Foundation
import UIKit

// MARK: - Central Cache Manager - Single Source of Truth
public class CentralCacheManager {
    static let shared = CentralCacheManager()
    
    // MARK: - Cache Types
    enum CacheType: String, CaseIterable {
        case profilePhoto = "profile_photo"
        case searchImages = "search_images"
        case popularUsers = "popular_users"
        case newUsers = "new_users"
        case searchUsers = "search_users"
        
        var keyPrefix: String {
            return "cache_\(self.rawValue)_"
        }
    }
    
    // MARK: - Current user tracking
    private var currentUserId: Int = 0
    private let userIdKey = "user_id"
    
    private init() {
        currentUserId = UserDefaults.standard.integer(forKey: userIdKey)
        print("🏗️ CentralCacheManager initialized for user: \(currentUserId)")
    }
    
    // MARK: - User Change Detection
    func checkUserChange() -> Bool {
        let newUserId = UserDefaults.standard.integer(forKey: userIdKey)
        
        if newUserId != currentUserId {
            print("🔄 User changed from \(currentUserId) to \(newUserId)")
            
            if newUserId == 0 {
                // User logged out
                print("👋 User logged out, clearing all caches")
                clearAllCaches()
            } else if currentUserId != 0 {
                // User switched
                print("🔄 User switched, clearing all caches")
                clearAllCaches()
            }
            
            currentUserId = newUserId
            return true
        }
        
        return false
    }
    
    // MARK: - Profile Photo Cache
    func saveProfilePhoto(imageData: Data, url: String) {
        guard currentUserId > 0 else { return }
        
        let imageKey = CacheType.profilePhoto.keyPrefix + "image"
        let urlKey = CacheType.profilePhoto.keyPrefix + "url"
        let userKey = CacheType.profilePhoto.keyPrefix + "user_id"
        let dateKey = CacheType.profilePhoto.keyPrefix + "date"
        
        UserDefaults.standard.set(imageData, forKey: imageKey)
        UserDefaults.standard.set(url, forKey: urlKey)
        UserDefaults.standard.set(currentUserId, forKey: userKey)
        UserDefaults.standard.set(Date(), forKey: dateKey)
        
        print("💾 Saved profile photo for user \(currentUserId): \(imageData.count) bytes")
    }
    
    func getProfilePhoto() -> (imageData: Data?, url: String?) {
        guard currentUserId > 0 else { return (nil, nil) }
        
        let imageKey = CacheType.profilePhoto.keyPrefix + "image"
        let urlKey = CacheType.profilePhoto.keyPrefix + "url"
        let userKey = CacheType.profilePhoto.keyPrefix + "user_id"
        
        let cachedUserId = UserDefaults.standard.integer(forKey: userKey)
        
        if cachedUserId == currentUserId {
            let imageData = UserDefaults.standard.data(forKey: imageKey)
            let url = UserDefaults.standard.string(forKey: urlKey)
            
            if imageData != nil {
                print("📱 Retrieved cached profile photo for user \(currentUserId)")
            }
            
            return (imageData, url)
        }
        
        return (nil, nil)
    }
    
    // MARK: - Search Image Cache
    private var searchImageCache: [String: SearchImageEntry] = [:]
    
    struct SearchImageEntry {
        let image: UIImage
        let timestamp: Date
        let userId: Int
        
        var isExpired: Bool {
            Date().timeIntervalSince(timestamp) > 300 // 5 minutes
        }
        
        var isValidForCurrentUser: Bool {
            return userId == CentralCacheManager.shared.currentUserId
        }
    }
    
    func saveSearchImage(_ image: UIImage, for url: String) {
        guard currentUserId > 0 else { return }
        
        let entry = SearchImageEntry(
            image: image,
            timestamp: Date(),
            userId: currentUserId
        )
        
        searchImageCache[url] = entry
        print("💾 Cached search image for user \(currentUserId): \(url)")
    }
    
    func getSearchImage(for url: String) -> UIImage? {
        guard let entry = searchImageCache[url] else { return nil }
        
        if entry.isValidForCurrentUser && !entry.isExpired {
            print("📱 Retrieved cached search image: \(url)")
            return entry.image
        }
        
        // Remove invalid/expired entry
        searchImageCache.removeValue(forKey: url)
        return nil
    }
    
    // MARK: - User Data Cache (In-Memory)
    private var userDataCache: [String: Any] = [:]
    
    func saveUserData<T: Codable>(_ data: [T], for type: CacheType) {
        guard currentUserId > 0 else { return }
        
        let key = "\(type.rawValue)_\(currentUserId)"
        userDataCache[key] = data
        
        print("💾 Cached \(data.count) items for \(type.rawValue) - user \(currentUserId)")
    }
    
    func getUserData<T: Codable>(for type: CacheType, as: T.Type) -> [T]? {
        guard currentUserId > 0 else { return nil }
        
        let key = "\(type.rawValue)_\(currentUserId)"
        
        if let data = userDataCache[key] as? [T] {
            print("📱 Retrieved cached \(type.rawValue) for user \(currentUserId)")
            return data
        }
        
        return nil
    }
    
    // MARK: - Cache Clearing Methods
    func clearCache(for type: CacheType) {
        print("cache type to clean: ", type)
        switch type {
        case .profilePhoto:
            clearProfilePhotoCache()
        case .searchImages:
            clearSearchImageCache()
        case .popularUsers, .newUsers, .searchUsers:
            clearUserDataCache(for: type)
        }
        
        print("🧹 Cleared \(type.rawValue) cache")
    }
    
    func clearAllCaches() {
        print("🧹 Clearing ALL caches...")
        
        // Clear UserDefaults cache keys
        let allKeys = UserDefaults.standard.dictionaryRepresentation().keys
        
        for cacheType in CacheType.allCases {
            let prefix = cacheType.keyPrefix
            let keysToRemove = allKeys.filter { $0.hasPrefix(prefix) }
            
            for key in keysToRemove {
                UserDefaults.standard.removeObject(forKey: key)
            }
        }
        
        // Clear in-memory caches
        searchImageCache.removeAll()
        userDataCache.removeAll()
        
        print("✅ All caches cleared")
    }
    
    private func clearProfilePhotoCache() {
        let keys = [
            CacheType.profilePhoto.keyPrefix + "image",
            CacheType.profilePhoto.keyPrefix + "url",
            CacheType.profilePhoto.keyPrefix + "user_id",
            CacheType.profilePhoto.keyPrefix + "date"
        ]
        
        keys.forEach { UserDefaults.standard.removeObject(forKey: $0) }
    }
    
    private func clearSearchImageCache() {
        searchImageCache.removeAll()
    }
    
    private func clearUserDataCache(for type: CacheType) {
        print("User cached data cleared");
        let keysToRemove = userDataCache.keys.filter { $0.hasPrefix(type.rawValue) }
        print(userDataCache.keys);
        keysToRemove.forEach { userDataCache.removeValue(forKey: $0) }
    }
    
    // MARK: - Cache Statistics
    func getCacheStats() -> String {
        let profilePhotoSize = getProfilePhoto().imageData?.count ?? 0
        let searchImageCount = searchImageCache.count
        let userDataCount = userDataCache.count
        
        return """
        📊 Cache Stats for User \(currentUserId):
        - Profile Photo: \(profilePhotoSize) bytes
        - Search Images: \(searchImageCount) items
        - User Data: \(userDataCount) collections
        """
    }
    
    func printCacheStats() {
        print(getCacheStats())
    }
    
    // MARK: - Cleanup expired entries
    func cleanupExpiredEntries() {
        let before = searchImageCache.count
        searchImageCache = searchImageCache.filter { !$0.value.isExpired && $0.value.isValidForCurrentUser }
        let after = searchImageCache.count
        
        if before > after {
            print("🧹 Cleaned up \(before - after) expired search image entries")
        }
    }
}

// MARK: - Cache Manager Extensions for specific use cases
extension CentralCacheManager {
    
    // MARK: - Profile Photo Helpers
    func hasValidProfilePhoto() -> Bool {
        let (imageData, _) = getProfilePhoto()
        return imageData != nil
    }
    
    func clearProfilePhoto() {
        clearCache(for: .profilePhoto)
    }
    
    func clearUserData() {
        clearCache(for: .popularUsers)
        clearCache(for: .newUsers)
    }
    
    // MARK: - Search Data Helpers
    func savePopularUsers<T: Codable>(_ users: [T]) {
        saveUserData(users, for: .popularUsers)
    }
    
    func getPopularUsers<T: Codable>(as type: T.Type) -> [T]? {
        return getUserData(for: .popularUsers, as: type)
    }
    
    func saveNewUsers<T: Codable>(_ users: [T]) {
        saveUserData(users, for: .newUsers)
    }
    
    func getNewUsers<T: Codable>(as type: T.Type) -> [T]? {
        return getUserData(for: .newUsers, as: type)
    }
    
    // MARK: - Force refresh (clear and reload)
    func forceRefreshUser() {
        print("🔄 Force refreshing for user \(currentUserId)")
        clearAllCaches()
    }
}

// MARK: - Notification Support
extension CentralCacheManager {
    func setupNotifications() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(userDidLogin),
            name: .userDidLogin,
            object: nil
        )
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(userDidLogout),
            name: .userDidLogout,
            object: nil
        )
        
        // Cleanup timer
        Timer.scheduledTimer(withTimeInterval: 300, repeats: true) { _ in
            self.cleanupExpiredEntries()
        }
    }
    
    @objc private func userDidLogin() {
        print("🔔 User login notification received in CacheManager")
        checkUserChange()
    }
    
    @objc private func userDidLogout() {
        print("🔔 User logout notification received in CacheManager")
        clearAllCaches()
        currentUserId = 0
    }
}
