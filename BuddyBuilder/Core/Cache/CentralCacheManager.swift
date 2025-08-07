// BuddyBuilder/Core/Managers/CentralCacheManager.swift - UPDATED: ONLY IMAGE CACHING

import Foundation
import UIKit

// MARK: - Image Cache Entry (Only for images)
struct ImageCacheEntry {
    let image: UIImage
    let timestamp: Date
    let userId: Int // Track which user this image belongs to
    
    var isExpired: Bool {
        Date().timeIntervalSince(timestamp) > CentralCacheManager.cacheExpirationInterval
    }
    
    var belongsToCurrentUser: Bool {
        let currentUserId = UserDefaults.standard.integer(forKey: "user_id")
        return userId == currentUserId && currentUserId > 0
    }
}

// MARK: - Central Cache Manager - ONLY FOR IMAGES (NO USER DATA)
class CentralCacheManager {
    static let shared = CentralCacheManager()
    
    // Cache expiration time: 10 minutes for profile images, 5 minutes for search images
    static let cacheExpirationInterval: TimeInterval = 600 // 10 minutes for profile images
    static let searchCacheExpirationInterval: TimeInterval = 300 // 5 minutes for search images
    
    // ONLY image caches - NO USER DATA CACHE
    private var profileImageCache: [String: ImageCacheEntry] = [:]
    private var searchImageCache: [String: ImageCacheEntry] = [:]
    
    private let cacheQueue = DispatchQueue(label: "com.buddybuilder.imagecache", attributes: .concurrent)
    
    // Track current user for cache validation
    private var lastKnownUserId: Int = 0
    
    private init() {
        lastKnownUserId = UserDefaults.standard.integer(forKey: "user_id")
        startCleanupTimer()
    }
    
    // MARK: - User Change Detection (Only for images)
    func checkUserChange() {
        let currentUserId = UserDefaults.standard.integer(forKey: "user_id")
        
        if currentUserId != lastKnownUserId {
            print("🔄 CentralCache: User changed from \(lastKnownUserId) to \(currentUserId), clearing IMAGE caches...")
            clearAllImageCaches()
            lastKnownUserId = currentUserId
        }
    }
    
    // MARK: - Profile Image Cache Methods
    func getProfileImage(for url: String) -> UIImage? {
        checkUserChange()
        
        return cacheQueue.sync {
            if let entry = profileImageCache[url] {
                if !entry.isExpired && entry.belongsToCurrentUser {
                    print("✅ Profile image cache hit: \(url)")
                    return entry.image
                } else {
                    if entry.isExpired {
                        print("⏰ Profile image cache expired: \(url)")
                    } else {
                        print("👤 Profile image cache belongs to different user: \(url)")
                    }
                    profileImageCache.removeValue(forKey: url)
                }
            }
            return nil
        }
    }
    
    func saveProfileImage(_ image: UIImage, for url: String) {
        let currentUserId = UserDefaults.standard.integer(forKey: "user_id")
        
        cacheQueue.async(flags: .barrier) {
            self.profileImageCache[url] = ImageCacheEntry(
                image: image,
                timestamp: Date(),
                userId: currentUserId
            )
            print("💾 Profile image cached for user \(currentUserId): \(url)")
        }
    }
    
    // MARK: - Search Image Cache Methods
    func getSearchImage(for url: String) -> UIImage? {
        checkUserChange()
        
        return cacheQueue.sync {
            if let entry = searchImageCache[url] {
                // Use shorter expiration for search images
                let isExpired = Date().timeIntervalSince(entry.timestamp) > Self.searchCacheExpirationInterval
                
                if !isExpired && entry.belongsToCurrentUser {
                    print("✅ Search image cache hit: \(url)")
                    return entry.image
                } else {
                    if isExpired {
                        print("⏰ Search image cache expired: \(url)")
                    } else {
                        print("👤 Search image cache belongs to different user: \(url)")
                    }
                    searchImageCache.removeValue(forKey: url)
                }
            }
            return nil
        }
    }
    
    func saveSearchImage(_ image: UIImage, for url: String) {
        let currentUserId = UserDefaults.standard.integer(forKey: "user_id")
        
        cacheQueue.async(flags: .barrier) {
            self.searchImageCache[url] = ImageCacheEntry(
                image: image,
                timestamp: Date(),
                userId: currentUserId
            )
            print("💾 Search image cached for user \(currentUserId): \(url)")
        }
    }
    
    // MARK: - Clear Methods (Only images)
    func clearAllImageCaches() {
        cacheQueue.async(flags: .barrier) {
            let profileCount = self.profileImageCache.count
            let searchCount = self.searchImageCache.count
            
            self.profileImageCache.removeAll()
            self.searchImageCache.removeAll()
            
            print("🗑️ Cleared all image caches: \(profileCount) profile images, \(searchCount) search images")
        }
    }
    
    func clearProfileImageCache() {
        cacheQueue.async(flags: .barrier) {
            let count = self.profileImageCache.count
            self.profileImageCache.removeAll()
            print("🗑️ Cleared profile image cache: \(count) images")
        }
    }
    
    func clearSearchImageCache() {
        cacheQueue.async(flags: .barrier) {
            let count = self.searchImageCache.count
            self.searchImageCache.removeAll()
            print("🗑️ Cleared search image cache: \(count) images")
        }
    }
    
    // MARK: - User Data Management (REMOVED - NO MORE DATA CACHING)
    // NOTE: All user data caching methods removed - data always comes fresh from API
    
    func clearUserData() {
        // Only clear image caches when user changes
        clearAllImageCaches()
        lastKnownUserId = 0
        print("🧹 Cleared user data (images only) - user data now always fresh from API")
    }
    
    // MARK: - Cleanup Timer (Only for images)
    private func startCleanupTimer() {
        Timer.scheduledTimer(withTimeInterval: 300, repeats: true) { _ in
            self.cleanupExpiredImages()
        }
    }
    
    private func cleanupExpiredImages() {
        cacheQueue.async(flags: .barrier) {
            let beforeProfile = self.profileImageCache.count
            let beforeSearch = self.searchImageCache.count
            
            // Clean profile images
            self.profileImageCache = self.profileImageCache.filter { entry in
                !entry.value.isExpired && entry.value.belongsToCurrentUser
            }
            
            // Clean search images (with shorter expiration)
            self.searchImageCache = self.searchImageCache.filter { entry in
                let isExpired = Date().timeIntervalSince(entry.value.timestamp) > Self.searchCacheExpirationInterval
                return !isExpired && entry.value.belongsToCurrentUser
            }
            
            let afterProfile = self.profileImageCache.count
            let afterSearch = self.searchImageCache.count
            
            let cleanedProfile = beforeProfile - afterProfile
            let cleanedSearch = beforeSearch - afterSearch
            
            if cleanedProfile > 0 || cleanedSearch > 0 {
                print("🧹 Image cache cleanup: \(cleanedProfile) profile images, \(cleanedSearch) search images removed")
            }
        }
    }
    
    // MARK: - Cache Statistics (Only images)
    var cacheStats: String {
        cacheQueue.sync {
            let profileCount = profileImageCache.count
            let searchCount = searchImageCache.count
            let totalImages = profileCount + searchCount
            
            return "Cache Stats: \(totalImages) total images (\(profileCount) profile, \(searchCount) search) - NO USER DATA CACHED"
        }
    }
    
    func logCacheStatus() {
        print("📊 \(cacheStats)")
    }
}
