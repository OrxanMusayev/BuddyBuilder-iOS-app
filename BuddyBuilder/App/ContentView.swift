// Dosya Yolu: BuddyBuilder/App/ContentView.swift

import SwiftUI

struct ContentView: View {
    @EnvironmentObject var authViewModel: AuthenticationViewModel
    
    var body: some View {
        Group {
            if authViewModel.isAuthenticated {
                MainTabView()
                    .transition(.asymmetric(
                        insertion: .move(edge: .trailing).combined(with: .opacity),
                        removal: .move(edge: .leading).combined(with: .opacity)
                    ))
                    .onAppear {
                        print("🏠 MainTabView appeared - User is authenticated")
                    }
            } else {
                LoginView()
                    .transition(.asymmetric(
                        insertion: .move(edge: .leading).combined(with: .opacity),
                        removal: .move(edge: .trailing).combined(with: .opacity)
                    ))
                    .onAppear {
                        print("🔐 LoginView appeared - User is NOT authenticated")
                    }
            }
        }
        .animation(.easeInOut(duration: 0.5), value: authViewModel.isAuthenticated)
        .onAppear {
            print("📱 ContentView appeared")
            print("🔍 Initial isAuthenticated: \(authViewModel.isAuthenticated)")
            // Uygulama açıldığında önceki login'i kontrol et
            authViewModel.checkExistingLogin()
        }
        .onChange(of: authViewModel.isAuthenticated) { oldValue, newValue in
            print("🔄 isAuthenticated changed from \(oldValue) to \(newValue)")
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(AuthenticationViewModel())
}
