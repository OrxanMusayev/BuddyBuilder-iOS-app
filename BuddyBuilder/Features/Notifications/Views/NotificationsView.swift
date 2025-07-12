import SwiftUI


struct NotificationsView: View {
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Image(systemName: "bell.circle")
                    .font(.system(size: 80))
                    .foregroundColor(.primaryOrange)
                
                Text("notifications.title")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(.textPrimary)
                
                Text("notifications.description")
                    .font(.system(size: 16))
                    .foregroundColor(.textSecondary)
                    .multilineTextAlignment(.center)
                
                Spacer()
            }
            .padding()
            .navigationTitle("notifications.title")
        }
    }
}
