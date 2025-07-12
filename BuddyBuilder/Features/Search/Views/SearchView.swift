import SwiftUI


struct SearchView: View {
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Image(systemName: "magnifyingglass.circle")
                    .font(.system(size: 80))
                    .foregroundColor(.primaryOrange)
                
                Text("search.title")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(.textPrimary)
                
                Text("search.description")
                    .font(.system(size: 16))
                    .foregroundColor(.textSecondary)
                    .multilineTextAlignment(.center)
                
                Spacer()
            }
            .padding()
            .navigationTitle("search.title")
        }
    }
}
