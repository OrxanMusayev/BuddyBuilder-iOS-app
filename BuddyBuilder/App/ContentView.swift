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
                LoginView()
                    .environmentObject(authViewModel)
                    .environmentObject(localizationManager)
            }
        }
        .onAppear {
            print("📱 ContentView appeared")
            print("🔍 Auth status: \(authViewModel.isAuthenticated)")
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(AuthenticationViewModel())
        .environmentObject(LocalizationManager(localizationService: MockLocalizationService()))
}
