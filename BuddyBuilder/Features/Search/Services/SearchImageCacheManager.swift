// BuddyBuilder/Features/Search/Services/SearchImageCacheManager.swift - DEPRECATED
// NOTE: This file is now deprecated. Use CentralCacheManager.shared for all image caching.

import Foundation
import UIKit
import Combine

// MARK: - DEPRECATED - Use CentralCacheManager instead
@available(*, deprecated, message: "Use CentralCacheManager.shared for image caching")
class SearchImageCacheManager {
    static let shared = SearchImageCacheManager()
    
    private init() {
        print("⚠️ SearchImageCacheManager is deprecated. Use CentralCacheManager.shared instead.")
    }
    
    // MARK: - Deprecated methods - redirect to CentralCacheManager
    func checkForUserChange() {
        CentralCacheManager.shared.checkUserChange()
    }
    
    func getCachedImage(for url: String) -> UIImage? {
        return CentralCacheManager.shared.getSearchImage(for: url)
    }
    
    func cacheImage(_ image: UIImage, for url: String) {
        CentralCacheManager.shared.saveSearchImage(image, for: url)
    }
    
    func loadImage(from urlString: String?) -> AnyPublisher<UIImage?, Never> {
        guard let urlString = urlString, !urlString.isEmpty else {
            return Just(nil).eraseToAnyPublisher()
        }
        
        // Check cache first
        if let cachedImage = CentralCacheManager.shared.getSearchImage(for: urlString) {
            return Just(cachedImage).eraseToAnyPublisher()
        }
        
        // Download if not cached
        guard let url = URL(string: urlString) else {
            return Just(nil).eraseToAnyPublisher()
        }
        
        return URLSession.shared.dataTaskPublisher(for: url)
            .map { data, _ -> UIImage? in
                guard let image = UIImage(data: data) else { return nil }
                CentralCacheManager.shared.saveSearchImage(image, for: urlString)
                return image
            }
            .catch { _ -> AnyPublisher<UIImage?, Never> in
                Just(nil).eraseToAnyPublisher()
            }
            .receive(on: DispatchQueue.main)
            .eraseToAnyPublisher()
    }
    
    func clearAllCache() {
        CentralCacheManager.shared.clearSearchImageCache()
    }
    
    func clearCacheOnUserChange() {
        CentralCacheManager.shared.clearSearchImageCache()
    }
    
    func forceClearAllCache() {
        CentralCacheManager.shared.clearSearchImageCache()
    }
    
    func logCacheStatus() {
        CentralCacheManager.shared.logCacheStatus()
    }
    
    var cacheStats: String {
        return CentralCacheManager.shared.cacheStats
    }
}
