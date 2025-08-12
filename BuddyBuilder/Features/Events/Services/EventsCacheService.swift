// BuddyBuilder/Features/Events/Services/EventsCacheService.swift

import Foundation
import Combine

// MARK: - Cache Entry Model
struct EventsCacheEntry: Codable {
    let data: EventsResponse
    let timestamp: Date
    let userId: String
    let cacheType: EventsCacheType
    
    enum EventsCacheType: String, Codable {
        case allEvents = "all_events"
        case myEvents = "my_events"
    }
    
    var isExpired: Bool {
        let ttl: TimeInterval = 30 * 60 // 30 dakika TTL
        return Date().timeIntervalSince(timestamp) > ttl
    }
    
    var belongsToCurrentUser: Bool {
        guard let currentUserId = UserDefaults.standard.string(forKey: "user_id"),
              !currentUserId.isEmpty else {
            return false
        }
        return userId == currentUserId
    }
    
    var ageInMinutes: Double {
        Date().timeIntervalSince(timestamp) / 60
    }
}

// MARK: - Events Cache Service Protocol
protocol EventsCacheServiceProtocol {
    func getCachedEvents(for type: EventsCacheEntry.EventsCacheType) -> EventsCacheEntry?
    func saveEvents(_ response: EventsResponse, for type: EventsCacheEntry.EventsCacheType)
    func clearCache()
    func clearCacheForType(_ type: EventsCacheEntry.EventsCacheType)
    func isCacheValid(for type: EventsCacheEntry.EventsCacheType) -> Bool
    func getCacheAge(for type: EventsCacheEntry.EventsCacheType) -> TimeInterval?
}

// MARK: - Events Cache Service Implementation
class EventsCacheService: EventsCacheServiceProtocol, ObservableObject {
    static let shared = EventsCacheService()
    
    // MARK: - Cache Storage
    private let cacheQueue = DispatchQueue(label: "com.buddybuilder.events.cache", attributes: .concurrent)
    private var memoryCache: [String: EventsCacheEntry] = [:]
    private let userDefaults = UserDefaults.standard
    
    // MARK: - Cache Keys
    private enum CacheKeys {
        static let allEventsPrefix = "events_cache_all_"
        static let myEventsPrefix = "events_cache_my_"
        static let lastUserId = "events_cache_last_user_id"
    }
    
    private init() {
        checkUserChange()
        loadMemoryCacheFromDisk()
        startCacheCleanupTimer()
    }
    
    // MARK: - Public Methods
    func getCachedEvents(for type: EventsCacheEntry.EventsCacheType) -> EventsCacheEntry? {
        return cacheQueue.sync {
            let cacheKey = cacheKey(for: type)
            
            // Önce memory cache'i kontrol et
            if let entry = memoryCache[cacheKey] {
                if entry.belongsToCurrentUser && !entry.isExpired {
                    print("✅ Memory cache hit for \(type.rawValue) (age: \(String(format: "%.1f", entry.ageInMinutes)) min)")
                    return entry
                } else {
                    print("⚠️ Memory cache expired or invalid user for \(type.rawValue)")
                    memoryCache.removeValue(forKey: cacheKey)
                }
            }
            
            // Disk cache'i kontrol et
            if let entry = loadFromDisk(cacheKey: cacheKey) {
                if entry.belongsToCurrentUser && !entry.isExpired {
                    print("✅ Disk cache hit for \(type.rawValue) (age: \(String(format: "%.1f", entry.ageInMinutes)) min)")
                    // Memory cache'e de ekle
                    memoryCache[cacheKey] = entry
                    return entry
                } else {
                    print("⚠️ Disk cache expired or invalid user for \(type.rawValue)")
                    clearCacheFromDisk(cacheKey: cacheKey)
                }
            }
            
            print("❌ No valid cache found for \(type.rawValue)")
            return nil
        }
    }
    
    func saveEvents(_ response: EventsResponse, for type: EventsCacheEntry.EventsCacheType) {
        guard let currentUserId = UserDefaults.standard.string(forKey: "user_id"),
              !currentUserId.isEmpty else {
            print("⚠️ No current user ID, cannot cache events")
            return
        }
        
        let entry = EventsCacheEntry(
            data: response,
            timestamp: Date(),
            userId: currentUserId,
            cacheType: type
        )
        
        cacheQueue.async(flags: .barrier) {
            let cacheKey = self.cacheKey(for: type)
            
            // Memory cache'e kaydet
            self.memoryCache[cacheKey] = entry
            
            // Disk cache'e kaydet
            self.saveToDisk(entry: entry, cacheKey: cacheKey)
            
            print("💾 Events cached for \(type.rawValue) - \(response.events.count) events (user: \(currentUserId))")
        }
    }
    
    func isCacheValid(for type: EventsCacheEntry.EventsCacheType) -> Bool {
        guard let entry = getCachedEvents(for: type) else { return false }
        return !entry.isExpired && entry.belongsToCurrentUser
    }
    
    func getCacheAge(for type: EventsCacheEntry.EventsCacheType) -> TimeInterval? {
        guard let entry = getCachedEvents(for: type) else { return nil }
        return Date().timeIntervalSince(entry.timestamp)
    }
    
    func clearCache() {
        cacheQueue.async(flags: .barrier) {
            let beforeCount = self.memoryCache.count
            self.memoryCache.removeAll()
            
            // Disk cache'i temizle
            self.clearAllDiskCache()
            
            print("🗑️ All events cache cleared - removed \(beforeCount) entries")
        }
    }
    
    func clearCacheForType(_ type: EventsCacheEntry.EventsCacheType) {
        cacheQueue.async(flags: .barrier) {
            let cacheKey = self.cacheKey(for: type)
            self.memoryCache.removeValue(forKey: cacheKey)
            self.clearCacheFromDisk(cacheKey: cacheKey)
            
            print("🗑️ Cache cleared for \(type.rawValue)")
        }
    }
    
    // MARK: - User Change Detection
    private func checkUserChange() {
        guard let currentUserId = UserDefaults.standard.string(forKey: "user_id") else {
            print("⚠️ No current user ID found")
            return
        }
        
        let lastUserId = userDefaults.string(forKey: CacheKeys.lastUserId) ?? ""
        
        if currentUserId != lastUserId {
            print("🔄 User changed from \(lastUserId) to \(currentUserId), clearing events cache...")
            clearCache()
            userDefaults.set(currentUserId, forKey: CacheKeys.lastUserId)
        }
    }
    
    // MARK: - Private Helper Methods
    private func cacheKey(for type: EventsCacheEntry.EventsCacheType) -> String {
        guard let userId = UserDefaults.standard.string(forKey: "user_id") else {
            return type.rawValue
        }
        
        switch type {
        case .allEvents:
            return "\(CacheKeys.allEventsPrefix)\(userId)"
        case .myEvents:
            return "\(CacheKeys.myEventsPrefix)\(userId)"
        }
    }
    
    // MARK: - Disk Cache Operations
    private func saveToDisk(entry: EventsCacheEntry, cacheKey: String) {
        do {
            let data = try JSONEncoder().encode(entry)
            userDefaults.set(data, forKey: cacheKey)
            print("💾 Saved to disk cache: \(cacheKey)")
        } catch {
            print("❌ Failed to save cache to disk: \(error)")
        }
    }
    
    private func loadFromDisk(cacheKey: String) -> EventsCacheEntry? {
        guard let data = userDefaults.data(forKey: cacheKey) else {
            return nil
        }
        
        do {
            let entry = try JSONDecoder().decode(EventsCacheEntry.self, from: data)
            return entry
        } catch {
            print("❌ Failed to load cache from disk: \(error)")
            // Bozuk cache'i temizle
            userDefaults.removeObject(forKey: cacheKey)
            return nil
        }
    }
    
    private func clearCacheFromDisk(cacheKey: String) {
        userDefaults.removeObject(forKey: cacheKey)
    }
    
    private func clearAllDiskCache() {
        let keys = userDefaults.dictionaryRepresentation().keys
        for key in keys {
            if key.hasPrefix(CacheKeys.allEventsPrefix) || key.hasPrefix(CacheKeys.myEventsPrefix) {
                userDefaults.removeObject(forKey: key)
            }
        }
    }
    
    private func loadMemoryCacheFromDisk() {
        cacheQueue.async(flags: .barrier) {
            guard let userId = UserDefaults.standard.string(forKey: "user_id") else { return }
            
            // All events cache'i yükle
            let allEventsKey = self.cacheKey(for: .allEvents)
            if let allEvents = self.loadFromDisk(cacheKey: allEventsKey) {
                self.memoryCache[allEventsKey] = allEvents
            }
            
            // My events cache'i yükle
            let myEventsKey = self.cacheKey(for: .myEvents)
            if let myEvents = self.loadFromDisk(cacheKey: myEventsKey) {
                self.memoryCache[myEventsKey] = myEvents
            }
            
            print("🔄 Memory cache loaded from disk")
        }
    }
    
    // MARK: - Cache Cleanup Timer
    private func startCacheCleanupTimer() {
        Timer.scheduledTimer(withTimeInterval: 300, repeats: true) { _ in // Her 5 dakikada bir
            self.cleanupExpiredCache()
        }
    }
    
    private func cleanupExpiredCache() {
        cacheQueue.async(flags: .barrier) {
            let beforeCount = self.memoryCache.count
            
            // Memory cache'den expired olanları temizle
            self.memoryCache = self.memoryCache.filter { _, entry in
                let isValid = !entry.isExpired && entry.belongsToCurrentUser
                if !isValid {
                    print("🧹 Removing expired cache entry: \(entry.cacheType.rawValue)")
                }
                return isValid
            }
            
            let afterCount = self.memoryCache.count
            let cleanedCount = beforeCount - afterCount
            
            if cleanedCount > 0 {
                print("🧹 Cache cleanup: removed \(cleanedCount) expired entries")
            }
        }
    }
    
    // MARK: - Debug Methods
    func logCacheStatus() {
        cacheQueue.sync {
            print("📊 Events Cache Status:")
            print("   Memory entries: \(memoryCache.count)")
            
            for (key, entry) in memoryCache {
                let age = String(format: "%.1f", entry.ageInMinutes)
                let status = entry.isExpired ? "EXPIRED" : "VALID"
                print("   - \(key): \(age) min old (\(status))")
            }
        }
    }
}
