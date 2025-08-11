// BuddyBuilder/Shared/Components/SpinningLoader.swift

import SwiftUI

// MARK: - Modern Spinning Loader Component
struct SpinningLoader: View {
    @State private var isRotating = false
    let size: CGFloat
    let lineWidth: CGFloat
    let color: Color
    
    // Default initializer
    init(size: CGFloat = 60, lineWidth: CGFloat = 4, color: Color = .primaryOrange) {
        self.size = size
        self.lineWidth = lineWidth
        self.color = color
    }
    
    var body: some View {
        ZStack {
            // Background circle
            Circle()
                .stroke(color.opacity(0.2), lineWidth: lineWidth)
                .frame(width: size, height: size)
            
            // Spinning arc
            Circle()
                .trim(from: 0, to: 0.7)
                .stroke(
                    LinearGradient(
                        colors: [color, color.opacity(0.6)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                )
                .frame(width: size, height: size)
                .rotationEffect(.degrees(isRotating ? 360 : 0))
                .animation(.linear(duration: 1).repeatForever(autoreverses: false), value: isRotating)
                .onAppear {
                    isRotating = true
                }
        }
    }
}

// MARK: - Modern Loading Overlay
struct ModernLoadingOverlay: View {
    let message: String
    let size: CGFloat
    let isVisible: Bool
    
    init(message: String, size: CGFloat = 60, isVisible: Bool = true) {
        self.message = message
        self.size = size
        self.isVisible = isVisible
    }
    
    var body: some View {
        if isVisible {
            ZStack {
                Color.black.opacity(0.3)
                    .ignoresSafeArea()
                
                VStack(spacing: 24) {
                    SpinningLoader(size: size)
                    
                    Text(message)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.textPrimary)
                        .multilineTextAlignment(.center)
                }
                .padding(.horizontal, 32)
                .padding(.vertical, 40)
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(.ultraThinMaterial)
                        .shadow(color: .black.opacity(0.1), radius: 20, x: 0, y: 10)
                )
                .padding(.horizontal, 40)
            }
            .transition(.asymmetric(
                insertion: .opacity.combined(with: .scale(scale: 0.9)),
                removal: .opacity
            ))
            .zIndex(999)
        }
    }
}

// MARK: - Logout Loading Overlay (Specific for logout)
struct LogoutLoadingOverlay: View {
    let isVisible: Bool
    
    var body: some View {
        ModernLoadingOverlay(
            message: "Logging out...",
            size: 50,
            isVisible: isVisible
        )
    }
}

// MARK: - Preview
#Preview {
    ZStack {
        Color.blue.opacity(0.1)
            .ignoresSafeArea()
        
        VStack(spacing: 40) {
            SpinningLoader()
            
            SpinningLoader(size: 40, lineWidth: 3, color: .green)
            
            ModernLoadingOverlay(message: "Loading your data...")
        }
    }
}
