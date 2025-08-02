import Foundation
import SwiftUI
// MARK: - Settings Section Types
enum SettingsSection: String, CaseIterable {
    case account = "settings.account"
    case languageRegion = "settings.language_region"
    case notifications = "settings.notifications"
    case support = "settings.support"
    
    var title: String {
        return rawValue
    }
    
    var icon: String {
        switch self {
        case .account:
            return "person.circle"
        case .languageRegion:
            return "globe.asia.australia"
        case .notifications:
            return "bell.circle"
        case .support:
            return "questionmark.circle"
        }
    }
    
    var color: Color {
        switch self {
        case .account:
            return .primaryOrange
        case .languageRegion:
            return .blue
        case .notifications:
            return .green
        case .support:
            return .purple
        }
    }
}

// MARK: - Account Menu Items
enum AccountMenuItem: String, CaseIterable {
    case personalDetails = "settings.account.personal_details"
    case changePassword = "settings.account.change_password"
    case deleteAccount = "settings.account.delete_account"
    
    var title: String {
        return rawValue
    }
    
    var icon: String {
        switch self {
        case .personalDetails:
            return "person.text.rectangle"
        case .changePassword:
            return "key.horizontal"
        case .deleteAccount:
            return "trash.circle"
        }
    }
    
    var color: Color {
        switch self {
        case .personalDetails:
            return .blue
        case .changePassword:
            return .orange
        case .deleteAccount:
            return .red
        }
    }
}

// MARK: - Language & Region Menu Items
enum LanguageRegionMenuItem: String, CaseIterable {
    case changeLanguage = "settings.language_region.change_language"
    case country = "settings.language_region.country"
    case city = "settings.language_region.city"
    
    var title: String {
        return rawValue
    }
    
    var icon: String {
        switch self {
        case .changeLanguage:
            return "textformat.abc"
        case .country:
            return "flag"
        case .city:
            return "location"
        }
    }
    
    var color: Color {
        switch self {
        case .changeLanguage:
            return .blue
        case .country:
            return .green
        case .city:
            return .orange
        }
    }
}

// MARK: - Support Menu Items
enum SupportMenuItem: String, CaseIterable {
    case contactSupport = "settings.support.contact_support"
    case reportBug = "settings.support.report_bug"
    case sendFeedback = "settings.support.send_feedback"
    case rateApp = "settings.support.rate_app"
    
    var title: String {
        return rawValue
    }
    
    var icon: String {
        switch self {
        case .contactSupport:
            return "headphones.circle"
        case .reportBug:
            return "ant.circle"
        case .sendFeedback:
            return "message.circle"
        case .rateApp:
            return "star.circle"
        }
    }
    
    var color: Color {
        switch self {
        case .contactSupport:
            return .blue
        case .reportBug:
            return .red
        case .sendFeedback:
            return .green
        case .rateApp:
            return .yellow
        }
    }
}
