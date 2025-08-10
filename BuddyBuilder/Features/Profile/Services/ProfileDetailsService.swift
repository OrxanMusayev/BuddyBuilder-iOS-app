// BuddyBuilder/Features/Profile/Services/ProfileDetailsService.swift

import Foundation
import Combine

// MARK: - Profile Details Service Protocol
protocol ProfileDetailsServiceProtocol {
    func fetchProfileDetails() -> AnyPublisher<ProfileDetails, Error>
    func updateProfile(_ request: ProfileUpdateRequest) -> AnyPublisher<ProfileDetails, Error>
    func fetchProfileDetailsWithAutoRefresh() -> AnyPublisher<ProfileDetails, Error>
    func updateProfileWithAutoRefresh(_ request: ProfileUpdateRequest) -> AnyPublisher<ProfileDetails, Error>
}

// MARK: - Profile Details Service Implementation
class ProfileDetailsService: ProfileDetailsServiceProtocol {
    private let networkManager = NetworkManager.shared
    private let baseURL = "http://192.168.100.76:5206/api/Profile"
    
    // MARK: - Fetch Profile Details (with auto-refresh)
    func fetchProfileDetailsWithAutoRefresh() -> AnyPublisher<ProfileDetails, Error> {
        let headers = getAuthHeaders()
        
        print("🌐 Fetching profile details with auto-refresh from: \(baseURL)")
        
        return networkManager.requestWithAutoRefresh(
            endpoint: baseURL,
            method: .GET,
            headers: headers,
            type: ProfileDetailsResponse.self
        )
        .compactMap { response in
            if response.success {
                return response.data
            } else {
                print("❌ Profile fetch failed: \(response.message ?? "Unknown error")")
                return nil
            }
        }
        .handleEvents(
            receiveOutput: { profile in
                print("✅ Profile details fetched successfully with auto-refresh: \(profile.username)")
            },
            receiveCompletion: { completion in
                if case .failure(let error) = completion {
                    print("❌ Failed to fetch profile details with auto-refresh: \(error)")
                    Task { @MainActor in
                        AuthErrorHandler.shared.handleAuthError(error)
                    }
                }
            }
        )
        .eraseToAnyPublisher()
    }
    
    // MARK: - Update Profile (with auto-refresh)
    func updateProfileWithAutoRefresh(_ request: ProfileUpdateRequest) -> AnyPublisher<ProfileDetails, Error> {
        let headers = getAuthHeaders()
        
        guard let requestBody = try? JSONEncoder().encode(request) else {
            return Fail(error: ProfileDetailsError.invalidData).eraseToAnyPublisher()
        }
        
        print("🌐 Updating profile with auto-refresh")
        print("📤 Request body: \(String(data: requestBody, encoding: .utf8) ?? "nil")")
        
        return networkManager.requestWithAutoRefresh(
            endpoint: baseURL,
            method: .PUT,
            body: requestBody,
            headers: headers,
            type: ProfileUpdateResponse.self
        )
        .compactMap { response in
            if response.success {
                return response.data
            } else {
                print("❌ Profile update failed: \(response.message ?? "Unknown error")")
                return nil
            }
        }
        .handleEvents(
            receiveOutput: { profile in
                print("✅ Profile updated successfully with auto-refresh: \(profile.username)")
            },
            receiveCompletion: { completion in
                if case .failure(let error) = completion {
                    print("❌ Failed to update profile with auto-refresh: \(error)")
                    Task { @MainActor in
                        AuthErrorHandler.shared.handleAuthError(error)
                    }
                }
            }
        )
        .eraseToAnyPublisher()
    }
    
    // MARK: - Original methods (for backward compatibility)
    func fetchProfileDetails() -> AnyPublisher<ProfileDetails, Error> {
        return fetchProfileDetailsWithAutoRefresh()
    }
    
    func updateProfile(_ request: ProfileUpdateRequest) -> AnyPublisher<ProfileDetails, Error> {
        return updateProfileWithAutoRefresh(request)
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

// MARK: - Mock Profile Details Service (for testing)
class MockProfileDetailsService: ProfileDetailsServiceProtocol {
    private var mockProfile: ProfileDetails = ProfileDetails(
        userId: "123",
        username: "johndoe",
        firstName: "John",
        lastName: "Doe",
        email: "john.doe@example.com",
        gender: 1,
        phoneNumber: "+1234567890",
        countryId: 1,
        cityId: 1,
        district: "Downtown",
        bio: "Passionate sports enthusiast who loves playing basketball and tennis. Always looking for new challenges and partners to play with!",
        profileImageUrl: "https://via.placeholder.com/150x150/FF6B35/FFFFFF?text=JD",
        overallExperienceLevel: 3,
        isProfileComplete: true,
        preferredSports: [
            PreferredSportDetails(
                sportId: 1,
                sportName: "Basketball",
                sportIconUrl: nil,
                experienceLevel: 3,
                isPreferred: true,
                notes: "Love playing center position"
            ),
            PreferredSportDetails(
                sportId: 2,
                sportName: "Tennis",
                sportIconUrl: nil,
                experienceLevel: 2,
                isPreferred: true,
                notes: "Weekend player"
            )
        ],
        aboutMe: "I'm a software developer who discovered my passion for sports later in life. Now I can't imagine my routine without regular physical activity!",
        createdAt: "2024-01-15T10:30:00Z",
        updatedAt: "2024-07-20T14:45:00Z",
        dateOfBirth: "2004-07-20T14:45:00Z",
    )
    
    func fetchProfileDetailsWithAutoRefresh() -> AnyPublisher<ProfileDetails, Error> {
        print("🧪 MOCK: Fetching profile details with auto-refresh")
        
        return Just(mockProfile)
            .setFailureType(to: Error.self)
            .delay(for: .seconds(1), scheduler: RunLoop.main)
            .eraseToAnyPublisher()
    }
    
    func updateProfileWithAutoRefresh(_ request: ProfileUpdateRequest) -> AnyPublisher<ProfileDetails, Error> {
        print("🧪 MOCK: Updating profile with auto-refresh")
        print("📤 Update request: firstName=\(request.firstName ?? "nil"), lastName=\(request.lastName ?? "nil")")
        
        // Simulate profile update
        let updatedProfile = ProfileDetails(
            userId: mockProfile.userId,
            username: mockProfile.username,
            firstName: request.firstName ?? mockProfile.firstName,
            lastName: request.lastName ?? mockProfile.lastName,
            email: mockProfile.email,
            gender: request.gender ?? mockProfile.gender,
            phoneNumber: request.phoneNumber ?? mockProfile.phoneNumber,
            countryId: mockProfile.countryId,
            cityId: mockProfile.cityId,
            district: mockProfile.district,
            bio: request.bio ?? mockProfile.bio,
            profileImageUrl: request.profileImageUrl ?? mockProfile.profileImageUrl,
            overallExperienceLevel: request.overallExperienceLevel ?? mockProfile.overallExperienceLevel,
            isProfileComplete: mockProfile.isProfileComplete,
            preferredSports: mockProfile.preferredSports,
            aboutMe: mockProfile.aboutMe,
            createdAt: mockProfile.createdAt,
            updatedAt: ISO8601DateFormatter().string(from: Date()),
            dateOfBirth: "2004-07-20T14:45:00Z"
        )
        
        mockProfile = updatedProfile
        
        return Just(updatedProfile)
            .setFailureType(to: Error.self)
            .delay(for: .seconds(1.5), scheduler: RunLoop.main)
            .eraseToAnyPublisher()
    }
    
    // MARK: - Backward compatibility methods
    func fetchProfileDetails() -> AnyPublisher<ProfileDetails, Error> {
        return fetchProfileDetailsWithAutoRefresh()
    }
    
    func updateProfile(_ request: ProfileUpdateRequest) -> AnyPublisher<ProfileDetails, Error> {
        return updateProfileWithAutoRefresh(request)
    }
}
