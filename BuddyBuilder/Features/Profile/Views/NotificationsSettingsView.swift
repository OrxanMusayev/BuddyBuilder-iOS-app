// BuddyBuilder/Features/Profile/Views/NotificationSettingsView.swift

import SwiftUI

// MARK: - Notification Settings View Model
class NotificationSettingsViewModel: ObservableObject {
    @Published var isLoading = false
    @Published var errorMessage: String = ""
    @Published var showError = false
    
    // Notification settings
    @Published var pushNotificationsEnabled = true
    @Published var emailNotificationsEnabled = false
    @Published var smsNotificationsEnabled = false
    @Published var eventRemindersEnabled = true
    @Published var chatMessagesEnabled = true
    @Published var matchUpdatesEnabled = true
    @Published var promotionalNotificationsEnabled = false
    
    func handleError(_ message: String) {
        errorMessage = message
        showError = true
        print("❌ Notification Settings Error: \(message)")
    }
    
    func saveNotificationSettings() {
        // TODO: Implement save notification settings to backend
        print("💾 Saving notification settings...")
        print("Push: \(pushNotificationsEnabled)")
        print("Email: \(emailNotificationsEnabled)")
        print("SMS: \(smsNotificationsEnabled)")
        print("Event Reminders: \(eventRemindersEnabled)")
        print("Chat Messages: \(chatMessagesEnabled)")
        print("Match Updates: \(matchUpdatesEnabled)")
        print("Promotional: \(promotionalNotificationsEnabled)")
    }
}

// MARK: - Notification Setting Item Model
struct NotificationSettingItem {
    let id: String
    let title: String
    let description: String
    let customIcon: String
    let iconColor: Color
    let backgroundColor: Color
    let binding: Binding<Bool>
}

// MARK: - Notification Settings View
struct NotificationSettingsView: View {
    @StateObject private var viewModel = NotificationSettingsViewModel()
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
                    
                    // Notification Settings Content
                    notificationSettingsContent
                }
            }
        }
        .navigationBarHidden(true)
        .alert("notifications.error.title".localized(using: localizationManager), isPresented: $viewModel.showError) {
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
                Text("notifications.title".localized(using: localizationManager))
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
    
    // MARK: - Notification Settings Content
    private var notificationSettingsContent: some View {
        ScrollView {
            VStack(spacing: 24) {
                // General Notifications Section
                generalNotificationsSection
                
                // App Features Section
                appFeaturesSection
                
                // Marketing Section
                marketingSection
                
                Spacer(minLength: 40)
            }
            .padding(.horizontal, 20)
            .padding(.top, 20)
        }
    }
    
    // MARK: - General Notifications Section
    private var generalNotificationsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            sectionHeader(
                title: "notifications.section.general".localized(using: localizationManager),
                icon: "bell.circle"
            )
            
            VStack(spacing: 0) {
                ForEach(Array(generalNotificationItems.enumerated()), id: \.offset) { index, item in
                    NotificationSettingItemView(item: item)
                    
                    if index < generalNotificationItems.count - 1 {
                        NotificationDivider()
                    }
                }
            }
            .background(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
        }
    }
    
    // MARK: - App Features Section
    private var appFeaturesSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            sectionHeader(
                title: "notifications.section.features".localized(using: localizationManager),
                icon: "app.badge"
            )
            
            VStack(spacing: 0) {
                ForEach(Array(appFeatureNotificationItems.enumerated()), id: \.offset) { index, item in
                    NotificationSettingItemView(item: item)
                    
                    if index < appFeatureNotificationItems.count - 1 {
                        NotificationDivider()
                    }
                }
            }
            .background(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
        }
    }
    
    // MARK: - Marketing Section
    private var marketingSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            sectionHeader(
                title: "notifications.section.marketing".localized(using: localizationManager),
                icon: "megaphone"
            )
            
            VStack(spacing: 0) {
                ForEach(Array(marketingNotificationItems.enumerated()), id: \.offset) { index, item in
                    NotificationSettingItemView(item: item)
                    
                    if index < marketingNotificationItems.count - 1 {
                        NotificationDivider()
                    }
                }
            }
            .background(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
        }
    }
    
    // MARK: - Section Header
    private func sectionHeader(title: String, icon: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.primaryOrange)
            
            Text(title)
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.textPrimary)
            
            Spacer()
        }
        .padding(.horizontal, 4)
    }
    
    // MARK: - General Notification Items
    private var generalNotificationItems: [NotificationSettingItem] {
        [
            NotificationSettingItem(
                id: "push",
                title: "notifications.push.title".localized(using: localizationManager),
                description: "notifications.push.description".localized(using: localizationManager),
                customIcon: "iphone.radiowaves.left.and.right",
                iconColor: .blue,
                backgroundColor: Color.blue.opacity(0.1),
                binding: $viewModel.pushNotificationsEnabled
            ),
            NotificationSettingItem(
                id: "email",
                title: "notifications.email.title".localized(using: localizationManager),
                description: "notifications.email.description".localized(using: localizationManager),
                customIcon: "envelope.badge",
                iconColor: .green,
                backgroundColor: Color.green.opacity(0.1),
                binding: $viewModel.emailNotificationsEnabled
            ),
            NotificationSettingItem(
                id: "sms",
                title: "notifications.sms.title".localized(using: localizationManager),
                description: "notifications.sms.description".localized(using: localizationManager),
                customIcon: "message.badge",
                iconColor: .orange,
                backgroundColor: Color.orange.opacity(0.1),
                binding: $viewModel.smsNotificationsEnabled
            )
        ]
    }
    
    // MARK: - App Feature Notification Items
    private var appFeatureNotificationItems: [NotificationSettingItem] {
        [
            NotificationSettingItem(
                id: "events",
                title: "notifications.events.title".localized(using: localizationManager),
                description: "notifications.events.description".localized(using: localizationManager),
                customIcon: "calendar.badge.plus",
                iconColor: .purple,
                backgroundColor: Color.purple.opacity(0.1),
                binding: $viewModel.eventRemindersEnabled
            ),
            NotificationSettingItem(
                id: "chat",
                title: "notifications.chat.title".localized(using: localizationManager),
                description: "notifications.chat.description".localized(using: localizationManager),
                customIcon: "bubble.left.and.bubble.right",
                iconColor: .cyan,
                backgroundColor: Color.cyan.opacity(0.1),
                binding: $viewModel.chatMessagesEnabled
            ),
            NotificationSettingItem(
                id: "matches",
                title: "notifications.matches.title".localized(using: localizationManager),
                description: "notifications.matches.description".localized(using: localizationManager),
                customIcon: "sportscourt",
                iconColor: .mint,
                backgroundColor: Color.mint.opacity(0.1),
                binding: $viewModel.matchUpdatesEnabled
            )
        ]
    }
    
    // MARK: - Marketing Notification Items
    private var marketingNotificationItems: [NotificationSettingItem] {
        [
            NotificationSettingItem(
                id: "promotional",
                title: "notifications.promotional.title".localized(using: localizationManager),
                description: "notifications.promotional.description".localized(using: localizationManager),
                customIcon: "tag.circle",
                iconColor: .pink,
                backgroundColor: Color.pink.opacity(0.1),
                binding: $viewModel.promotionalNotificationsEnabled
            )
        ]
    }
}

// MARK: - Notification Setting Item View
struct NotificationSettingItemView: View {
    let item: NotificationSettingItem
    
    var body: some View {
        HStack(spacing: 16) {
            // Outline (içi boş) siyah iconlar
            Image(systemName: getOutlineIcon(item.customIcon))
                .font(.system(size: 20, weight: .medium))
                .foregroundColor(.black)
                .frame(width: 24, height: 24)
            
            // Content
            VStack(alignment: .leading, spacing: 2) {
                Text(item.title)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.textPrimary)
                    .lineLimit(1)
                
                Text(item.description)
                    .font(.system(size: 13, weight: .regular))
                    .foregroundColor(.textSecondary)
                    .lineLimit(2)
            }
            
            Spacer()
            
            // Custom Toggle
            Toggle("", isOn: item.binding)
                .toggleStyle(CustomToggleStyle())
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }
    
    // Icon'ları outline (içi boş) versiyonlarına çevir
    private func getOutlineIcon(_ icon: String) -> String {
        switch icon {
        case "iphone.radiowaves.left.and.right":
            return "iphone"
        case "envelope.badge":
            return "envelope"
        case "message.badge":
            return "message"
        case "calendar.badge.plus":
            return "calendar"
        case "bubble.left.and.bubble.right":
            return "bubble.left.and.bubble.right"
        case "sportscourt":
            return "sportscourt"
        case "tag.circle":
            return "tag"
        default:
            return icon
        }
    }
}

// MARK: - Custom Toggle Style
struct CustomToggleStyle: ToggleStyle {
    func makeBody(configuration: Configuration) -> some View {
        Button(action: {
            configuration.isOn.toggle()
        }) {
            ZStack {
                RoundedRectangle(cornerRadius: 16)
                    .fill(configuration.isOn ? Color.primaryOrange : Color.gray.opacity(0.3))
                    .frame(width: 50, height: 30)
                    .animation(.easeInOut(duration: 0.2), value: configuration.isOn)
                
                Circle()
                    .fill(Color.white)
                    .frame(width: 26, height: 26)
                    .offset(x: configuration.isOn ? 10 : -10)
                    .animation(.spring(response: 0.3, dampingFraction: 0.6), value: configuration.isOn)
                    .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Notification Divider
struct NotificationDivider: View {
    var body: some View {
        Divider()
            .padding(.leading, 56) // Icon width'e göre ayarlandı (24 + 16 + 16)
            .background(Color.formBorder.opacity(0.2))
    }
}

// MARK: - Notification Settings Localization Keys Extension
extension String {
    // Notifications Keys
    static let notificationsTitle = "notifications.title"
    static let notificationsErrorTitle = "notifications.error.title"
    
    // Notification Sections
    static let notificationsSectionGeneral = "notifications.section.general"
    static let notificationsSectionFeatures = "notifications.section.features"
    static let notificationsSectionMarketing = "notifications.section.marketing"
    
    // General Notifications
    static let notificationsPushTitle = "notifications.push.title"
    static let notificationsPushDescription = "notifications.push.description"
    static let notificationsEmailTitle = "notifications.email.title"
    static let notificationsEmailDescription = "notifications.email.description"
    static let notificationsSmsTitle = "notifications.sms.title"
    static let notificationsSmsDescription = "notifications.sms.description"
    
    // App Feature Notifications
    static let notificationsEventsTitle = "notifications.events.title"
    static let notificationsEventsDescription = "notifications.events.description"
    static let notificationsChatTitle = "notifications.chat.title"
    static let notificationsChatDescription = "notifications.chat.description"
    static let notificationsMatchesTitle = "notifications.matches.title"
    static let notificationsMatchesDescription = "notifications.matches.description"
    
    // Marketing Notifications
    static let notificationsPromotionalTitle = "notifications.promotional.title"
    static let notificationsPromotionalDescription = "notifications.promotional.description"
}

// MARK: - Preview
#Preview {
    NotificationSettingsView()
        .environmentObject(LocalizationManager())
}
