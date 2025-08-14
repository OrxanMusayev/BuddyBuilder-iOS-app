// BuddyBuilder/Features/UserProfile/Views/UserProfileView.swift - DARK MODE UYUMLU GÜNCELLEMESİ

import SwiftUI
import Combine

struct UserProfileView: View {
    let userId: String
    @StateObject private var viewModel: UserProfileViewModel
    @EnvironmentObject var localizationManager: LocalizationManager
    @Environment(\.dismiss) var dismiss
    
    init(userId: String) {
        self.userId = userId
        self._viewModel = StateObject(wrappedValue: UserProfileViewModel(userId: userId))
    }

    var body: some View {
        NavigationStack {
            ZStack {
                // Background - DARK MODE UYUMLU
                Color.dynamicBackground
                    .ignoresSafeArea(.all)
                
                VStack(spacing: 0) {
                    // Custom Header - DARK MODE UYUMLU
                    customHeader
                    
                    // Content
                    if viewModel.isLoadingProfile && viewModel.profileDetails == nil {
                        loadingView
                    } else if viewModel.profileDetails != nil {
                        profileContentView
                    } else {
                        errorStateView
                    }
                }
            }
        }
        .navigationBarHidden(true)
        .alert("Error", isPresented: $viewModel.showError) {
            Button("OK") { }
        } message: {
            Text(viewModel.errorMessage)
        }
        .sheet(isPresented: $viewModel.showReportOptions) {
            Group {
                if viewModel.isBlocked {
                    UserUnblockActionSheet(
                        userName: viewModel.userDisplayName,
                        onUnblockUser: {
                            viewModel.unblockUser()
                        }
                    )
                } else {
                    UserReportActionSheet(
                        userName: viewModel.userDisplayName,
                        onBlockUser: {
                            viewModel.blockUser()
                        },
                        onReportUser: {
                            viewModel.reportUser()
                        }
                    )
                }
            }
            .environmentObject(localizationManager)
        }
    }
    
    // MARK: - Helper Methods for Formatting
    private func formatSportsCount(_ count: Int) -> String {
        switch count {
        case 0:
            return "user.profile.no_sports".localized(using: localizationManager)
        case 1:
            return "user.profile.one_sport".localized(using: localizationManager)
        default:
            return String(format: "user.profile.multiple_sports".localized(using: localizationManager), count)
        }
    }
    
    // MARK: - Custom Header - DARK MODE UYUMLU
    private var customHeader: some View {
        HStack {
            // Back button
            Button(action: { dismiss() }) {
                Image(systemName: "arrow.left")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.primaryOrange)
                    .frame(width: 44, height: 44)
                    .background(Color.clear)
            }
            
            Spacer()
            
            // Title
            Text("user.profile.title".localized(using: localizationManager))
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .foregroundColor(.primaryText) // DARK MODE UYUMLU
            
            Spacer()
            
            // More options button
            Button(action: {
                viewModel.showReportOptions = true
            }) {
                Image(systemName: "ellipsis")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.secondaryText) // DARK MODE UYUMLU
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .background(Color.cardBackground.opacity(0.95)) // DARK MODE UYUMLU
    }
    
    // MARK: - Loading View - YENİ SKELETON CARD İLE
    private var loadingView: some View {
        VStack(spacing: 20) {
            Spacer()
            
            // Profile skeleton
            UserProfileSkeleton()
                .padding(.horizontal, 20)
            
            Spacer()
        }
        .padding(.top, 20)
    }
    
    // MARK: - Error State View - DARK MODE UYUMLU
    private var errorStateView: some View {
        VStack(spacing: 20) {
            Spacer()
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 50, weight: .light))
                .foregroundColor(.red.opacity(0.6))
            Text("user.profile.error.load_failed".localized(using: localizationManager))
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.primaryText) // DARK MODE UYUMLU
            Button("common.try_again".localized(using: localizationManager)) {
                viewModel.refresh()
            }
            .font(.system(size: 16, weight: .medium))
            .foregroundColor(.primaryOrange)
            .padding(.horizontal, 20)
            .padding(.vertical, 10)
            .background(
                Capsule()
                    .stroke(Color.primaryOrange, lineWidth: 1)
            )
            Spacer()
        }
    }
    
    // MARK: - Profile Content View
    private var profileContentView: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Profile Header Section
                profileHeaderSection
                
                // Profile Stats Section (like ProfileView)
                profileStatsSection
                
                // Action Buttons Section (moved here after stats)
                actionButtonsSection
                
                // User Info Cards
                userInfoCards
                
                // Sports Section
                sportsSection
                
                Spacer(minLength: 100)
            }
            .padding(.horizontal, 20)
            .padding(.top, 20)
        }
        .refreshable {
            viewModel.refresh()
        }
    }
    
    // MARK: - Profile Header Section - SearchView UserCard ile AYNI STIL
    private var profileHeaderSection: some View {
        VStack(spacing: 20) {
            // Profile Image - SearchView UserCard ile birebir aynı
            ZStack {
                SearchAsyncImage(
                    url: viewModel.profileDetails?.profileImageUrl,
                    placeholder: "person.crop.circle.fill"
                )
                .frame(width: 120, height: 120)
                .clipShape(Circle())
                
                // Eğer kullanıcı yeniyse NEW badge (SearchView'daki gibi)
                // Bu kısım isteğe bağlı - profil sayfasında genellikle badge olmaz
            }
            .frame(height: 130) // SearchView'daki UserCard ile aynı frame logic
            
            // User Info
            VStack(spacing: 8) {
                Text(viewModel.userDisplayName)
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundColor(.primaryText) // DARK MODE UYUMLU
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                
                Text("@\(viewModel.profileDetails?.username ?? "")")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(.secondaryText) // DARK MODE UYUMLU
                    .lineLimit(1)
                
                if !viewModel.userBio.isEmpty && viewModel.userBio != "user.profile.no_bio_available" {
                    Text(viewModel.userBio)
                        .font(.system(size: 16))
                        .foregroundColor(.secondaryText) // DARK MODE UYUMLU
                        .multilineTextAlignment(.center)
                        .lineLimit(3)
                        .padding(.horizontal, 20)
                        .padding(.top, 8)
                }
            }
        }
        .padding(.top, 20)
    }
    
    // MARK: - Profile Stats Section (like ProfileView) - DARK MODE UYUMLU
    private var profileStatsSection: some View {
        HStack(spacing: 0) {
            ProfileStatCard(
                title: "user.profile.stats.events".localized(using: localizationManager),
                value: "8",
                icon: "calendar.circle.fill",
                color: .primaryOrange
            )
            
            Divider()
                .frame(height: 50)
                .background(Color.dynamicBorder.opacity(0.3)) // DARK MODE UYUMLU
            
            ProfileStatCard(
                title: "user.profile.stats.matches".localized(using: localizationManager),
                value: "15",
                icon: "person.2.circle.fill",
                color: .primaryOrange
            )
            
            Divider()
                .frame(height: 50)
                .background(Color.dynamicBorder.opacity(0.3)) // DARK MODE UYUMLU
            
            ProfileStatCard(
                title: "user.profile.stats.score".localized(using: localizationManager),
                value: "642",
                icon: "star.circle.fill",
                color: .primaryOrange
            )
        }
        .padding(10)
        .background(Color.cardBackground) // DARK MODE UYUMLU
        .clipShape(RoundedRectangle(cornerRadius: 25))
        .shadow(color: .dynamicShadow, radius: 10, x: 0, y: 4) // DARK MODE UYUMLU
    }
    
    // MARK: - User Info Cards
    private var userInfoCards: some View {
        VStack(spacing: 16) {
            // Basic Info Card
            basicInfoCard
            
            // About Me Card
            if !viewModel.userAboutMe.isEmpty && viewModel.userAboutMe != "No additional information available" {
                aboutMeCard
            }
        }
    }
    
    // MARK: - Basic Info Card - DARK MODE UYUMLU
    private var basicInfoCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            sectionHeader(title: "user.profile.section.basic_info".localized(using: localizationManager), icon: "person.circle")
            
            VStack(spacing: 12) {
                infoRow(icon: "star.circle", title: "user.profile.field.experience".localized(using: localizationManager), value: viewModel.userExperienceLevel.localized(using: localizationManager))
                
                if let gender = viewModel.profileDetails?.genderEnum {
                    infoRow(icon: "person.2.circle", title: "user.profile.field.gender".localized(using: localizationManager), value: gender.displayName.localized(using: localizationManager))
                }
                
                // Show age only if available
                if viewModel.shouldShowAge, let age = viewModel.userAge {
                    infoRow(icon: "calendar.badge.clock", title: "user.profile.field.age".localized(using: localizationManager), value: String(format: "user.profile.age_years".localized(using: localizationManager), age))
                }
                
                infoRow(icon: "location.circle", title: "user.profile.field.location".localized(using: localizationManager), value: viewModel.userLocation.localized(using: localizationManager))
                
                infoRow(icon: "calendar.circle", title: "user.profile.field.joined".localized(using: localizationManager), value: viewModel.joinedDate)
                
                infoRow(icon: "figure.run.circle", title: "user.profile.field.sports".localized(using: localizationManager), value: formatSportsCount(viewModel.userSportsCount))
            }
        }
        .padding(20)
        .background(Color.cardBackground) // DARK MODE UYUMLU
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .shadow(color: .dynamicShadow, radius: 10, x: 0, y: 4) // DARK MODE UYUMLU
    }
    
    // MARK: - About Me Card - DARK MODE UYUMLU
    private var aboutMeCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            sectionHeader(title: "user.profile.section.about_me".localized(using: localizationManager), icon: "text.quote")
            
            Text(viewModel.userAboutMe == "user.profile.no_additional_info" ?
                 "user.profile.no_additional_info".localized(using: localizationManager) :
                 viewModel.userAboutMe)
                .font(.system(size: 16))
                .foregroundColor(.primaryText) // DARK MODE UYUMLU
                .lineLimit(nil)
        }
        .padding(20)
        .background(Color.cardBackground) // DARK MODE UYUMLU
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .shadow(color: .dynamicShadow, radius: 10, x: 0, y: 4) // DARK MODE UYUMLU
    }
    
    // MARK: - Sports Section - DARK MODE UYUMLU
    private var sportsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            sectionHeader(title: "user.profile.section.sports".localized(using: localizationManager), icon: "sportscourt")
            
            if let sports = viewModel.profileDetails?.preferredSports, !sports.isEmpty {
                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: 2), spacing: 12) {
                    ForEach(sports, id: \.sportId) { sport in
                        SportCard(sport: sport)
                    }
                }
            } else {
                Text("user.profile.no_sports".localized(using: localizationManager))
                    .font(.system(size: 16))
                    .foregroundColor(.secondaryText) // DARK MODE UYUMLU
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 20)
            }
        }
        .padding(20)
        .background(Color.cardBackground) // DARK MODE UYUMLU
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .shadow(color: .dynamicShadow, radius: 10, x: 0, y: 4) // DARK MODE UYUMLU
    }
    
    // MARK: - Action Buttons Section
    private var actionButtonsSection: some View {
        VStack(spacing: 12) {
            if viewModel.isBlocked {
                blockedUserMessage
            } else if viewModel.connectionRequestSent {
                connectionRequestSentMessage
            } else if viewModel.isConnected {
                connectedUserButtons
            } else {
                defaultActionButtons
            }
        }
        .padding(.horizontal, 0) // Remove extra padding since it's already in parent
    }
    
    // MARK: - Default Action Buttons
    private var defaultActionButtons: some View {
        HStack(spacing: 12) {
            // Match Button (updated from Connect)
            Button(action: {
                viewModel.sendConnectionRequest()
            }) {
                HStack(spacing: 6) {
                    Image(systemName: "person.badge.plus")
                        .font(.system(size: 14, weight: .medium))
                    Text("user.profile.action.match".localized(using: localizationManager))
                        .font(.system(size: 14, weight: .semibold))
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .background(Color.primaryOrange)
                .clipShape(RoundedRectangle(cornerRadius: 20))
            }
            
            // Message Button
            Button(action: {
                viewModel.sendMessage()
            }) {
                HStack(spacing: 6) {
                    Image(systemName: "message")
                        .font(.system(size: 14, weight: .medium))
                    Text("user.profile.action.message".localized(using: localizationManager))
                        .font(.system(size: 14, weight: .semibold))
                }
                .foregroundColor(.primaryOrange)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .background(Color.clear)
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(Color.primaryOrange, lineWidth: 1.5)
                )
            }
        }
    }
    
    // MARK: - Connected User Buttons
    private var connectedUserButtons: some View {
        HStack(spacing: 12) {
            Button(action: {
                viewModel.sendMessage()
            }) {
                HStack(spacing: 6) {
                    Image(systemName: "message.fill")
                        .font(.system(size: 14, weight: .medium))
                    Text("user.profile.action.message".localized(using: localizationManager))
                        .font(.system(size: 14, weight: .semibold))
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .background(Color.blue)
                .clipShape(RoundedRectangle(cornerRadius: 20))
            }
        }
    }
    
    // MARK: - Connection Request Sent Message
    private var connectionRequestSentMessage: some View {
        VStack(spacing: 8) {
            Image(systemName: "clock")
                .font(.system(size: 24))
                .foregroundColor(.orange)
            
            Text("user.profile.status.match_request_sent".localized(using: localizationManager))
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.primaryText) // DARK MODE UYUMLU
            
            Text("user.profile.status.waiting_response".localized(using: localizationManager))
                .font(.system(size: 14))
                .foregroundColor(.secondaryText) // DARK MODE UYUMLU
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
        .background(Color.orange.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 20))
    }
    
    // MARK: - Blocked User Message
    private var blockedUserMessage: some View {
        VStack(spacing: 8) {
            Image(systemName: "person.slash")
                .font(.system(size: 24))
                .foregroundColor(.red)
            
            Text("user.profile.status.user_blocked".localized(using: localizationManager))
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.primaryText) // DARK MODE UYUMLU
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
        .background(Color.red.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 20))
    }
    
    // MARK: - Helper Views - DARK MODE UYUMLU
    private func sectionHeader(title: String, icon: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 18, weight: .medium))
                .foregroundColor(.primaryOrange)
            
            Text(title)
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(.primaryText) // DARK MODE UYUMLU
            
            Spacer()
        }
    }
    
    private func infoRow(icon: String, title: String, value: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundColor(.primaryOrange)
                .frame(width: 20)
            
            Text(title)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.secondaryText) // DARK MODE UYUMLU
            
            Spacer()
            
            Text(value)
                .font(.system(size: 16))
                .foregroundColor(.primaryText) // DARK MODE UYUMLU
        }
    }
}

// MARK: - YENİ: User Profile Skeleton (EventCard Skeleton Tarzında)
struct UserProfileSkeleton: View {
    @State private var isAnimating = false
    
    var body: some View {
        VStack(spacing: 24) {
            // Profile header skeleton
            VStack(spacing: 20) {
                // Profile image skeleton
                Circle()
                    .fill(Color.gray.opacity(0.2))
                    .frame(width: 120, height: 120)
                    .shimmer(isAnimating: isAnimating)
                
                // Name and username skeleton
                VStack(spacing: 8) {
                    Rectangle()
                        .fill(Color.gray.opacity(0.2))
                        .frame(width: 200, height: 24)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .shimmer(isAnimating: isAnimating)
                    
                    Rectangle()
                        .fill(Color.gray.opacity(0.2))
                        .frame(width: 150, height: 18)
                        .clipShape(RoundedRectangle(cornerRadius: 9))
                        .shimmer(isAnimating: isAnimating)
                    
                    Rectangle()
                        .fill(Color.gray.opacity(0.2))
                        .frame(width: 250, height: 16)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                        .shimmer(isAnimating: isAnimating)
                }
            }
            
            // Stats skeleton
            HStack(spacing: 0) {
                ForEach(0..<3, id: \.self) { index in
                    VStack(spacing: 8) {
                        Circle()
                            .fill(Color.gray.opacity(0.2))
                            .frame(width: 30, height: 30)
                            .shimmer(isAnimating: isAnimating)
                        
                        Rectangle()
                            .fill(Color.gray.opacity(0.2))
                            .frame(width: 40, height: 16)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                            .shimmer(isAnimating: isAnimating)
                        
                        Rectangle()
                            .fill(Color.gray.opacity(0.2))
                            .frame(width: 60, height: 12)
                            .clipShape(RoundedRectangle(cornerRadius: 6))
                            .shimmer(isAnimating: isAnimating)
                    }
                    .frame(maxWidth: .infinity)
                    
                    if index < 2 {
                        Divider()
                            .frame(height: 50)
                            .background(Color.gray.opacity(0.2))
                    }
                }
            }
            .padding(10)
            .background(Color.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: 25))
            .shadow(color: .dynamicShadow, radius: 10, x: 0, y: 4)
            
            // Action buttons skeleton
            HStack(spacing: 12) {
                Rectangle()
                    .fill(Color.gray.opacity(0.2))
                    .frame(height: 44)
                    .clipShape(RoundedRectangle(cornerRadius: 20))
                    .shimmer(isAnimating: isAnimating)
                
                Rectangle()
                    .fill(Color.gray.opacity(0.2))
                    .frame(height: 44)
                    .clipShape(RoundedRectangle(cornerRadius: 20))
                    .shimmer(isAnimating: isAnimating)
            }
            
            // Info cards skeleton
            VStack(spacing: 16) {
                ForEach(0..<2, id: \.self) { _ in
                    VStack(alignment: .leading, spacing: 16) {
                        // Section header skeleton
                        HStack(spacing: 12) {
                            Circle()
                                .fill(Color.gray.opacity(0.2))
                                .frame(width: 18, height: 18)
                                .shimmer(isAnimating: isAnimating)
                            
                            Rectangle()
                                .fill(Color.gray.opacity(0.2))
                                .frame(width: 120, height: 18)
                                .clipShape(RoundedRectangle(cornerRadius: 9))
                                .shimmer(isAnimating: isAnimating)
                            
                            Spacer()
                        }
                        
                        // Content skeleton
                        VStack(spacing: 12) {
                            ForEach(0..<3, id: \.self) { _ in
                                HStack(spacing: 12) {
                                    Circle()
                                        .fill(Color.gray.opacity(0.2))
                                        .frame(width: 16, height: 16)
                                        .shimmer(isAnimating: isAnimating)
                                    
                                    Rectangle()
                                        .fill(Color.gray.opacity(0.2))
                                        .frame(width: 100, height: 16)
                                        .clipShape(RoundedRectangle(cornerRadius: 8))
                                        .shimmer(isAnimating: isAnimating)
                                    
                                    Spacer()
                                    
                                    Rectangle()
                                        .fill(Color.gray.opacity(0.2))
                                        .frame(width: 80, height: 16)
                                        .clipShape(RoundedRectangle(cornerRadius: 8))
                                        .shimmer(isAnimating: isAnimating)
                                }
                            }
                        }
                    }
                    .padding(20)
                    .background(Color.cardBackground)
                    .clipShape(RoundedRectangle(cornerRadius: 20))
                    .shadow(color: .dynamicShadow, radius: 10, x: 0, y: 4)
                }
            }
        }
        .onAppear {
            withAnimation(Animation.easeInOut(duration: 1.0).repeatForever(autoreverses: true)) {
                isAnimating = true
            }
        }
    }
}

// MARK: - User Report Action Sheet Component - DARK MODE UYUMLU
struct UserReportActionSheet: View {
    let userName: String
    let onBlockUser: () -> Void
    let onReportUser: () -> Void
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var localizationManager: LocalizationManager
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            VStack(spacing: 16) {
                // Drag handle
                RoundedRectangle(cornerRadius: 2.5)
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 40, height: 5)
                    .padding(.top, 8)
                
                // Title
                Text(String(format: "user.profile.report.title".localized(using: localizationManager), userName))
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.primaryText) // DARK MODE UYUMLU
                
                Text("user.profile.report.subtitle".localized(using: localizationManager))
                    .font(.system(size: 14))
                    .foregroundColor(.secondaryText) // DARK MODE UYUMLU
            }
            .padding(.bottom, 24)
            
            // Options
            VStack(spacing: 12) {
                // Block User Option
                Button(action: {
                    dismiss()
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        onBlockUser()
                    }
                }) {
                    HStack(spacing: 14) {
                        ZStack {
                            Circle()
                                .fill(Color.red.opacity(0.1))
                                .frame(width: 40, height: 40)
                            
                            Image(systemName: "person.slash.fill")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.red)
                        }
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text("user.profile.report.block_user".localized(using: localizationManager))
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.primaryText) // DARK MODE UYUMLU
                            
                            Text("user.profile.report.block_description".localized(using: localizationManager))
                                .font(.system(size: 12))
                                .foregroundColor(.secondaryText) // DARK MODE UYUMLU
                        }
                        
                        Spacer()
                        
                        Image(systemName: "chevron.right")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.tertiaryText) // DARK MODE UYUMLU
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(Color.formBackground.opacity(0.5)) // DARK MODE UYUMLU
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .buttonStyle(PlainButtonStyle())
                
                // Report User Option
                Button(action: {
                    dismiss()
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        onReportUser()
                    }
                }) {
                    HStack(spacing: 14) {
                        ZStack {
                            Circle()
                                .fill(Color.orange.opacity(0.1))
                                .frame(width: 40, height: 40)
                            
                            Image(systemName: "exclamationmark.triangle.fill")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.orange)
                        }
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text("user.profile.report.report_user".localized(using: localizationManager))
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.primaryText) // DARK MODE UYUMLU
                            
                            Text("user.profile.report.report_description".localized(using: localizationManager))
                                .font(.system(size: 12))
                                .foregroundColor(.secondaryText) // DARK MODE UYUMLU
                        }
                        
                        Spacer()
                        
                        Image(systemName: "chevron.right")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.secondaryText) // DARK MODE UYUMLU
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(Color.formBackground.opacity(0.5)) // DARK MODE UYUMLU
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .buttonStyle(PlainButtonStyle())
            }
            .padding(.horizontal, 20)
            
            // Cancel Button
            Button(action: {
                dismiss()
            }) {
                Text("common.cancel".localized(using: localizationManager))
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.secondaryText) // DARK MODE UYUMLU
                    .frame(maxWidth: .infinity)
                    .frame(height: 44)
                    .background(Color.formBackground) // DARK MODE UYUMLU
                    .clipShape(RoundedRectangle(cornerRadius: 22))
            }
            .padding(.horizontal, 20)
            .padding(.top, 20)
            .padding(.bottom, 20)
        }
        .background(Color.cardBackground) // DARK MODE UYUMLU
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .presentationDetents([.height(280)])
        .presentationDragIndicator(.hidden)
    }
}

// MARK: - User Unblock Action Sheet Component - DARK MODE UYUMLU
struct UserUnblockActionSheet: View {
    let userName: String
    let onUnblockUser: () -> Void
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var localizationManager: LocalizationManager
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            VStack(spacing: 16) {
                // Drag handle
                RoundedRectangle(cornerRadius: 2.5)
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 40, height: 5)
                    .padding(.top, 8)
                
                // Title
                Text("user.profile.report.blocked_title".localized(using: localizationManager))
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.primaryText) // DARK MODE UYUMLU
                
                Text(String(format: "user.profile.report.blocked_subtitle".localized(using: localizationManager), userName))
                    .font(.system(size: 14))
                    .foregroundColor(.secondaryText) // DARK MODE UYUMLU
            }
            .padding(.bottom, 24)
            
            // Unblock Option
            VStack(spacing: 12) {
                Button(action: {
                    dismiss()
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        onUnblockUser()
                    }
                }) {
                    HStack(spacing: 14) {
                        ZStack {
                            Circle()
                                .fill(Color.green.opacity(0.1))
                                .frame(width: 40, height: 40)
                            
                            Image(systemName: "person.fill.checkmark")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.green)
                        }
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text("user.profile.report.unblock_user".localized(using: localizationManager))
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.primaryText) // DARK MODE UYUMLU
                            
                            Text(String(format: "user.profile.report.unblock_description".localized(using: localizationManager), userName))
                                .font(.system(size: 12))
                                .foregroundColor(.secondaryText) // DARK MODE UYUMLU
                        }
                        
                        Spacer()
                        
                        Image(systemName: "chevron.right")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.secondaryText) // DARK MODE UYUMLU
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(Color.formBackground.opacity(0.5)) // DARK MODE UYUMLU
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .buttonStyle(PlainButtonStyle())
            }
            .padding(.horizontal, 20)
            
            // Cancel Button
            Button(action: {
                dismiss()
            }) {
                Text("common.cancel".localized(using: localizationManager))
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.secondaryText) // DARK MODE UYUMLU
                    .frame(maxWidth: .infinity)
                    .frame(height: 44)
                    .background(Color.formBackground) // DARK MODE UYUMLU
                    .clipShape(RoundedRectangle(cornerRadius: 22))
            }
            .padding(.horizontal, 20)
            .padding(.top, 20)
            .padding(.bottom, 20)
        }
        .background(Color.cardBackground) // DARK MODE UYUMLU
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .presentationDetents([.height(200)])
        .presentationDragIndicator(.hidden)
    }
}

// MARK: - Sport Card Component - DARK MODE UYUMLU
struct SportCard: View {
    let sport: PreferredSportDetails
    
    var body: some View {
        VStack(spacing: 8) {
            // Sport icon or placeholder - SearchAsyncImage ile değiştirildi
            if let iconUrl = sport.sportIconUrl, !iconUrl.isEmpty {
                SearchAsyncImage(url: iconUrl, placeholder: "sportscourt.fill")
                    .frame(width: 30, height: 30)
                    .clipShape(RoundedRectangle(cornerRadius: 6))
            } else {
                Image(systemName: "sportscourt.fill")
                    .font(.system(size: 24))
                    .foregroundColor(.primaryOrange)
            }
            
            Text(sport.sportName)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.primaryText) // DARK MODE UYUMLU
                .lineLimit(1)
            
            Text("Level \(sport.experienceLevel)")
                .font(.system(size: 12))
                .foregroundColor(.secondaryText) // DARK MODE UYUMLU
            
            if let notes = sport.notes, !notes.isEmpty {
                Text(notes)
                    .font(.system(size: 10))
                    .foregroundColor(.tertiaryText) // DARK MODE UYUMLU
                    .lineLimit(2)
                    .multilineTextAlignment(.center)
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity, minHeight: 120)
        .background(Color.formBackground) // DARK MODE UYUMLU
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.dynamicBorder, lineWidth: 1) // DARK MODE UYUMLU
        )
    }
}


// MARK: - Preview
#Preview {
    UserProfileView(userId: "3005")
        .environmentObject(LocalizationManager())
}
