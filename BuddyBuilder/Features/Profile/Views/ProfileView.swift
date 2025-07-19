import SwiftUI

// MARK: - Profile View - Modern & Multilingual
struct ProfileView: View {
    @EnvironmentObject var authViewModel: AuthenticationViewModel
    @EnvironmentObject var localizationManager: LocalizationManager
    @Environment(\.presentationMode) var presentationMode
    @State private var showLogoutConfirmation = false
    @State private var showLogoutLoading = false
    
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
                
                // Custom Modern Alert Overlay
                if showLogoutConfirmation {
                    Color.black.opacity(0.4)
                        .ignoresSafeArea()
                        .transition(.opacity)
                        .onTapGesture {
                            withAnimation(.easeInOut(duration: 0.3)) {
                                showLogoutConfirmation = false
                            }
                        }
                    
                    VStack(spacing: 0) {
                        // Header
                        VStack(spacing: 16) {
                            // Icon
                            ZStack {
                                Circle()
                                    .fill(Color.red.opacity(0.1))
                                    .frame(width: 60, height: 60)
                                
                                Image(systemName: "arrow.right.square")
                                    .font(.system(size: 24, weight: .medium))
                                    .foregroundColor(.red)
                            }
                            
                            // Title
                            Text("auth.logout.confirmation.title".localized(using: localizationManager))
                                .font(.system(size: 20, weight: .semibold))
                                .foregroundColor(.primary)
                            
                            // Message
                            Text("auth.logout.confirmation.message".localized(using: localizationManager))
                                .font(.system(size: 16))
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                                .lineLimit(nil)
                        }
                        .padding(.top, 32)
                        .padding(.horizontal, 24)
                        .padding(.bottom, 32)
                        
                        Divider()
                            .background(Color.gray.opacity(0.3))
                        
                        // Buttons
                        HStack(spacing: 0) {
                            // Cancel Button
                            Button(action: {
                                    showLogoutConfirmation = false
                            }) {
                                Text("auth.logout.confirmation.cancel".localized(using: localizationManager))
                                    .font(.system(size: 17, weight: .medium))
                                    .foregroundColor(.blue)
                                    .frame(maxWidth: .infinity, minHeight: 56)
                            }
                            .buttonStyle(PlainButtonStyle())
                            
                            Divider()
                                .background(Color.gray.opacity(0.3))
                                .frame(height: 56)
                            
                            // Confirm Button
                            Button(action: {
                                showLogoutConfirmation = false
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                    withAnimation(.easeInOut(duration: 0.3)) {
                                        showLogoutLoading = true
                                    }
                                    
                                    // 1.5 saniye loading göster, sonra logout yap
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                                        authViewModel.logout()
                                        // Loading'i hemen kapat çünkü ViewModel logout işlemini hallediyor
                                        withAnimation(.easeInOut(duration: 0.3)) {
                                            showLogoutLoading = false
                                        }
                                    }
                                }
                            }) {
                                Text("auth.logout.confirmation.confirm".localized(using: localizationManager))
                                    .font(.system(size: 17, weight: .semibold))
                                    .foregroundColor(.red)
                                    .frame(maxWidth: .infinity, minHeight: 56)
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(.regularMaterial)
                            .shadow(color: .black.opacity(0.15), radius: 20, x: 0, y: 10)
                    )
                    .frame(maxWidth: 320)
                    .padding(.horizontal, 40)
                    .scaleEffect(showLogoutConfirmation ? 1.0 : 0.8)
                    .opacity(showLogoutConfirmation ? 1.0 : 0.0)
                    .transition(.asymmetric(
                        insertion: .scale.combined(with: .opacity),
                        removal: .scale.combined(with: .opacity)
                    ))
                }
                
                // Logout Loading Overlay
                if showLogoutLoading {
                    ZStack {
                        // Beyaz arka plan
                        Color.gray
                            .ignoresSafeArea()
                        
                        // Loading Spinner
                        ZStack {
                            Circle()
                                .stroke(Color.primaryOrange.opacity(0.2), lineWidth: 4)
                                .frame(width: 60, height: 60)
                            
                            Circle()
                                .trim(from: 0, to: 0.7)
                                .stroke(
                                    AngularGradient(
                                        colors: [.primaryOrange, .primaryOrange.opacity(0.1)],
                                        center: .center
                                    ),
                                    style: StrokeStyle(lineWidth: 4, lineCap: .round)
                                )
                                .frame(width: 60, height: 60)
                                .rotationEffect(.degrees(showLogoutLoading ? 360 : 0))
                                .animation(
                                    .linear(duration: 1.0)
                                        .repeatForever(autoreverses: false),
                                    value: showLogoutLoading
                                )
                        }
                    }
                }

            }
            .animation(.easeInOut(duration: 0.3), value: showLogoutConfirmation)
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
                Text(getCurrentUsername())
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundColor(.textPrimary)
                
                Text(getCurrentUserEmail())
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
        
            // Logout butonu
            Button(action: {
                print("isAuthenticated: ", authViewModel.isAuthenticated)
                showLogoutConfirmation = true
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
    
    // MARK: - Helper Methods
    private func getCurrentUsername() -> String {
        if let username = UserDefaults.standard.string(forKey: "username"), !username.isEmpty {
            return username
        }
        return "profile.user.name".localized(using: localizationManager)
    }
    
    private func getCurrentUserEmail() -> String {
        if let email = UserDefaults.standard.string(forKey: "user_email"), !email.isEmpty {
            return email
        }
        return "user@example.com"
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
