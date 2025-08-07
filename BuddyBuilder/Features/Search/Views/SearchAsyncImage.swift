// BuddyBuilder/Features/Search/Views/SearchAsyncImage.swift - SIMPLIFIED

import SwiftUI
import Combine

struct SearchAsyncImage: View {
    let url: String?
    let placeholder: String
    @State private var loadedImage: UIImage?
    @State private var isLoading = true
    @State private var cancellables = Set<AnyCancellable>()
    
    private let cacheManager = CentralCacheManager.shared
    
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
        
        // Check for user changes
        cacheManager.checkUserChange()
        
        self.isLoading = true
        
        // Check cache first
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
        
        print("📥 Downloading search image from: \(url)")
        
        URLSession.shared.dataTaskPublisher(for: imageURL)
            .map { data, _ -> UIImage? in
                guard let image = UIImage(data: data) else { return nil }
                
                // Cache the downloaded image
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
