// BuddyBuilder/Features/Search/Services/SearchImageCacheManager.swift

import Foundation
import UIKit
import Combine

// MARK: - Search Image Cache Entry
struct ImageCacheEntry {
    let image: UIImage
    let timestamp: Date
    
    var isExpired: Bool {
        Date().timeIntervalSince(timestamp) > SearchImageCacheManager.cacheExpirationInterval
    }
}

// MARK: - Search Image Cache Manager
class SearchImageCacheManager {
    static let shared = SearchImageCacheManager()
    
    // Cache expiration time: 10 minutes (600 seconds)
    static let cacheExpirationInterval: TimeInterval = 600 // 10 minutes
    
    // In-memory cache for images
    private var imageCache: [String: ImageCacheEntry] = [:]
    private let cacheQueue = DispatchQueue(label: "com.buddybuilder.searchimagecache", attributes: .concurrent)
    
    private init() {
        // Start cleanup timer
        startCleanupTimer()
    }
    
    // MARK: - Get Cached Image
    func getCachedImage(for url: String) -> UIImage? {
        cacheQueue.sync {
            if let entry = imageCache[url] {
                if !entry.isExpired {
                    print("✅ Cache hit for image: \(url)")
                    return entry.image
                } else {
                    print("⏰ Cache expired for image: \(url)")
                    // Remove expired entry
                    imageCache.removeValue(forKey: url)
                }
            }
            return nil
        }
    }
    
    // MARK: - Cache Image
    func cacheImage(_ image: UIImage, for url: String) {
        cacheQueue.async(flags: .barrier) {
            self.imageCache[url] = ImageCacheEntry(image: image, timestamp: Date())
            print("💾 Cached image for: \(url) (expires in \(SearchImageCacheManager.cacheExpirationInterval) seconds)")
        }
    }
    
    // MARK: - Download and Cache Image
    func loadImage(from urlString: String?) -> AnyPublisher<UIImage?, Never> {
        guard let urlString = urlString, !urlString.isEmpty else {
            return Just(nil).eraseToAnyPublisher()
        }
        
        // Check cache first
        if let cachedImage = getCachedImage(for: urlString) {
            return Just(cachedImage).eraseToAnyPublisher()
        }
        
        // Download if not cached or expired
        guard let url = URL(string: urlString) else {
            return Just(nil).eraseToAnyPublisher()
        }
        
        print("📥 Downloading image from: \(urlString)")
        
        return URLSession.shared.dataTaskPublisher(for: url)
            .map { data, _ -> UIImage? in
                guard let image = UIImage(data: data) else { return nil }
                
                // Cache the downloaded image
                self.cacheImage(image, for: urlString)
                return image
            }
            .catch { error -> AnyPublisher<UIImage?, Never> in
                print("❌ Failed to download image: \(error)")
                return Just(nil).eraseToAnyPublisher()
            }
            .receive(on: DispatchQueue.main)
            .eraseToAnyPublisher()
    }
    
    // MARK: - Clear All Cache
    func clearAllCache() {
        cacheQueue.async(flags: .barrier) {
            self.imageCache.removeAll()
            print("🗑️ Cleared all search image cache")
        }
    }
    
    // MARK: - Clear Expired Entries
    private func clearExpiredEntries() {
        cacheQueue.async(flags: .barrier) {
            let before = self.imageCache.count
            self.imageCache = self.imageCache.filter { !$0.value.isExpired }
            let after = self.imageCache.count
            if before > after {
                print("🧹 Cleaned up \(before - after) expired cache entries")
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
            let total = imageCache.count
            let expired = imageCache.filter { $0.value.isExpired }.count
            let active = total - expired
            return "Cache Stats: Total=\(total), Active=\(active), Expired=\(expired)"
        }
    }
}

// MARK: - Async Image View for Search
import SwiftUI
import Combine

struct SearchAsyncImage: View {
    let url: String?
    let placeholder: String
    @State private var loadedImage: UIImage?
    @State private var isLoading = true
    @State private var cancellables = Set<AnyCancellable>()
    
    private let cacheManager = SearchImageCacheManager.shared
    
    var body: some View {
        Group {
            if let image = loadedImage {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .transition(.opacity)
            } else if isLoading {
                ZStack {
                    Circle()
                        .fill(Color.gray.opacity(0.1))
                    
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .gray))
                        .scaleEffect(0.6)
                }
            } else {
                // Fallback placeholder
                Image(systemName: placeholder)
                    .font(.system(size: 35))
                    .foregroundColor(.gray.opacity(0.4))
            }
        }
        .animation(.easeInOut(duration: 0.2), value: loadedImage)
        .onAppear {
            loadImage()
        }
        .onChange(of: url) { _ in
            // Cancel previous subscriptions
            cancellables.removeAll()
            // Reset state
            loadedImage = nil
            // Load new image
            loadImage()
        }
    }
    
    private func loadImage() {
        guard let url = url, !url.isEmpty else {
            self.isLoading = false
            self.loadedImage = nil
            return
        }
        
        // Check if already loaded for this URL
        if loadedImage != nil && !cancellables.isEmpty {
            return
        }
        
        self.isLoading = true
        
        cacheManager.loadImage(from: url)
            .sink { image in
                self.loadedImage = image
                self.isLoading = false
            }
            .store(in: &cancellables)
    }
}
