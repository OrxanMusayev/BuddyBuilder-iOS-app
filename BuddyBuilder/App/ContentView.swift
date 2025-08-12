import SwiftUI

struct ContentView: View {
    @EnvironmentObject var authViewModel: AuthenticationViewModel
    @EnvironmentObject var localizationManager: LocalizationManager
    
    var body: some View {
        Group {
            if authViewModel.isAuthenticated {
                MainTabView()
                    .environmentObject(authViewModel)
                    .environmentObject(localizationManager)
            } else {
                // Full screen login experience
                LoginView()
                    .environmentObject(authViewModel)
                    .environmentObject(localizationManager)
                    .ignoresSafeArea(.all) // Ensure full screen
            }
        }
        .animation(.easeInOut(duration: 0.5), value: authViewModel.isAuthenticated)
        .onAppear {
            print("📱 ContentView appeared")
            print("🔍 Auth status: \(authViewModel.isAuthenticated)")
        }
        .preferredColorScheme(.light) // Consistent light mode
    }
}

#Preview {
    ContentView()
        .environmentObject(AuthenticationViewModel())
        .environmentObject(LocalizationManager(localizationService: MockLocalizationService()))
}
