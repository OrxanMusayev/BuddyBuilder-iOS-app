// BuddyBuilder/Features/Authentication/Views/RegistrationVisualComponents.swift

import SwiftUI

// MARK: - User Creation Visual (Basic Info Step)
struct UserCreationVisual: View {
    var body: some View {
        ZStack {
            // Static background circle
            Circle()
                .fill(
                    RadialGradient(
                        colors: [.primaryOrange.opacity(0.3), .primaryOrange.opacity(0.1)],
                        center: .center,
                        startRadius: 10,
                        endRadius: 40
                    )
                )
                .frame(width: 80, height: 80)
            
            // Main content
            ZStack {
                // Document background
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.white)
                    .frame(width: 40, height: 50)
                    .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
                
                // Document lines - STATIC
                VStack(spacing: 3) {
                    ForEach(0..<4, id: \.self) { _ in
                        RoundedRectangle(cornerRadius: 0.5)
                            .fill(Color.gray.opacity(0.3))
                            .frame(width: 28, height: 2)
                    }
                }
                .offset(y: -5)
                
                // Pencil - STATIC (no animation)
                ZStack {
                    RoundedRectangle(cornerRadius: 2)
                        .fill(
                            LinearGradient(
                                colors: [.primaryOrange, .primaryOrange.opacity(0.8)],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .frame(width: 3, height: 20)
                    
                    Circle()
                        .fill(Color.primaryOrange)
                        .frame(width: 4, height: 4)
                        .offset(y: -12)
                }
                .rotationEffect(.degrees(-30))
                .offset(x: 15, y: 15)
            }
        }
    }
}

// MARK: - Location Visual (Location Step) - NEW DESIGN
struct LocationVisual: View {
    var body: some View {
        ZStack {
            // Background circle
            Circle()
                .fill(
                    RadialGradient(
                        colors: [.primaryOrange.opacity(0.3), .primaryOrange.opacity(0.1)],
                        center: .center,
                        startRadius: 10,
                        endRadius: 40
                    )
                )
                .frame(width: 80, height: 80)
            
            // Main content - NEW DESIGN: World with location pin
            ZStack {
                // Globe background
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Color.blue.opacity(0.6), Color.blue.opacity(0.4)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 45, height: 45)
                    .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
                
                // Continents/land shapes
                VStack(spacing: 1) {
                    HStack(spacing: 2) {
                        Circle().fill(Color.green.opacity(0.7)).frame(width: 6, height: 4)
                        Circle().fill(Color.green.opacity(0.7)).frame(width: 4, height: 3)
                    }
                    .offset(x: -8, y: -6)
                    
                    HStack(spacing: 1) {
                        RoundedRectangle(cornerRadius: 1)
                            .fill(Color.green.opacity(0.7))
                            .frame(width: 8, height: 5)
                        Circle().fill(Color.green.opacity(0.7)).frame(width: 3, height: 3)
                    }
                    .offset(x: 2, y: -2)
                    
                    Circle().fill(Color.green.opacity(0.7)).frame(width: 5, height: 4)
                        .offset(x: -6, y: 2)
                }
                
                // Location pin - prominent and centered
                VStack(spacing: -1) {
                    Circle()
                        .fill(Color.primaryOrange)
                        .frame(width: 10, height: 10)
                        .overlay(
                            Circle()
                                .fill(Color.white)
                                .frame(width: 4, height: 4)
                        )
                    
                    // Pin stem
                    Path { path in
                        path.move(to: CGPoint(x: 0, y: 0))
                        path.addLine(to: CGPoint(x: 5, y: 8))
                        path.addLine(to: CGPoint(x: -5, y: 8))
                        path.closeSubpath()
                    }
                    .fill(Color.primaryOrange)
                    .frame(width: 10, height: 8)
                }
                .offset(x: 8, y: -5)
                .shadow(color: .black.opacity(0.2), radius: 2, x: 1, y: 1)
            }
        }
    }
}

// MARK: - Sports Visual (Sports Preferences Step)
struct SportsVisual: View {
    var body: some View {
        ZStack {
            // Background circle
            Circle()
                .fill(
                    RadialGradient(
                        colors: [.primaryOrange.opacity(0.3), .primaryOrange.opacity(0.1)],
                        center: .center,
                        startRadius: 10,
                        endRadius: 40
                    )
                )
                .frame(width: 80, height: 80)
            
            // Main content
            ZStack {
                // Modern card background
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.white)
                    .frame(width: 45, height: 45)
                    .shadow(color: .black.opacity(0.1), radius: 6, x: 0, y: 3)
                
                // Sport icons grid (2x2)
                VStack(spacing: 4) {
                    HStack(spacing: 4) {
                        Image(systemName: "basketball.fill")
                            .font(.system(size: 8, weight: .medium))
                            .foregroundColor(.primaryOrange)
                        
                        Image(systemName: "tennis.racket")
                            .font(.system(size: 8, weight: .medium))
                            .foregroundColor(.primaryOrange.opacity(0.7))
                    }
                    
                    HStack(spacing: 4) {
                        Image(systemName: "figure.run")
                            .font(.system(size: 8, weight: .medium))
                            .foregroundColor(.primaryOrange.opacity(0.7))
                        
                        Image(systemName: "dumbbell.fill")
                            .font(.system(size: 8, weight: .medium))
                            .foregroundColor(.primaryOrange)
                    }
                }
                
                // Selection indicator
                Circle()
                    .fill(Color.primaryOrange)
                    .frame(width: 12, height: 12)
                    .overlay(
                        Image(systemName: "checkmark")
                            .font(.system(size: 6, weight: .bold))
                            .foregroundColor(.white)
                    )
                    .offset(x: 14, y: 14)
            }
        }
    }
}

// MARK: - Success Visual (Registration Complete)
struct SuccessVisual: View {
    @State private var isAnimating = false
    
    var body: some View {
        ZStack {
            // Success burst background
            ForEach(0..<8, id: \.self) { index in
                Rectangle()
                    .fill(LinearGradient(colors: [.green, .green.opacity(0.3)], startPoint: .leading, endPoint: .trailing))
                    .frame(width: 30, height: 3)
                    .offset(x: 15)
                    .rotationEffect(.degrees(Double(index) * 45))
                    .scaleEffect(isAnimating ? 1.2 : 0.8)
                    .opacity(isAnimating ? 1.0 : 0.6)
            }
            
            // Central checkmark
            Circle()
                .fill(LinearGradient(colors: [.green, .green.opacity(0.8)], startPoint: .topLeading, endPoint: .bottomTrailing))
                .frame(width: 50, height: 50)
                .overlay(
                    Image(systemName: "checkmark")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.white)
                )
                .scaleEffect(isAnimating ? 1.1 : 1.0)
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true)) {
                isAnimating = true
            }
        }
    }
}
