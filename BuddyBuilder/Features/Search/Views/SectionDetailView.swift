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
                Image(systemName: section.icon)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.gray.opacity(0.8))
                
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
        VStack(spacing: 12) {
            // Profile Image - Standardized
            ZStack {
                Circle()
                    .fill(Color.gray.opacity(0.12))
                    .frame(width: 70, height: 70)
                
                if let imageUrl = user.profileImageUrl {
                    AsyncImage(url: URL(string: imageUrl)) { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    } placeholder: {
                        Image(systemName: "person.crop.circle.fill")
                            .font(.system(size: 90))
                            .foregroundColor(.gray.opacity(0.5))
                    }
                    .frame(width: 90, height: 90)
                    .clipShape(Circle())
                } else {
                    Image(systemName: "person.crop.circle.fill")
                        .font(.system(size: 90))
                        .foregroundColor(.gray.opacity(0.5))
                }
                
                // Status indicators - NO STROKE
                if section == .newJoiners {
                    VStack {
                        HStack {
                            Spacer()
                            Circle()
                                .fill(Color.red)
                                .frame(width: 14, height: 14)
                                .offset(x: 5, y: -5)
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
                                .frame(width: 14, height: 14)
                                .offset(x: 5, y: 5)
                        }
                    }
                }
            }
            
            // User Info - Fixed Heights
            VStack(spacing: 6) {
                Text(user.name)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.textPrimary)
                    .lineLimit(1)
                    .frame(height: 18) // Fixed height
                
                Text("@\(user.username)")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.textSecondary)
                    .lineLimit(1)
                    .frame(height: 16) // Fixed height
                
                Text(user.bio)
                    .font(.system(size: 11))
                    .foregroundColor(.textSecondary)
                    .lineLimit(3)
                    .multilineTextAlignment(.center)
                    .frame(height: 42) // Fixed height for 3 lines
                
                Text(user.location)
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(.gray.opacity(0.8))
                    .lineLimit(1)
                    .frame(height: 14) // Fixed height
            }
            
            Spacer() // Push button to bottom
            
            // Action Button - Fixed Height
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
                .frame(height: 32) // Fixed button height
                .background(Color.clear)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(getButtonColor(), lineWidth: 1.5)
                )
            }
            .scaleEffect(isPressed ? 0.95 : 1.0)
        }
        .frame(maxWidth: .infinity, minHeight: 280, maxHeight: 280) // Fixed card size
        .padding(16)
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
        VStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(Color.gray.opacity(0.12))
                    .frame(width: 90, height: 90)
                
                if let imageUrl = trainer.profileImageUrl {
                    AsyncImage(url: URL(string: imageUrl)) { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    } placeholder: {
                        Image(systemName: "person.crop.circle.badge.checkmark.fill")
                            .font(.system(size: 55))
                            .foregroundColor(.gray.opacity(0.5))
                    }
                    .frame(width: 90, height: 90)
                    .clipShape(Circle())
                } else {
                    Image(systemName: "person.crop.circle.badge.checkmark.fill")
                        .font(.system(size: 55))
                        .foregroundColor(.gray.opacity(0.5))
                }
                
                // Verified badge - NO STROKE
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        Image(systemName: "checkmark.seal.fill")
                            .font(.system(size: 16))
                            .foregroundColor(.blue)
                            .offset(x: 5, y: 5)
                    }
                }
            }
            
            // Trainer Info - Fixed Heights
            VStack(spacing: 6) {
                Text(trainer.name)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.textPrimary)
                    .lineLimit(1)
                    .frame(height: 18) // Fixed height
                
                Text(trainer.specialty)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.purple)
                    .lineLimit(1)
                    .frame(height: 16) // Fixed height
                
                Text(trainer.gym)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.textSecondary)
                    .lineLimit(2)
                    .multilineTextAlignment(.center)
                    .frame(height: 28) // Fixed height for 2 lines
                
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
                .frame(height: 28) // Fixed height
            }
            
            Spacer() // Push buttons to bottom
            
            // Action Buttons - Fixed Heights
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
                    .frame(height: 32) // Fixed button height
                    .background(Color.clear)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color.purple, lineWidth: 1.5)
                    )
                }
            }
        }
        .frame(maxWidth: .infinity, minHeight: 260, maxHeight: 260) // Same as user cards
        .padding(16)
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
