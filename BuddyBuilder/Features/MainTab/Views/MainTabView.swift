import SwiftUI

struct MainTabView: View {
    @EnvironmentObject var localizationManager: LocalizationManager
    @State private var selectedTab: TabItem = .events
    
    var body: some View {
        VStack(spacing: 0) {
            // Tab Content - Full screen
            Group {
                switch selectedTab {
                case .events:
                    EventsView()
                        .environmentObject(localizationManager)
                case .search:
                    SearchView()
                        .environmentObject(localizationManager)
                case .messages:
                    MessagesView()
                        .environmentObject(localizationManager)
                case .notifications:
                    NotificationsView()
                        .environmentObject(localizationManager)
                case .profile:
                    ProfileView()
                        .environmentObject(localizationManager)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            
            // Custom Tab Bar - Alt kısımda
            CustomTabBar(selectedTab: $selectedTab)
                .environmentObject(localizationManager)
        }
        .ignoresSafeArea(.keyboard)
        .ignoresSafeArea(.container, edges: .bottom) // Alt safe area'yı tamamen ignore et
        .background(Color.white)
    }
}

enum TabItem: CaseIterable {
    case events, search, messages, notifications, profile
    
    @MainActor
    func title(using manager: LocalizationManager) -> String {
        switch self {
        case .events:
            return "nav.events".localized(using: manager)
        case .search:
            return "nav.search".localized(using: manager)
        case .messages:
            return "nav.messages".localized(using: manager)
        case .notifications:
            return "nav.notifications".localized(using: manager)
        case .profile:
            return "nav.profile".localized(using: manager)
        }
    }
    
    var icon: String {
        switch self {
        case .events:
            return "calendar"
        case .search:
            return "magnifyingglass"
        case .messages:
            return "message"
        case .notifications:
            return "bell"
        case .profile:
            return "person.circle"
        }
    }
    
    var selectedIcon: String {
        switch self {
        case .events:
            return "calendar.circle.fill"
        case .search:
            return "magnifyingglass.circle.fill"
        case .messages:
            return "message.circle.fill"
        case .notifications:
            return "bell.circle.fill"
        case .profile:
            return "person.circle.fill"
        }
    }
}

#Preview {
    MainTabView()
        .environmentObject(LocalizationManager(localizationService: MockLocalizationService()))
}
