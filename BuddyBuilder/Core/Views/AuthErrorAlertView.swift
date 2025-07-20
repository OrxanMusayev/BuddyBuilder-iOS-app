// BuddyBuilder/Core/Views/AuthErrorAlertView.swift

import SwiftUI

struct AuthErrorAlertView: View {
    @ObservedObject var authErrorHandler = AuthErrorHandler.shared
    
    var body: some View {
        EmptyView()
            .alert("Oturum Süresi Doldu", isPresented: $authErrorHandler.showAuthError) {
                Button("Tamam") {
                    authErrorHandler.showAuthError = false
                }
            } message: {
                Text(authErrorHandler.authErrorMessage)
            }
    }
}
