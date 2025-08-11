// BuddyBuilder/Features/Authentication/Views/LoginView.swift
// UPDATED: Enhanced keyboard dismissal

import SwiftUI

struct LoginView: View {
    @EnvironmentObject var authViewModel: AuthenticationViewModel
    @EnvironmentObject var localizationManager: LocalizationManager
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Full screen background with tap gesture
                LoginBackgroundView()
                    .ignoresSafeArea(.all)
                    .contentShape(Rectangle()) // Make entire background tappable
                    .onTapGesture {
                        // Dismiss keyboard when background is tapped
                        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                    }
                
                // Direct content - no card wrapper
                LoginContentView()
                    .environmentObject(authViewModel)
                    .environmentObject(localizationManager)
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
