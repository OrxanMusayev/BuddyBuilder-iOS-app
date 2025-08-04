import SwiftUI

struct LoginView: View {
    @EnvironmentObject var authViewModel: AuthenticationViewModel
    @EnvironmentObject var localizationManager: LocalizationManager
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Full screen background
                LoginBackgroundView()
                    .ignoresSafeArea(.all)
                
                // Direct content - no card wrapper
                LoginContentView()
                    .environmentObject(authViewModel)
                    .environmentObject(localizationManager)
                    .padding(.horizontal, 20)
            }
            .navigationBarHidden(true)
        }
        .navigationBarHidden(true)
        .onChange(of: localizationManager.currentLanguage) {
            print("🔄 Language changed in LoginView")
        }
    }
}

#Preview {
    LoginView()
        .environmentObject(AuthenticationViewModel())
        .environmentObject(LocalizationManager(localizationService: MockLocalizationService()))
}
