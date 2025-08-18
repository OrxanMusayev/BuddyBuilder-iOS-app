// BuddyBuilder/Features/Events/Views/EventDetailView.swift
// YENI DOSYA: Event detaylarını gösteren modern sayfa

import SwiftUI

struct EventDetailView: View {
    let event: Event
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var localizationManager: LocalizationManager
    @State private var isJoining = false
    @State private var showShareSheet = false
    @State private var scrollOffset: CGFloat = 0
    
    // MARK: - Constants
    private let headerHeight: CGFloat = 300
    private let imageHeight: CGFloat = 250
    
    // MARK: - Computed Properties
    private var isOwnerEvent: Bool {
        return event.isOwner
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Background
                Color.dynamicBackground
                    .ignoresSafeArea(.all)
                
                // Main Content
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 0) {
                        // Hero Image Section
                        heroImageSection
                        
                        // Event Details Content
                        eventDetailsContent
                    }
                }
                .padding(.top, 80) // Azaltıldı: 120 -> 80
                .onScrollOffsetChanged { offset in
                    scrollOffset = offset
                }
                
                // Floating Header
                floatingHeader
                
                // Floating Action Button (sadece join/leave için)
                if !isOwnerEvent {
                    floatingActionButton
                }
            }
        }
        .ignoresSafeArea(.all) // Tüm safe area'yı ignore et
        .navigationBarHidden(true)
        .sheet(isPresented: $showShareSheet) {
            ShareSheet(event: event)
        }
    }
    
    // MARK: - Hero Image Section
    private var heroImageSection: some View {
        ZStack {
            // Event Image
            AsyncImage(url: URL(string: event.imageUrl ?? defaultImageUrl)) { image in
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
                            .font(.system(size: 50, weight: .light))
                            .foregroundColor(.primaryOrange.opacity(0.6))
                    )
            }
            .frame(height: imageHeight) // Normale döndür
            .clipped()
            .overlay(
                // Gradient overlay
                LinearGradient(
                    colors: [Color.clear, Color.black.opacity(0.3), Color.black.opacity(0.7)],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            
            // Badges (üst köşeler - image içinde)
            VStack {
                HStack {
                    eventTypeBadge
                    Spacer()
                    participationStatusBadge
                }
                Spacer()
            }
            .padding(.horizontal, 20)
            .padding(.top, 40) // Azaltıldı: 40 -> 30
            
            // Event Title and Basic Info (centered at bottom)
            VStack {
                Spacer()
                VStack(alignment: .center, spacing: 8) {
                    Text(event.name)
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                        .shadow(color: .black.opacity(0.3), radius: 2, x: 0, y: 1)
                    
                    VStack(spacing: 12) { // Artırıldı: 8 -> 12
                        HStack(spacing: 4) {
                            Image(systemName: "calendar")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.white.opacity(0.9))
                                
                                Text(event.formattedEventDate)
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.white.opacity(0.9))
                        }
                        
                        HStack(spacing: 4) {
                            Image(systemName: "location")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.white.opacity(0.9))
                            
                            Text(event.location)
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.white.opacity(0.9))
                                .lineLimit(4)
                        }
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.horizontal, 20)
                .padding(.bottom, 40) // Artırıldı: 20 -> 30
            }
        }
        .frame(height: headerHeight + 20) // Height artırıldı
    }
    
    // MARK: - Floating Header
    private var floatingHeader: some View {
        VStack(spacing: 0) {
            // Top header with back/share buttons and badges
            VStack(spacing: 16) {
                // Back and Share buttons
                HStack {
                    // Back Button
                    Button(action: {
                        dismiss()
                    }) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.primaryText)
                            .frame(width: 32, height: 32)
                    }
                    
                    Spacer()
                    
                    // Title (visible when scrolled)
                    if scrollOffset > 150 { // Normale döndür
                        Text(event.name)
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.primaryText)
                            .lineLimit(1)
                            .transition(.opacity)
                    }
                    
                    Spacer()
                    
                    // Share Button
                    Button(action: {
                        showShareSheet = true
                    }) {
                        Image(systemName: "square.and.arrow.up")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.primaryText)
                            .frame(width: 32, height: 32)
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 50) // Azaltıldı: 60 -> 50
            
            Spacer()
        }
        .background(
            Rectangle()
                .fill(Color.clear) // Şeffaf arka plan
                .ignoresSafeArea(edges: .top)
        )
        .animation(.easeInOut(duration: 0.2), value: scrollOffset)
    }
    
    // MARK: - Event Details Content
    private var eventDetailsContent: some View {
        VStack(spacing: 24) {
            // Quick Stats
            quickStatsSection
            
            // Description
            descriptionSection
            
            // Event Details
            detailsSection
            
            // Participants
            participantsSection
            
            // Location Details (if available)
            locationSection
            
            // Action Buttons Section
            actionButtonsSection
            
            // Bottom Spacer
            Color.clear.frame(height: 40)
        }
        .padding(.horizontal, 20)
        .padding(.top, 20)
        .background(
            Color.dynamicBackground
                .clipShape(
                    RoundedRectangle(cornerRadius: 24)
                        .offset(y: -24)
                )
        )
    }
    
    // MARK: - Quick Stats Section
    private var quickStatsSection: some View {
        HStack(spacing: 16) {
            // Participants
            VStack(spacing: 4) {
                Text("\(event.currentParticipants)")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(.primaryOrange)
                
                Text("events.participants".localized(using: localizationManager))
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.secondaryText)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.cardBackground)
                    .shadow(color: Color.dynamicShadow, radius: 4, x: 0, y: 2)
            )
            
            // Available Spots
            VStack(spacing: 4) {
                Text("\(max(0, event.maxParticipants - event.currentParticipants))")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(.green)
                
                Text("events.spots_left".localized(using: localizationManager))
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.secondaryText)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.cardBackground)
                    .shadow(color: Color.dynamicShadow, radius: 4, x: 0, y: 2)
            )
            
            // Entry Fee
            VStack(spacing: 4) {
                if event.entryFee > 0 {
                    Text("$\(String(format: "%.0f", event.entryFee))")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.primaryOrange)
                } else {
                    Text("FREE")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.green)
                }
                
                Text("events.entry_fee".localized(using: localizationManager))
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.secondaryText)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.cardBackground)
                    .shadow(color: Color.dynamicShadow, radius: 4, x: 0, y: 2)
            )
        }
    }
    
    // MARK: - Description Section
    private var descriptionSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("events.description".localized(using: localizationManager))
                .font(.system(size: 20, weight: .semibold))
                .foregroundColor(.primaryText)
            
            Text(event.description)
                .font(.system(size: 16, weight: .regular))
                .foregroundColor(.secondaryText)
                .lineSpacing(4)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.cardBackground)
                .shadow(color: Color.dynamicShadow, radius: 4, x: 0, y: 2)
        )
    }
    
    // MARK: - Details Section
    private var detailsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("events.details".localized(using: localizationManager))
                .font(.system(size: 20, weight: .semibold))
                .foregroundColor(.primaryText)
            
            VStack(spacing: 12) {
                DetailRow(
                    icon: "sportscourt",
                    title: "Sport",
                    value: event.sport.name
                )
                
                DetailRow(
                    icon: "calendar",
                    title: "Date & Time",
                    value: event.formattedEventDate
                )
                
                DetailRow(
                    icon: "clock",
                    title: "Registration Deadline",
                    value: formatDate(event.registrationDeadlineDate)
                )
                
                DetailRow(
                    icon: "person.2",
                    title: "Max Participants",
                    value: "\(event.maxParticipants)"
                )
                
                if event.daysUntilEvent >= 0 {
                    DetailRow(
                        icon: "hourglass",
                        title: "Days Until Event",
                        value: "\(event.daysUntilEvent) days"
                    )
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.cardBackground)
                .shadow(color: Color.dynamicShadow, radius: 4, x: 0, y: 2)
        )
    }
    
    // MARK: - Participants Section
    private var participantsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("events.participants".localized(using: localizationManager))
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(.primaryText)
                
                Spacer()
                
                Text("\(event.currentParticipants)/\(event.maxParticipants)")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.secondaryText)
            }
            
            // Participants Grid
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 4), spacing: 12) {
                ForEach(event.participants.prefix(8), id: \.id) { participant in
                    ParticipantCard(participant: participant)
                }
                
                if event.participants.count > 8 {
                    VStack(spacing: 4) {
                        Circle()
                            .fill(Color.secondaryText.opacity(0.2))
                            .frame(width: 60, height: 60)
                            .overlay(
                                Text("+\(event.participants.count - 8)")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(.secondaryText)
                            )
                        
                        Text("More")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.secondaryText)
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.cardBackground)
                .shadow(color: Color.dynamicShadow, radius: 4, x: 0, y: 2)
        )
    }
    
    // MARK: - Location Section
    private var locationSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("events.location".localized(using: localizationManager))
                .font(.system(size: 20, weight: .semibold))
                .foregroundColor(.primaryText)
            
            HStack(spacing: 12) {
                Image(systemName: "location.fill")
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(.primaryOrange)
                    .frame(width: 40, height: 40)
                    .background(
                        Circle()
                            .fill(Color.primaryOrange.opacity(0.1))
                    )
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(event.location)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.primaryText)
                    
                    Text("Tap to open in Maps")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.secondaryText)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.secondaryText)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.cardBackground)
                .shadow(color: Color.dynamicShadow, radius: 4, x: 0, y: 2)
        )
        .onTapGesture {
            // TODO: Open in Maps
        }
    }
    
    // MARK: - Action Buttons Section
    private var actionButtonsSection: some View {
        VStack(spacing: 20) {
            if isOwnerEvent {
                // Owner için Edit/Delete butonları
                HStack(spacing: 12) {
                    // Delete Button
                    Button(action: {
                        // TODO: Handle delete action
                    }) {
                        HStack(spacing: 6) {
                            Image(systemName: "trash.fill")
                                .font(.system(size: 14, weight: .semibold))
                            
                            Text("events.delete".localized(using: localizationManager))
                                .font(.system(size: 14, weight: .semibold))
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 12)
                        .background(
                            Capsule()
                                .fill(Color.red)
                                .shadow(color: Color.dynamicShadow.opacity(0.2), radius: 4, x: 0, y: 2)
                        )
                    }
                    
                    // Edit Button
                    Button(action: {
                        // TODO: Handle edit action
                    }) {
                        HStack(spacing: 6) {
                            Image(systemName: "pencil.circle.fill")
                                .font(.system(size: 14, weight: .semibold))
                            
                            Text("events.edit".localized(using: localizationManager))
                                .font(.system(size: 14, weight: .semibold))
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 12)
                        .background(
                            Capsule()
                                .fill(Color.primaryOrange)
                                .shadow(color: Color.dynamicShadow.opacity(0.2), radius: 4, x: 0, y: 2)
                        )
                    }
                }
                .padding(.top, 24)
            }
        }
    }
    
    // MARK: - Floating Action Button (Sadece Join/Leave için)
    private var floatingActionButton: some View {
        VStack {
            Spacer()
            
            HStack {
                Spacer()
                
                if event.canJoin || event.isParticipant {
                    Button(action: {
                        // TODO: Handle join/leave action
                        isJoining.toggle()
                    }) {
                        HStack(spacing: 8) {
                            if isJoining {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                    .scaleEffect(0.8)
                            } else {
                                Image(systemName: event.isParticipant ? "minus.circle.fill" : "plus.circle.fill")
                                    .font(.system(size: 18, weight: .semibold))
                            }
                            
                            Text(event.isParticipant ? "Leave Event" : "Join Event")
                                .font(.system(size: 16, weight: .semibold))
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 16)
                        .background(
                            Capsule()
                                .fill(event.isParticipant ? Color.red : Color.primaryOrange)
                                .shadow(color: Color.dynamicShadow.opacity(0.3), radius: 8, x: 0, y: 4)
                        )
                    }
                    .disabled(isJoining)
                    .scaleEffect(isJoining ? 0.95 : 1.0)
                    .animation(.easeInOut(duration: 0.1), value: isJoining)
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 40)
        }
    }
    
    // MARK: - Helper Components
    private var eventTypeBadge: some View {
        Text(event.eventTypeName)
            .font(.system(size: 12, weight: .semibold))
            .foregroundColor(.white)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(
                Capsule()
                    .fill(Color.black.opacity(0.6))
            )
    }
    
    private var participationStatusBadge: some View {
        Group {
            if event.isParticipant {
                HStack(spacing: 4) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 12, weight: .semibold))
                    
                    Text("Joined")
                        .font(.system(size: 12, weight: .semibold))
                }
                .foregroundColor(.white)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(
                    Capsule()
                        .fill(Color.green.opacity(0.8))
                )
            }
        }
    }
    
    // MARK: - Helper Methods
    private var defaultImageUrl: String {
        return "https://images.unsplash.com/photo-1571019613454-1cb2f99b2d8b"
    }
    
    private func formatDate(_ date: Date?) -> String {
        guard let date = date else { return "N/A" }
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

// MARK: - Supporting Views
struct DetailRow: View {
    let icon: String
    let title: String
    let value: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.primaryOrange)
                .frame(width: 24, height: 24)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.secondaryText)
                
                Text(value)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.primaryText)
            }
            
            Spacer()
        }
    }
}

struct ParticipantCard: View {
    let participant: ParticipantDto
    
    var body: some View {
        VStack(spacing: 8) {
            AsyncImage(url: URL(string: participant.profileImageUrl ?? "")) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } placeholder: {
                Circle()
                    .fill(Color.primaryOrange.opacity(0.2))
                    .overlay(
                        Image(systemName: "person.fill")
                            .font(.system(size: 20, weight: .medium))
                            .foregroundColor(.primaryOrange)
                    )
            }
            .frame(width: 60, height: 60)
            .clipShape(Circle())
            
            Text(participant.displayName)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.primaryText)
                .lineLimit(1)
                .multilineTextAlignment(.center)
        }
    }
}

struct ShareSheet: View {
    let event: Event
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        VStack {
            Text("Share Event")
                .font(.headline)
                .padding()
            
            // TODO: Implement share functionality
            Button("Close") {
                dismiss()
            }
            .padding()
        }
    }
}

// MARK: - Scroll Offset Preference
struct ScrollOffsetPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

extension View {
    func onScrollOffsetChanged(perform action: @escaping (CGFloat) -> Void) -> some View {
        self.background(
            GeometryReader { geometry in
                Color.clear
                    .preference(
                        key: ScrollOffsetPreferenceKey.self,
                        value: geometry.frame(in: .named("scroll")).minY
                    )
            }
        )
        .onPreferenceChange(ScrollOffsetPreferenceKey.self, perform: action)
        .coordinateSpace(name: "scroll")
    }
}
