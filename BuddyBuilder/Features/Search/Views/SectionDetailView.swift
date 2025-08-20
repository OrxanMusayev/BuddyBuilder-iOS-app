// BuddyBuilder/Features/Search/Views/SectionDetailView.swift - FINAL NAVIGATION FIX

import SwiftUI
struct SectionDetailView: View {
    let section: SectionType
    let users: [SearchUser]
    let hasMorePages: Bool
    let isLoading: Bool
    let onDismiss: () -> Void
    let onLoadMore: () -> Void
    let onRefresh: () -> Void  // YENİ: Refresh callback
    let onUserSelected: (String) -> Void
    @EnvironmentObject var localizationManager: LocalizationManager
    @State private var searchText: String = ""
    
    // Filtered data based on search text
    private var filteredUsers: [SearchUser] {
        if searchText.isEmpty {
            return users
        } else {
            return users.filter { user in
                (user.fullName?.localizedCaseInsensitiveContains(searchText) ?? false) ||
                user.username.localizedCaseInsensitiveContains(searchText)
            }
        }
    }
    
    var body: some View {
        ZStack {
            // Background
            Color(.systemGroupedBackground)
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header
                headerView
                
                // Search Bar - Inline
                VStack(spacing: 0) {
                    HStack(spacing: 12) {
                        HStack(spacing: 10) {
                            Image(systemName: "magnifyingglass")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(Color(.systemGray2))
                            
                            TextField("Search in \(section.title.lowercased())...", text: $searchText)
                                .font(.system(size: 16))
                                .foregroundColor(Color(.label))
                                .textInputAutocapitalization(.never)
                                .autocorrectionDisabled()
                            
                            if !searchText.isEmpty {
                                Button(action: { searchText = "" }) {
                                    Image(systemName: "xmark.circle.fill")
                                        .font(.system(size: 16))
                                        .foregroundColor(Color(.systemGray2))
                                }
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .background(Color(.systemGray5))
                        .clipShape(RoundedRectangle(cornerRadius: 25))
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 16)
                    .background(Color(.systemBackground))
                }
                
                // Content
                ScrollView {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 16), count: 2), spacing: 16) {
                        if isLoading && users.isEmpty {
                            // Show skeleton cards while loading
                            ForEach(0..<6, id: \.self) { _ in
                                SkeletonDetailUserCard()
                            }
                        } else {
                            ForEach(filteredUsers) { user in
                                DetailUserCard(
                                    user: user,
                                    section: section,
                                    onCardTap: {
                                        onUserSelected(user.id)
                                    }
                                )
                            }
                            
                            // No results message
                            if !searchText.isEmpty && filteredUsers.isEmpty && !isLoading {
                                VStack(spacing: 16) {
                                    Image(systemName: "magnifyingglass")
                                        .font(.system(size: 40, weight: .light))
                                        .foregroundColor(.gray)
                                    
                                    Text("No results found for '\(searchText)'")
                                        .font(.system(size: 16, weight: .medium))
                                        .foregroundColor(.gray)
                                        .multilineTextAlignment(.center)
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.top, 60)
                            }
                            
                            // Load more indicator
                            if hasMorePages && searchText.isEmpty {
                                loadMoreSection
                                    .onAppear {
                                        onLoadMore()
                                    }
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                    .padding(.bottom, 100)
                }
                .refreshable {
                    // YENİ: Pull-to-refresh özelliği
                    onRefresh()
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
            
            Text(section.title)
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.primary)
            
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
                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 16), count: 2), spacing: 16) {
                    ForEach(0..<4, id: \.self) { _ in
                        SkeletonDetailUserCard()
                    }
                }
            }
        }
        .frame(maxWidth: .infinity)
        .gridCellColumns(2)
    }
}

// MARK: - Detail User Card - UPDATED WITH DELEGATION
struct DetailUserCard: View {
    let user: SearchUser
    let section: SectionType
    let onCardTap: () -> Void // Delegate to parent
    @State private var isPressed = false
    
    var body: some View {
        VStack(spacing: 12) {
            // Profile Image - Same as SearchView UserCard
            ZStack {
                SearchAsyncImage(
                    url: user.profileImageUrl,
                    placeholder: "person.crop.circle.fill"
                )
                .frame(width: 90, height: 90)
                .clipShape(Circle())
                
                // Status indicators - REMOVED RED DOT
                if section == .activeUsers && user.isOnline {
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
                    .foregroundColor(.primaryOrange)
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
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .frame(height: 32) // Fixed button height
                .background(Color.clear)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(getButtonColor(), lineWidth: 1.5)
                )
            }
            .scaleEffect(isPressed ? 0.95 : 1.0)
        }
        .frame(maxWidth: .infinity, minHeight: 260, maxHeight: 260) // Reduced card height
        .padding(16)
        .background(Color.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(
                    Color(.systemGray4),
                    lineWidth: 1
                )
        )
        .shadow(
            color: Color.black.opacity(isPressed ? 0.05 : 0.08),
            radius: isPressed ? 8 : 10,
            x: 0,
            y: isPressed ? 3 : 5
        )
        .scaleEffect(isPressed ? 0.98 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isPressed)
        .onTapGesture {
            // NAVIGATION: Delegate to parent
            onCardTap()
        }
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in
                    withAnimation {
                        isPressed = true
                    }
                }
                .onEnded { _ in
                    withAnimation {
                        isPressed = false
                    }
                }
        )
    }
    
    private func getButtonColor() -> Color {
        switch section {
        case .popularUsers: return Color.primaryOrange
        case .newJoiners: return Color.primaryOrange
        case .activeUsers: return Color.blue
        }
    }
    
    private func getButtonIcon() -> String {
        switch section {
        case .popularUsers: return "plus.circle.fill"
        case .newJoiners: return "plus.circle.fill"
        case .activeUsers: return "message.circle.fill"
        }
    }
    
    private func getButtonTitle() -> String {
        switch section {
        case .popularUsers: return "Match"
        case .newJoiners: return "Match"
        case .activeUsers: return "Message"
        }
    }
}

// MARK: - Skeleton Detail User Card
struct SkeletonDetailUserCard: View {
    @State private var isAnimating = false
    
    var body: some View {
        VStack(spacing: 16) {
            // Profile Image Skeleton
            Circle()
                .fill(Color.gray.opacity(0.3))
                .frame(width: 90, height: 90)
                .shimmer(isAnimating: isAnimating)
                .clipShape(Circle())
            
            // User Info Skeleton
            VStack(spacing: 8) {
                // Name skeleton
                Rectangle()
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 80, height: 16)
                    .clipShape(RoundedRectangle(cornerRadius: 4))
                    .shimmer(isAnimating: isAnimating)
                
                // Username skeleton
                Rectangle()
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 60, height: 12)
                    .clipShape(RoundedRectangle(cornerRadius: 4))
                    .shimmer(isAnimating: isAnimating)
                
                // Bio skeleton (3 lines)
                VStack(spacing: 4) {
                    Rectangle()
                        .fill(Color.gray.opacity(0.3))
                        .frame(width: 100, height: 10)
                        .clipShape(RoundedRectangle(cornerRadius: 4))
                        .shimmer(isAnimating: isAnimating)
                    
                    Rectangle()
                        .fill(Color.gray.opacity(0.3))
                        .frame(width: 80, height: 10)
                        .clipShape(RoundedRectangle(cornerRadius: 4))
                        .shimmer(isAnimating: isAnimating)
                    
                    Rectangle()
                        .fill(Color.gray.opacity(0.3))
                        .frame(width: 60, height: 10)
                        .clipShape(RoundedRectangle(cornerRadius: 4))
                        .shimmer(isAnimating: isAnimating)
                }
                
                // Location skeleton
                Rectangle()
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 50, height: 10)
                    .clipShape(RoundedRectangle(cornerRadius: 4))
                    .shimmer(isAnimating: isAnimating)
            }
            
            Spacer()
            
            // Button skeleton
            Capsule()
                .fill(Color.gray.opacity(0.3))
                .frame(width: 80, height: 28)
                .shimmer(isAnimating: isAnimating)
        }
        .frame(maxWidth: .infinity, minHeight: 260, maxHeight: 260)
        .padding(16)
        .background(Color.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(
                    Color(.systemGray4),
                    lineWidth: 1
                )
        )
        .shadow(
            color: Color.black.opacity(0.08),
            radius: 10,
            x: 0,
            y: 5
        )
        .onAppear {
            withAnimation(Animation.easeInOut(duration: 1.0).repeatForever(autoreverses: true)) {
                isAnimating = true
            }
        }
    }
}
