// MARK: - Updated Section Detail View with Pagination
import SwiftUI

struct SectionDetailView: View {
    let section: SectionType
    let users: [SearchUser]
    let trainers: [SearchTrainer]
    let hasMorePages: Bool
    let isLoading: Bool
    let onDismiss: () -> Void
    let onLoadMore: () -> Void
    @EnvironmentObject var localizationManager: LocalizationManager
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Background
                Color(.systemGroupedBackground)
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Header
                    headerView
                    
                    // Content
                    ScrollView {
                        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 16), count: 2), spacing: 16) {
                            if section == .topTrainers {
                                ForEach(trainers) { trainer in
                                    DetailTrainerCard(trainer: trainer)
                                }
                            } else {
                                ForEach(users) { user in
                                    DetailUserCard(
                                        user: user,
                                        section: section
                                    )
                                }
                            }
                            
                            // Load more indicator
                            if hasMorePages {
                                loadMoreSection
                                    .onAppear {
                                        onLoadMore()
                                    }
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 20)
                        .padding(.bottom, 100)
                    }
                }
            }
        }
        .navigationBarHidden(true)
    }
    
    private var headerView: some View {
        HStack {
            Button(action: onDismiss) {
                HStack(spacing: 8) {
                    Image(systemName: "arrow.left")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.primaryOrange)
                        .frame(width: 44, height: 44)
                        .background(Color.clear)
                }
                .foregroundColor(.primary)
            }
            
            Spacer()
            
            VStack(spacing: 4) {
                Text(section.title)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.primary)
            }
            
            Spacer()
            
            // Placeholder for balance
            HStack(spacing: 8) {
                Text("Back")
                    .font(.system(size: 16, weight: .medium))
                    .opacity(0)
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .background(Color(.systemBackground))
    }
    
    private var loadMoreSection: some View {
        VStack(spacing: 12) {
            if isLoading {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .primaryOrange))
                    .scaleEffect(1.2)
                
                Text("Loading more...")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.textSecondary)
            }
        }
        .frame(height: 80)
        .frame(maxWidth: .infinity)
        .gridCellColumns(2) // Span both columns
    }
}

// MARK: - Detail User Card (Updated for SearchUser)
struct DetailUserCard: View {
    let user: SearchUser
    let section: SectionType
    @State private var isPressed = false
    
    var body: some View {
        VStack(spacing: 10) {
            // Profile Image - Larger size
            ZStack {
                Circle()
                    .fill(Color.gray.opacity(0.12))
                    .frame(width: 80, height: 80) // Increased from 70 to 80
                
                if let imageUrl = user.profileImageUrl {
                    AsyncImage(url: URL(string: imageUrl)) { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    } placeholder: {
                        Image(systemName: "person.crop.circle.fill")
                            .font(.system(size: 65)) // Increased from 55 to 65
                            .foregroundColor(.gray.opacity(0.5))
                    }
                    .frame(width: 80, height: 80) // Increased from 70 to 80
                    .clipShape(Circle())
                } else {
                    Image(systemName: "person.crop.circle.fill")
                        .font(.system(size: 65)) // Increased from 55 to 65
                        .foregroundColor(.gray.opacity(0.5))
                }
                
                // Status indicators - NO STROKE
                if section == .newJoiners {
                    VStack {
                        HStack {
                            Spacer()
                            Circle()
                                .fill(Color.red)
                                .frame(width: 16, height: 16) // Slightly larger for bigger profile image
                                .offset(x: 8, y: -8)
                        }
                        Spacer()
                    }
                } else if section == .activeUsers && user.isOnline {
                    VStack {
                        Spacer()
                        HStack {
                            Spacer()
                            Circle()
                                .fill(Color.green)
                                .frame(width: 16, height: 16) // Slightly larger for bigger profile image
                                .offset(x: 8, y: 8)
                        }
                    }
                }
            }
            
            // User Info - Reduced spacing and heights
            VStack(spacing: 4) {
                Text(user.name)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.textPrimary)
                    .lineLimit(1)
                    .frame(height: 16) // Reduced from 18
                
                Text("@\(user.username)")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.textSecondary)
                    .lineLimit(1)
                    .frame(height: 14) // Reduced from 16
                
                Text(user.bio)
                    .font(.system(size: 11))
                    .foregroundColor(.textSecondary)
                    .lineLimit(2) // Reduced from 3 lines to 2
                    .multilineTextAlignment(.center)
                    .frame(height: 28) // Reduced from 42 to 28
                
                Text(user.location)
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(.primaryOrange)
                    .lineLimit(1)
                    .frame(height: 12) // Reduced from 14
            }
            
            Spacer() // Push button to bottom
            
            // Action Button - Reduced height
            Button(action: {
                print("Action for \(user.name)")
            }) {
                HStack(spacing: 6) {
                    Image(systemName: getButtonIcon())
                        .font(.system(size: 12, weight: .medium))
                    
                    Text(getButtonTitle())
                        .font(.system(size: 12, weight: .semibold))
                }
                .foregroundColor(getButtonColor())
                .frame(maxWidth: .infinity)
                .frame(height: 28) // Reduced from 32 to 28
                .background(Color.clear)
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(getButtonColor(), lineWidth: 1.5)
                )
            }
            .scaleEffect(isPressed ? 0.95 : 1.0)
        }
        .frame(maxWidth: .infinity, minHeight: 240, maxHeight: 240) // Reduced from 280 to 240
        .padding(14) // Reduced from 16 to 14
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
        .scaleEffect(isPressed ? 0.98 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isPressed)
        .onTapGesture {
            withAnimation {
                isPressed = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                withAnimation {
                    isPressed = false
                }
            }
        }
    }
    
    private func getButtonColor() -> Color {
        switch section {
        case .popularUsers: return Color.red
        case .newJoiners: return Color.green
        case .activeUsers: return Color.blue
        case .topTrainers: return Color.purple
        }
    }
    
    private func getButtonIcon() -> String {
        switch section {
        case .popularUsers: return "plus.circle.fill"
        case .newJoiners: return "hand.wave.fill"
        case .activeUsers: return "message.circle.fill"
        case .topTrainers: return "person.fill"
        }
    }
    
    private func getButtonTitle() -> String {
        switch section {
        case .popularUsers: return "Match"
        case .newJoiners: return "Welcome"
        case .activeUsers: return "Message"
        case .topTrainers: return "Contact"
        }
    }
}

// MARK: - Detail Trainer Card (Updated for SearchTrainer)
struct DetailTrainerCard: View {
    let trainer: SearchTrainer
    @State private var isPressed = false
    
    var body: some View {
        VStack(spacing: 10) {
            ZStack {
                Circle()
                    .fill(Color.gray.opacity(0.12))
                    .frame(width: 80, height: 80) // Increased from 70 to 80
                
                if let imageUrl = trainer.profileImageUrl {
                    AsyncImage(url: URL(string: imageUrl)) { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    } placeholder: {
                        Image(systemName: "person.crop.circle.badge.checkmark.fill")
                            .font(.system(size: 65)) // Increased from 55 to 65
                            .foregroundColor(.gray.opacity(0.5))
                    }
                    .frame(width: 80, height: 80) // Increased from 70 to 80
                    .clipShape(Circle())
                } else {
                    Image(systemName: "person.crop.circle.badge.checkmark.fill")
                        .font(.system(size: 65)) // Increased from 55 to 65
                        .foregroundColor(.gray.opacity(0.5))
                }
                
                // Verified badge - NO STROKE
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        Image(systemName: "checkmark.seal.fill")
                            .font(.system(size: 18)) // Slightly larger for bigger profile image
                            .foregroundColor(.blue)
                            .offset(x: 8, y: 8)
                    }
                }
            }
            
            // Trainer Info - Reduced spacing and heights
            VStack(spacing: 4) {
                Text(trainer.name)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.textPrimary)
                    .lineLimit(1)
                    .frame(height: 16) // Reduced from 18
                
                Text(trainer.specialty)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.purple)
                    .lineLimit(1)
                    .frame(height: 14) // Reduced from 16
                
                Text(trainer.gym)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.textSecondary)
                    .lineLimit(2)
                    .multilineTextAlignment(.center)
                    .frame(height: 24) // Reduced from 28
                
                HStack(spacing: 4) {
                    Image(systemName: "star.fill")
                        .font(.system(size: 12))
                        .foregroundColor(.yellow)
                    
                    Text(trainer.formattedRating)
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.textPrimary)
                    
                    Text("(\(trainer.experience))")
                        .font(.system(size: 10))
                        .foregroundColor(.textSecondary)
                }
                .frame(height: 24) // Reduced from 28
            }
            
            Spacer() // Push buttons to bottom
            
            // Action Buttons - Reduced height
            VStack(spacing: 8) {
                Button(action: {
                    print("View events for \(trainer.name)")
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: "calendar.circle")
                            .font(.system(size: 12))
                        Text("Events")
                            .font(.system(size: 12, weight: .semibold))
                    }
                    .foregroundColor(.purple)
                    .frame(maxWidth: .infinity)
                    .frame(height: 28) // Reduced from 32 to 28
                    .background(Color.clear)
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(Color.purple, lineWidth: 1.5)
                    )
                }
            }
        }
        .frame(maxWidth: .infinity, minHeight: 240, maxHeight: 240) // Reduced from 280 to 240
        .padding(14) // Reduced from 16 to 14
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
        .scaleEffect(isPressed ? 0.98 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isPressed)
        .onTapGesture {
            withAnimation {
                isPressed = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                withAnimation {
                    isPressed = false
                }
            }
        }
    }
}

// MARK: - Shimmer Effect Extension
extension View {
    func shimmer() -> some View {
        self
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .fill(
                        LinearGradient(
                            colors: [Color.clear, Color.white.opacity(0.6), Color.clear],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .rotationEffect(.degrees(30))
                    .offset(x: -250)
                    .animation(
                        Animation.linear(duration: 1.5)
                            .repeatForever(autoreverses: false),
                        value: UUID()
                    )
            )
            .clipped()
    }
}

// MARK: - Preview
#Preview {
    SearchView()
        .environmentObject(LocalizationManager(localizationService: MockLocalizationService()))
}
