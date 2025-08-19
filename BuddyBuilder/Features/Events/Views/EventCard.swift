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
    
    let onTap: (() -> Void)?
    
    @EnvironmentObject var localizationManager: LocalizationManager
    @State private var isJoining = false
    @State private var isCooldown = false
    @State private var showingMyEventActions = false
    @State private var dragOffset: CGSize = .zero
    @State private var isFavorite = false
    
    // API Service and Combine
    private let eventsService = CompleteEventsService()
    @State private var cancellables = Set<AnyCancellable>()
    
    // Swipe threshold
    private let swipeThreshold: CGFloat = 60
    
    // Layout constants
    private let imageHeight: CGFloat = 120
    private let cardCornerRadius: CGFloat = 16
    
    init(
        event: Event,
        onJoin: @escaping () -> Void,
        onLeave: @escaping () -> Void,
        isMyEvent: Bool = false,
        onShare: (() -> Void)? = nil,
        onDelete: (() -> Void)? = nil,
        onEdit: (() -> Void)? = nil,
        onDeactivate: (() -> Void)? = nil,
        onToggleFavorite: (() -> Void)? = nil,
        onTap: (() -> Void)? = nil
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
        self.onTap = onTap
    }
    
    var body: some View {
        print("🎯 EventCard.body recomputed for event \(event.id) - isParticipant: \(event.isParticipant)")
        return ZStack {
            // Swipe Action Background (My Events için)
            if isMyEvent && showingMyEventActions {
                myEventSwipeBackground
            }
            
            // Main Card Content
            mainCardContent
                .clipShape(RoundedRectangle(cornerRadius: (isMyEvent && showingMyEventActions) ? 0 : cardCornerRadius))
                .offset(x: dragOffset.width)
                .onTapGesture {
                    if isMyEvent && showingMyEventActions {
                        resetSwipe()
                    } else {
                        onTap?()
                    }
                }
                .gesture(
                    isMyEvent ? swipeGesture : nil
                )
                .simultaneousGesture(
                    isMyEvent ? longPressGesture : nil
                )
                .animation(.spring(response: 0.3, dampingFraction: 0.8), value: dragOffset)
        }
        .clipShape(RoundedRectangle(cornerRadius: cardCornerRadius))
    }
    
    // MARK: - Main Card Content
    private var mainCardContent: some View {
        VStack(spacing: 0) {
            // Event Image Section
            eventImageSection
                .frame(height: imageHeight)
                .clipped()
            
            // Event Details Section
            eventDetailsSection
        }
        .background(Color.cardBackground)
        .overlay(
            RoundedRectangle(cornerRadius: (isMyEvent && showingMyEventActions) ? 0 : cardCornerRadius)
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
        ZStack {
            Group {
                let imageUrlString = event.imageUrl ?? defaultImageUrl(for: event.sport.name)
                
                AsyncImage(url: URL(string: imageUrlString)) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    case .failure(_):
                        placeholderImage
                    case .empty:
                        placeholderImage
                            .overlay(
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .primaryOrange))
                                    .scaleEffect(0.8)
                            )
                    @unknown default:
                        placeholderImage
                    }
                }
            }
            .frame(height: imageHeight)
            .frame(maxWidth: .infinity)
            .clipped()
            
            // Overlay with badges
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
        .frame(height: imageHeight)
    }
    
    // MARK: - Placeholder Image
    private var placeholderImage: some View {
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
    
    // MARK: - Favorite Button
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
                .frame(width: 32, height: 32)
                .background(
                    Circle()
                        .fill(Color.clear)
                )
        }
        .scaleEffect(isFavorite ? 1.2 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isFavorite)
    }
    
    // MARK: - Event Details Section
    private var eventDetailsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Title and Participation Status
            eventTitleSection
            
            // Date and Location
            dateLocationSection
            
            // Entry Fee
            entryFeeSection
            
            // Participants and Action
            participantsAndActionSection
            
            // Days until event
            daysUntilSection
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    // MARK: - Title Section
    private var eventTitleSection: some View {
        HStack {
            Text(event.name)
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.primaryText)
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)
            
            Spacer()
            
            if event.isParticipant {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.green)
            }
        }
    }
    
    // MARK: - Date and Location Section
    private var dateLocationSection: some View {
        HStack(spacing: 16) {
            // Date
            HStack(spacing: 6) {
                Image(systemName: "calendar")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.secondaryText)
                    .frame(width: 12)
                
                Text(event.formattedEventDate)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.primaryText)
            }
            
            // Location
            HStack(spacing: 6) {
                Image(systemName: "location")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.textSecondary)
                    .frame(width: 12)
                
                Text(event.location)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.textSecondary)
                    .lineLimit(1)
            }
            
            Spacer()
        }
    }
    
    // MARK: - Entry Fee Section
    private var entryFeeSection: some View {
        Group {
            if event.entryFee > 0 {
                HStack(spacing: 6) {
                    Image(systemName: "dollarsign.circle")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.textSecondary)
                        .frame(width: 12)
                    
                    Text("$\(String(format: "%.0f", event.entryFee))")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.primaryOrange)
                }
            } else {
                HStack(spacing: 6) {
                    Image(systemName: "gift.circle")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.green)
                        .frame(width: 12)
                    
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
            // TEMPORARILY HIDDEN: Participant Avatars (commented out)
            // participantAvatarsSection
            
            participantInfoSection
            
            Spacer()
            
            // Join/Leave Button (sadece My Events değilse)
            if !isMyEvent && (event.canJoin || event.isParticipant) {
                joinLeaveButton
            }
            
            // Sport Tag
            sportTagSection
        }
    }
    
    // MARK: - Participant Info
    private var participantInfoSection: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text("events.participants.count".localized(using: localizationManager)
                 .replacingOccurrences(of: "{current}", with: "\(event.currentParticipants)")
                 .replacingOccurrences(of: "{max}", with: "\(event.maxParticipants)"))
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.textSecondary)
            
            let availableSpots = max(0, event.maxParticipants - event.currentParticipants)
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
    }
    
    // MARK: - Sport Tag
    private var sportTagSection: some View {
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
    
    // MARK: - Days Until Section
    private var daysUntilSection: some View {
        Group {
            if event.daysUntilEvent >= 0 {
                HStack(spacing: 6) {
                    Image(systemName: "clock")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.textSecondary)
                        .frame(width: 12)
                    
                    Text(daysUntilText)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.textSecondary)
                }
            }
        }
    }
    
    // MARK: - SIMPLIFIED: Join/Leave Button - Let ViewModel Handle State
    private var joinLeaveButton: some View {
        Button(action: {
            // Check if we're in cooldown period
            guard !isCooldown && !isJoining else {
                print("⏰ EventCard: Button is in cooldown or processing, ignoring tap")
                return
            }
            
            print("🎯 EventCard: Join/Leave button tapped for event \(event.id)")
            print("   Event isParticipant: \(event.isParticipant)")
            
            withAnimation(.easeInOut(duration: 0.2)) {
                isJoining = true
                isCooldown = true
            }
            
            // SIMPLIFIED: Direct parent callback, let ViewModel handle everything
            if event.isParticipant {
                print("🚪 EventCard: Calling onLeave")
                onLeave()
            } else {
                print("🚪 EventCard: Calling onJoin")
                onJoin()
            }
            
            // Reset loading state after a delay
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                isJoining = false
            }
            
            // Reset cooldown after a short delay (1.5 seconds total)
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                isCooldown = false
                print("⏰ EventCard: Cooldown period ended for event \(event.id)")
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
        .disabled(isJoining || isCooldown)
        .opacity((isJoining || isCooldown) ? 0.7 : 1.0)
    }
    
    // MARK: - Helper Methods
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
    
    // MARK: - Swipe Actions (keeping existing implementation)
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
        .clipShape(RoundedRectangle(cornerRadius: cardCornerRadius))
    }
    
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
    
    private func resetSwipe() {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
            dragOffset.width = 0
            showingMyEventActions = false
        }
    }
}

// MARK: - Factory Methods
extension EventCard {
    
    // MARK: - All Events Factory Method
    static func forAllEvents(
        event: Event,
        onJoin: @escaping () -> Void,
        onLeave: @escaping () -> Void,
        onToggleFavorite: @escaping () -> Void,
        onTap: @escaping () -> Void
    ) -> EventCard {
        return EventCard(
            event: event,
            onJoin: onJoin,
            onLeave: onLeave,
            isMyEvent: false,
            onShare: nil,
            onDelete: nil,
            onEdit: nil,
            onDeactivate: nil,
            onToggleFavorite: onToggleFavorite,
            onTap: onTap
        )
    }
    
    // MARK: - My Events Factory Method
    static func forMyEvents(
        event: Event,
        onShare: @escaping () -> Void,
        onDelete: @escaping () -> Void,
        onEdit: @escaping () -> Void,
        onDeactivate: @escaping () -> Void,
        onToggleFavorite: @escaping () -> Void,
        onTap: @escaping () -> Void
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
            onToggleFavorite: onToggleFavorite,
            onTap: onTap
        )
    }
}

// MARK: - Event Card Skeleton
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

// MARK: - Shimmer Effect Extension
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
