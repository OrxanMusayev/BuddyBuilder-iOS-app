// BuddyBuilder/Features/Profile/Views/ProfileView.swift

import SwiftUI
import PhotosUI
import Combine
// ProfileView.swift dosyasında sadece ProfileViewModel class'ını değiştirin:

// ProfileView.swift dosyasında sadece ProfileViewModel class'ını değiştirin:

// MARK: - Profile View Model - SIMPLIFIED
class ProfileViewModel: ObservableObject {
    @Published var profilePhotoURL: String?
    @Published var isLoadingPhoto = false
    @Published var showImagePicker = false
    @Published var showCamera = false
    @Published var showPhotoOptions = false
    @Published var errorMessage: String = ""
    @Published var showError = false
    
    private let profilePhotoService: ProfilePhotoServiceProtocol
    private var cancellables = Set<AnyCancellable>()
    
    init(profilePhotoService: ProfilePhotoServiceProtocol = ProfilePhotoService()) {
        self.profilePhotoService = profilePhotoService
        loadProfilePhoto()
    }
    
    // 🔴 SIMPLIFIED: Direct protocol methods (already have auto-refresh)
    func loadProfilePhoto() {
        isLoadingPhoto = true
        
        profilePhotoService.fetchProfilePhotoURL()
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    self?.isLoadingPhoto = false
                    if case .failure(let error) = completion {
                        print("❌ Failed to load profile photo: \(error)")
                    }
                },
                receiveValue: { [weak self] url in
                    self?.profilePhotoURL = url
                }
            )
            .store(in: &cancellables)
    }
    
    // 🔴 SIMPLIFIED: Direct protocol methods
    func uploadProfilePhoto(_ imageData: Data) {
        isLoadingPhoto = true
        
        let publisher = profilePhotoURL == nil ?
            profilePhotoService.uploadProfilePhoto(imageData) :
            profilePhotoService.updateProfilePhoto(imageData)
        
        publisher
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    self?.isLoadingPhoto = false
                    if case .failure(let error) = completion {
                        self?.handleError("Failed to upload photo: \(error.localizedDescription)")
                    }
                },
                receiveValue: { [weak self] url in
                    self?.profilePhotoURL = url
                    print("✅ Profile photo updated successfully")
                }
            )
            .store(in: &cancellables)
    }
    
    // 🔴 SIMPLIFIED: Direct protocol method
    func deleteProfilePhoto() {
        isLoadingPhoto = true
        
        profilePhotoService.deleteProfilePhoto()
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    self?.isLoadingPhoto = false
                    if case .failure(let error) = completion {
                        self?.handleError("Failed to delete photo: \(error.localizedDescription)")
                    }
                },
                receiveValue: { [weak self] success in
                    if success {
                        self?.profilePhotoURL = nil
                        print("✅ Profile photo deleted successfully")
                    }
                }
            )
            .store(in: &cancellables)
    }
    
    private func handleError(_ message: String) {
        errorMessage = message
        showError = true
    }
}

// ProfileView'in geri kalanı aynı kalacak, sadece ProfileViewModel değişti



// MARK: - Profile View - Modern & Multilingual with Photo Integration
struct ProfileView: View {
    @EnvironmentObject var authViewModel: AuthenticationViewModel
    @EnvironmentObject var localizationManager: LocalizationManager
    @StateObject private var profileViewModel = ProfileViewModel()
    @Environment(\.presentationMode) var presentationMode
    @State private var showLogoutConfirmation = false
    @State private var showLogoutLoading = false
    @State private var selectedPhoto: PhotosPickerItem?
    @State private var navigateToMySports = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Background
                LoginBackgroundView()
                
                ScrollView {
                    VStack(spacing: 32) {
                        // Profile Header with Photo
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
                
                // Overlays (logout, error, etc.)
                if showLogoutConfirmation {
                    logoutConfirmationOverlay
                }
                
                if showLogoutLoading {
                    logoutLoadingOverlay
                }
            }
            .navigationDestination(isPresented: $navigateToMySports) {
                MySportsView()
                    .environmentObject(localizationManager)
            }
        }
        .photosPicker(isPresented: $profileViewModel.showImagePicker, selection: $selectedPhoto, matching: .images)
        .sheet(isPresented: $profileViewModel.showPhotoOptions) {
            CustomPhotoSelectionSheet(
                hasExistingPhoto: profileViewModel.profilePhotoURL != nil,
                onTakePhoto: {
                    profileViewModel.showPhotoOptions = false
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        profileViewModel.showCamera = true
                    }
                },
                onChooseLibrary: {
                    profileViewModel.showPhotoOptions = false
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        profileViewModel.showImagePicker = true
                    }
                },
                onDeletePhoto: {
                    profileViewModel.showPhotoOptions = false
                    profileViewModel.deleteProfilePhoto()
                }
            )
        }
        .fullScreenCover(isPresented: $profileViewModel.showCamera) {
            CameraView { imageData in
                profileViewModel.uploadProfilePhoto(imageData)
            }
        }
        .onChange(of: selectedPhoto) { newPhoto in
            if let newPhoto = newPhoto {
                Task {
                    if let data = try? await newPhoto.loadTransferable(type: Data.self) {
                        await MainActor.run {
                            profileViewModel.uploadProfilePhoto(data)
                        }
                    }
                }
            }
        }
        .alert("Error", isPresented: $profileViewModel.showError) {
            Button("OK") { }
        } message: {
            Text(profileViewModel.errorMessage)
        }
    }
    
    // MARK: - Profile Header Section with Photo
    private var profileHeaderSection: some View {
        VStack(spacing: 20) {
            // Profile Image with Upload Functionality
            Button(action: {
                profileViewModel.showPhotoOptions = true
            }) {
                ZStack {
                    if profileViewModel.isLoadingPhoto {
                        // Loading state
                        Circle()
                            .fill(Color.gray.opacity(0.1))
                            .frame(width: 100, height: 100)
                            .overlay(
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .primaryOrange))
                            )
                    } else if let photoURL = profileViewModel.profilePhotoURL, !photoURL.isEmpty {
                        // Profile photo from API
                        AsyncImage(url: URL(string: photoURL)) { image in
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                        } placeholder: {
                            Circle()
                                .fill(Color.gray.opacity(0.1))
                                .overlay(
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: .primaryOrange))
                                )
                        }
                        .frame(width: 100, height: 100)
                        .clipShape(Circle())
                        
                        // Camera edit icon for existing photo
                        Circle()
                            .fill(Color.white)
                            .frame(width: 32, height: 32)
                            .overlay(
                                Image(systemName: "pencil")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(.primaryOrange)
                            )
                            .offset(x: 35, y: 35)
                            .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
                    } else {
                        // Modern default profile icon - SUBTLE & SOFT
                        ZStack {
                            // Soft background circle
                            Circle()
                                .fill(
                                    LinearGradient(
                                        colors: [
                                            Color.gray.opacity(0.08),
                                            Color.gray.opacity(0.12)
                                        ],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 100, height: 100)
                            
                            // Subtle border
                            Circle()
                                .stroke(
                                    Color.gray.opacity(0.15),
                                    lineWidth: 1
                                )
                                .frame(width: 100, height: 100)
                            
                            // Modern person icon - very subtle
                            Image(systemName: "person.crop.circle")
                                .font(.system(size: 45, weight: .ultraLight))
                                .foregroundColor(.gray.opacity(0.3))
                        }
                        
                        // Add photo icon
                        Circle()
                            .fill(Color.primaryOrange)
                            .frame(width: 32, height: 32)
                            .overlay(
                                Image(systemName: "plus")
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(.white)
                            )
                            .offset(x: 35, y: 35)
                            .shadow(color: .primaryOrange.opacity(0.3), radius: 6, x: 0, y: 3)
                    }
                }
                .shadow(color: .black.opacity(0.05), radius: 10, x: 0, y: 5)
            }
            .disabled(profileViewModel.isLoadingPhoto)
            
            // User Info
            VStack(spacing: 8) {
                Text(getCurrentUsername())
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundColor(.textPrimary)
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
                    navigateToMySports = true
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
                    // TODO: Show settings submenu
                }
            )
            
            ProfileMenuDivider()
        
            // Logout butonu
            Button(action: {
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
    
    // MARK: - Logout Confirmation Overlay
    private var logoutConfirmationOverlay: some View {
        Color.black.opacity(0.4)
            .ignoresSafeArea()
            .transition(.opacity)
            .onTapGesture {
                withAnimation(.easeInOut(duration: 0.3)) {
                    showLogoutConfirmation = false
                }
            }
            .overlay(
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
                                
                                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                                    authViewModel.logout()
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
            )
    }
    
    // MARK: - Logout Loading Overlay
    private var logoutLoadingOverlay: some View {
        ZStack {
            Color.gray
                .ignoresSafeArea()
            
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
    
    // MARK: - Helper Methods
    private func getCurrentUsername() -> String {
        if let username = UserDefaults.standard.string(forKey: "username"), !username.isEmpty {
            return username
        }
        return "profile.user.name".localized(using: localizationManager)
    }
}

// MARK: - Custom Photo Selection Sheet
struct CustomPhotoSelectionSheet: View {
    let hasExistingPhoto: Bool
    let onTakePhoto: () -> Void
    let onChooseLibrary: () -> Void
    let onDeletePhoto: () -> Void
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        VStack(spacing: 0) {
            // Compact Header
            VStack(spacing: 12) {
                // Drag handle
                RoundedRectangle(cornerRadius: 2.5)
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 40, height: 5)
                    .padding(.top, 8)
                
                // Title only
                Text("Profile Photo")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.textPrimary)
            }
            .padding(.bottom, 20)
            
            // Compact Options
            VStack(spacing: 12) {
                // Take Photo Option
                CompactPhotoOptionButton(
                    icon: "camera.fill",
                    title: "Take Photo",
                    color: .primaryOrange,
                    action: onTakePhoto
                )
                
                // Photo Library Option
                CompactPhotoOptionButton(
                    icon: "photo.fill",
                    title: "Photo Library",
                    color: .blue,
                    action: onChooseLibrary
                )
                
                // Delete Option (only if photo exists)
                if hasExistingPhoto {
                    CompactPhotoOptionButton(
                        icon: "trash.fill",
                        title: "Remove Photo",
                        color: .red,
                        action: onDeletePhoto
                    )
                }
            }
            .padding(.horizontal, 20)
            
            // Compact Cancel Button
            Button(action: {
                dismiss()
            }) {
                Text("Cancel")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(.textSecondary)
                    .frame(maxWidth: .infinity)
                    .frame(height: 44)
                    .background(Color.formBackground)
                    .clipShape(RoundedRectangle(cornerRadius: 22))
            }
            .padding(.horizontal, 20)
            .padding(.top, 16)
            .padding(.bottom, 20)
        }
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .presentationDetents([.height(hasExistingPhoto ? 280 : 240)])
        .presentationDragIndicator(.hidden)
    }
}

// MARK: - Compact Photo Option Button
struct CompactPhotoOptionButton: View {
    let icon: String
    let title: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 14) {
                // Compact icon background
                ZStack {
                    Circle()
                        .fill(color.opacity(0.1))
                        .frame(width: 40, height: 40)
                    
                    Image(systemName: icon)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(color)
                }
                
                // Title only
                Text(title)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.textPrimary)
                
                Spacer()
                
                // Small arrow
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.textSecondary)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(Color.formBackground.opacity(0.5))
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Camera View (Simple Implementation)
struct CameraView: View {
    let onImageCaptured: (Data) -> Void
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            VStack {
                HStack {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(.white)
                    .padding()
                    
                    Spacer()
                }
                
                Spacer()
                
                Text("Camera functionality would be implemented here")
                    .foregroundColor(.white)
                    .font(.headline)
                
                Spacer()
                
                Button("Capture") {
                    // Mock capture - in real implementation, this would capture from camera
                    if let mockImageData = UIImage(systemName: "person.circle.fill")?.jpegData(compressionQuality: 0.8) {
                        onImageCaptured(mockImageData)
                    }
                    dismiss()
                }
                .foregroundColor(.white)
                .font(.headline)
                .padding()
            }
        }
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
