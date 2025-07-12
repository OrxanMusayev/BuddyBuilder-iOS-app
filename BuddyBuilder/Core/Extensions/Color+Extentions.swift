
import SwiftUI

extension Color {
    // Ana renkler (SCSS'den adapte edildi)
    static let primaryOrange = Color(red: 1.0, green: 0.42, blue: 0.21) // #FF6B35
    static let primaryDarkOrange = Color(red: 204.0, green: 102, blue: 0)
    static let primaryBlue = Color(red: 0.4, green: 0.49, blue: 0.92) // #667eea
    static let primaryPurple = Color(red: 0.46, green: 0.29, blue: 0.64) // #764ba2
    
    // Gradient renkler
    static let backgroundGradient = LinearGradient(
        colors: [primaryBlue, primaryPurple, primaryOrange],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    // Form renkler
    static let formBackground = Color(red: 0.98, green: 0.98, blue: 0.99) // #fafbfc
    static let formBorder = Color(red: 0.9, green: 0.91, blue: 0.92) // #e5e7eb
    static let textPrimary = Color(red: 0.22, green: 0.25, blue: 0.32) // #374151
    static let textSecondary = Color(red: 0.61, green: 0.64, blue: 0.69) // #9ca3af
}
