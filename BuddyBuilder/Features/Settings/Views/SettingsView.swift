import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var localizationManager: LocalizationManager
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Background
                LoginBackgroundView()
                
                VStack(spacing: 0) {
                    // Custom Header
                    customHeader
                    
                    // Settings Content
                    ScrollView {
                        VStack(spacing: 16) {
                            ForEach(SettingsSection.allCases, id: \.self) { section in
                                NavigationLink(destination: destinationView(for: section)) {
                                    SettingsMenuRow(
                                        icon: section.icon,
                                        title: section.title.localized(using: localizationManager),
                                        subtitle: getSubtitle(for: section),
                                        color: section.color
                                    )
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 20)
                    }
                }
            }
        }
        .navigationBarHidden(true)
    }
    
    // MARK: - Custom Header
    private var customHeader: some View {
        VStack(spacing: 16) {
            HStack {
                // Back button
                Button(action: { dismiss() }) {
                    HStack(spacing: 8) {
                        Image(systemName: "arrow.left")
                            .font(.system(size: 16, weight: .medium))
                        Text("common.back".localized(using: localizationManager))
                            .font(.system(size: 16, weight: .medium))
                    }
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
                
                // Placeholder for symmetry
                Color.clear
                    .frame(width: 80)
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .background(Color.white.opacity(0.95))
    }
    
    // MARK: - Destination Views
    @ViewBuilder
    private func destinationView(for section: SettingsSection) -> some View {
        switch section {
        case .account:
            AccountSettingsView()
                .environmentObject(localizationManager)
        case .languageRegion:
            LanguageRegionSettingsView()
                .environmentObject(localizationManager)
        case .notifications:
            NotificationSettingsView()
                .environmentObject(localizationManager)
        case .support:
            SupportSettingsView()
                .environmentObject(localizationManager)
        }
    }
    
    // MARK: - Subtitle Helper
    private func getSubtitle(for section: SettingsSection) -> String {
        switch section {
        case .account:
            return "settings.account.subtitle".localized(using: localizationManager)
        case .languageRegion:
            return localizationManager.currentLanguage!.nativeName
        case .notifications:
            return "settings.notifications.subtitle".localized(using: localizationManager)
        case .support:
            return "settings.support.subtitle".localized(using: localizationManager)
        }
    }
}

// MARK: - Account Settings View
struct AccountSettingsView: View {
    @EnvironmentObject var localizationManager: LocalizationManager
    @Environment(\.dismiss) var dismiss
    @State private var showDeleteConfirmation = false
    
    var body: some View {
        ZStack {
            // Background
            LoginBackgroundView()
            
            VStack(spacing: 0) {
                // Custom Header
                SettingsSubHeader(
                    title: "settings.account".localized(using: localizationManager),
                    dismiss: dismiss
                )
                
                // Account Menu Content
                ScrollView {
                    VStack(spacing: 16) {
                        ForEach(AccountMenuItem.allCases, id: \.self) { item in
                            Button(action: {
                                handleAccountAction(item)
                            }) {
                                SettingsMenuRow(
                                    icon: item.icon,
                                    title: item.title.localized(using: localizationManager),
                                    subtitle: getAccountSubtitle(for: item),
                                    color: item.color,
                                    showArrow: item != .deleteAccount
                                )
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                }
            }
        }
        .navigationBarHidden(true)
        .alert("settings.account.delete_account.confirmation.title".localized(using: localizationManager),
               isPresented: $showDeleteConfirmation) {
            Button("common.cancel".localized(using: localizationManager), role: .cancel) { }
            Button("settings.account.delete_account.confirmation.delete".localized(using: localizationManager),
                   role: .destructive) {
                // TODO: Implement account deletion
            }
        } message: {
            Text("settings.account.delete_account.confirmation.message".localized(using: localizationManager))
        }
    }
    
    private func handleAccountAction(_ item: AccountMenuItem) {
        switch item {
        case .personalDetails:
            // TODO: Navigate to personal details
            break
        case .changePassword:
            // TODO: Navigate to change password
            break
        case .deleteAccount:
            showDeleteConfirmation = true
        }
    }
    
    private func getAccountSubtitle(for item: AccountMenuItem) -> String {
        switch item {
        case .personalDetails:
            return "settings.account.personal_details.subtitle".localized(using: localizationManager)
        case .changePassword:
            return "settings.account.change_password.subtitle".localized(using: localizationManager)
        case .deleteAccount:
            return "settings.account.delete_account.subtitle".localized(using: localizationManager)
        }
    }
}

// MARK: - Language & Region Settings View
struct LanguageRegionSettingsView: View {
    @EnvironmentObject var localizationManager: LocalizationManager
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        ZStack {
            LoginBackgroundView()
            
            VStack(spacing: 0) {
                SettingsSubHeader(
                    title: "settings.language_region".localized(using: localizationManager),
                    dismiss: dismiss
                )
                
                ScrollView {
                    VStack(spacing: 16) {
                        ForEach(LanguageRegionMenuItem.allCases, id: \.self) { item in
                            Button(action: {
                                handleLanguageRegionAction(item)
                            }) {
                                SettingsMenuRow(
                                    icon: item.icon,
                                    title: item.title.localized(using: localizationManager),
                                    subtitle: getLanguageRegionSubtitle(for: item),
                                    color: item.color
                                )
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                }
            }
        }
        .navigationBarHidden(true)
    }
    
    private func handleLanguageRegionAction(_ item: LanguageRegionMenuItem) {
        switch item {
        case .changeLanguage:
            // TODO: Show language picker
            break
        case .country:
            // TODO: Show country picker
            break
        case .city:
            // TODO: Show city picker
            break
        }
    }
    
    private func getLanguageRegionSubtitle(for item: LanguageRegionMenuItem) -> String {
        switch item {
        case .changeLanguage:
            return localizationManager.currentLanguage!.nativeName
        case .country:
            return "Turkey" // TODO: Get from user profile
        case .city:
            return "Istanbul" // TODO: Get from user profile
        }
    }
}

// MARK: - Notification Settings View
struct NotificationSettingsView: View {
    @EnvironmentObject var localizationManager: LocalizationManager
    @Environment(\.dismiss) var dismiss
    @State private var notificationSettings = NotificationSettings.default
    
    var body: some View {
        ZStack {
            LoginBackgroundView()
            
            VStack(spacing: 0) {
                SettingsSubHeader(
                    title: "settings.notifications".localized(using: localizationManager),
                    dismiss: dismiss
                )
                
                ScrollView {
                    VStack(spacing: 20) {
                        // Push Notifications Toggle
                        NotificationToggleRow(
                            title: "settings.notifications.push_notifications".localized(using: localizationManager),
                            subtitle: "settings.notifications.push_notifications.subtitle".localized(using: localizationManager),
                            isEnabled: $notificationSettings.pushNotificationsEnabled,
                            icon: "bell.fill"
                        )
                        
                        // Event Reminders Toggle
                        NotificationToggleRow(
                            title: "settings.notifications.event_reminders".localized(using: localizationManager),
                            subtitle: "settings.notifications.event_reminders.subtitle".localized(using: localizationManager),
                            isEnabled: $notificationSettings.eventRemindersEnabled,
                            icon: "calendar.badge.clock"
                        )
                        
                        // Messaging Toggle
                        NotificationToggleRow(
                            title: "settings.notifications.messaging".localized(using: localizationManager),
                            subtitle: "settings.notifications.messaging.subtitle".localized(using: localizationManager),
                            isEnabled: $notificationSettings.messagingEnabled,
                            icon: "message.fill"
                        )
                        
                        // Marketing Toggle
                        NotificationToggleRow(
                            title: "settings.notifications.marketing".localized(using: localizationManager),
                            subtitle: "settings.notifications.marketing.subtitle".localized(using: localizationManager),
                            isEnabled: $notificationSettings.marketingEnabled,
                            icon: "megaphone.fill"
                        )
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                }
            }
        }
        .navigationBarHidden(true)
    }
}

// MARK: - Support Settings View
struct SupportSettingsView: View {
    @EnvironmentObject var localizationManager: LocalizationManager
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        ZStack {
            LoginBackgroundView()
            
            VStack(spacing: 0) {
                SettingsSubHeader(
                    title: "settings.support".localized(using: localizationManager),
                    dismiss: dismiss
                )
                
                ScrollView {
                    VStack(spacing: 16) {
                        ForEach(SupportMenuItem.allCases, id: \.self) { item in
                            Button(action: {
                                handleSupportAction(item)
                            }) {
                                SettingsMenuRow(
                                    icon: item.icon,
                                    title: item.title.localized(using: localizationManager),
                                    subtitle: getSupportSubtitle(for: item),
                                    color: item.color
                                )
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                }
            }
        }
        .navigationBarHidden(true)
    }
    
    private func handleSupportAction(_ item: SupportMenuItem) {
        switch item {
        case .contactSupport:
            // TODO: Open email composer or support chat
            break
        case .reportBug:
            // TODO: Open bug report form
            break
        case .sendFeedback:
            // TODO: Open feedback form
            break
        case .rateApp:
            // TODO: Open App Store rating
            break
        }
    }
    
    private func getSupportSubtitle(for item: SupportMenuItem) -> String {
        switch item {
        case .contactSupport:
            return "settings.support.contact_support.subtitle".localized(using: localizationManager)
        case .reportBug:
            return "settings.support.report_bug.subtitle".localized(using: localizationManager)
        case .sendFeedback:
            return "settings.support.send_feedback.subtitle".localized(using: localizationManager)
        case .rateApp:
            return "settings.support.rate_app.subtitle".localized(using: localizationManager)
        }
    }
}

// MARK: - Supporting Views

// Settings Menu Row
struct SettingsMenuRow: View {
    let icon: String
    let title: String
    let subtitle: String
    let color: Color
    var showArrow: Bool = true
    
    var body: some View {
        HStack(spacing: 16) {
            // Icon
            ZStack {
                Circle()
                    .fill(color.opacity(0.1))
                    .frame(width: 44, height: 44)
                
                Image(systemName: icon)
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(color)
            }
            
            // Text Content
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.textPrimary)
                    .lineLimit(1)
                
                Text(subtitle)
                    .font(.system(size: 14))
                    .foregroundColor(.textSecondary)
                    .lineLimit(2)
            }
            
            Spacer()
            
            // Arrow
            if showArrow {
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.textSecondary)
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 3)
    }
}

// Settings Sub Header
struct SettingsSubHeader: View {
    let title: String
    let dismiss: DismissAction
    
    var body: some View {
        VStack(spacing: 16) {
            HStack {
                Button(action: { dismiss() }) {
                    HStack(spacing: 8) {
                        Image(systemName: "arrow.left")
                            .font(.system(size: 16, weight: .medium))
                        Text("common.back")
                            .font(.system(size: 16, weight: .medium))
                    }
                    .foregroundColor(.primaryOrange)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                }
                
                Spacer()
                
                Text(title)
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundColor(.textPrimary)
                
                Spacer()
                
                Color.clear
                    .frame(width: 80)
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .background(Color.white.opacity(0.95))
    }
}

// Notification Toggle Row
struct NotificationToggleRow: View {
    let title: String
    let subtitle: String
    @Binding var isEnabled: Bool
    let icon: String
    
    var body: some View {
        HStack(spacing: 16) {
            // Icon
            ZStack {
                Circle()
                    .fill(isEnabled ? Color.green.opacity(0.1) : Color.gray.opacity(0.1))
                    .frame(width: 44, height: 44)
                
                Image(systemName: icon)
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(isEnabled ? .green : .gray)
            }
            
            // Text Content
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.textPrimary)
                    .lineLimit(1)
                
                Text(subtitle)
                    .font(.system(size: 14))
                    .foregroundColor(.textSecondary)
                    .lineLimit(2)
            }
            
            Spacer()
            
            // Toggle
            Toggle("", isOn: $isEnabled)
                .toggleStyle(SwitchToggleStyle(tint: .primaryOrange))
                .scaleEffect(0.9)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 3)
    }
}

// MARK: - Preview
#Preview {
    SettingsView()
        .environmentObject(LocalizationManager())
}
