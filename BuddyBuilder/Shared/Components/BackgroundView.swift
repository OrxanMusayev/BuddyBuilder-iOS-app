
import SwiftUI

struct BackgroundView: View {
    var body: some View {
        ZStack {
            // Ana gradient
            Color.backgroundGradient
                .ignoresSafeArea()
            
            // Overlay
            RadialGradient(
                colors: [
                    Color.white.opacity(0.3),
                    Color.clear
                ],
                center: UnitPoint(x: 0.2, y: 0.8),
                startRadius: 0,
                endRadius: 300
            )
            .ignoresSafeArea()
            
            RadialGradient(
                colors: [
                    Color.primaryOrange.opacity(0.3),
                    Color.clear
                ],
                center: UnitPoint(x: 0.8, y: 0.2),
                startRadius: 0,
                endRadius: 300
            )
            .ignoresSafeArea()
            
            // Floating shapes
            FloatingShapesView()
        }
    }
}

struct FloatingShapesView: View {
    var body: some View {
        ZStack {
            FloatingShape(size: 100, position: CGPoint(x: 0.1, y: 0.2), duration: 20)
            FloatingShape(size: 60, position: CGPoint(x: 0.85, y: 0.6), duration: 15)
            FloatingShape(size: 80, position: CGPoint(x: 0.2, y: 0.8), duration: 25)
            FloatingShape(size: 120, position: CGPoint(x: 0.7, y: 0.1), duration: 20)
        }
    }
}

struct FloatingShape: View {
    let size: CGFloat
    let position: CGPoint
    let duration: Double
    
    @State private var isAnimating = false
    
    var body: some View {
        Circle()
            .fill(Color.white.opacity(0.1))
            .frame(width: size, height: size)
            .position(x: UIScreen.main.bounds.width * position.x,
                     y: UIScreen.main.bounds.height * position.y)
            .offset(y: isAnimating ? -100 : 0)
            .rotationEffect(.degrees(isAnimating ? 360 : 0))
            .opacity(isAnimating ? 0.3 : 0.7)
            .animation(
                Animation.linear(duration: duration)
                    .repeatForever(autoreverses: true),
                value: isAnimating
            )
            .onAppear {
                isAnimating = true
            }
    }
}
