import SwiftUI

// MARK: - Profile View - Modern & Multilingual
struct ProfileView: View {
    @StateObject private var authViewModel = AuthenticationViewModel()
    @EnvironmentObject var localizationManager: LocalizationManager
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background
                LoginBackgroundView()
                
                ScrollView {
                    VStack(spacing: 32) {
                        // Profile Header
                        profileHeaderSection
                        
                        // Profile Stats
                        profileStatsSection
                        
                        // Menu Options (including logout)
                        menuSection
                        
                        Spacer(minLength: 40)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                }
            }
        }
    }
    
    // MARK: - Profile Header Section
    private var profileHeaderSection: some View {
        VStack(spacing: 20) {
            // Profile Image
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [.primaryOrange, Color.primaryOrange.opacity(0.7)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 100, height: 100)
                    .shadow(color: .primaryOrange.opacity(0.2), radius: 15, x: 0, y: 8)
                
                Image(systemName: "person.fill")
                    .font(.system(size: 40, weight: .medium))
                    .foregroundColor(.white)
            }
            
            // User Info
            VStack(spacing: 8) {
                Text("profile.user.name".localized(using: localizationManager))
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundColor(.textPrimary)
                
                Text("user@example.com")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(.textSecondary)
            }
        }
        .padding(.top, 20)
    }
    
    // MARK: - Profile Stats Section
    private var profileStatsSection: some View {
        HStack(spacing: 0) {
            ProfileStatCard(
                title: "profile.stats.events".localized(using: localizationManager),
                value: "12",
                icon: "calendar.circle.fill",
                color: .primaryOrange
            )
            
            Divider()
                .frame(height: 50)
                .background(Color.formBorder.opacity(0.3))
            
            ProfileStatCard(
                title: "profile.stats.activities".localized(using: localizationManager),
                value: "28",
                icon: "figure.run.circle.fill",
                color: .primaryOrange
            )
            
            Divider()
                .frame(height: 50)
                .background(Color.formBorder.opacity(0.3))
            
            ProfileStatCard(
                title: "profile.stats.score".localized(using: localizationManager),
                value: "856",
                icon: "star.circle.fill",
                color: .primaryOrange
            )
        }
        .padding(20)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 25))
        .shadow(color: .black.opacity(0.05), radius: 10, x: 0, y: 4)
    }
    
    // MARK: - Menu Section
    private var menuSection: some View {
        VStack(spacing: 0) {
            ProfileMenuRow(
                icon: "person.crop.circle",
                title: "profile.menu.profile".localized(using: localizationManager),
                color: .primaryOrange,
                action: {
                    // TODO: Navigate to profile details
                }
            )
            
            ProfileMenuDivider()
            
            ProfileMenuRow(
                icon: "figure.run.circle",
                title: "profile.menu.my_sports".localized(using: localizationManager),
                color: .primaryOrange,
                action: {
                    // TODO: Navigate to my sports
                }
            )
            
            ProfileMenuDivider()
            
            ProfileMenuRow(
                icon: "trophy.circle",
                title: "profile.menu.achievements".localized(using: localizationManager),
                color: .primaryOrange,
                action: {
                    // TODO: Navigate to achievements
                }
            )
            
            ProfileMenuDivider()
            
            ProfileMenuRow(
                icon: "gearshape.circle",
                title: "profile.menu.settings".localized(using: localizationManager),
                color: .gray,
                action: {
                    // TODO: Show settings submenu (account, language, notifications, theme, privacy)
                }
            )
            
            ProfileMenuDivider()
            
            Button(action: {
                Task {
                    await authViewModel.logout()
                }
            }) {
                HStack(spacing: 16) {
                    if authViewModel.isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .red))
                            .scaleEffect(0.8)
                            .frame(width: 24, height: 24)
                    } else {
                        Image(systemName: "arrow.right.square")
                            .font(.system(size: 20, weight: .medium))
                            .foregroundColor(.red)
                            .frame(width: 24, height: 24)
                    }
                    
                    Text("auth.logout".localized(using: localizationManager))
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.red)
                        .lineLimit(1)
                    
                    Spacer()
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
            }
            .disabled(authViewModel.isLoading)
            .opacity(authViewModel.isLoading ? 0.7 : 1.0)
            .buttonStyle(PlainButtonStyle())
        }
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 25))
        .shadow(color: .black.opacity(0.05), radius: 10, x: 0, y: 4)
    }
}

// MARK: - Profile Stat Card
struct ProfileStatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 24, weight: .medium))
                .foregroundColor(.primaryOrange)
            
            Text(value)
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .foregroundColor(.textPrimary)
            
            Text(title)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.textSecondary)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Profile Menu Row
struct ProfileMenuRow: View {
    let icon: String
    let title: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                Image(systemName: icon)
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(color)
                    .frame(width: 24, height: 24)
                
                Text(title)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.textPrimary)
                    .lineLimit(1)
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.textSecondary)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Profile Menu Divider
struct ProfileMenuDivider: View {
    var body: some View {
        Divider()
            .padding(.leading, 72)
            .background(Color.formBorder.opacity(0.2))
    }
}

// MARK: - Preview
#Preview {
    ProfileView()
        .environmentObject(LocalizationManager(localizationService: MockLocalizationService()))
}
