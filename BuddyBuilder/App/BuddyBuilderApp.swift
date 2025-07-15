import SwiftUI

@main
struct BuddyBuilderApp: App {
    @StateObject private var authViewModel = AuthenticationViewModel()
    @StateObject private var localizationManager = LocalizationManager()
    @State private var isInitializing = true
    @State private var splashAnimationCompleted = false
    @State private var showMainContent = false
    @State private var splashOpacity: Double = 1.0
    
    init() {
        print("🚀 BuddyBuilderApp initialized")
//        #if DEBUG
//        // Debug modda cache temizlemeyi geçici olarak kapatıyoruz
//        UserDefaults.standard.removePersistentDomain(forName: Bundle.main.bundleIdentifier!)
//        print("🐛 DEBUG MODE: Keeping cached data for testing")
//        #endif
    }
    
    var body: some Scene {
        WindowGroup {
            ZStack {
                // Ana içerik (her zaman arka planda hazır)
                if authViewModel.isAuthenticated {
                    MainTabView()
                        .environmentObject(authViewModel)
                        .environmentObject(localizationManager)
                        .environment(\.localizationManager, localizationManager)
                        .opacity(showMainContent ? 1.0 : 0.0)
                        .scaleEffect(showMainContent ? 1.0 : 0.9)
                } else {
                    LoginView()
                        .environmentObject(authViewModel)
                        .environmentObject(localizationManager)
                        .environment(\.localizationManager, localizationManager)
                        .opacity(showMainContent ? 1.0 : 0.0)
                        .scaleEffect(showMainContent ? 1.0 : 0.9)
                }
                
                // Splash Screen (overlay olarak)
                if isInitializing {
                    SplashScreenView(onAnimationComplete: {
                        splashAnimationCompleted = true
                    })
                    .environmentObject(localizationManager)
                    .opacity(splashOpacity)
                    .zIndex(1) // En üstte olsun
                }
            }
            .task {
                await setupApp()
            }
        }
    }
    
    @MainActor
    private func setupApp() async {
        print("🛠️ Setting up application...")
        
        #if DEBUG
        print("🐛 DEBUG MODE: Fresh start - no cached data")
        #endif
        
        // Initialize localization first
        await localizationManager.initialize()
        
        // Check authentication state
        await checkAuthenticationState()
        
        // Splash screen animasyonunun tamamlanmasını bekle
        while !splashAnimationCompleted {
            try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 saniye kontrol
        }
        
        // Ek bekleme süresi - kullanıcının logo ve içeriği görmesi için
        try? await Task.sleep(nanoseconds: 120_000_000) // 1.2 saniye
        
        // 1. Adım: Ana içeriği yumuşakça göster (arka planda hazırlanıyor)
        withAnimation(.easeInOut(duration: 0.5)) {
            showMainContent = true
        }
        
        // Küçük bir bekleme
        try? await Task.sleep(nanoseconds: 400_000_000) // 0.6 saniye
        
        // 2. Adım: Splash screen'i yumuşakça gizle
        withAnimation(.easeInOut(duration: 0.8)) {
            splashOpacity = 0.0
        }
        
        // 3. Adım: Splash screen tamamen kaldır
        try? await Task.sleep(nanoseconds: 500_000_000) // 0.8 saniye (animasyon bitmesini bekle)
        
        withAnimation(.easeInOut(duration: 0.3)) {
            isInitializing = false
        }
        
        print("✅ Application setup completed")
        print("🌍 Current language: \(localizationManager.currentLanguage?.code ?? "unknown")")
        print("📚 Loaded translations: \(localizationManager.translations.count)")
        print("🔐 Auth status: \(authViewModel.isAuthenticated ? "Authenticated" : "Not authenticated")")
    }
    
    @MainActor
    private func checkAuthenticationState() async {
//        #if DEBUG
//        // Test için simulated token
//        UserDefaults.standard.set("test_auth_token_12345", forKey: "auth_token")
//        print("🧪 DEBUG: Simulated auth token set for testing")
//        #endif
        
        // Check if user was previously logged in
        if let savedToken = UserDefaults.standard.string(forKey: "auth_token"),
           !savedToken.isEmpty {
            print("🔐 Found saved auth token: \(savedToken.prefix(10))...")
            
            // Here you would typically validate the token with your backend
            // For now, we'll just mark as authenticated if token exists
            authViewModel.isAuthenticated = true
            print("✅ User automatically authenticated")
        } else {
            print("❌ No saved auth token found")
            authViewModel.isAuthenticated = false
        }
    }
}

// MARK: - Splash Screen View
struct SplashScreenView: View {
    @EnvironmentObject var localizationManager: LocalizationManager
    @State private var scale: CGFloat = 0.8
    @State private var opacity: Double = 0.0
    @State private var logoRotation: Double = 0
    @State private var showSecondaryAnimation = false
    @State private var fadingOut = false

    let onAnimationComplete: () -> Void

    var body: some View {
        ZStack {
            // Background View
            LoginBackgroundView()

            VStack(spacing: 40) {
                // Logo + BuddyBuilder (tek blok)
                VStack(spacing: 20) {
                    // Logo
                    ZStack {
                        RoundedRectangle(cornerRadius: 32)
                            .fill(
                                LinearGradient(
                                    colors: [
                                        Color.primaryOrange,
                                        Color.primaryOrange.opacity(0.8),
                                        Color.pink.opacity(0.6)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 120, height: 120)
                            .shadow(color: .primaryOrange.opacity(0.3), radius: 20, x: 0, y: 10)
                            .rotationEffect(.degrees(logoRotation))

                        // Daireler ve çizgiler
                        VStack(spacing: 8) {
                            HStack(spacing: 6) {
                                ForEach(0..<3, id: \.self) { index in
                                    Circle()
                                        .fill(Color.white)
                                        .frame(width: index == 1 ? 16 : 12, height: index == 1 ? 16 : 12)
                                        .opacity(index == 1 ? 1.0 : 0.8)
                                        .scaleEffect(showSecondaryAnimation ? 1.1 : 1.0)
                                        .animation(
                                            .easeInOut(duration: 0.8)
                                                .delay(Double(index) * 0.2)
                                                .repeatForever(autoreverses: true),
                                            value: showSecondaryAnimation
                                        )
                                }
                            }

                            VStack(spacing: 3) {
                                Rectangle()
                                    .fill(Color.white.opacity(0.9))
                                    .frame(width: 24, height: 2)
                                    .clipShape(Capsule())

                                Rectangle()
                                    .fill(Color.white.opacity(0.7))
                                    .frame(width: 18, height: 2)
                                    .clipShape(Capsule())
                            }
                            .scaleEffect(showSecondaryAnimation ? 1.05 : 1.0)
                        }
                    }

                    // App name
                    Text("BuddyBuilder")
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [Color.primaryOrange, Color.primaryOrange.opacity(0.8)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                }
                .scaleEffect(scale)
                .opacity(fadingOut ? 0.0 : opacity)

                // Progress indicator (isteğe bağlı)
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .primaryOrange))
                    .scaleEffect(1.2)
                    .opacity(fadingOut ? 0.0 : opacity)
            }
        }
        .onAppear {
            startSplashAnimation()
        }
    }

    private func startSplashAnimation() {
        // Giriş animasyonu
        withAnimation(.easeOut(duration: 0.6)) {
            scale = 1.0
            opacity = 1.0
        }

        // Logo döndürme
        withAnimation(.easeInOut(duration: 1.0).delay(0.3)) {
            logoRotation = 360
        }

        // Nokta animasyonu
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            showSecondaryAnimation = true
        }

        // Fade out (logo + BuddyBuilder + progress)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
            withAnimation(.easeInOut(duration: 1.0)) {
                fadingOut = true
            }
        }

        // Splash ekranı tamamlandı
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            onAnimationComplete()
        }
    }
}
