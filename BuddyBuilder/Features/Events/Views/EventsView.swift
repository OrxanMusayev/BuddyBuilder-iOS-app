import SwiftUI

struct EventsView: View {
    @EnvironmentObject var localizationManager: LocalizationManager
    
    var body: some View {
        VStack(spacing: 20) {
            Spacer()
            
            Image(systemName: "calendar.circle.fill")
                .font(.system(size: 80))
                .foregroundColor(.primaryOrange)
            
            Text("nav.events".localized(using: localizationManager))
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(.textPrimary)
            
            Text("events.coming.soon".localized(using: localizationManager))
                .font(.system(size: 16))
                .foregroundColor(.textSecondary)
            
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(LoginBackgroundView())
    }
}

#Preview {
    EventsView()
        .environmentObject(LocalizationManager(localizationService: MockLocalizationService()))
}
