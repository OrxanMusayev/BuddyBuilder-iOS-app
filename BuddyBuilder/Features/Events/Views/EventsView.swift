import SwiftUI


struct EventsView: View {
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Image(systemName: "calendar.circle")
                    .font(.system(size: 80))
                    .foregroundColor(.primaryOrange)
                
                Text("events.title")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(.textPrimary)
                
                Text("events.description")
                    .font(.system(size: 16))
                    .foregroundColor(.textSecondary)
                    .multilineTextAlignment(.center)
                
                Spacer()
            }
            .padding()
        }
    }
}
