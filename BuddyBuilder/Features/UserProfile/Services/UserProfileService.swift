// BuddyBuilder/Features/UserProfile/Services/UserProfileService.swift

import Foundation
import Combine

// MARK: - User Profile Service Protocol
protocol UserProfileServiceProtocol {
    func fetchUserProfile(userId: String) -> AnyPublisher<ProfileDetails, Error>
}

// MARK: - User Profile Service Implementation
class UserProfileService: UserProfileServiceProtocol {
    private let networkManager = NetworkManager.shared
    private let baseURL = "http://192.168.100.76:5206/api/Profile"
    
    // MARK: - Fetch User Profile by ID
    func fetchUserProfile(userId: String) -> AnyPublisher<ProfileDetails, Error> {
        let endpoint = "\(baseURL)/user-profile/\(userId)"
        let headers = getAuthHeaders()
        
        print("🌐 Fetching user profile for ID: \(userId) from: \(endpoint)")
        
        return networkManager.requestWithAutoRefresh(
            endpoint: endpoint,
            method: .GET,
            headers: headers,
            type: ProfileDetailsResponse.self
        )
        .compactMap { response in
            if response.success {
                return response.data
            } else {
                print("❌ User profile fetch failed: \(response.message ?? "Unknown error")")
                return nil
            }
        }
        .handleEvents(
            receiveOutput: { profile in
                print("✅ User profile fetched successfully: \(profile.username)")
            },
            receiveCompletion: { completion in
                if case .failure(let error) = completion {
                    print("❌ Failed to fetch user profile: \(error)")
                    Task { @MainActor in
                        AuthErrorHandler.shared.handleAuthError(error)
                    }
                }
            }
        )
        .eraseToAnyPublisher()
    }
    
    // MARK: - Private Helper Methods
    private func getAuthHeaders() -> [String: String] {
        guard let token = UserDefaults.standard.string(forKey: "auth_token") else {
            print("⚠️ No auth token found")
            return [:]
        }
        
        return [
            "Authorization": "Bearer \(token)",
            "Content-Type": "application/json"
        ]
    }
}

// MARK: - Mock User Profile Service (for testing)
class MockUserProfileService: UserProfileServiceProtocol {
    func fetchUserProfile(userId: String) -> AnyPublisher<ProfileDetails, Error> {
        print("🧪 MOCK: Fetching user profile for ID: \(userId)")
        
        let mockProfile = ProfileDetails(
            userId: userId,
            username: "mockuser\(userId)",
            firstName: "Mock",
            lastName: "User",
            email: "mock.user\(userId)@example.com",
            gender: Int.random(in: 1...2),
            phoneNumber: "+1234567890",
            countryId: 1,
            cityId: 1,
            district: "Mock District",
            bio: "This is a mock user profile for testing purposes. Passionate about sports and fitness!",
            profileImageUrl: "https://via.placeholder.com/150x150/FF6B35/FFFFFF?text=M\(userId)",
            overallExperienceLevel: Int.random(in: 1...4),
            isProfileComplete: true,
            preferredSports: [
                PreferredSportDetails(
                    sportId: 1,
                    sportName: "Basketball",
                    sportIconUrl: nil,
                    experienceLevel: Int.random(in: 1...4),
                    isPreferred: true,
                    notes: "Mock basketball experience"
                ),
                PreferredSportDetails(
                    sportId: 2,
                    sportName: "Tennis",
                    sportIconUrl: nil,
                    experienceLevel: Int.random(in: 1...4),
                    isPreferred: true,
                    notes: "Mock tennis experience"
                )
            ],
            aboutMe: "Mock user with great enthusiasm for sports and connecting with like-minded people!",
            createdAt: "05.08.2025 13:18:49", // Turkish DateTime format
            updatedAt: "20.07.2024 14:45:32", // Turkish DateTime format
            dateOfBirth:"15.05.1995 00:00:00"// Some users have age, some don't
        )
        
        return Just(mockProfile)
            .setFailureType(to: Error.self)
            .delay(for: .seconds(1), scheduler: RunLoop.main)
            .eraseToAnyPublisher()
    }
}
