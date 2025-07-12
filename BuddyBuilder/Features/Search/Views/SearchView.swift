import SwiftUI

struct SearchView: View {
    @EnvironmentObject var localizationManager: LocalizationManager
    
    var body: some View {
        VStack(spacing: 20) {
            Spacer()
            
            Image(systemName: "magnifyingglass.circle.fill")
                .font(.system(size: 80))
                .foregroundColor(.primaryOrange)
            
            Text("nav.search".localized(using: localizationManager))
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(.textPrimary)
            
            Text("search.coming.soon".localized(using: localizationManager))
                .font(.system(size: 16))
                .foregroundColor(.textSecondary)
            
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(LoginBackgroundView())
    }
}

#Preview {
    SearchView()
        .environmentObject(LocalizationManager(localizationService: MockLocalizationService()))
}
