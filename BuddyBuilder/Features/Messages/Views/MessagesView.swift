// BuddyBuilder/Features/Messages/Views/MessagesView.swift - CLEAN VERSION

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

// MARK: - Messages View - CLEAN LAYOUT
struct MessagesView: View {
    @StateObject private var viewModel = MessagesViewModel()
    @EnvironmentObject var localizationManager: LocalizationManager
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Header
                headerView
                
                // Search Bar
                searchBarView
                
                // Content
                contentView
            }
            .background(Color(.systemGroupedBackground))
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
    
    // MARK: - Header View
    private var headerView: some View {
        HStack {
            Text("Messages")
                .font(.system(size: 32, weight: .bold))
                .foregroundColor(.primary)
            
            Spacer()
            
            // Unread count badge
            if viewModel.totalUnreadCount > 0 {
                Text("\(viewModel.totalUnreadCount)")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.red)
                    .clipShape(Capsule())
            }
            
            // New Message Button
            Button(action: {
                print("New message tapped")
            }) {
                Image(systemName: "square.and.pencil")
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(.primaryOrange)
                    .frame(width: 44, height: 44)
                    .background(Color.white)
                    .clipShape(Circle())
                    .shadow(color: .black.opacity(0.1), radius: 4)
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .background(Color.white)
    }
    
    // MARK: - Search Bar View
    private var searchBarView: some View {
        VStack(spacing: 0) {
            HStack(spacing: 12) {
                HStack(spacing: 10) {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 16))
                        .foregroundColor(.gray)
                    
                    TextField("Search messages...", text: $viewModel.searchText)
                        .font(.system(size: 16))
                    
                    if !viewModel.searchText.isEmpty {
                        Button(action: { viewModel.searchText = "" }) {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 16))
                                .foregroundColor(.gray)
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(Color(.systemGray6))
                .clipShape(RoundedRectangle(cornerRadius: 20))
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background(Color.white)
            
            Divider()
        }
    }
    
    // MARK: - Content View
    private var contentView: some View {
        Group {
            if viewModel.isLoading {
                loadingView
            } else if viewModel.filteredChatRooms.isEmpty {
                emptyStateView
            } else {
                chatListView
            }
        }
    }
    
    // MARK: - Loading View
    private var loadingView: some View {
        VStack(spacing: 20) {
            Spacer()
            ProgressView()
                .scaleEffect(1.5)
            Text("Loading messages...")
                .font(.system(size: 16))
                .foregroundColor(.gray)
            Spacer()
        }
    }
    
    // MARK: - Empty State View
    private var emptyStateView: some View {
        VStack(spacing: 24) {
            Spacer()
            
            Image(systemName: "message.circle")
                .font(.system(size: 80))
                .foregroundColor(.primaryOrange.opacity(0.6))
            
            VStack(spacing: 8) {
                Text("No Messages Yet")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(.primary)
                
                Text("Start a conversation with your\nsports buddies!")
                    .font(.system(size: 16))
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
            }
            
            Button(action: {
                print("Start chatting tapped")
            }) {
                Text("Start Chatting")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 32)
                    .padding(.vertical, 12)
                    .background(Color.primaryOrange)
                    .clipShape(Capsule())
            }
            
            Spacer()
        }
    }
    
    // MARK: - Chat List View
    private var chatListView: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                ForEach(viewModel.filteredChatRooms) { chatRoom in
                    CleanChatRow(chatRoom: chatRoom) {
                        viewModel.openChat(chatRoom)
                    }
                    
                    if chatRoom.id != viewModel.filteredChatRooms.last?.id {
                        Divider()
                            .padding(.leading, 80)
                    }
                }
            }
            .background(Color.white)
        }
        .refreshable {
            viewModel.loadChatRooms()
        }
    }
}

// MARK: - Clean Chat Row
struct CleanChatRow: View {
    let chatRoom: ChatRoom
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 16) {
                // Profile Image
                ZStack {
                    SearchAsyncImage(
                        url: chatRoom.participantProfileImageUrl,
                        placeholder: chatRoom.chatType.icon
                    )
                    .frame(width: 60, height: 60)
                    .clipShape(Circle())
                    
                    // Online indicator
                    if chatRoom.isOnline && chatRoom.chatType == .direct {
                        Circle()
                            .fill(Color.green)
                            .frame(width: 16, height: 16)
                            .overlay(Circle().stroke(Color.white, lineWidth: 2))
                            .offset(x: 20, y: 20)
                    }
                    
                    // Group badge
                    if chatRoom.chatType == .group {
                        Image(systemName: "person.3.fill")
                            .font(.system(size: 12))
                            .foregroundColor(.white)
                            .frame(width: 20, height: 20)
                            .background(Color.blue)
                            .clipShape(Circle())
                            .offset(x: 20, y: 20)
                    }
                }
                
                // Chat Info
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text(chatRoom.participantName)
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundColor(.primary)
                            .lineLimit(1)
                        
                        Spacer()
                        
                        Text(chatRoom.timeAgo)
                            .font(.system(size: 14))
                            .foregroundColor(.gray)
                    }
                    
                    HStack {
                        Text(chatRoom.displayLastMessage)
                            .font(.system(size: 15))
                            .foregroundColor(.gray)
                            .lineLimit(2)
                        
                        Spacer()
                        
                        // Unread count
                        if chatRoom.unreadCount > 0 {
                            Text("\(chatRoom.unreadCount)")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(.white)
                                .frame(minWidth: 20, minHeight: 20)
                                .background(Color.red)
                                .clipShape(Circle())
                        }
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Chat Detail View - SIMPLIFIED
struct ChatDetailView: View {
    let chatRoom: ChatRoom
    let onDismiss: () -> Void
    @StateObject private var viewModel = ChatDetailViewModel()
    @State private var messageText = ""
    @FocusState private var isMessageFieldFocused: Bool
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            chatHeader
            
            // Messages
            messagesView
            
            // Input
            messageInput
        }
        .background(Color(.systemGroupedBackground))
        .onAppear {
            viewModel.loadMessages(for: chatRoom.id)
        }
    }
    
    // MARK: - Chat Header
    private var chatHeader: some View {
        HStack(spacing: 16) {
            Button(action: onDismiss) {
                Image(systemName: "arrow.left")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(.primaryOrange)
            }
            
            SearchAsyncImage(
                url: chatRoom.participantProfileImageUrl,
                placeholder: chatRoom.chatType.icon
            )
            .frame(width: 40, height: 40)
            .clipShape(Circle())
            
            VStack(alignment: .leading, spacing: 2) {
                Text(chatRoom.participantName)
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(.primary)
                
                Text(chatRoom.isOnline ? "Online" : "Offline")
                    .font(.system(size: 13))
                    .foregroundColor(chatRoom.isOnline ? .green : .gray)
            }
            
            Spacer()
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(Color.white)
        .shadow(color: .black.opacity(0.05), radius: 1)
    }
    
    // MARK: - Messages View
    private var messagesView: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                if viewModel.isLoading {
                    ProgressView()
                        .padding(40)
                } else if viewModel.messages.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "message")
                            .font(.system(size: 40))
                            .foregroundColor(.gray.opacity(0.5))
                        
                        Text("No messages yet")
                            .font(.system(size: 16))
                            .foregroundColor(.gray)
                        
                        Text("Start the conversation!")
                            .font(.system(size: 14))
                            .foregroundColor(.gray)
                    }
                    .padding(40)
                } else {
                    ForEach(viewModel.messages) { message in
                        CleanMessageBubble(message: message)
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 16)
        }
        .defaultScrollAnchor(.bottom)
    }
    
    // MARK: - Message Input
    private var messageInput: some View {
        VStack(spacing: 0) {
            Divider()
            
            HStack(spacing: 12) {
                TextField("Type a message...", text: $messageText)
                    .font(.system(size: 16))
                    .focused($isMessageFieldFocused)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                
                Button(action: sendMessage) {
                    Image(systemName: "arrow.up.circle.fill")
                        .font(.system(size: 28))
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

// MARK: - Clean Message Bubble
struct CleanMessageBubble: View {
    let message: Message
    
    var body: some View {
        HStack {
            if message.isFromCurrentUser {
                Spacer(minLength: 60)
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text(message.content)
                        .font(.system(size: 16))
                        .foregroundColor(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(Color.primaryOrange)
                        .clipShape(RoundedRectangle(cornerRadius: 18))
                    
                    Text(message.timeString)
                        .font(.system(size: 11))
                        .foregroundColor(.gray)
                        .padding(.trailing, 8)
                }
            } else {
                VStack(alignment: .leading, spacing: 4) {
                    Text(message.content)
                        .font(.system(size: 16))
                        .foregroundColor(.primary)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(Color(.systemGray5))
                        .clipShape(RoundedRectangle(cornerRadius: 18))
                    
                    Text(message.timeString)
                        .font(.system(size: 11))
                        .foregroundColor(.gray)
                        .padding(.leading, 8)
                }
                
                Spacer(minLength: 60)
            }
        }
    }
}

// MARK: - Preview
#Preview {
    MessagesView()
        .environmentObject(LocalizationManager(localizationService: MockLocalizationService()))
}
