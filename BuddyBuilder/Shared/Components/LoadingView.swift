import Swift.UI

struct LoadingView: View {
    let message: String
    let isVisible: Bool
    
    init(message: String = "Yükleniyor...", isVisible: Bool = true) {
        self.message = message
        self.isVisible = isVisible
    }
    
    var body: some View {
        if isVisible {
            ZStack {
                // Background overlay
                Color.black.opacity(0.3)
                    .ignoresSafeArea(.all)
                
                // Loading content
                VStack(spacing: 16) {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .scaleEffect(1.2)
                    
                    Text(message)
                        .font(.subheadline)
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                }
                .padding(24)
                .background(.ultraThinMaterial)
                .cornerRadius(12)
                .shadow(radius: 4)
            }
            .animation(.easeInOut(duration: 0.2), value: isVisible)
        }
    }
}
