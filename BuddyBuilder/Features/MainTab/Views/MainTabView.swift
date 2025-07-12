import SwiftUI

struct MainTabView: View {
    @State private var selectedTab: TabItem = .events
    
    var body: some View {
        VStack(spacing: 0) {
            // Tab Content - Full screen
            Group {
                switch selectedTab {
                case .events:
                    EventsView()
                case .search:
                    SearchView()
                case .notifications:
                    NotificationsView()
                case .profile:
                    ProfileView()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            
            // Custom Tab Bar - Alt kısımda
            CustomTabBar(selectedTab: $selectedTab)
        }
        .ignoresSafeArea(.keyboard)
        .background(Color.white) // Ana background beyaz
    }
}

enum TabItem: CaseIterable {
    case events, search, notifications, profile
    
    var title: String {
        switch self {
        case .events: return "nav.events"
        case .search: return "nav.search"
        case .notifications: return "nav.notifications"
        case .profile: return "nav.profile"
        }
    }
    
    var icon: String {
        switch self {
        case .events: return "calendar"
        case .search: return "magnifyingglass"
        case .notifications: return "bell"
        case .profile: return "person.circle"
        }
    }
    
    var selectedIcon: String {
        switch self {
        case .events: return "calendar.circle.fill"
        case .search: return "magnifyingglass.circle.fill"
        case .notifications: return "bell.fill"
        case .profile: return "person.circle.fill"
        }
    }
}

#Preview {
    MainTabView()
}
