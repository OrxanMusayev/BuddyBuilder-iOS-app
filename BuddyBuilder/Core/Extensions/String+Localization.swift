import Foundation
import SwiftUI

// MARK: - String Localization Extensions
extension String {
    /// Localizes the string using the LocalizationManager
    /// - Parameter manager: The localization manager to use for translation
    /// - Returns: Localized string or the original key if translation not found
    @MainActor
    func localized(using manager: LocalizationManager) -> String {
        return manager.translate(self)
    }
}

// MARK: - Text View Extension for Localization
extension Text {
    /// Creates a Text view with localized content
    /// - Parameters:
    ///   - key: The localization key
    ///   - manager: The localization manager
    /// - Returns: Text view with localized content
    @MainActor
    static func localized(_ key: String, using manager: LocalizationManager) -> Text {
        return Text(key.localized(using: manager))
    }
}

// MARK: - View Modifier for Localization
struct LocalizedTextModifier: ViewModifier {
    let key: String
    @ObservedObject var localizationManager: LocalizationManager
    
    init(_ key: String, localizationManager: LocalizationManager) {
        self.key = key
        self.localizationManager = localizationManager
    }
    
    @MainActor
    func body(content: Content) -> some View {
        Text(key.localized(using: localizationManager))
    }
}

// MARK: - View Extension for Easy Localization
extension View {
    /// Applies localized text to a view
    /// - Parameters:
    ///   - key: The localization key
    ///   - manager: The localization manager
    /// - Returns: Modified view with localized text
    @MainActor
    func localizedText(_ key: String, using manager: LocalizationManager) -> some View {
        Text(key.localized(using: manager))
    }
}

// MARK: - Button Extension for Localized Titles
extension Button where Label == Text {
    /// Creates a button with localized title
    /// - Parameters:
    ///   - titleKey: The localization key for the title
    ///   - manager: The localization manager
    ///   - action: The action to perform when button is tapped
    @MainActor
    init(localizedTitle titleKey: String,
         using manager: LocalizationManager,
         action: @escaping () -> Void) {
        self.init(action: action) {
            Text(titleKey.localized(using: manager))
        }
    }
}
