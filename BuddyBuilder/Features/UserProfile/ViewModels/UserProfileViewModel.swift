// BuddyBuilder/Features/UserProfile/ViewModels/UserProfileViewModel.swift - SearchAsyncImage UYUMLU GÜNCELLENMİŞ

import SwiftUI
import Combine

// MARK: - User Profile View Model - SearchAsyncImage UYUMLU
class UserProfileViewModel: ObservableObject {
    @Published var profileDetails: ProfileDetails?
    @Published var isLoadingProfile = false
    @Published var errorMessage: String = ""
    @Published var showError = false
    
    // User actions
    @Published var showConnectionOptions = false
    @Published var showReportOptions = false
    @Published var isBlocked = false
    @Published var isConnected = false
    @Published var connectionRequestSent = false
    
    private let userProfileService: UserProfileServiceProtocol
    private var cancellables = Set<AnyCancellable>()
    
    // User ID to fetch
    let userId: Int
    
    init(userId: Int,
         userProfileService: UserProfileServiceProtocol = UserProfileService()) {
        self.userId = userId
        self.userProfileService = userProfileService
        
        loadUserProfile()
    }
    
    // MARK: - Load User Profile - SADECE API VERİSİ, FOTOĞRAF MANUEL YÜKLENMİYOR
    func loadUserProfile() {
        isLoadingProfile = true
        errorMessage = ""
        
        userProfileService.fetchUserProfile(userId: userId)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    self?.isLoadingProfile = false
                    if case .failure(let error) = completion {
                        self?.handleError("Failed to load user profile: \(error.localizedDescription)")
                    }
                },
                receiveValue: { [weak self] profile in
                    self?.profileDetails = profile
                    print("✅ User profile loaded successfully for ID: \(profile.userId)")
                    
                    // YENİ: Profil fotoğrafı SearchAsyncImage tarafından otomatik yüklenecek
                    // Manuel fotoğraf yükleme kaldırıldı
                }
            )
            .store(in: &cancellables)
    }
    
    // MARK: - User Actions
    func sendConnectionRequest() {
        // TODO: Implement connection request API call
        print("🔗 Sending match request to user: \(userId)")
        connectionRequestSent = true
        showConnectionOptions = false
        
        // Mock implementation - replace with actual API call
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            // Simulate success
            print("✅ Match request sent successfully")
        }
    }
    
    func sendMessage() {
        // TODO: Implement messaging functionality
        print("💬 Opening chat with user: \(userId)")
        showConnectionOptions = false
    }
    
    func blockUser() {
        // TODO: Implement block user API call
        print("🚫 Blocking user: \(userId)")
        isBlocked = true
        showReportOptions = false
        
        // Mock implementation - replace with actual API call
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            print("✅ User blocked successfully")
        }
    }
    
    func unblockUser() {
        // TODO: Implement unblock user API call
        print("✅ Unblocking user: \(userId)")
        isBlocked = false
        showReportOptions = false
        
        // Mock implementation - replace with actual API call
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            print("✅ User unblocked successfully")
        }
    }
    
    func reportUser() {
        // TODO: Implement report user API call
        print("⚠️ Reporting user: \(userId)")
        showReportOptions = false
        
        // Mock implementation - replace with actual API call
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            print("✅ User reported successfully")
        }
    }
    
    // MARK: - Computed Properties
    var userDisplayName: String {
        guard let profile = profileDetails else { return "User" }
        
        let firstName = profile.firstName?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let lastName = profile.lastName?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        
        if firstName.isEmpty && lastName.isEmpty {
            return profile.username
        } else if firstName.isEmpty {
            return lastName
        } else if lastName.isEmpty {
            return firstName
        } else {
            return "\(firstName) \(lastName)"
        }
    }
    
    var userBio: String {
        guard let bio = profileDetails?.bio, !bio.isEmpty else {
            return "user.profile.no_bio_available"
        }
        return bio
    }
    
    var userAboutMe: String {
        guard let aboutMe = profileDetails?.aboutMe, !aboutMe.isEmpty else {
            return "user.profile.no_additional_info"
        }
        return aboutMe
    }
    
    var userLocation: String {
        // TODO: You might need to fetch city/country names based on IDs
        // For now, returning a localized placeholder
        return "user.profile.location_not_specified"
    }
    
    var userExperienceLevel: String {
        guard let profile = profileDetails else { return "user.profile.experience_unknown" }
        return profile.overallExperienceLevelEnum?.displayName ?? "user.profile.experience_unknown"
    }
    
    var userSportsCount: Int {
        return profileDetails?.preferredSports?.count ?? 0
    }
    
    var userSportsCountText: String {
        let count = userSportsCount
        if count == 0 {
            return "user.profile.no_sports"
        } else if count == 1 {
            return "user.profile.one_sport"
        } else {
            return "user.profile.multiple_sports" // Will need to format with count
        }
    }
    
    var joinedDate: String {
        guard let profile = profileDetails else {
            print("❌ Profile details is nil")
            return "user.profile.date_unknown"
        }
        
        let createdAtString = profile.createdAt
        print("🔍 Raw createdAt from API: '\(createdAtString)'")
        
        // Try different date formatters - adding Turkish/European format first
        let formatters = [
            createDateFormatter(format: "dd.MM.yyyy HH:mm:ss"), // Turkish format: 05.08.2025 13:18:49
            createDateFormatter(format: "dd.MM.yyyy"),          // Just date part: 05.08.2025
            ISO8601DateFormatter(),
            createDateFormatter(format: "yyyy-MM-dd'T'HH:mm:ss.SSSSSS'Z'"),
            createDateFormatter(format: "yyyy-MM-dd'T'HH:mm:ss'Z'"),
            createDateFormatter(format: "yyyy-MM-dd'T'HH:mm:ss.SSS'Z'"),
            createDateFormatter(format: "yyyy-MM-dd HH:mm:ss"),
            createDateFormatter(format: "yyyy-MM-dd")
        ]
        
        for (index, formatter) in formatters.enumerated() {
            if let formatter = formatter as? DateFormatter {
                if let date = formatter.date(from: createdAtString) {
                    print("✅ Successfully parsed with formatter \(index) (format: \(formatter.dateFormat ?? "unknown")): \(date)")
                    let displayFormatter = DateFormatter()
                    displayFormatter.dateStyle = .medium
                    displayFormatter.locale = Locale.current // Use current locale for display
                    return displayFormatter.string(from: date)
                }
            } else if let isoFormatter = formatter as? ISO8601DateFormatter {
                if let date = isoFormatter.date(from: createdAtString) {
                    print("✅ Successfully parsed with ISO8601 formatter: \(date)")
                    let displayFormatter = DateFormatter()
                    displayFormatter.dateStyle = .medium
                    displayFormatter.locale = Locale.current
                    return displayFormatter.string(from: date)
                }
            }
        }
        
        print("❌ Could not parse createdAt with any formatter")
        
        // If all parsing fails, try to extract just the date part (before space)
        if createdAtString.contains(" ") {
            let datePart = String(createdAtString.split(separator: " ").first ?? "")
            print("🔄 Trying to parse date part only: '\(datePart)'")
            
            let simpleDateFormatter = DateFormatter()
            simpleDateFormatter.dateFormat = "dd.MM.yyyy"
            
            if let date = simpleDateFormatter.date(from: datePart) {
                print("✅ Successfully parsed date part: \(date)")
                let displayFormatter = DateFormatter()
                displayFormatter.dateStyle = .medium
                displayFormatter.locale = Locale.current
                return displayFormatter.string(from: date)
            }
        }
        
        print("❌ All date parsing attempts failed for: '\(createdAtString)'")
        return "user.profile.date_unknown"
    }
    
    private func createDateFormatter(format: String) -> DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = format
        formatter.locale = Locale(identifier: "en_US_POSIX") // Use POSIX locale for parsing
        formatter.timeZone = TimeZone.current // Use current timezone
        return formatter
    }
    
    var userAge: String? {
        guard let profile = profileDetails,
              let dateOfBirth = profile.dateOfBirth,
              !dateOfBirth.isEmpty else {
            print("ℹ️ DateOfBirth is missing or empty")
            return nil // Don't show age if dateOfBirth is missing or empty
        }
        
        print("🔍 Raw dateOfBirth from API: '\(dateOfBirth)'")
        
        // Try different date formatters for dateOfBirth - adding Turkish/European format first
        let formatters = [
            createDateFormatter(format: "dd.MM.yyyy HH:mm:ss"), // Turkish format: 05.08.2025 13:18:49
            createDateFormatter(format: "dd.MM.yyyy"),          // Just date part: 05.08.2025
            ISO8601DateFormatter(),
            createDateFormatter(format: "yyyy-MM-dd'T'HH:mm:ss.SSSSSS'Z'"),
            createDateFormatter(format: "yyyy-MM-dd'T'HH:mm:ss'Z'"),
            createDateFormatter(format: "yyyy-MM-dd'T'HH:mm:ss.SSS'Z'"),
            createDateFormatter(format: "yyyy-MM-dd HH:mm:ss"),
            createDateFormatter(format: "yyyy-MM-dd")
        ]
        
        var birthDate: Date?
        
        for (index, formatter) in formatters.enumerated() {
            if let formatter = formatter as? DateFormatter {
                if let date = formatter.date(from: dateOfBirth) {
                    print("✅ Successfully parsed dateOfBirth with formatter \(index) (format: \(formatter.dateFormat ?? "unknown")): \(date)")
                    birthDate = date
                    break
                }
            } else if let isoFormatter = formatter as? ISO8601DateFormatter {
                if let date = isoFormatter.date(from: dateOfBirth) {
                    print("✅ Successfully parsed dateOfBirth with ISO8601 formatter: \(date)")
                    birthDate = date
                    break
                }
            }
        }
        
        // If parsing fails, try to extract just the date part (before space)
        if birthDate == nil && dateOfBirth.contains(" ") {
            let datePart = String(dateOfBirth.split(separator: " ").first ?? "")
            print("🔄 Trying to parse dateOfBirth date part only: '\(datePart)'")
            
            let simpleDateFormatter = DateFormatter()
            simpleDateFormatter.dateFormat = "dd.MM.yyyy"
            simpleDateFormatter.locale = Locale(identifier: "en_US_POSIX")
            
            if let date = simpleDateFormatter.date(from: datePart) {
                print("✅ Successfully parsed dateOfBirth date part: \(date)")
                birthDate = date
            }
        }
        
        guard let validBirthDate = birthDate else {
            print("❌ Could not parse dateOfBirth: '\(dateOfBirth)'")
            return nil
        }
        
        let calendar = Calendar.current
        let now = Date()
        let ageComponents = calendar.dateComponents([.year], from: validBirthDate, to: now)
        
        guard let age = ageComponents.year, age >= 0 else {
            print("❌ Invalid age calculated from dateOfBirth")
            return nil
        }
        
        print("✅ Calculated age: \(age)")
        return "\(age)"
    }
    
    var shouldShowAge: Bool {
        return userAge != nil
    }
    
    // MARK: - YENİ: Profile Image URL Helper
    var profileImageUrl: String? {
        return profileDetails?.profileImageUrl
    }
    
    // MARK: - Helper Methods
    private func handleError(_ message: String) {
        errorMessage = message
        showError = true
        print("❌ UserProfile Error: \(message)")
    }
    
    func refresh() {
        loadUserProfile()
        // Profil fotoğrafı SearchAsyncImage tarafından otomatik olarak yenilenecek
        // Manuel fotoğraf yükleme kaldırıldı
    }
}
