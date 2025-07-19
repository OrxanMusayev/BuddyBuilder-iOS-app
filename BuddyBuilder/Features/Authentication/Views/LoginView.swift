import SwiftUI

struct LoginView: View {
    @EnvironmentObject var authViewModel: AuthenticationViewModel
    @EnvironmentObject var localizationManager: LocalizationManager
    
    var body: some View {
        NavigationStack {
            GeometryReader { geometry in
                ZStack {
                    // Arka plan
                    LoginBackgroundView()
                    
                    // İçerik
                    ScrollView {
                        VStack(spacing: 0) {
                            Spacer(minLength: 80)
                            
                            LoginContentView()
                                .environmentObject(authViewModel)
                                .environmentObject(localizationManager)
                                .frame(maxWidth: 420)
                                .padding(.horizontal, 20)
                            
                            Spacer(minLength: 100)
                        }
                    }
                }
            }
            .ignoresSafeArea()
        }
        .onChange(of: localizationManager.currentLanguage) {
            // Language changed, UI will automatically update
            print("🔄 Language changed in LoginView")
        }
    }
}

#Preview {
    LoginView()
        .environmentObject(AuthenticationViewModel())
        .environmentObject(LocalizationManager(localizationService: MockLocalizationService()))
}
