import SwiftUI

// MARK: - Event Card
struct EventCard: View {
    let event: Event
    let onTap: () -> Void
    @EnvironmentObject var localizationManager: LocalizationManager
    @State private var isJoining = false
    
    var body: some View {
        VStack(spacing: 0) {
            // Event Image and Type Badge
            ZStack(alignment: .topTrailing) {
                AsyncImage(url: URL(string: event.imageUrl)) { image in
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
                
                // Event Type Badge
                HStack(spacing: 4) {
                    Image(systemName: event.type.icon)
                        .font(.system(size: 10, weight: .medium))
                    
                    Text(event.type.rawValue.localized(using: localizationManager))
                        .font(.system(size: 10, weight: .medium))
                }
                .foregroundColor(.white)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(
                    Capsule()
                        .fill(Color.black.opacity(0.6))
                )
                .padding(.top, 12)
                .padding(.trailing, 12)
            }
            
            // Event Details
            VStack(alignment: .leading, spacing: 12) {
                // Title and Participation Status
                HStack {
                    Text(event.title)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.textPrimary)
                        .lineLimit(2)
                    
                    Spacer()
                    
                    if event.isParticipating {
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
                            .foregroundColor(.textSecondary)
                        
                        Text(event.formattedDate)
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.textSecondary)
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
                
                // Participants and Action
                HStack {
                    // Participant Avatars
                    HStack(spacing: -8) {
                        ForEach(event.participants.prefix(3), id: \.id) { participant in
                            AsyncImage(url: URL(string: participant.avatarUrl)) { image in
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
                        
                        if event.participants.count > 3 {
                            Circle()
                                .fill(Color.textSecondary.opacity(0.2))
                                .frame(width: 24, height: 24)
                                .overlay(
                                    Text("+\(event.participants.count - 3)")
                                        .font(.system(size: 8, weight: .semibold))
                                        .foregroundColor(.textSecondary)
                                )
                                .overlay(
                                    Circle()
                                        .stroke(Color.white, lineWidth: 2)
                                )
                        }
                    }
                    
                    Text(event.formattedParticipantCount + " " + "events.participants".localized(using: localizationManager))
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.textSecondary)
                    
                    Spacer()
                    
                    // Join/Leave Button
                    if event.availableSpots > 0 || event.isParticipating {
                        Button(action: {
                            Task {
                                isJoining = true
                                // TODO: Implement join/leave functionality
                                // This should be handled by the parent view
                                try? await Task.sleep(nanoseconds: 1_000_000_000)
                                isJoining = false
                            }
                        }) {
                            HStack(spacing: 4) {
                                if isJoining {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                        .scaleEffect(0.6)
                                } else {
                                    Image(systemName: event.isParticipating ? "minus.circle" : "plus.circle")
                                        .font(.system(size: 12, weight: .medium))
                                }
                                
                                Text(event.isParticipating ? "events.leave".localized(using: localizationManager) : "events.join".localized(using: localizationManager))
                                    .font(.system(size: 12, weight: .medium))
                            }
                            .foregroundColor(.white)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(
                                Capsule()
                                    .fill(event.isParticipating ? Color.red : Color.primaryOrange)
                            )
                        }
                        .disabled(isJoining)
                        .opacity(isJoining ? 0.7 : 1.0)
                    }
                    
                    // Sport Tag
                    Text(event.sport.rawValue.localized(using: localizationManager))
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
            .padding(16)
        }
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.05), radius: 10, x: 0, y: 4)
        .onTapGesture {
            onTap()
        }
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
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.05), radius: 10, x: 0, y: 4)
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

// MARK: - Preview
#Preview {
    ScrollView {
        VStack(spacing: 16) {
            EventCard(
                event: Event(
                    id: "1",
                    title: "Weekend Football Tournament",
                    description: "Join us for an exciting football tournament!",
                    imageUrl: "https://images.unsplash.com/photo-1574629810360-7efbbe195018",
                    date: Date(),
                    location: "Central Park",
                    type: .tournament,
                    sport: .football,
                    participants: [],
                    maxParticipants: 16,
                    isParticipating: false,
                    createdBy: "user123",
                    createdAt: Date()
                ),
                onTap: {}
            )
            .environmentObject(LocalizationManager(localizationService: MockLocalizationService()))
            
            EventCardSkeleton()
        }
        .padding()
    }
}
