// BuddyBuilder/Features/Notifications/Views/NotificationsView.swift

import SwiftUI
import Combine

// MARK: - Notification Models
struct AppNotification: Codable, Identifiable {
    let id: Int
    let title: String
    let message: String
    let type: NotificationType
    let timestamp: String
    let isRead: Bool
    let actionData: NotificationActionData?
    let senderUserId: String?
    let senderName: String?
    let senderProfileImageUrl: String?
    
    enum NotificationType: String, Codable, CaseIterable {
        case friendRequest = "friend_request"
        case eventInvitation = "event_invitation"
        case matchRequest = "match_request"
        case message = "message"
        case eventReminder = "event_reminder"
        case achievement = "achievement"
        case system = "system"
        case groupInvite = "group_invite"
        case eventUpdate = "event_update"
        case newFollower = "new_follower"
        
        var icon: String {
            switch self {
            case .friendRequest: return "person.badge.plus"
            case .eventInvitation: return "calendar.badge.plus"
            case .matchRequest: return "sportscourt"
            case .message: return "message.fill"
            case .eventReminder: return "bell.fill"
            case .achievement: return "trophy.fill"
            case .system: return "gear.circle.fill"
            case .groupInvite: return "person.3.fill"
            case .eventUpdate: return "calendar.circle.fill"
            case .newFollower: return "person.crop.circle.badge.plus"
            }
        }
        
        var color: Color {
            switch self {
            case .friendRequest: return .blue
            case .eventInvitation: return .purple
            case .matchRequest: return .primaryOrange
            case .message: return .green
            case .eventReminder: return .orange
            case .achievement: return .yellow
            case .system: return .gray
            case .groupInvite: return .cyan
            case .eventUpdate: return .indigo
            case .newFollower: return .pink
            }
        }
        
        var backgroundColor: Color {
            return color.opacity(0.1)
        }
        
        var displayName: String {
            switch self {
            case .friendRequest: return "Friend Request"
            case .eventInvitation: return "Event Invitation"
            case .matchRequest: return "Match Request"
            case .message: return "Message"
            case .eventReminder: return "Event Reminder"
            case .achievement: return "Achievement"
            case .system: return "System"
            case .groupInvite: return "Group Invite"
            case .eventUpdate: return "Event Update"
            case .newFollower: return "New Follower"
            }
        }
    }
    
    struct NotificationActionData: Codable {
        let actionType: String?
        let targetId: Int?
        let targetUrl: String?
        let eventId: Int?
        let userId: String?
        let groupId: Int?
    }
    
    var timeAgo: String {
        let formatter = ISO8601DateFormatter()
        guard let date = formatter.date(from: timestamp) else { return "now" }
        
        let interval = Date().timeIntervalSince(date)
        
        if interval < 60 {
            return "now"
        } else if interval < 3600 {
            let minutes = Int(interval / 60)
            return "\(minutes)m ago"
        } else if interval < 86400 {
            let hours = Int(interval / 3600)
            return "\(hours)h ago"
        } else if interval < 604800 {
            let days = Int(interval / 86400)
            return "\(days)d ago"
        } else {
            let weeks = Int(interval / 604800)
            return "\(weeks)w ago"
        }
    }
    
    var hasAction: Bool {
        return actionData?.actionType != nil &&
               (type == .friendRequest || type == .eventInvitation || type == .matchRequest || type == .groupInvite)
    }
    
    var actionButtons: [NotificationAction] {
        guard hasAction else { return [] }
        
        switch type {
        case .friendRequest:
            return [
                NotificationAction(id: "accept", title: "Accept", type: .primary, style: .filled),
                NotificationAction(id: "decline", title: "Decline", type: .secondary, style: .outlined)
            ]
        case .eventInvitation:
            return [
                NotificationAction(id: "join", title: "Join", type: .primary, style: .filled),
                NotificationAction(id: "maybe", title: "Maybe", type: .secondary, style: .outlined),
                NotificationAction(id: "decline", title: "Pass", type: .destructive, style: .text)
            ]
        case .matchRequest:
            return [
                NotificationAction(id: "accept", title: "Accept", type: .primary, style: .filled),
                NotificationAction(id: "decline", title: "Decline", type: .secondary, style: .outlined)
            ]
        case .groupInvite:
            return [
                NotificationAction(id: "join", title: "Join Group", type: .primary, style: .filled),
                NotificationAction(id: "decline", title: "Decline", type: .secondary, style: .outlined)
            ]
        default:
            return []
        }
    }
}

struct NotificationAction: Identifiable {
    let id: String
    let title: String
    let type: ActionType
    let style: ActionStyle
    
    enum ActionType {
        case primary
        case secondary
        case destructive
    }
    
    enum ActionStyle {
        case filled
        case outlined
        case text
    }
}

// MARK: - Notifications Service Protocol
protocol NotificationsServiceProtocol {
    func fetchNotifications(page: Int, pageSize: Int) -> AnyPublisher<[AppNotification], Error>
    func markAsRead(notificationId: Int) -> AnyPublisher<Bool, Error>
    func markAllAsRead() -> AnyPublisher<Bool, Error>
    func deleteNotification(notificationId: Int) -> AnyPublisher<Bool, Error>
    func handleNotificationAction(notificationId: Int, action: String) -> AnyPublisher<Bool, Error>
    func getUnreadCount() -> AnyPublisher<Int, Error>
}

// MARK: - Mock Notifications Service
class MockNotificationsService: NotificationsServiceProtocol {
    private var mockNotifications: [AppNotification] = [
        AppNotification(
            id: 1,
            title: "New Friend Request",
            message: "Sarah Johnson wants to connect with you",
            type: .friendRequest,
            timestamp: ISO8601DateFormatter().string(from: Date().addingTimeInterval(-300)),
            isRead: false,
            actionData: AppNotification.NotificationActionData(
                actionType: "friend_request",
                targetId: nil,
                targetUrl: nil,
                eventId: nil,
                userId: "201",
                groupId: nil
            ),
            senderUserId: "201",
            senderName: "Sarah Johnson",
            senderProfileImageUrl: "https://via.placeholder.com/150x150/FF6B35/FFFFFF?text=SJ"
        ),
        AppNotification(
            id: 2,
            title: "Event Invitation",
            message: "You're invited to 'Basketball Pickup Game' tomorrow at 6 PM",
            type: .eventInvitation,
            timestamp: ISO8601DateFormatter().string(from: Date().addingTimeInterval(-1800)),
            isRead: false,
            actionData: AppNotification.NotificationActionData(
                actionType: "event_invitation",
                targetId: nil,
                targetUrl: nil,
                eventId: 101,
                userId: "202",
                groupId: nil
            ),
            senderUserId: "202",
            senderName: "Mike Chen",
            senderProfileImageUrl: "https://via.placeholder.com/150x150/2196F3/FFFFFF?text=MC"
        ),
        AppNotification(
            id: 3,
            title: "Match Request",
            message: "Alex wants to play tennis with you this weekend",
            type: .matchRequest,
            timestamp: ISO8601DateFormatter().string(from: Date().addingTimeInterval(-3600)),
            isRead: true,
            actionData: AppNotification.NotificationActionData(
                actionType: "match_request",
                targetId: nil,
                targetUrl: nil,
                eventId: nil,
                userId: "203",
                groupId: nil
            ),
            senderUserId: "203",
            senderName: "Alex Rodriguez",
            senderProfileImageUrl: "https://via.placeholder.com/150x150/4CAF50/FFFFFF?text=AR"
        ),
        AppNotification(
            id: 4,
            title: "New Message",
            message: "Emma Wilson: \"Thanks for the great game today! 🏀\"",
            type: .message,
            timestamp: ISO8601DateFormatter().string(from: Date().addingTimeInterval(-7200)),
            isRead: true,
            actionData: nil,
            senderUserId: "204",
            senderName: "Emma Wilson",
            senderProfileImageUrl: "https://via.placeholder.com/150x150/FF9800/FFFFFF?text=EW"
        ),
        AppNotification(
            id: 5,
            title: "Event Reminder",
            message: "Your yoga session starts in 30 minutes",
            type: .eventReminder,
            timestamp: ISO8601DateFormatter().string(from: Date().addingTimeInterval(-10800)),
            isRead: true,
            actionData: AppNotification.NotificationActionData(
                actionType: "open_event",
                targetId: nil,
                targetUrl: nil,
                eventId: 102,
                userId: nil,
                groupId: nil
            ),
            senderUserId: nil,
            senderName: nil,
            senderProfileImageUrl: nil
        ),
        AppNotification(
            id: 6,
            title: "Achievement Unlocked! 🏆",
            message: "You've completed 10 workouts this month!",
            type: .achievement,
            timestamp: ISO8601DateFormatter().string(from: Date().addingTimeInterval(-86400)),
            isRead: true,
            actionData: nil,
            senderUserId: nil,
            senderName: nil,
            senderProfileImageUrl: nil
        ),
        AppNotification(
            id: 7,
            title: "Group Invitation",
            message: "You've been invited to join 'Weekend Warriors' group",
            type: .groupInvite,
            timestamp: ISO8601DateFormatter().string(from: Date().addingTimeInterval(-172800)),
            isRead: false,
            actionData: AppNotification.NotificationActionData(
                actionType: "group_invite",
                targetId: nil,
                targetUrl: nil,
                eventId: nil,
                userId: "205",
                groupId: 301
            ),
            senderUserId: "205",
            senderName: "Team Captain",
            senderProfileImageUrl: "https://via.placeholder.com/150x150/9C27B0/FFFFFF?text=TC"
        ),
        AppNotification(
            id: 8,
            title: "Event Update",
            message: "Basketball game location changed to Court B",
            type: .eventUpdate,
            timestamp: ISO8601DateFormatter().string(from: Date().addingTimeInterval(-259200)),
            isRead: true,
            actionData: AppNotification.NotificationActionData(
                actionType: "open_event",
                targetId: nil,
                targetUrl: nil,
                eventId: 103,
                userId: nil,
                groupId: nil
            ),
            senderUserId: nil,
            senderName: nil,
            senderProfileImageUrl: nil
        )
    ]
    
    func fetchNotifications(page: Int = 1, pageSize: Int = 20) -> AnyPublisher<[AppNotification], Error> {
        print("🧪 MOCK: Fetching notifications (page \(page), size \(pageSize))...")
        
        // Simulate pagination
        let startIndex = (page - 1) * pageSize
        let endIndex = min(startIndex + pageSize, mockNotifications.count)
        
        let pageNotifications = startIndex < mockNotifications.count ?
            Array(mockNotifications[startIndex..<endIndex]) : []
        
        return Just(pageNotifications)
            .setFailureType(to: Error.self)
            .delay(for: .seconds(1), scheduler: RunLoop.main)
            .eraseToAnyPublisher()
    }
    
    func markAsRead(notificationId: Int) -> AnyPublisher<Bool, Error> {
        print("🧪 MOCK: Marking notification \(notificationId) as read")
        
        if let index = mockNotifications.firstIndex(where: { $0.id == notificationId }) {
            mockNotifications[index] = AppNotification(
                id: mockNotifications[index].id,
                title: mockNotifications[index].title,
                message: mockNotifications[index].message,
                type: mockNotifications[index].type,
                timestamp: mockNotifications[index].timestamp,
                isRead: true, // Mark as read
                actionData: mockNotifications[index].actionData,
                senderUserId: mockNotifications[index].senderUserId,
                senderName: mockNotifications[index].senderName,
                senderProfileImageUrl: mockNotifications[index].senderProfileImageUrl
            )
        }
        
        return Just(true)
            .setFailureType(to: Error.self)
            .delay(for: .seconds(0.3), scheduler: RunLoop.main)
            .eraseToAnyPublisher()
    }
    
    func markAllAsRead() -> AnyPublisher<Bool, Error> {
        print("🧪 MOCK: Marking all notifications as read")
        
        mockNotifications = mockNotifications.map { notification in
            AppNotification(
                id: notification.id,
                title: notification.title,
                message: notification.message,
                type: notification.type,
                timestamp: notification.timestamp,
                isRead: true, // Mark all as read
                actionData: notification.actionData,
                senderUserId: notification.senderUserId,
                senderName: notification.senderName,
                senderProfileImageUrl: notification.senderProfileImageUrl
            )
        }
        
        return Just(true)
            .setFailureType(to: Error.self)
            .delay(for: .seconds(0.5), scheduler: RunLoop.main)
            .eraseToAnyPublisher()
    }
    
    func deleteNotification(notificationId: Int) -> AnyPublisher<Bool, Error> {
        print("🧪 MOCK: Deleting notification \(notificationId)")
        
        mockNotifications.removeAll { $0.id == notificationId }
        
        return Just(true)
            .setFailureType(to: Error.self)
            .delay(for: .seconds(0.3), scheduler: RunLoop.main)
            .eraseToAnyPublisher()
    }
    
    func handleNotificationAction(notificationId: Int, action: String) -> AnyPublisher<Bool, Error> {
        print("🧪 MOCK: Handling action '\(action)' for notification \(notificationId)")
        
        // Mark notification as read after action
        if let index = mockNotifications.firstIndex(where: { $0.id == notificationId }) {
            mockNotifications[index] = AppNotification(
                id: mockNotifications[index].id,
                title: mockNotifications[index].title,
                message: mockNotifications[index].message,
                type: mockNotifications[index].type,
                timestamp: mockNotifications[index].timestamp,
                isRead: true,
                actionData: nil, // Remove action data after handling
                senderUserId: mockNotifications[index].senderUserId,
                senderName: mockNotifications[index].senderName,
                senderProfileImageUrl: mockNotifications[index].senderProfileImageUrl
            )
        }
        
        return Just(true)
            .setFailureType(to: Error.self)
            .delay(for: .seconds(0.8), scheduler: RunLoop.main)
            .eraseToAnyPublisher()
    }
    
    func getUnreadCount() -> AnyPublisher<Int, Error> {
        let unreadCount = mockNotifications.filter { !$0.isRead }.count
        print("🧪 MOCK: Unread count: \(unreadCount)")
        
        return Just(unreadCount)
            .setFailureType(to: Error.self)
            .delay(for: .seconds(0.2), scheduler: RunLoop.main)
            .eraseToAnyPublisher()
    }
}

// MARK: - Notifications View Model
class NotificationsViewModel: ObservableObject {
    @Published var notifications: [AppNotification] = []
    @Published var filteredNotifications: [AppNotification] = []
    @Published var selectedFilter: NotificationFilter = .all
    @Published var isLoading = false
    @Published var isLoadingMore = false
    @Published var hasMorePages = true
    @Published var unreadCount = 0
    @Published var errorMessage: String = ""
    @Published var showError = false
    
    // Pagination
    private var currentPage = 1
    private let pageSize = 20
    
    private let notificationsService: NotificationsServiceProtocol
    private var cancellables = Set<AnyCancellable>()
    
    init(notificationsService: NotificationsServiceProtocol = MockNotificationsService()) {
        self.notificationsService = notificationsService
        loadNotifications()
        loadUnreadCount()
    }
    
    enum NotificationFilter: String, CaseIterable {
        case all = "all"
        case unread = "unread"
        case friendRequests = "friend_requests"
        case events = "events"
        case messages = "messages"
        
        var displayName: String {
            switch self {
            case .all: return "All"
            case .unread: return "Unread"
            case .friendRequests: return "Requests"
            case .events: return "Events"
            case .messages: return "Messages"
            }
        }
        
        func matches(_ notification: AppNotification) -> Bool {
            switch self {
            case .all:
                return true
            case .unread:
                return !notification.isRead
            case .friendRequests:
                return notification.type == .friendRequest || notification.type == .matchRequest
            case .events:
                return notification.type == .eventInvitation || notification.type == .eventReminder || notification.type == .eventUpdate
            case .messages:
                return notification.type == .message
            }
        }
    }
    
    var hasUnreadNotifications: Bool {
        unreadCount > 0
    }
    
    // MARK: - Load Notifications
    func loadNotifications(refresh: Bool = false) {
        if refresh {
            currentPage = 1
            hasMorePages = true
            notifications.removeAll()
        }
        
        isLoading = refresh || notifications.isEmpty
        errorMessage = ""
        
        notificationsService.fetchNotifications(page: currentPage, pageSize: pageSize)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    self?.isLoading = false
                    self?.isLoadingMore = false
                    if case .failure(let error) = completion {
                        self?.handleError("Failed to load notifications: \(error.localizedDescription)")
                    }
                },
                receiveValue: { [weak self] newNotifications in
                    if refresh {
                        self?.notifications = newNotifications
                    } else {
                        self?.notifications.append(contentsOf: newNotifications)
                    }
                    
                    self?.hasMorePages = newNotifications.count == self?.pageSize
                    self?.applyFilter()
                    self?.loadUnreadCount()
                    
                    print("✅ Loaded \(newNotifications.count) notifications")
                }
            )
            .store(in: &cancellables)
    }
    
    func loadMoreNotifications() {
        guard !isLoadingMore && hasMorePages else { return }
        
        isLoadingMore = true
        currentPage += 1
        
        loadNotifications()
    }
    
    // MARK: - Load Unread Count
    func loadUnreadCount() {
        notificationsService.getUnreadCount()
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { completion in
                    if case .failure(let error) = completion {
                        print("❌ Failed to load unread count: \(error)")
                    }
                },
                receiveValue: { [weak self] count in
                    self?.unreadCount = count
                }
            )
            .store(in: &cancellables)
    }
    
    // MARK: - Filter Methods
    func setFilter(_ filter: NotificationFilter) {
        selectedFilter = filter
        applyFilter()
    }
    
    private func applyFilter() {
        filteredNotifications = notifications.filter { selectedFilter.matches($0) }
    }
    
    // MARK: - Notification Actions
    func markAsRead(_ notification: AppNotification) {
        guard !notification.isRead else { return }
        
        notificationsService.markAsRead(notificationId: notification.id)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { completion in
                    if case .failure(let error) = completion {
                        print("❌ Failed to mark as read: \(error)")
                    }
                },
                receiveValue: { [weak self] success in
                    if success {
                        self?.updateNotificationReadStatus(notification.id, isRead: true)
                        self?.loadUnreadCount()
                    }
                }
            )
            .store(in: &cancellables)
    }
    
    func markAllAsRead() {
        notificationsService.markAllAsRead()
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { completion in
                    if case .failure(let error) = completion {
                        print("❌ Failed to mark all as read: \(error)")
                    }
                },
                receiveValue: { [weak self] success in
                    if success {
                        self?.notifications = self?.notifications.map { notification in
                            AppNotification(
                                id: notification.id,
                                title: notification.title,
                                message: notification.message,
                                type: notification.type,
                                timestamp: notification.timestamp,
                                isRead: true,
                                actionData: notification.actionData,
                                senderUserId: notification.senderUserId,
                                senderName: notification.senderName,
                                senderProfileImageUrl: notification.senderProfileImageUrl
                            )
                        } ?? []
                        self?.applyFilter()
                        self?.loadUnreadCount()
                    }
                }
            )
            .store(in: &cancellables)
    }
    
    func deleteNotification(_ notification: AppNotification) {
        notificationsService.deleteNotification(notificationId: notification.id)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { completion in
                    if case .failure(let error) = completion {
                        print("❌ Failed to delete notification: \(error)")
                    }
                },
                receiveValue: { [weak self] success in
                    if success {
                        self?.notifications.removeAll { $0.id == notification.id }
                        self?.applyFilter()
                        self?.loadUnreadCount()
                    }
                }
            )
            .store(in: &cancellables)
    }
    
    func handleNotificationAction(_ notification: AppNotification, action: String) {
        notificationsService.handleNotificationAction(notificationId: notification.id, action: action)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { completion in
                    if case .failure(let error) = completion {
                        print("❌ Failed to handle notification action: \(error)")
                    }
                },
                receiveValue: { [weak self] success in
                    if success {
                        // Update notification to remove action buttons and mark as read
                        if let index = self?.notifications.firstIndex(where: { $0.id == notification.id }) {
                            self?.notifications[index] = AppNotification(
                                id: notification.id,
                                title: notification.title,
                                message: notification.message,
                                type: notification.type,
                                timestamp: notification.timestamp,
                                isRead: true,
                                actionData: nil, // Remove action data
                                senderUserId: notification.senderUserId,
                                senderName: notification.senderName,
                                senderProfileImageUrl: notification.senderProfileImageUrl
                            )
                        }
                        self?.applyFilter()
                        self?.loadUnreadCount()
                        
                        print("✅ Notification action '\(action)' handled successfully")
                    }
                }
            )
            .store(in: &cancellables)
    }
    
    // MARK: - Helper Methods
    private func updateNotificationReadStatus(_ notificationId: Int, isRead: Bool) {
        if let index = notifications.firstIndex(where: { $0.id == notificationId }) {
            notifications[index] = AppNotification(
                id: notifications[index].id,
                title: notifications[index].title,
                message: notifications[index].message,
                type: notifications[index].type,
                timestamp: notifications[index].timestamp,
                isRead: isRead,
                actionData: notifications[index].actionData,
                senderUserId: notifications[index].senderUserId,
                senderName: notifications[index].senderName,
                senderProfileImageUrl: notifications[index].senderProfileImageUrl
            )
            applyFilter()
        }
    }
    
    private func handleError(_ message: String) {
        errorMessage = message
        showError = true
        print("❌ NotificationsViewModel Error: \(message)")
    }
}

// MARK: - Notifications View
struct NotificationsView: View {
    @StateObject private var viewModel = NotificationsViewModel()
    @EnvironmentObject var localizationManager: LocalizationManager
    @State private var showingMarkAllAlert = false
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Custom Header
                customHeader
                
                // Filter Tabs
                filterTabsSection
                
                // Content
                if viewModel.isLoading && viewModel.notifications.isEmpty {
                    loadingView
                } else if viewModel.filteredNotifications.isEmpty {
                    emptyStateView
                } else {
                    notificationsList
                }
            }
            .background(Color.dynamicBackground)
        }
        .navigationBarHidden(true)
        .alert("notifications.mark_all.title".localized(using: localizationManager), isPresented: $showingMarkAllAlert) {
            Button("common.cancel".localized(using: localizationManager), role: .cancel) { }
            Button("notifications.mark_all.confirm".localized(using: localizationManager)) {
                viewModel.markAllAsRead()
            }
        } message: {
            Text("notifications.mark_all.message".localized(using: localizationManager))
        }
        .alert("notifications.error.title".localized(using: localizationManager), isPresented: $viewModel.showError) {
            Button("common.ok".localized(using: localizationManager)) { }
        } message: {
            Text(viewModel.errorMessage)
        }
        .onAppear {
            viewModel.loadNotifications(refresh: true)
        }
    }
    
    // MARK: - Custom Header
    private var customHeader: some View {
        VStack(spacing: 0) {
            HStack {
                // Title
                Text("nav.notifications".localized(using: localizationManager))
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundColor(.textPrimary)
                
                Spacer()
                
                // Unread count badge
                if viewModel.hasUnreadNotifications {
                    HStack(spacing: 8) {
                        ZStack {
                            Circle()
                                .fill(Color.red)
                                .frame(width: 20, height: 20)
                            
                            Text("\(viewModel.unreadCount)")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundColor(.white)
                        }
                        .transition(.scale.combined(with: .opacity))
                        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: viewModel.hasUnreadNotifications)
                        
                        // Mark All Read Button
                        Button(action: {
                            showingMarkAllAlert = true
                        }) {
                            Text("Mark All")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(.primaryOrange)
                        }
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
        }
        .background(Color.cardBackground)
    }
    
    // MARK: - Filter Tabs Section
    private var filterTabsSection: some View {
        VStack(spacing: 0) {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(NotificationsViewModel.NotificationFilter.allCases, id: \.rawValue) { filter in
                        FilterTabButton(
                            title: filter.displayName,
                            isSelected: viewModel.selectedFilter == filter,
                            unreadCount: filter == .unread ? viewModel.unreadCount : nil
                        ) {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                viewModel.setFilter(filter)
                            }
                        }
                    }
                }
                .padding(.horizontal, 20)
            }
            .padding(.vertical, 12)
            .background(Color.cardBackground)
        }
    }
    
    // MARK: - Loading View
    private var loadingView: some View {
        VStack(spacing: 20) {
            Spacer()
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle(tint: .primaryOrange))
                .scaleEffect(1.5)
            Text("notifications.loading".localized(using: localizationManager))
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.textSecondary)
            Spacer()
        }
    }
    
    // MARK: - Empty State View
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Spacer()
            
            Image(systemName: getEmptyStateIcon())
                .font(.system(size: 80))
                .foregroundColor(.primaryOrange.opacity(0.6))
            
            Text(getEmptyStateTitle())
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(.textPrimary)
            
            Text(getEmptyStateDescription())
                .font(.system(size: 16))
                .foregroundColor(.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
            
            Spacer()
        }
    }
    
    private func getEmptyStateIcon() -> String {
        switch viewModel.selectedFilter {
        case .all:
            return "bell.circle"
        case .unread:
            return "bell.badge"
        case .friendRequests:
            return "person.badge.plus"
        case .events:
            return "calendar.circle"
        case .messages:
            return "message.circle"
        }
    }
    
    private func getEmptyStateTitle() -> String {
        switch viewModel.selectedFilter {
        case .all:
            return "notifications.empty.all.title".localized(using: localizationManager)
        case .unread:
            return "notifications.empty.unread.title".localized(using: localizationManager)
        case .friendRequests:
            return "notifications.empty.requests.title".localized(using: localizationManager)
        case .events:
            return "notifications.empty.events.title".localized(using: localizationManager)
        case .messages:
            return "notifications.empty.messages.title".localized(using: localizationManager)
        }
    }
    
    private func getEmptyStateDescription() -> String {
        switch viewModel.selectedFilter {
        case .all:
            return "notifications.empty.all.description".localized(using: localizationManager)
        case .unread:
            return "notifications.empty.unread.description".localized(using: localizationManager)
        case .friendRequests:
            return "notifications.empty.requests.description".localized(using: localizationManager)
        case .events:
            return "notifications.empty.events.description".localized(using: localizationManager)
        case .messages:
            return "notifications.empty.messages.description".localized(using: localizationManager)
        }
    }
    
    // MARK: - Notifications List
    private var notificationsList: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                ForEach(viewModel.filteredNotifications) { notification in
                    NotificationRow(
                        notification: notification,
                        onTap: {
                            if !notification.isRead {
                                viewModel.markAsRead(notification)
                            }
                        },
                        onAction: { action in
                            viewModel.handleNotificationAction(notification, action: action)
                        },
                        onDelete: {
                            viewModel.deleteNotification(notification)
                        }
                    )
                    
                    if notification.id != viewModel.filteredNotifications.last?.id {
                        Divider()
                            .padding(.leading, 88)
                            .foregroundColor(.cardBackground.opacity(0.5))
                    }
                }
                
                // Load More Indicator
                if viewModel.hasMorePages {
                    LoadMoreNotificationsView(isLoading: viewModel.isLoadingMore)
                        .onAppear {
                            viewModel.loadMoreNotifications()
                        }
                }
            }
            .background(Color.cardBackground)
        }
        .refreshable {
            viewModel.loadNotifications(refresh: true)
        }
    }
}

// MARK: - Filter Tab Button
struct FilterTabButton: View {
    let title: String
    let isSelected: Bool
    let unreadCount: Int?
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Text(title)
                    .font(.system(size: 14, weight: isSelected ? .semibold : .medium))
                    .foregroundColor(isSelected ? .white : .textSecondary)
                
                if let count = unreadCount, count > 0 {
                    ZStack {
                        Circle()
                            .fill(isSelected ? .white : .red)
                            .frame(width: 16, height: 16)
                        
                        Text("\(count)")
                            .font(.system(size: 9, weight: .bold))
                            .foregroundColor(isSelected ? .primaryOrange : .white)
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(isSelected ? Color.primaryOrange : Color.cardBackground)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(isSelected ? Color.clear : Color.textSecondary.opacity(0.3), lineWidth: 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Notification Row
struct NotificationRow: View {
    let notification: AppNotification
    let onTap: () -> Void
    let onAction: (String) -> Void
    let onDelete: () -> Void
    @State private var isPressed = false
    @State private var actionInProgress: String? = nil
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 0) {
                HStack(alignment: .top, spacing: 16) {
                    // Notification Icon or Profile Image
                    ZStack {
                        if let profileImageUrl = notification.senderProfileImageUrl {
                            SearchAsyncImage(
                                url: profileImageUrl,
                                placeholder: "person.crop.circle.fill"
                            )
                            .frame(width: 56, height: 56)
                            .clipShape(Circle())
                        } else {
                            ZStack {
                                Circle()
                                    .fill(notification.type.backgroundColor)
                                    .frame(width: 56, height: 56)
                                
                                Image(systemName: notification.type.icon)
                                    .font(.system(size: 24, weight: .medium))
                                    .foregroundColor(notification.type.color)
                            }
                        }
                    }
                    
                    // Notification Content
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(notification.title)
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(.textPrimary)
                                    .lineLimit(1)
                                
                                Text(notification.message)
                                    .font(.system(size: 14))
                                    .foregroundColor(.textSecondary)
                                    .lineLimit(3)
                            }
                            
                            Spacer()
                            
                            VStack {
                                Text(notification.timeAgo)
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundColor(.textSecondary.opacity(0.8))
                                
                                Spacer()
                                
                                // Unread indicator - positioned at the right side
                                if !notification.isRead {
                                    Circle()
                                        .fill(Color.red)
                                        .frame(width: 10, height: 10)
                                }
                            }
                        }
                        
                        // Action Buttons
                        if notification.hasAction && !notification.actionButtons.isEmpty {
                            notificationActionButtons
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
            }
            .background(notification.isRead ? Color.cardBackground : Color.primaryOrange.opacity(0.05))
        }
        .buttonStyle(PlainButtonStyle())
        .contextMenu {
            Button(action: onDelete) {
                Label("Delete", systemImage: "trash")
            }
            
            if !notification.isRead {
                Button(action: onTap) {
                    Label("Mark as Read", systemImage: "envelope.open")
                }
            }
        }
        .scaleEffect(isPressed ? 0.98 : 1.0)
        .animation(.spring(response: 0.2, dampingFraction: 0.6), value: isPressed)
        .onTapGesture {
            withAnimation {
                isPressed = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                withAnimation {
                    isPressed = false
                }
            }
            onTap()
        }
    }
    
    private var notificationActionButtons: some View {
        HStack(spacing: 8) {
            ForEach(notification.actionButtons) { actionButton in
                Button(action: {
                    actionInProgress = actionButton.id
                    onAction(actionButton.id)
                    
                    // Reset action progress after delay
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                        actionInProgress = nil
                    }
                }) {
                    HStack(spacing: 4) {
                        if actionInProgress == actionButton.id {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: getActionTextColor(actionButton)))
                                .scaleEffect(0.8)
                        } else {
                            Text(actionButton.title)
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundColor(getActionTextColor(actionButton))
                        }
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(getActionBackgroundColor(actionButton))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(getActionBorderColor(actionButton), lineWidth: actionButton.style == .outlined ? 1 : 0)
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                }
                .disabled(actionInProgress != nil)
                .buttonStyle(PlainButtonStyle())
            }
            
            Spacer()
        }
        .padding(.top, 4)
    }
    
    private func getActionTextColor(_ action: NotificationAction) -> Color {
        switch (action.type, action.style) {
        case (.primary, .filled):
            return .white
        case (.primary, _):
            return .primaryOrange
        case (.secondary, .filled):
            return .white
        case (.secondary, _):
            return .textSecondary
        case (.destructive, .filled):
            return .white
        case (.destructive, _):
            return .red
        }
    }
    
    private func getActionBackgroundColor(_ action: NotificationAction) -> Color {
        switch (action.type, action.style) {
        case (.primary, .filled):
            return .primaryOrange
        case (.secondary, .filled):
            return .textSecondary
        case (.destructive, .filled):
            return .red
        case (_, .text):
            return .clear
        case (_, .outlined):
            return .clear
        default:
            return .clear
        }
    }
    
    private func getActionBorderColor(_ action: NotificationAction) -> Color {
        switch action.type {
        case .primary:
            return .primaryOrange
        case .secondary:
            return .textSecondary
        case .destructive:
            return .red
        }
    }
}

// MARK: - Load More Notifications View
struct LoadMoreNotificationsView: View {
    let isLoading: Bool
    
    var body: some View {
        HStack {
            Spacer()
            
            if isLoading {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .primaryOrange))
                    .scaleEffect(0.8)
            } else {
                Text("Loading more...")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.textSecondary)
            }
            
            Spacer()
        }
        .padding(.vertical, 20)
        .background(Color.cardBackground)
    }
}

// MARK: - Notifications Localization Keys Extension
extension String {
    // Notifications Keys
    static let notificationsLoading = "notifications.loading"
    
    // Mark All Read
    static let notificationsMarkAllTitle = "notifications.mark_all.title"
    static let notificationsMarkAllMessage = "notifications.mark_all.message"
    static let notificationsMarkAllConfirm = "notifications.mark_all.confirm"
    
    // Empty States
    static let notificationsEmptyAllTitle = "notifications.empty.all.title"
    static let notificationsEmptyAllDescription = "notifications.empty.all.description"
    static let notificationsEmptyUnreadTitle = "notifications.empty.unread.title"
    static let notificationsEmptyUnreadDescription = "notifications.empty.unread.description"
    static let notificationsEmptyRequestsTitle = "notifications.empty.requests.title"
    static let notificationsEmptyRequestsDescription = "notifications.empty.requests.description"
    static let notificationsEmptyEventsTitle = "notifications.empty.events.title"
    static let notificationsEmptyEventsDescription = "notifications.empty.events.description"
    static let notificationsEmptyMessagesTitle = "notifications.empty.messages.title"
    static let notificationsEmptyMessagesDescription = "notifications.empty.messages.description"
}

// MARK: - Preview
#Preview {
    NotificationsView()
        .environmentObject(LocalizationManager(localizationService: MockLocalizationService()))
}
