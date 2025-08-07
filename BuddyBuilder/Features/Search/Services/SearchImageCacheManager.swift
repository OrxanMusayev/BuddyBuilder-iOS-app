// BuddyBuilder/Features/Search/Services/SearchImageCacheManager.swift - FIXED WITH UNIQUE CACHE KEYS

import Foundation
import UIKit
import Combine

// MARK: - Search Image Cache Entry
struct SearchImageCacheEntry {
    let image: UIImage
    let timestamp: Date
    let userId: Int // NEW: Track which user this image belongs to
    
    var isExpired: Bool {
        Date().timeIntervalSince(timestamp) > SearchImageCacheManager.cacheExpirationInterval
    }
    
    var belongsToCurrentUser: Bool {
        let currentUserId = UserDefaults.standard.integer(forKey: "user_id")
        return userId == currentUserId && currentUserId > 0
    }
}

// MARK: - Search Image Cache Manager - FIXED WITH SEPARATE NAMESPACE
class SearchImageCacheManager {
    static let shared = SearchImageCacheManager()
    
    // Cache expiration time: 5 minutes (300 seconds) - REDUCED from 10 minutes
    static let cacheExpirationInterval: TimeInterval = 300 // 5 minutes
    
    // FIXED: In-memory cache with user tracking - SEPARATE from profile cache
    private var searchImageCache: [String: SearchImageCacheEntry] = [:]
    private let cacheQueue = DispatchQueue(label: "com.buddybuilder.searchimagecache", attributes: .concurrent)
    
    // NEW: Track current user for cache validation
    private var lastKnownUserId: Int = 0
    
    private init() {
        lastKnownUserId = UserDefaults.standard.integer(forKey: "user_id")
        // Start cleanup timer
        startCleanupTimer()
    }
    
    // MARK: - NEW: Check for user change and clear cache if needed
    func checkForUserChange() {
        let currentUserId = UserDefaults.standard.integer(forKey: "user_id")
        
        if currentUserId != lastKnownUserId && currentUserId > 0 {
            print("🔄 Search cache: User changed from \(lastKnownUserId) to \(currentUserId), clearing cache...")
            clearAllCache()
            lastKnownUserId = currentUserId
        }
    }
    
    // MARK: - Get Cached Image - FIXED WITH USER VALIDATION
    func getCachedImage(for url: String) -> UIImage? {
        checkForUserChange() // Check for user changes before accessing cache
        
        return cacheQueue.sync {
            if let entry = searchImageCache[url] {
                if !entry.isExpired && entry.belongsToCurrentUser {
                    print("✅ Search cache hit for image: \(url)")
                    return entry.image
                } else {
                    if entry.isExpired {
                        print("⏰ Search cache expired for image: \(url)")
                    } else {
                        print("👤 Search cache belongs to different user for image: \(url)")
                    }
                    // Remove invalid entry
                    searchImageCache.removeValue(forKey: url)
                }
            }
            return nil
        }
    }
    
    // MARK: - Cache Image - FIXED WITH USER TRACKING
    func cacheImage(_ image: UIImage, for url: String) {
        let currentUserId = UserDefaults.standard.integer(forKey: "user_id")
        
        cacheQueue.async(flags: .barrier) {
            self.searchImageCache[url] = SearchImageCacheEntry(
                image: image,
                timestamp: Date(),
                userId: currentUserId
            )
            print("💾 Search cached image for user \(currentUserId): \(url) (expires in \(SearchImageCacheManager.cacheExpirationInterval) seconds)")
        }
    }
    
    // MARK: - Download and Cache Image - UPDATED WITH USER CHANGE CHECK
    func loadImage(from urlString: String?) -> AnyPublisher<UIImage?, Never> {
        guard let urlString = urlString, !urlString.isEmpty else {
            return Just(nil).eraseToAnyPublisher()
        }
        
        // Check cache first (with user validation)
        if let cachedImage = getCachedImage(for: urlString) {
            return Just(cachedImage).eraseToAnyPublisher()
        }
        
        // Download if not cached or expired
        guard let url = URL(string: urlString) else {
            return Just(nil).eraseToAnyPublisher()
        }
        
        print("📥 Search downloading image from: \(urlString)")
        
        return URLSession.shared.dataTaskPublisher(for: url)
            .map { data, _ -> UIImage? in
                guard let image = UIImage(data: data) else { return nil }
                
                // Cache the downloaded image
                self.cacheImage(image, for: urlString)
                return image
            }
            .catch { error -> AnyPublisher<UIImage?, Never> in
                print("❌ Search failed to download image: \(error)")
                return Just(nil).eraseToAnyPublisher()
            }
            .receive(on: DispatchQueue.main)
            .eraseToAnyPublisher()
    }
    
    // MARK: - Clear All Cache - UPDATED
    func clearAllCache() {
        cacheQueue.async(flags: .barrier) {
            self.searchImageCache.removeAll()
            print("🗑️ Cleared all search image cache")
        }
    }
    
    // MARK: - NEW: Clear cache when user logs out
    func clearCacheOnUserChange() {
        clearAllCache()
        lastKnownUserId = 0
        print("🔄 Cleared search image cache due to user change")
    }
    
    // MARK: - NEW: Get current cache stats for debugging
    func logCacheStatus() {
        let stats = cacheStats
        print("📊 \(stats)")
    }
    
    // MARK: - NEW: Force clear all cache (for logout)
    func forceClearAllCache() {
        cacheQueue.async(flags: .barrier) {
            let before = self.searchImageCache.count
            self.searchImageCache.removeAll()
            self.lastKnownUserId = 0
            print("🧹 FORCE cleared all search image cache: \(before) entries removed")
        }
    }
    
    // MARK: - Clear Expired Entries - UPDATED WITH USER VALIDATION
    private func clearExpiredEntries() {
        cacheQueue.async(flags: .barrier) {
            let before = self.searchImageCache.count
            
            // Remove expired entries and entries from different users
            self.searchImageCache = self.searchImageCache.filter { entry in
                !entry.value.isExpired && entry.value.belongsToCurrentUser
            }
            
            let after = self.searchImageCache.count
            if before > after {
                print("🧹 Search cache cleaned up \(before - after) expired/invalid entries")
            }
        }
    }
    
    // MARK: - Cleanup Timer
    private func startCleanupTimer() {
        // Run cleanup every 5 minutes
        Timer.scheduledTimer(withTimeInterval: 300, repeats: true) { _ in
            self.clearExpiredEntries()
        }
    }
    
    // MARK: - Cache Statistics (for debugging)
    var cacheStats: String {
        cacheQueue.sync {
            let total = searchImageCache.count
            let expired = searchImageCache.filter { $0.value.isExpired }.count
            let wrongUser = searchImageCache.filter { !$0.value.belongsToCurrentUser }.count
            let active = total - expired - wrongUser
            return "Search Cache Stats: Total=\(total), Active=\(active), Expired=\(expired), WrongUser=\(wrongUser)"
        }
    }
}
