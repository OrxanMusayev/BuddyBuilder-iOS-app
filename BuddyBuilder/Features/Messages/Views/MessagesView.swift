// BuddyBuilder/Features/Messages/Views/MessagesView.swift - MODERN VERSION

import SwiftUI
import Combine

// MARK: - Message Models
struct ChatRoom: Codable, Identifiable {
    let id: Int
    let participantName: String
    let participantUsername: String
    let participantProfileImageUrl: String?
    let lastMessage: String?
    let lastMessageDate: String
    let unreadCount: Int
    let isOnline: Bool
    let chatType: ChatType
    
    enum ChatType: String, Codable {
        case direct = "direct"
        case group = "group"
        
        var icon: String {
            switch self {
            case .direct: return "person.circle.fill"
            case .group: return "person.3.circle.fill"
            }
        }
    }
    
    var timeAgo: String {
        let formatter = ISO8601DateFormatter()
        guard let date = formatter.date(from: lastMessageDate) else { return "now" }
        
        let interval = Date().timeIntervalSince(date)
        
        if interval < 60 {
            return "now"
        } else if interval < 3600 {
            let minutes = Int(interval / 60)
            return "\(minutes)m"
        } else if interval < 86400 {
            let hours = Int(interval / 3600)
            return "\(hours)h"
        } else {
            let days = Int(interval / 86400)
            return "\(days)d"
        }
    }
    
    var displayLastMessage: String {
        return lastMessage ?? "No messages yet"
    }
}

struct Message: Codable, Identifiable {
    let id: Int
    let senderId: Int
    let senderName: String
    let content: String
    let timestamp: String
    let isRead: Bool
    
    var timeString: String {
        let formatter = ISO8601DateFormatter()
        guard let date = formatter.date(from: timestamp) else { return "" }
        
        let timeFormatter = DateFormatter()
        timeFormatter.timeStyle = .short
        return timeFormatter.string(from: date)
    }
    
    var isFromCurrentUser: Bool {
        let currentUserId = UserDefaults.standard.integer(forKey: "user_id")
        return senderId == currentUserId
    }
}

// MARK: - Messages Service Protocol
protocol MessagesServiceProtocol {
    func fetchChatRooms() -> AnyPublisher<[ChatRoom], Error>
    func fetchMessages(for chatRoomId: Int) -> AnyPublisher<[Message], Error>
    func sendMessage(to chatRoomId: Int, content: String) -> AnyPublisher<Message, Error>
}

// MARK: - Mock Messages Service
class MockMessagesService: MessagesServiceProtocol {
    private let mockChatRooms: [ChatRoom] = [
        ChatRoom(
            id: 1,
            participantName: "Sarah Johnson",
            participantUsername: "sarah_j",
            participantProfileImageUrl: "https://via.placeholder.com/150x150/FF6B35/FFFFFF?text=SJ",
            lastMessage: "Hey! Are you joining the basketball game tomorrow?",
            lastMessageDate: ISO8601DateFormatter().string(from: Date().addingTimeInterval(-300)),
            unreadCount: 2,
            isOnline: true,
            chatType: .direct
        ),
        ChatRoom(
            id: 2,
            participantName: "Weekend Warriors",
            participantUsername: "weekend_warriors",
            participantProfileImageUrl: "https://via.placeholder.com/150x150/4CAF50/FFFFFF?text=WW",
            lastMessage: "Who's bringing the water bottles?",
            lastMessageDate: ISO8601DateFormatter().string(from: Date().addingTimeInterval(-1800)),
            unreadCount: 0,
            isOnline: false,
            chatType: .group
        ),
        ChatRoom(
            id: 3,
            participantName: "Mike Chen",
            participantUsername: "mike_c",
            participantProfileImageUrl: "https://via.placeholder.com/150x150/2196F3/FFFFFF?text=MC",
            lastMessage: "Great game today!",
            lastMessageDate: ISO8601DateFormatter().string(from: Date().addingTimeInterval(-3600)),
            unreadCount: 0,
            isOnline: true,
            chatType: .direct
        ),
        ChatRoom(
            id: 4,
            participantName: "Emma Wilson",
            participantUsername: "emma_w",
            participantProfileImageUrl: "https://via.placeholder.com/150x150/FF9800/FFFFFF?text=EW",
            lastMessage: "Thanks for the yoga session recommendations!",
            lastMessageDate: ISO8601DateFormatter().string(from: Date().addingTimeInterval(-86400)),
            unreadCount: 1,
            isOnline: false,
            chatType: .direct
        )
    ]
    
    private let mockMessages: [Int: [Message]] = [
        1: [
            Message(
                id: 101,
                senderId: 201,
                senderName: "Sarah Johnson",
                content: "Hey! Are you free this weekend?",
                timestamp: ISO8601DateFormatter().string(from: Date().addingTimeInterval(-3600)),
                isRead: true
            ),
            Message(
                id: 102,
                senderId: UserDefaults.standard.integer(forKey: "user_id"),
                senderName: "You",
                content: "Yes! What do you have in mind?",
                timestamp: ISO8601DateFormatter().string(from: Date().addingTimeInterval(-3300)),
                isRead: true
            ),
            Message(
                id: 103,
                senderId: 201,
                senderName: "Sarah Johnson",
                content: "Hey! Are you joining the basketball game tomorrow?",
                timestamp: ISO8601DateFormatter().string(from: Date().addingTimeInterval(-300)),
                isRead: false
            )
        ]
    ]
    
    func fetchChatRooms() -> AnyPublisher<[ChatRoom], Error> {
        print("🧪 MOCK: Fetching chat rooms...")
        return Just(mockChatRooms)
            .setFailureType(to: Error.self)
            .delay(for: .seconds(1), scheduler: RunLoop.main)
            .eraseToAnyPublisher()
    }
    
    func fetchMessages(for chatRoomId: Int) -> AnyPublisher<[Message], Error> {
        print("🧪 MOCK: Fetching messages for chat room \(chatRoomId)...")
        let messages = mockMessages[chatRoomId] ?? []
        return Just(messages)
            .setFailureType(to: Error.self)
            .delay(for: .seconds(0.8), scheduler: RunLoop.main)
            .eraseToAnyPublisher()
    }
    
    func sendMessage(to chatRoomId: Int, content: String) -> AnyPublisher<Message, Error> {
        print("🧪 MOCK: Sending message to chat room \(chatRoomId): \(content)")
        let newMessage = Message(
            id: Int.random(in: 1000...9999),
            senderId: UserDefaults.standard.integer(forKey: "user_id"),
            senderName: "You",
            content: content,
            timestamp: ISO8601DateFormatter().string(from: Date()),
            isRead: true
        )
        
        return Just(newMessage)
            .setFailureType(to: Error.self)
            .delay(for: .seconds(0.5), scheduler: RunLoop.main)
            .eraseToAnyPublisher()
    }
}

// MARK: - Messages View Model
class MessagesViewModel: ObservableObject {
    @Published var chatRooms: [ChatRoom] = []
    @Published var searchText: String = ""
    @Published var isLoading = false
    @Published var errorMessage: String = ""
    @Published var showError = false
    @Published var selectedChatRoom: ChatRoom?
    @Published var showChatDetail = false
    
    private let messagesService: MessagesServiceProtocol
    private var cancellables = Set<AnyCancellable>()
    
    init(messagesService: MessagesServiceProtocol = MockMessagesService()) {
        self.messagesService = messagesService
        loadChatRooms()
    }
    
    var filteredChatRooms: [ChatRoom] {
        if searchText.isEmpty {
            return chatRooms
        } else {
            return chatRooms.filter { room in
                room.participantName.localizedCaseInsensitiveContains(searchText) ||
                room.participantUsername.localizedCaseInsensitiveContains(searchText) ||
                (room.lastMessage?.localizedCaseInsensitiveContains(searchText) ?? false)
            }
        }
    }
    
    var totalUnreadCount: Int {
        chatRooms.reduce(0) { $0 + $1.unreadCount }
    }
    
    // MARK: - Load Chat Rooms
    func loadChatRooms() {
        isLoading = true
        errorMessage = ""
        
        messagesService.fetchChatRooms()
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    self?.isLoading = false
                    if case .failure(let error) = completion {
                        self?.handleError("Failed to load messages: \(error.localizedDescription)")
                    }
                },
                receiveValue: { [weak self] chatRooms in
                    self?.chatRooms = chatRooms
                    print("✅ Loaded \(chatRooms.count) chat rooms")
                }
            )
            .store(in: &cancellables)
    }
    
    // MARK: - Chat Actions
    func openChat(_ chatRoom: ChatRoom) {
        selectedChatRoom = chatRoom
        showChatDetail = true
    }
    
    func closeChatDetail() {
        showChatDetail = false
        selectedChatRoom = nil
    }
    
    private func handleError(_ message: String) {
        errorMessage = message
        showError = true
        print("❌ MessagesViewModel Error: \(message)")
    }
}

// MARK: - Messages View - MODERN DESIGN
struct MessagesView: View {
    @StateObject private var viewModel = MessagesViewModel()
    @EnvironmentObject var localizationManager: LocalizationManager
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Background - same as UserProfile
                LoginBackgroundView()
                
                VStack(spacing: 0) {
                    // Modern Header
                    modernHeader
                    
                    // Content with modern styling
                    contentView
                }
            }
        }
        .navigationBarHidden(true)
        .fullScreenCover(isPresented: $viewModel.showChatDetail) {
            if let chatRoom = viewModel.selectedChatRoom {
                ChatDetailView(
                    chatRoom: chatRoom,
                    onDismiss: {
                        viewModel.closeChatDetail()
                    }
                )
                .environmentObject(localizationManager)
            }
        }
        .alert("Error", isPresented: $viewModel.showError) {
            Button("OK") { }
        } message: {
            Text(viewModel.errorMessage)
        }
        .onAppear {
            viewModel.loadChatRooms()
        }
    }
    
    // MARK: - Modern Header
    private var modernHeader: some View {
        VStack(spacing: 0) {
            HStack(alignment: .center) {
                // Title with modern styling
                VStack(alignment: .leading, spacing: 4) {
                    Text("Messages")
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .foregroundColor(.textPrimary)
                    
                    if viewModel.totalUnreadCount > 0 {
                        Text("\(viewModel.totalUnreadCount) unread")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.textSecondary)
                    } else {
                        Text("Stay connected")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.textSecondary)
                    }
                }
                
                Spacer()
                
                // Modern action buttons
                HStack(spacing: 12) {
                    // Search toggle button
                    Button(action: {
                        print("Search tapped")
                    }) {
                        Image(systemName: "magnifyingglass")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.primaryOrange)
                            .frame(width: 44, height: 44)
                            .background(Color.white)
                            .clipShape(Circle())
                            .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
                    }
                    
                    // New Message Button with modern styling
                    Button(action: {
                        print("New message tapped")
                    }) {
                        Image(systemName: "plus.message.fill")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.white)
                            .frame(width: 44, height: 44)
                            .background(
                                LinearGradient(
                                    colors: [
                                        Color.primaryOrange,
                                        Color.primaryOrange.opacity(0.8)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .clipShape(Circle())
                            .shadow(color: .primaryOrange.opacity(0.3), radius: 8, x: 0, y: 4)
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 16)
            .padding(.bottom, 20)
            .background(Color.white.opacity(0.95))
        }
    }
    
    // MARK: - Content View
    private var contentView: some View {
        VStack(spacing: 0) {
            // Search Bar with modern styling
            if !viewModel.searchText.isEmpty || viewModel.chatRooms.count > 3 {
                modernSearchBar
            }
            
            // Main content
            Group {
                if viewModel.isLoading {
                    modernLoadingView
                } else if viewModel.filteredChatRooms.isEmpty {
                    modernEmptyStateView
                } else {
                    modernChatListView
                }
            }
        }
    }
    
    // MARK: - Modern Search Bar
    private var modernSearchBar: some View {
        VStack(spacing: 0) {
            HStack(spacing: 16) {
                HStack(spacing: 12) {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.textSecondary)
                    
                    TextField("Search conversations...", text: $viewModel.searchText)
                        .font(.system(size: 16))
                        .foregroundColor(.textPrimary)
                    
                    if !viewModel.searchText.isEmpty {
                        Button(action: { viewModel.searchText = "" }) {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 16))
                                .foregroundColor(.textSecondary)
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(Color(.systemGray6))
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 12)
            .background(Color.clear)
        }
    }
    
    // MARK: - Modern Loading View
    private var modernLoadingView: some View {
        VStack(spacing: 24) {
            Spacer()
            
            // Animated loading indicator
            ZStack {
                Circle()
                    .stroke(Color.primaryOrange.opacity(0.2), lineWidth: 4)
                    .frame(width: 60, height: 60)
                
                Circle()
                    .trim(from: 0, to: 0.7)
                    .stroke(
                        LinearGradient(
                            colors: [Color.primaryOrange, Color.primaryOrange.opacity(0.5)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        style: StrokeStyle(lineWidth: 4, lineCap: .round)
                    )
                    .frame(width: 60, height: 60)
                    .rotationEffect(.degrees(0))
                    .animation(.linear(duration: 1).repeatForever(autoreverses: false), value: UUID())
            }
            
            VStack(spacing: 8) {
                Text("Loading conversations...")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.textPrimary)
                
                Text("Getting your latest messages")
                    .font(.system(size: 14))
                    .foregroundColor(.textSecondary)
            }
            
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.clear)
    }
    
    // MARK: - Modern Empty State View
    private var modernEmptyStateView: some View {
        VStack(spacing: 32) {
            Spacer()
            
            // Modern illustration
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.primaryOrange.opacity(0.1),
                                Color.primaryOrange.opacity(0.05)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 120, height: 120)
                
                Image(systemName: "message.circle")
                    .font(.system(size: 60, weight: .light))
                    .foregroundColor(.primaryOrange)
            }
            
            VStack(spacing: 16) {
                Text("No Conversations Yet")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundColor(.textPrimary)
                
                Text("Start connecting with sports buddies\nand begin your first conversation!")
                    .font(.system(size: 16))
                    .foregroundColor(.textSecondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
            }
            
            // Modern CTA button
            Button(action: {
                print("Start chatting tapped")
            }) {
                HStack(spacing: 8) {
                    Image(systemName: "plus.message")
                        .font(.system(size: 16, weight: .semibold))
                    
                    Text("Start Chatting")
                        .font(.system(size: 16, weight: .semibold))
                }
                .foregroundColor(.white)
                .padding(.horizontal, 32)
                .padding(.vertical, 16)
                .background(
                    LinearGradient(
                        colors: [
                            Color.primaryOrange,
                            Color.primaryOrange.opacity(0.8)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .clipShape(Capsule())
                .shadow(color: .primaryOrange.opacity(0.3), radius: 12, x: 0, y: 6)
            }
            
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.clear)
    }
    
    // MARK: - Modern Chat List View
    private var modernChatListView: some View {
        ScrollView(showsIndicators: false) {
            LazyVStack(spacing: 0) {
                ForEach(viewModel.filteredChatRooms) { chatRoom in
                    CleanModernChatRow(chatRoom: chatRoom) {
                        viewModel.openChat(chatRoom)
                    }
                    
                    if chatRoom.id != viewModel.filteredChatRooms.last?.id {
                        Divider()
                            .padding(.leading, 80)
                    }
                }
                
                // Bottom padding
                Spacer(minLength: 20)
            }
            .background(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .shadow(color: .black.opacity(0.03), radius: 8, x: 0, y: 2)
            .padding(.horizontal, 16)
            .padding(.top, 8)
        }
        .refreshable {
            viewModel.loadChatRooms()
        }
    }
}

// MARK: - Clean Modern Chat Row
struct CleanModernChatRow: View {
    let chatRoom: ChatRoom
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 14) {
                // Clean Profile Image
                ZStack {
                    SearchAsyncImage(
                        url: chatRoom.participantProfileImageUrl,
                        placeholder: chatRoom.chatType.icon
                    )
                    .frame(width: 56, height: 56)
                    .clipShape(Circle())
                    
                    // Minimal online indicator
                    if chatRoom.isOnline && chatRoom.chatType == .direct {
                        Circle()
                            .fill(Color.green)
                            .frame(width: 14, height: 14)
                            .overlay(Circle().stroke(Color.white, lineWidth: 2))
                            .offset(x: 18, y: 18)
                    }
                    
                    // Minimal group indicator
                    if chatRoom.chatType == .group {
                        Circle()
                            .fill(Color.blue)
                            .frame(width: 18, height: 18)
                            .overlay(
                                Image(systemName: "person.3.fill")
                                    .font(.system(size: 9, weight: .bold))
                                    .foregroundColor(.white)
                            )
                            .overlay(Circle().stroke(Color.white, lineWidth: 2))
                            .offset(x: 18, y: 18)
                    }
                }
                
                // Chat content - simplified
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(chatRoom.participantName)
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundColor(.textPrimary)
                            .lineLimit(1)
                        
                        Spacer()
                        
                        HStack(spacing: 8) {
                            Text(chatRoom.timeAgo)
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.textSecondary)
                            
                            // Simple unread indicator
                            if chatRoom.unreadCount > 0 {
                                Text("\(chatRoom.unreadCount)")
                                    .font(.system(size: 12, weight: .bold))
                                    .foregroundColor(.white)
                                    .frame(minWidth: 18, minHeight: 18)
                                    .background(Color.primaryOrange)
                                    .clipShape(Circle())
                            }
                        }
                    }
                    
                    Text(chatRoom.displayLastMessage)
                        .font(.system(size: 15))
                        .foregroundColor(.textSecondary)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Simple Button Style for Chat Rows
struct SimpleChatRowButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .background(configuration.isPressed ? Color.gray.opacity(0.1) : Color.clear)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

// MARK: - Chat Detail View - MODERNIZED
struct ChatDetailView: View {
    let chatRoom: ChatRoom
    let onDismiss: () -> Void
    @StateObject private var viewModel = ChatDetailViewModel()
    @State private var messageText = ""
    @FocusState private var isMessageFieldFocused: Bool
    
    var body: some View {
        VStack(spacing: 0) {
            // Modern header
            modernChatHeader
            
            // Messages
            modernMessagesView
            
            // Modern input
            modernMessageInput
        }
        .background(
            LinearGradient(
                colors: [
                    Color(.systemGroupedBackground),
                    Color(.systemGroupedBackground).opacity(0.8)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
        )
        .onAppear {
            viewModel.loadMessages(for: chatRoom.id)
        }
    }
    
    // MARK: - Modern Chat Header
    private var modernChatHeader: some View {
        HStack(spacing: 16) {
            // Back button with modern styling
            Button(action: onDismiss) {
                Image(systemName: "arrow.left")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.primaryOrange)
                    .frame(width: 40, height: 40)
                    .background(Color.white)
                    .clipShape(Circle())
                    .shadow(color: .black.opacity(0.1), radius: 6, x: 0, y: 3)
            }
            
            // Profile info with modern styling
            HStack(spacing: 12) {
                ZStack {
                    SearchAsyncImage(
                        url: chatRoom.participantProfileImageUrl,
                        placeholder: chatRoom.chatType.icon
                    )
                    .frame(width: 45, height: 45)
                    .clipShape(Circle())
                    .overlay(
                        Circle()
                            .stroke(Color.white, lineWidth: 2)
                    )
                    
                    if chatRoom.isOnline && chatRoom.chatType == .direct {
                        Circle()
                            .fill(Color.green)
                            .frame(width: 14, height: 14)
                            .overlay(Circle().stroke(Color.white, lineWidth: 2))
                            .offset(x: 16, y: 16)
                    }
                }
                
                VStack(alignment: .leading, spacing: 3) {
                    Text(chatRoom.participantName)
                        .font(.system(size: 18, weight: .semibold, design: .rounded))
                        .foregroundColor(.textPrimary)
                    
                    Text(chatRoom.isOnline ? "Online" : "Offline")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(chatRoom.isOnline ? .green : .textSecondary)
                }
            }
            
            Spacer()
            
            // More options button
            Button(action: {
                print("More options tapped")
            }) {
                Image(systemName: "ellipsis")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.textSecondary)
                    .frame(width: 40, height: 40)
                    .background(Color.white)
                    .clipShape(Circle())
                    .shadow(color: .black.opacity(0.1), radius: 6, x: 0, y: 3)
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .background(
            Color.white.opacity(0.95)
                .shadow(color: .black.opacity(0.05), radius: 1)
        )
    }
    
    // MARK: - Modern Messages View
    private var modernMessagesView: some View {
        ScrollView(showsIndicators: false) {
            LazyVStack(spacing: 20) {
                if viewModel.isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .primaryOrange))
                        .scaleEffect(1.2)
                        .padding(40)
                } else if viewModel.messages.isEmpty {
                    VStack(spacing: 20) {
                        Image(systemName: "message")
                            .font(.system(size: 50, weight: .light))
                            .foregroundColor(.primaryOrange.opacity(0.5))
                        
                        VStack(spacing: 8) {
                            Text("No messages yet")
                                .font(.system(size: 20, weight: .semibold))
                                .foregroundColor(.textPrimary)
                            
                            Text("Start the conversation!")
                                .font(.system(size: 16))
                                .foregroundColor(.textSecondary)
                        }
                    }
                    .padding(40)
                } else {
                    ForEach(viewModel.messages) { message in
                        ModernMessageBubble(message: message)
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
        }
        .defaultScrollAnchor(.bottom)
    }
    
    // MARK: - Modern Message Input
    private var modernMessageInput: some View {
        VStack(spacing: 0) {
            Divider()
                .background(Color.gray.opacity(0.15))
            
            HStack(spacing: 12) {
                // Message input field with clean styling
                HStack(spacing: 10) {
                    TextField("Type a message...", text: $messageText, axis: .vertical)
                        .font(.system(size: 16))
                        .focused($isMessageFieldFocused)
                        .lineLimit(1...4)
                        .textFieldStyle(PlainTextFieldStyle())
                    
                    if !messageText.isEmpty {
                        Button(action: { messageText = "" }) {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 16))
                                .foregroundColor(.textSecondary)
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(Color(.systemGray6))
                .clipShape(RoundedRectangle(cornerRadius: 20))
                
                // Clean send button
                Button(action: sendMessage) {
                    Image(systemName: "arrow.up.circle.fill")
                        .font(.system(size: 32))
                        .foregroundColor(messageText.isEmpty ? .gray : .primaryOrange)
                }
                .disabled(messageText.isEmpty)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(Color.white)
        }
    }
    
    private func sendMessage() {
        guard !messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        
        let content = messageText
        messageText = ""
        
        viewModel.sendMessage(to: chatRoom.id, content: content)
    }
}

// MARK: - Chat Detail View Model
class ChatDetailViewModel: ObservableObject {
    @Published var messages: [Message] = []
    @Published var isLoading = false
    
    private let messagesService: MessagesServiceProtocol
    private var cancellables = Set<AnyCancellable>()
    
    init(messagesService: MessagesServiceProtocol = MockMessagesService()) {
        self.messagesService = messagesService
    }
    
    func loadMessages(for chatRoomId: Int) {
        isLoading = true
        
        messagesService.fetchMessages(for: chatRoomId)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    self?.isLoading = false
                    if case .failure(let error) = completion {
                        print("❌ Failed to load messages: \(error)")
                    }
                },
                receiveValue: { [weak self] messages in
                    self?.messages = messages
                    print("✅ Loaded \(messages.count) messages")
                }
            )
            .store(in: &cancellables)
    }
    
    func sendMessage(to chatRoomId: Int, content: String) {
        messagesService.sendMessage(to: chatRoomId, content: content)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { completion in
                    if case .failure(let error) = completion {
                        print("❌ Failed to send message: \(error)")
                    }
                },
                receiveValue: { [weak self] newMessage in
                    self?.messages.append(newMessage)
                    print("✅ Message sent successfully")
                }
            )
            .store(in: &cancellables)
    }
}

// MARK: - Modern Message Bubble
struct ModernMessageBubble: View {
    let message: Message
    
    var body: some View {
        HStack {
            if message.isFromCurrentUser {
                Spacer(minLength: 50)
                
                VStack(alignment: .trailing, spacing: 4) {
                    // Simplified message bubble
                    Text(message.content)
                        .font(.system(size: 16))
                        .foregroundColor(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(Color.primaryOrange)
                        .clipShape(
                            UnevenRoundedRectangle(
                                topLeadingRadius: 18,
                                bottomLeadingRadius: 18,
                                bottomTrailingRadius: 4,
                                topTrailingRadius: 18
                            )
                        )
                    
                    // Minimal timestamp
                    Text(message.timeString)
                        .font(.system(size: 11))
                        .foregroundColor(.textSecondary)
                        .padding(.trailing, 8)
                }
            } else {
                VStack(alignment: .leading, spacing: 4) {
                    // Simplified message bubble
                    Text(message.content)
                        .font(.system(size: 16))
                        .foregroundColor(.textPrimary)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(Color(.systemGray6))
                        .clipShape(
                            UnevenRoundedRectangle(
                                topLeadingRadius: 4,
                                bottomLeadingRadius: 18,
                                bottomTrailingRadius: 18,
                                topTrailingRadius: 18
                            )
                        )
                    
                    // Minimal timestamp
                    Text(message.timeString)
                        .font(.system(size: 11))
                        .foregroundColor(.textSecondary)
                        .padding(.leading, 8)
                }
                
                Spacer(minLength: 50)
            }
        }
    }
}

// MARK: - Preview
#Preview {
    MessagesView()
        .environmentObject(LocalizationManager(localizationService: MockLocalizationService()))
}
                
