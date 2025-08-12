// BuddyBuilder/Core/Extensions/Color+Extensions.swift
import SwiftUI
import UIKit

extension Color {
    // MARK: - Brand Colors (Always Fixed)
    static let primaryOrange = Color(red: 1.0, green: 0.42, blue: 0.21) // Mevcut brand color korunacak
    
    // MARK: - Semantic Background Colors (Dark Mode Adaptive)
    static var dynamicBackground: Color {
        Color(UIColor.systemBackground)
    }
    
    static var dynamicSecondaryBackground: Color {
        Color(UIColor.secondarySystemBackground)
    }
    
    static var dynamicTertiaryBackground: Color {
        Color(UIColor.tertiarySystemBackground)
    }
    
    static var dynamicGroupedBackground: Color {
        Color(UIColor.systemGroupedBackground)
    }
    
    static var dynamicSecondaryGroupedBackground: Color {
        Color(UIColor.secondarySystemGroupedBackground)
    }
    
    // MARK: - Card & Component Backgrounds
    static var cardBackground: Color {
        Color(UIColor.secondarySystemBackground)
    }
    
    static var formBackground: Color {
        Color(UIColor.tertiarySystemBackground)
    }
    
    static var headerBackground: Color {
        Color(UIColor.systemBackground).opacity(0.95)
    }
    
    // MARK: - Text Colors (Dark Mode Adaptive)
    static var primaryText: Color {
        Color(UIColor.label)
    }
    
    static var secondaryText: Color {
        Color(UIColor.secondaryLabel)
    }
    
    static var tertiaryText: Color {
        Color(UIColor.tertiaryLabel)
    }
    
    static var placeholderText: Color {
        Color(UIColor.placeholderText)
    }
    
    // MARK: - Border & Separator Colors
    static var dynamicBorder: Color {
        Color(UIColor.separator)
    }
    
    static var formBorder: Color {
        Color(UIColor.separator).opacity(0.6)
    }
    
    // MARK: - Shadow Colors (Dark Mode Adaptive)
    static var dynamicShadow: Color {
        Color(UIColor.label).opacity(0.1)
    }
    
    // MARK: - Overlay Colors
    static var overlayBackground: Color {
        Color(UIColor.label).opacity(0.4)
    }
    
    // MARK: - Status Colors (Always Fixed)
    static let successGreen = Color.green
    static let errorRed = Color.red
    static let warningOrange = Color.orange
    static let infoBlue = Color.blue
    
    // MARK: - Legacy Support (Gradually Remove These)
    @available(*, deprecated, message: "Use primaryText instead")
    static var textPrimary: Color { primaryText }
    
    @available(*, deprecated, message: "Use secondaryText instead")
    static var textSecondary: Color { secondaryText }
    
    @available(*, deprecated, message: "Use cardBackground instead")
    static var backgroundGradient: Color { cardBackground }
}

// BuddyBuilder/Core/Extensions/Color+Extensions.swift (Animation helpers ekleme)

extension Color {
    // MARK: - Animation Helpers
    static func animatedTransition(
        light: Color,
        dark: Color,
        colorScheme: ColorScheme,
        duration: Double = 0.3
    ) -> Color {
        return colorScheme == .light ? light : dark
    }
    
    // MARK: - Smooth Transition Colors
    static var smoothCardBackground: Color {
        Color(UIColor { traitCollection in
            return traitCollection.userInterfaceStyle == .dark ?
                UIColor.secondarySystemBackground :
                UIColor.systemBackground
        })
    }
    
    static var smoothTextPrimary: Color {
        Color(UIColor { traitCollection in
            return traitCollection.userInterfaceStyle == .dark ?
                UIColor.label :
                UIColor.label
        })
    }
}

extension Color {
    // MARK: - Adaptive Shadow Colors
    static func adaptiveShadow(for colorScheme: ColorScheme, intensity: ShadowIntensity = .medium) -> Color {
        let baseOpacity: Double
        
        switch intensity {
        case .subtle:
            baseOpacity = colorScheme == .light ? 0.05 : 0.15
        case .medium:
            baseOpacity = colorScheme == .light ? 0.1 : 0.2
        case .strong:
            baseOpacity = colorScheme == .light ? 0.15 : 0.3
        case .dramatic:
            baseOpacity = colorScheme == .light ? 0.2 : 0.4
        }
        
        return Color(UIColor.label).opacity(baseOpacity)
    }
    
    enum ShadowIntensity {
        case subtle, medium, strong, dramatic
    }
}


extension View {
    func adaptiveShadow(
        intensity: Color.ShadowIntensity = .medium,
        radius: CGFloat = 8,
        x: CGFloat = 0,
        y: CGFloat = 4
    ) -> some View {
        self.shadow(
            color: Color.adaptiveShadow(for: .light, intensity: intensity), // SwiftUI otomatik handle edecek
            radius: radius,
            x: x,
            y: y
        )
        .environment(\.colorScheme, .light) // Bu satır gereksiz, SwiftUI otomatik yapacak
    }
}
