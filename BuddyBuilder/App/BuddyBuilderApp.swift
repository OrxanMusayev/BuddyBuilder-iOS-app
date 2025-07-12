import SwiftUI

@main
struct BuddyBuilderApp: App {
    @StateObject private var authViewModel = AuthenticationViewModel()
    @StateObject private var localizationManager = LocalizationManager()
    
    init() {
        print("🚀 BuddyBuilderApp initialized")
        #if DEBUG
        UserDefaults.standard.removePersistentDomain(forName: Bundle.main.bundleIdentifier!)
        #endif
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(authViewModel)
                .environmentObject(localizationManager)
                .environment(\.localizationManager, localizationManager)
                .task {
                    await setupApp()
                }
                .onAppear {
                    print("📱 Main app view appeared")
                    print("🔍 AuthViewModel isAuthenticated: \(authViewModel.isAuthenticated)")
                }
        }
    }
    
    @MainActor
    private func setupApp() async {
        print("🛠️ Setting up application...")
        
        // Initialize localization first
        await localizationManager.initialize()
        
        print("✅ Application setup completed")
        print("🌍 Current language: \(localizationManager.currentLanguage?.code ?? "unknown")")
        print("📚 Loaded translations: \(localizationManager.translations.count)")
    }
}
