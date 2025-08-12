// BuddyBuilder/Features/Profile/Views/SettingsView.swift

import SwiftUI

// MARK: - Settings View Model
class SettingsViewModel: ObservableObject {
    @Published var isLoading = false
    @Published var errorMessage: String = ""
    @Published var showError = false
    @Published var notificationsEnabled = true
    @Published var selectedLanguage = "English"
    
    func handleError(_ message: String) {
        errorMessage = message
        showError = true
        print("❌ Settings Error: \(message)")
    }
}

// MARK: - Settings Menu Item Model
struct SettingsMenuItem {
    let id: String
    let title: String
    let subtitle: String?
    let customIcon: String
    let iconColor: Color
    let backgroundColor: Color
    let action: () -> Void
}

// MARK: - Settings View
struct SettingsView: View {
    @StateObject private var viewModel = SettingsViewModel()
    @EnvironmentObject var localizationManager: LocalizationManager
    @Environment(\.dismiss) var dismiss
    @State private var navigateToAccount = false
    @State private var navigateToLanguageRegion = false
    @State private var navigateToNotifications = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Background
                LoginBackgroundView()
                
                VStack(spacing: 0) {
                    // Custom Header
                    customHeader
                    
                    // Settings Content
                    settingsContent
                }
            }
            .navigationDestination(isPresented: $navigateToAccount) {
                AccountSettingsView()
                    .environmentObject(localizationManager)
            }
            .navigationDestination(isPresented: $navigateToLanguageRegion) {
                LanguageRegionSettingsView()
                    .environmentObject(localizationManager)
            }
            .navigationDestination(isPresented: $navigateToNotifications) {
                NotificationSettingsView()
                    .environmentObject(localizationManager)
            }
        }
        .navigationBarHidden(true)
        .alert("settings.error.title".localized(using: localizationManager), isPresented: $viewModel.showError) {
            Button("common.ok".localized(using: localizationManager)) { }
        } message: {
            Text(viewModel.errorMessage)
        }
    }
    
    // MARK: - Custom Header
    private var customHeader: some View {
        VStack(spacing: 16) {
            HStack {
                // Back button - sadece ok işareti
                Button(action: { dismiss() }) {
                    Image(systemName: "arrow.left")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.primaryOrange)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                }
                
                Spacer()
                
                // Title
                Text("settings.title".localized(using: localizationManager))
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundColor(.textPrimary)
                
                Spacer()
                
                // Balance space for back button
                HStack { }
                    .frame(width: 44) // ok işaretinin genişliği kadar
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .background(Color.white.opacity(0.95))
    }
    
    // MARK: - Settings Content
    private var settingsContent: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Main Settings Menu
                mainSettingsMenu
                
                // App Info Section
                appInfoSection
                
                Spacer(minLength: 40)
            }
            .padding(.horizontal, 20)
            .padding(.top, 20)
        }
    }
    
    // MARK: - Main Settings Menu
    private var mainSettingsMenu: some View {
        VStack(spacing: 0) {
            ForEach(Array(settingsMenuItems.enumerated()), id: \.offset) { index, item in
                SettingsMenuItemView(item: item)
                
                if index < settingsMenuItems.count - 1 {
                    SettingsMenuDivider()
                }
            }
        }
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .shadow(color: .black.opacity(0.05), radius: 10, x: 0, y: 4)
    }
    
    // MARK: - App Info Section
    private var appInfoSection: some View {
        VStack(spacing: 16) {
            HStack {
                Image(systemName: "info.circle")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.primaryOrange)
                
                Text("settings.section.app_info".localized(using: localizationManager))
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.textPrimary)
                
                Spacer()
            }
            
            VStack(spacing: 12) {
                HStack {
                    Text("settings.app.version".localized(using: localizationManager))
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.textSecondary)
                    
                    Spacer()
                    
                    Text("1.0.0")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.textPrimary)
                }
                
                HStack {
                    Text("settings.app.build".localized(using: localizationManager))
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.textSecondary)
                    
                    Spacer()
                    
                    Text("2024.08.02")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.textPrimary)
                }
            }
        }
        .padding(20)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .shadow(color: .black.opacity(0.05), radius: 10, x: 0, y: 4)
    }
    
    // MARK: - Settings Menu Items Configuration
    private var settingsMenuItems: [SettingsMenuItem] {
        [
            SettingsMenuItem(
                id: "account",
                title: "settings.menu.account".localized(using: localizationManager),
                subtitle: nil,
                customIcon: "person.crop.circle.badge.checkmark",
                iconColor: .blue,
                backgroundColor: Color.blue.opacity(0.1),
                action: {
                    navigateToAccount = true
                }
            ),
            SettingsMenuItem(
                id: "language",
                title: "settings.menu.language".localized(using: localizationManager),
                subtitle: nil,
                customIcon: "globe.americas.fill",
                iconColor: .green,
                backgroundColor: Color.green.opacity(0.1),
                action: {
                    navigateToLanguageRegion = true
                }
            ),
            SettingsMenuItem(
                id: "notifications",
                title: "settings.menu.notifications".localized(using: localizationManager),
                subtitle: nil,
                customIcon: "bell.badge.fill",
                iconColor: .orange,
                backgroundColor: Color.orange.opacity(0.1),
                action: {
                    navigateToNotifications = true
                }
            ),
            SettingsMenuItem(
                id: "support",
                title: "settings.menu.support".localized(using: localizationManager),
                subtitle: nil,
                customIcon: "questionmark.circle.fill",
                iconColor: .purple,
                backgroundColor: Color.purple.opacity(0.1),
                action: {
                    // TODO: Navigate to Support & Feedback
                    print("🟣 Support settings tapped")
                }
            )
        ]
    }
}

// MARK: - Settings Menu Item View
struct SettingsMenuItemView: View {
    let item: SettingsMenuItem
    
    var body: some View {
        Button(action: item.action) {
            HStack(spacing: 16) {
                // Outline (içi boş) siyah iconlar
                Image(systemName: getOutlineIcon(item.customIcon))
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(.primaryText)
                    .frame(width: 24, height: 24)
                
                // Title
                Text(item.title)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.primaryText)
                    .lineLimit(1)
                
                Spacer()
                
                // Arrow
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.tertiaryText)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    // Icon'ları outline (içi boş) versiyonlarına çevir
    private func getOutlineIcon(_ icon: String) -> String {
        switch icon {
        case "person.crop.circle.badge.checkmark":
            return "person.crop.circle"
        case "globe.americas.fill":
            return "globe.americas"
        case "bell.badge.fill":
            return "bell.badge"
        case "questionmark.circle.fill":
            return "questionmark.circle"
        default:
            return icon
        }
    }
}

// MARK: - Settings Menu Divider
struct SettingsMenuDivider: View {
    var body: some View {
        Divider()
            .padding(.leading, 60) // Icon width'e göre ayarlandı (24 + 16 + 20)
            .background(Color.dynamicBorder.opacity(0.3))
    }
}

// MARK: - Settings Localization Keys Extension
extension String {
    // Settings Keys
    static let settingsTitle = "settings.title"
    static let settingsErrorTitle = "settings.error.title"
    
    // Settings Sections
    static let settingsSectionAppInfo = "settings.section.app_info"
    
    // Settings Menu Items
    static let settingsMenuAccount = "settings.menu.account"
    static let settingsMenuLanguage = "settings.menu.language"
    static let settingsMenuNotifications = "settings.menu.notifications"
    static let settingsMenuSupport = "settings.menu.support"
    
    // App Info
    static let settingsAppVersion = "settings.app.version"
    static let settingsAppBuild = "settings.app.build"
}

// MARK: - Preview
#Preview {
    SettingsView()
        .environmentObject(LocalizationManager())
}
