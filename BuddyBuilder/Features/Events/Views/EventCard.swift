// BuddyBuilder/Features/Events/Views/EventCard.swift - GÜNCELLENMIŞ

import SwiftUI
import Combine

struct EventCard: View {
    let event: Event
        let onJoin: () -> Void
        let onLeave: () -> Void
        let isMyEvent: Bool
        
        // Swipe ve action callbacks
        let onShare: (() -> Void)?
        let onDelete: (() -> Void)?
        let onEdit: (() -> Void)?
        let onDeactivate: (() -> Void)?
        let onToggleFavorite: (() -> Void)?
        
        @EnvironmentObject var localizationManager: LocalizationManager
        @State private var isJoining = false
        @State private var showingMyEventActions = false
        @State private var dragOffset: CGSize = .zero
        @State private var isFavorite = false
        
        // FIXED: Local state to track participation status
        @State private var isParticipant: Bool
        @State private var currentParticipants: Int
        
        // API Service and Combine
        private let eventsService = CompleteEventsService()
        @State private var cancellables = Set<AnyCancellable>()
        
        // Swipe threshold
        private let swipeThreshold: CGFloat = 60
    
    init(
            event: Event,
            onJoin: @escaping () -> Void,
            onLeave: @escaping () -> Void,
            isMyEvent: Bool = false,
            onShare: (() -> Void)? = nil,
            onDelete: (() -> Void)? = nil,
            onEdit: (() -> Void)? = nil,
            onDeactivate: (() -> Void)? = nil,
            onToggleFavorite: (() -> Void)? = nil
        ) {
            self.event = event
            self.onJoin = onJoin
            self.onLeave = onLeave
            self.isMyEvent = isMyEvent
            self.onShare = onShare
            self.onDelete = onDelete
            self.onEdit = onEdit
            self.onDeactivate = onDeactivate
            self.onToggleFavorite = onToggleFavorite
            
            // FIXED: Initialize local state from event
            self._isParticipant = State(initialValue: event.isParticipant)
            self._currentParticipants = State(initialValue: event.currentParticipants)
            
            print("🎯 EventCard init - Event: \(event.name)")
            print("   isParticipant: \(event.isParticipant)")
            print("   currentParticipants: \(event.currentParticipants)")
        }
    
    var body: some View {
            ZStack {
                // Swipe Action Background (My Events için)
                if isMyEvent && showingMyEventActions {
                    myEventSwipeBackground
                }
                
                // Main Card Content
                mainCardContent
                    .clipShape(RoundedRectangle(cornerRadius: (isMyEvent && showingMyEventActions) ? 0 : 16))
                    .offset(x: dragOffset.width)
                    .gesture(
                        isMyEvent ? swipeGesture : nil
                    )
                    .simultaneousGesture(
                        isMyEvent ? longPressGesture : nil
                    )
                    .animation(.spring(response: 0.3, dampingFraction: 0.8), value: dragOffset)
            }
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .onTapGesture {
                // Close more menu when tapping anywhere
                if showingMyEventActions {
                    resetSwipe()
                }
            }
            // FIXED: Update local state when event changes
            .onAppear {
                updateLocalState()
            }
            .onChange(of: event.isParticipant) { newValue in
                print("🔄 EventCard - event.isParticipant changed to: \(newValue)")
                updateLocalState()
            }
            .onChange(of: event.currentParticipants) { newValue in
                print("🔄 EventCard - event.currentParticipants changed to: \(newValue)")
                updateLocalState()
            }
        }
        
        // MARK: - FIXED: Update Local State
        private func updateLocalState() {
            print("🔄 EventCard - Updating local state for event: \(event.name)")
            print("   From: isParticipant=\(isParticipant), currentParticipants=\(currentParticipants)")
            print("   To: isParticipant=\(event.isParticipant), currentParticipants=\(event.currentParticipants)")
            
            DispatchQueue.main.async {
                isParticipant = event.isParticipant
                currentParticipants = event.currentParticipants
            }
        }
    
    // MARK: - Main Card Content
    private var mainCardContent: some View {
        VStack(spacing: 0) {
            // Event Image and Badges
            ZStack {
                eventImageSection
                
                // Top overlay with badges
                VStack {
                    HStack {
                        eventTypeBadge
                        Spacer()
                        if !isMyEvent {
                            favoriteButton
                        }
                    }
                    .padding(.top, 12)
                    .padding(.horizontal, 12)
                    
                    Spacer()
                }
            }
            
            // Event Details
            eventDetailsSection
        }
        .background(Color.cardBackground)
        .overlay(
            RoundedRectangle(cornerRadius: (isMyEvent && showingMyEventActions) ? 0 : 16)
                .stroke(Color.dynamicBorder.opacity(0.3), lineWidth: 0.5)
        )
        .shadow(
            color: Color.dynamicShadow.opacity(0.15),
            radius: 8,
            x: 0,
            y: 2
        )
    }
    
    // MARK: - Event Image Section
    private var eventImageSection: some View {
        let imageUrlString = event.imageUrl ?? defaultImageUrl(for: event.sport.name)
        
        return AsyncImage(url: URL(string: imageUrlString)) { image in
            image
                .resizable()
                .aspectRatio(contentMode: .fill)
        } placeholder: {
            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [.primaryOrange.opacity(0.3), .primaryOrange.opacity(0.1)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(
                    Image(systemName: "calendar")
                        .font(.system(size: 30, weight: .light))
                        .foregroundColor(.primaryOrange.opacity(0.6))
                )
        }
        .frame(height: 120)
        .clipped()
    }
    
    // MARK: - Event Type Badge
    private var eventTypeBadge: some View {
        HStack(spacing: 4) {
            Image(systemName: eventTypeIcon(for: event.eventTypeName))
                .font(.system(size: 10, weight: .medium))
            
            Text(localizedEventTypeName)
                .font(.system(size: 10, weight: .medium))
                .lineLimit(1)
        }
        .foregroundColor(.white)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(
            Capsule()
                .fill(Color.black.opacity(0.7))
        )
    }
    
    // MARK: - Favorite Button (Only for All Events)
    private var favoriteButton: some View {
        Button(action: {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                isFavorite.toggle()
                onToggleFavorite?()
            }
        }) {
            Image(systemName: isFavorite ? "heart.fill" : "heart")
                .font(.system(size: 20, weight: .medium))
                .foregroundColor(isFavorite ? .primaryOrange : .white)
                .background(
                    Circle()
                        .fill(Color.clear)
                        .frame(width: 32, height: 32)
                )
        }
        .scaleEffect(isFavorite ? 1.2 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isFavorite)
    }
    
    // MARK: - Event Details Section
    private var eventDetailsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Title and Participation Status
            HStack {
                Text(event.name)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.primaryText)
                    .lineLimit(2)
                
                Spacer()
                
                if event.isParticipant {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.green)
                }
            }
            
            // Date and Location
            HStack(spacing: 16) {
                // Date
                HStack(spacing: 6) {
                    Image(systemName: "calendar")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.secondaryText)
                    
                    Text(event.formattedEventDate)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.primaryText)
                }
                
                // Location
                HStack(spacing: 6) {
                    Image(systemName: "location")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.textSecondary)
                    
                    Text(event.location)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.textSecondary)
                        .lineLimit(1)
                }
                
                Spacer()
            }
            
            // Entry Fee
            entryFeeSection
            
            // Participants and Action
            participantsAndActionSection
            
            // Days until event
            if event.daysUntilEvent >= 0 {
                HStack(spacing: 6) {
                    Image(systemName: "clock")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.textSecondary)
                    
                    Text(daysUntilText)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.textSecondary)
                }
            }
        }
        .padding(16)
    }
    
    // MARK: - Entry Fee Section
    private var entryFeeSection: some View {
        Group {
            if event.entryFee > 0 {
                HStack(spacing: 6) {
                    Image(systemName: "dollarsign.circle")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.textSecondary)
                    
                    Text("$\(String(format: "%.0f", event.entryFee))")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.primaryOrange)
                }
            } else {
                HStack(spacing: 6) {
                    Image(systemName: "gift.circle")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.green)
                    
                    Text("events.free".localized(using: localizationManager))
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.green)
                }
            }
        }
    }
    
    // MARK: - Participants and Action Section
    private var participantsAndActionSection: some View {
            HStack {
            // Participant Avatars
            HStack(spacing: -8) {
                ForEach(event.participants.prefix(3), id: \.id) { participant in
                    AsyncImage(url: URL(string: participant.profileImageUrl ?? "")) { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    } placeholder: {
                        Circle()
                            .fill(Color.primaryOrange.opacity(0.3))
                            .overlay(
                                Image(systemName: "person.fill")
                                    .font(.system(size: 8, weight: .medium))
                                    .foregroundColor(.primaryOrange)
                            )
                    }
                    .frame(width: 24, height: 24)
                    .clipShape(Circle())
                    .overlay(
                        Circle()
                            .stroke(Color.white, lineWidth: 2)
                    )
                }
                
                if event.currentParticipants > 3 {
                    Circle()
                        .fill(Color.textSecondary.opacity(0.2))
                        .frame(width: 24, height: 24)
                        .overlay(
                            Text("+\(event.currentParticipants - 3)")
                                .font(.system(size: 8, weight: .semibold))
                                .foregroundColor(.textSecondary)
                        )
                        .overlay(
                            Circle()
                                .stroke(Color.white, lineWidth: 2)
                        )
                }
            }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("events.participants.count".localized(using: localizationManager)
                         .replacingOccurrences(of: "{current}", with: "\(currentParticipants)") // FIXED: Use local state
                         .replacingOccurrences(of: "{max}", with: "\(event.maxParticipants)"))
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.textSecondary)
                    
                    let availableSpots = max(0, event.maxParticipants - currentParticipants) // FIXED: Calculate from local state
                    if availableSpots > 0 {
                        Text("events.spots.left".localized(using: localizationManager)
                             .replacingOccurrences(of: "{count}", with: "\(availableSpots)"))
                            .font(.system(size: 10, weight: .medium))
                            .foregroundColor(.green)
                    } else {
                        Text("events.full".localized(using: localizationManager))
                            .font(.system(size: 10, weight: .medium))
                            .foregroundColor(.red)
                    }
                }
                
                Spacer()
                
                // Join/Leave Button (sadece My Events değilse)
                if !isMyEvent && (event.canJoin || isParticipant) { // FIXED: Use local state
                    joinLeaveButton
                }
                
            // Sport Tag
            Text(event.sport.name)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.primaryOrange)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(
                    Capsule()
                        .fill(Color.primaryOrange.opacity(0.1))
                )
            }
        }
    
    // MARK: - Join/Leave Button - ENHANCED WITH TOAST NOTIFICATIONS
    private var joinLeaveButton: some View {
        Button(action: {
            withAnimation(.easeInOut(duration: 0.2)) {
                isJoining = true
            }
            
            if event.isParticipant {
                leaveEventAPI()
            } else {
                joinEventAPI()
            }
        }) {
            HStack(spacing: 4) {
                if isJoining {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .scaleEffect(0.6)
                } else {
                    Image(systemName: event.isParticipant ? "minus.circle" : "plus.circle")
                        .font(.system(size: 12, weight: .medium))
                }
                
                Text(event.isParticipant ?
                     "events.leave".localized(using: localizationManager) :
                     "events.join".localized(using: localizationManager))
                .font(.system(size: 12, weight: .medium))
            }
            .foregroundColor(.white)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(
                Capsule()
                    .fill(event.isParticipant ? Color.red : Color.primaryOrange)
            )
        }
        .disabled(isJoining)
        .opacity(isJoining ? 0.7 : 1.0)
    }
    
    private var eventTitleSection: some View {
            HStack {
                Text(event.name)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.primaryText)
                    .lineLimit(2)
                
                Spacer()
                
                // FIXED: Use local state for participation status
                if isParticipant {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.green)
                }
            }
        }
    
    // MARK: - ENHANCED API CALLS WITH TOAST NOTIFICATIONS
        
        // MARK: - FIXED: Enhanced API Calls with Immediate UI Update
        private func joinEventAPI() {
            print("🚀 Starting joinEventAPI for event \(event.id)")
            
            eventsService.joinEventWithAutoRefresh(eventId: event.id)
                .receive(on: DispatchQueue.main)
                .sink(
                    receiveCompletion: { completion in
                        withAnimation(.easeInOut(duration: 0.2)) {
                            isJoining = false
                        }
                        
                        switch completion {
                        case .finished:
                            print("✅ Join event completed successfully")
                            break
                        case .failure(let error):
                            print("❌ Failed to join event \(event.id): \(error)")
                            
                            let errorMessage = mapJoinErrorMessage(error.localizedDescription)
                            print("🎯 Showing toast with message: '\(errorMessage)'")
                            
                            // FIXED: Extended toast duration
                            ToastManager.shared.show(message: errorMessage, type: .error, duration: 5.0)
                            print("🍞 Toast show() called with 5 second duration")
                        }
                    },
                    receiveValue: { success in
                        print("📥 Join event receiveValue: \(success)")
                        
                        if success {
                            print("✅ Successfully joined event \(event.id)")
                            
                            // FIXED: Immediate UI update
                            withAnimation(.easeInOut(duration: 0.3)) {
                                isParticipant = true
                                currentParticipants += 1
                            }
                            print("🎯 UI Updated: isParticipant=\(isParticipant), currentParticipants=\(currentParticipants)")
                            
                            let successMessage = "Successfully joined the event!"
                            print("🎯 Showing success toast with message: '\(successMessage)'")
                            
                            // FIXED: Extended toast duration for success
                            ToastManager.shared.show(message: successMessage, type: .success, duration: 4.0)
                            print("🍞 Success toast show() called with 4 second duration")
                            
                            // Call original callback for parent updates
                            onJoin()
                            
                        } else {
                            print("⚠️ Join event API returned false for event \(event.id)")
                            let errorMessage = "Failed to join the event. Please try again."
                            print("🎯 Showing error toast with message: '\(errorMessage)'")
                            ToastManager.shared.show(message: errorMessage, type: .error, duration: 5.0)
                            print("🍞 Error toast show() called")
                        }
                    }
                )
                .store(in: &cancellables)
        }
        
        private func leaveEventAPI() {
            print("🚀 Starting leaveEventAPI for event \(event.id)")
            
            eventsService.leaveEventWithAutoRefresh(eventId: event.id)
                .receive(on: DispatchQueue.main)
                .sink(
                    receiveCompletion: { completion in
                        withAnimation(.easeInOut(duration: 0.2)) {
                            isJoining = false
                        }
                        
                        switch completion {
                        case .finished:
                            print("✅ Leave event completed successfully")
                            break
                        case .failure(let error):
                            print("❌ Failed to leave event \(event.id): \(error)")
                            
                            let errorMessage = mapLeaveErrorMessage(error.localizedDescription)
                            print("🎯 Showing toast with message: '\(errorMessage)'")
                            
                            // FIXED: Extended toast duration
                            ToastManager.shared.show(message: errorMessage, type: .error, duration: 5.0)
                            print("🍞 Toast show() called")
                        }
                    },
                    receiveValue: { success in
                        print("📥 Leave event receiveValue: \(success)")
                        
                        if success {
                            print("✅ Successfully left event \(event.id)")
                            
                            // FIXED: Immediate UI update
                            withAnimation(.easeInOut(duration: 0.3)) {
                                isParticipant = false
                                currentParticipants = max(0, currentParticipants - 1)
                            }
                            print("🎯 UI Updated: isParticipant=\(isParticipant), currentParticipants=\(currentParticipants)")
                            
                            let successMessage = "Successfully left the event!"
                            print("🎯 Showing success toast with message: '\(successMessage)'")
                            
                            // FIXED: Extended toast duration for success
                            ToastManager.shared.show(message: successMessage, type: .success, duration: 4.0)
                            print("🍞 Success toast show() called")
                            
                            // Call original callback for parent updates
                            onLeave()
                            
                        } else {
                            print("⚠️ Leave event API returned false for event \(event.id)")
                            let errorMessage = "Failed to leave the event. Please try again."
                            print("🎯 Showing error toast with message: '\(errorMessage)'")
                            ToastManager.shared.show(message: errorMessage, type: .error, duration: 5.0)
                            print("🍞 Error toast show() called")
                        }
                    }
                )
                .store(in: &cancellables)
        }
    
    // MARK: - Enhanced Error Message Mapping
    private func mapJoinErrorMessage(_ originalMessage: String) -> String {
        let message = originalMessage.lowercased()
        
        switch true {
        case message.contains("skill level") && message.contains("above"):
            return "Your skill level is too high for this event."
        case message.contains("skill level") && message.contains("below"):
            return "Your skill level is too low for this event."
        case message.contains("skill level"):
            return "Your skill level doesn't match the event requirements."
        case message.contains("maximum allowed"):
            return "You don't meet the requirements for this event."
        case message.contains("already registered") || message.contains("already joined"):
            return "You're already registered for this event."
        case message.contains("event is full") || message.contains("no more spots"):
            return "This event is full. No more spots available."
        case message.contains("registration closed") || message.contains("deadline passed"):
            return "Registration for this event has closed."
        case message.contains("gender restriction"):
            return "This event has gender restrictions."
        case message.contains("age restriction"):
            return "You don't meet the age requirements for this event."
        case message.contains("not found"):
            return "Event not found. It may have been deleted."
        case message.contains("unauthorized") || message.contains("permission"):
            return "You don't have permission to join this event."
        case message.contains("network") || message.contains("connection"):
            return "Network error. Please check your connection."
        case message.contains("server") || message.contains("internal"):
            return "Server error. Please try again later."
        default:
            return originalMessage.isEmpty ? "Failed to join the event. Please try again." : originalMessage
        }
    }
    
    private func mapLeaveErrorMessage(_ originalMessage: String) -> String {
        let message = originalMessage.lowercased()
        
        switch true {
        case message.contains("not registered") || message.contains("not joined"):
            return "You're not registered for this event."
        case message.contains("cannot leave") && message.contains("started"):
            return "Cannot leave event that has already started."
        case message.contains("cannot leave") && message.contains("owner"):
            return "Event owners cannot leave their own events."
        case message.contains("not found"):
            return "Event not found. It may have been deleted."
        case message.contains("unauthorized") || message.contains("permission"):
            return "You don't have permission to leave this event."
        case message.contains("network") || message.contains("connection"):
            return "Network error. Please check your connection."
        case message.contains("server") || message.contains("internal"):
            return "Server error. Please try again later."
        default:
            return originalMessage.isEmpty ? "Failed to leave the event. Please try again." : originalMessage
        }
    }
    
    // MARK: - Swipe Actions
    private var myEventSwipeBackground: some View {
        HStack {
            Spacer()
            
            Button(action: {
                if let onShare = onShare {
                    onShare()
                } else if let onEdit = onEdit {
                    onEdit()
                } else if let onDelete = onDelete {
                    onDelete()
                } else if let onDeactivate = onDeactivate {
                    onDeactivate()
                }
                resetSwipe()
            }) {
                Image(systemName: "ellipsis")
                    .font(.system(size: 22, weight: .medium))
                    .foregroundColor(.white)
                    .frame(width: 80)
                    .frame(maxHeight: .infinity)
                    .background(Color.primaryOrange)
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
    
    // MARK: - Gestures
    private var swipeGesture: some Gesture {
        DragGesture()
            .onChanged { value in
                if value.translation.width < 0 {
                    dragOffset.width = max(value.translation.width, -80)
                }
            }
            .onEnded { value in
                if value.translation.width < -swipeThreshold {
                    dragOffset.width = -80
                    showingMyEventActions = true
                } else {
                    resetSwipe()
                }
            }
    }
    
    private var longPressGesture: some Gesture {
        LongPressGesture(minimumDuration: 0.1)
            .onEnded { _ in
                if let onShare = onShare {
                    onShare()
                } else if let onEdit = onEdit {
                    onEdit()
                } else if let onDelete = onDelete {
                    onDelete()
                } else if let onDeactivate = onDeactivate {
                    onDeactivate()
                }
            }
    }
    
    // MARK: - Helper Methods
    private func resetSwipe() {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
            dragOffset.width = 0
            showingMyEventActions = false
        }
    }
    
    private var daysUntilText: String {
        switch event.daysUntilEvent {
        case 0:
            return "events.today".localized(using: localizationManager)
        case 1:
            return "events.tomorrow".localized(using: localizationManager)
        case let days where days > 1:
            return "events.in.days".localized(using: localizationManager)
                .replacingOccurrences(of: "{count}", with: "\(days)")
        default:
            return "events.passed".localized(using: localizationManager)
        }
    }
    
    private var localizedEventTypeName: String {
        let key = "events.type.\(event.eventTypeName.lowercased())"
        return key.localized(using: localizationManager)
    }
    
    private func defaultImageUrl(for sportType: String) -> String {
        switch sportType.lowercased() {
        case "soccer", "football":
            return "https://images.unsplash.com/photo-1574629810360-7efbbe195018"
        case "volleyball":
            return "https://media.istockphoto.com/id/1582215564/photo/women-hands-blocking-volleyball-ball.jpg?s=1024x1024&w=is&k=20&c=v-cDKThS4z6t2JePrunvhod6yxioAlE0_mjiA3aodBE="
        case "tennis":
            return "https://images.unsplash.com/photo-1622279457486-62dcc4a431d6"
        case "basketball":
            return "https://images.unsplash.com/photo-1546519638-68e109498ffc"
        case "golf":
            return "https://images.unsplash.com/photo-1535131749006-b7f58c99034b"
        case "swimming":
            return "https://images.unsplash.com/photo-1530549387789-4c1017266635"
        case "running":
            return "https://images.unsplash.com/photo-1571019613454-1cb2f99b2d8b"
        case "cycling":
            return "https://images.unsplash.com/photo-1558618047-3c8c76ca7d13"
        case "fitness":
            return "https://images.unsplash.com/photo-1534258936925-c58bed479fcb"
        default:
            return "https://images.unsplash.com/photo-1571019613454-1cb2f99b2d8b"
        }
    }
    
    private func eventTypeIcon(for eventTypeName: String) -> String {
        switch eventTypeName.lowercased() {
        case "normal":
            return "calendar"
        case "tournament":
            return "trophy"
        case "featured":
            return "star"
        default:
            return "calendar"
        }
    }
}

// MARK: - Factory Methods
extension EventCard {
    static func forAllEvents(
        event: Event,
        onJoin: @escaping () -> Void,
        onLeave: @escaping () -> Void,
        onToggleFavorite: @escaping () -> Void
    ) -> EventCard {
        return EventCard(
            event: event,
            onJoin: onJoin,
            onLeave: onLeave,
            isMyEvent: false,
            onToggleFavorite: onToggleFavorite
        )
    }
    
    static func forMyEvents(
        event: Event,
        onShare: @escaping () -> Void,
        onDelete: @escaping () -> Void,
        onEdit: @escaping () -> Void,
        onDeactivate: @escaping () -> Void,
        onToggleFavorite: @escaping () -> Void
    ) -> EventCard {
        return EventCard(
            event: event,
            onJoin: {},
            onLeave: {},
            isMyEvent: true,
            onShare: onShare,
            onDelete: onDelete,
            onEdit: onEdit,
            onDeactivate: onDeactivate,
            onToggleFavorite: onToggleFavorite
        )
    }
}

// MARK: - Event Card Skeleton (Unchanged)
struct EventCardSkeleton: View {
    @State private var isAnimating = false
    
    var body: some View {
        VStack(spacing: 0) {
            Rectangle()
                .fill(Color.gray.opacity(0.2))
                .frame(height: 120)
                .shimmer(isAnimating: isAnimating)
            
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Rectangle()
                        .fill(Color.gray.opacity(0.2))
                        .frame(height: 16)
                        .shimmer(isAnimating: isAnimating)
                    
                    Spacer()
                    
                    Circle()
                        .fill(Color.gray.opacity(0.2))
                        .frame(width: 16, height: 16)
                        .shimmer(isAnimating: isAnimating)
                }
                
                HStack(spacing: 16) {
                    Rectangle()
                        .fill(Color.gray.opacity(0.2))
                        .frame(width: 80, height: 12)
                        .shimmer(isAnimating: isAnimating)
                    
                    Rectangle()
                        .fill(Color.gray.opacity(0.2))
                        .frame(width: 100, height: 12)
                        .shimmer(isAnimating: isAnimating)
                    
                    Spacer()
                }
                
                HStack {
                    HStack(spacing: -8) {
                        ForEach(0..<3, id: \.self) { _ in
                            Circle()
                                .fill(Color.gray.opacity(0.2))
                                .frame(width: 24, height: 24)
                                .shimmer(isAnimating: isAnimating)
                        }
                    }
                    
                    Rectangle()
                        .fill(Color.gray.opacity(0.2))
                        .frame(width: 80, height: 12)
                        .shimmer(isAnimating: isAnimating)
                    
                    Spacer()
                    
                    Capsule()
                        .fill(Color.gray.opacity(0.2))
                        .frame(width: 60, height: 24)
                        .shimmer(isAnimating: isAnimating)
                    
                    Capsule()
                        .fill(Color.gray.opacity(0.2))
                        .frame(width: 60, height: 20)
                        .shimmer(isAnimating: isAnimating)
                }
            }
            .padding(16)
        }
        .background(Color.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .dynamicShadow, radius: 10, x: 0, y: 4)
        .onAppear {
            withAnimation(Animation.easeInOut(duration: 1.0).repeatForever(autoreverses: true)) {
                isAnimating = true
            }
        }
    }
}

// MARK: - Shimmer Effect Extension (Unchanged)
extension View {
    func shimmer(isAnimating: Bool) -> some View {
        self
            .overlay(
                Rectangle()
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.clear,
                                Color.white.opacity(0.6),
                                Color.clear
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .rotationEffect(.degrees(30))
                    .offset(x: isAnimating ? 300 : -300)
                    .animation(
                        isAnimating ? Animation.linear(duration: 1.0).repeatForever(autoreverses: false) : .default,
                        value: isAnimating
                    )
            )
            .clipped()
    }
}
