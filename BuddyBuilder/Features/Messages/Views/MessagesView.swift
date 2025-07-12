import SwiftUI

struct MessagesView: View {
    @EnvironmentObject var localizationManager: LocalizationManager
    
    var body: some View {
        VStack(spacing: 20) {
            Spacer()
            
            Image(systemName: "message.circle.fill")
                .font(.system(size: 80))
                .foregroundColor(.primaryOrange)
            
            Text("nav.messages".localized(using: localizationManager))
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(.textPrimary)
            
            Text("messages.coming.soon".localized(using: localizationManager))
                .font(.system(size: 16))
                .foregroundColor(.textSecondary)
            
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(LoginBackgroundView())
    }
}

#Preview {
    MessagesView()
        .environmentObject(LocalizationManager(localizationService: MockLocalizationService()))
}
