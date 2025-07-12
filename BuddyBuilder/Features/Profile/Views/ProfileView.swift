import SwiftUI

// MARK: - Profile View - Simplified
struct ProfileView: View {
    @StateObject private var authViewModel = AuthenticationViewModel()
    @Environment(\.presentationMode) var presentationMode
    @State private var showEditProfile = false
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background
                LinearGradient(
                    colors: [
                        Color.blue.opacity(0.1),
                        Color.gray.opacity(0.05)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea(.all)
                
                ScrollView {
                    VStack(spacing: 32) {
                        // Profile Header
                        profileHeaderSection
                        
                        // Profile Stats
                        profileStatsSection
                        
                        // Settings Options
                        settingsSection
                        
                        // Logout Section
                        logoutSection
                        
                        Spacer(minLength: 40)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                }
            }
            .navigationTitle("")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Kapat") {
                        presentationMode.wrappedValue.dismiss()
                    }
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.orange)
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Düzenle") {
                        showEditProfile = true
                    }
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.orange)
                }
            }
        }
        .sheet(isPresented: $showEditProfile) {
            EditProfileView()
        }
    }
    
    // MARK: - Profile Header Section
    private var profileHeaderSection: some View {
        VStack(spacing: 20) {
            // Profile Image
            Button(action: {
                // TODO: Change profile image
            }) {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [.orange, Color.orange.opacity(0.7)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 120, height: 120)
                        .shadow(color: .orange.opacity(0.3), radius: 20, x: 0, y: 10)
                    
                    Image(systemName: "person.fill")
                        .font(.system(size: 50, weight: .medium))
                        .foregroundColor(.white)
                    
                    // Edit overlay
                    VStack {
                        Spacer()
                        HStack {
                            Spacer()
                            ZStack {
                                Circle()
                                    .fill(.white)
                                    .frame(width: 36, height: 36)
                                    .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
                                
                                Image(systemName: "camera.fill")
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(.orange)
                            }
                        }
                    }
                    .frame(width: 120, height: 120)
                }
            }
            
            // User Info
            VStack(spacing: 8) {
                Text("Kullanıcı Adı") // TODO: Get from user data
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundColor(.primary)
                
                Text("user@example.com") // TODO: Get from user data
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.secondary)
            }
        }
        .padding(.top, 20)
    }
    
    // MARK: - Profile Stats Section
    private var profileStatsSection: some View {
        HStack(spacing: 0) {
            SimpleStatCard(title: "Partnerlık", value: "12", icon: "person.2", color: .blue)
            
            Divider()
                .frame(height: 60)
                .background(Color.gray.opacity(0.2))
            
            SimpleStatCard(title: "Aktivite", value: "28", icon: "figure.walk", color: .green)
            
            Divider()
                .frame(height: 60)
                .background(Color.gray.opacity(0.2))
            
            SimpleStatCard(title: "Puan", value: "856", icon: "star.fill", color: .orange)
        }
        .padding(24)
        .background(Color.white)
        .cornerRadius(20)
        .shadow(color: .black.opacity(0.06), radius: 12, x: 0, y: 4)
    }
    
    // MARK: - Settings Section
    private var settingsSection: some View {
        VStack(spacing: 20) {
            HStack {
                Text("Ayarlar")
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                    .foregroundColor(.primary)
                
                Spacer()
            }
            
            VStack(spacing: 0) {
                SimpleSettingRow(
                    icon: "person.circle.fill",
                    title: "Kişisel Bilgiler",
                    color: .orange,
                    action: {
                        showEditProfile = true
                    }
                )
                
                Divider()
                    .padding(.leading, 60)
                    .background(Color.gray.opacity(0.1))
                
                SimpleSettingRow(
                    icon: "bell.fill",
                    title: "Bildirimler",
                    color: .blue,
                    action: {
                        // TODO: Navigate to notifications settings
                    }
                )
                
                Divider()
                    .padding(.leading, 60)
                    .background(Color.gray.opacity(0.1))
                
                SimpleSettingRow(
                    icon: "lock.fill",
                    title: "Gizlilik",
                    color: .green,
                    action: {
                        // TODO: Navigate to privacy settings
                    }
                )
                
                Divider()
                    .padding(.leading, 60)
                    .background(Color.gray.opacity(0.1))
                
                SimpleSettingRow(
                    icon: "questionmark.circle.fill",
                    title: "Yardım",
                    color: .purple,
                    action: {
                        // TODO: Navigate to help
                    }
                )
            }
            .background(Color.white)
            .cornerRadius(20)
            .shadow(color: .black.opacity(0.06), radius: 12, x: 0, y: 4)
        }
    }
    
    // MARK: - Logout Section
    private var logoutSection: some View {
        Button(action: {
            Task {
                await authViewModel.logout()
            }
        }) {
            HStack(spacing: 12) {
                if authViewModel.isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .scaleEffect(0.8)
                }
                
                Text("Çıkış Yap")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                LinearGradient(
                    colors: [.red, Color.red.opacity(0.8)],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .cornerRadius(20)
            .shadow(color: .red.opacity(0.3), radius: 8, x: 0, y: 4)
        }
        .disabled(authViewModel.isLoading)
        .opacity(authViewModel.isLoading ? 0.8 : 1.0)
    }
}

// MARK: - Simple Stat Card
struct SimpleStatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(color.opacity(0.1))
                    .frame(width: 48, height: 48)
                
                Image(systemName: icon)
                    .font(.system(size: 22, weight: .medium))
                    .foregroundColor(color)
            }
            
            Text(value)
                .font(.system(size: 24, weight: .bold, design: .rounded))
                .foregroundColor(.primary)
            
            Text(title)
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Simple Setting Row
struct SimpleSettingRow: View {
    let icon: String
    let title: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(color.opacity(0.1))
                        .frame(width: 40, height: 40)
                    
                    Image(systemName: icon)
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(color)
                }
                
                Text(title)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.primary)
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.gray)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Edit Profile View (Simplified)
struct EditProfileView: View {
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        NavigationView {
            ZStack {
                LinearGradient(
                    colors: [
                        Color.blue.opacity(0.1),
                        Color.gray.opacity(0.05)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea(.all)
                
                VStack(spacing: 40) {
                    Spacer()
                    
                    Image(systemName: "person.crop.circle.badge.plus")
                        .font(.system(size: 80))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.orange, Color.orange.opacity(0.7)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                    
                    VStack(spacing: 16) {
                        Text("Profil Düzenleme")
                            .font(.system(size: 28, weight: .bold, design: .rounded))
                            .foregroundColor(.primary)
                        
                        Text("Bu özellik yakında eklenecek...")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    
                    Spacer()
                }
                .padding(32)
            }
            .navigationTitle("")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("İptal") {
                        presentationMode.wrappedValue.dismiss()
                    }
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.orange)
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Kaydet") {
                        presentationMode.wrappedValue.dismiss()
                    }
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.orange)
                }
            }
        }
    }
}

// MARK: - Preview
#Preview {
    ProfileView()
}
