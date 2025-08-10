// BuddyBuilder/Features/Search/Views/SearchAsyncImage.swift - FINAL VERSION (ONLY IMAGE CACHE)

import SwiftUI
import Combine

struct SearchAsyncImage: View {
    let url: String?
    let placeholder: String
    @State private var loadedImage: UIImage?
    @State private var isLoading = true
    @State private var cancellables = Set<AnyCancellable>()
    
    // Use CentralCacheManager for image caching only
    private let cacheManager = CentralCacheManager.shared
    
    var body: some View {
        ZStack {
            if let image = loadedImage {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .transition(.opacity)
            } else if isLoading {
                // Loading state - light gray background with spinner
                Color.dynamicTertiaryBackground
                
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    .scaleEffect(0.8)
            } else {
                // Fallback placeholder - icon with lighter gray color for better visibility
                Image(systemName: placeholder)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .foregroundColor(.tertiaryText) // ✅ Updated (daha görünür)
                    .background(Color.dynamicSecondaryBackground)
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
            isLoading = true
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
        
        // Check user changes in cache manager
        cacheManager.checkUserChange()
        
        // Check search image cache first
        if let cachedImage = cacheManager.getSearchImage(for: url) {
            self.loadedImage = cachedImage
            self.isLoading = false
            return
        }
        
        // Download if not cached
        guard let imageURL = URL(string: url) else {
            self.isLoading = false
            return
        }
        
        URLSession.shared.dataTaskPublisher(for: imageURL)
            .map { data, _ -> UIImage? in
                guard let image = UIImage(data: data) else { return nil }
                
                // Cache the downloaded image using CentralCacheManager
                self.cacheManager.saveSearchImage(image, for: url)
                return image
            }
            .catch { error -> AnyPublisher<UIImage?, Never> in
                print("❌ Failed to download search image: \(error)")
                return Just(nil).eraseToAnyPublisher()
            }
            .receive(on: DispatchQueue.main)
            .sink { image in
                self.loadedImage = image
                self.isLoading = false
            }
            .store(in: &cancellables)
    }
}
