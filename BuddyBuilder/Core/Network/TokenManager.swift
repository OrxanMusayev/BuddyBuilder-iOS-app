// BuddyBuilder/Core/Network/TokenManager.swift

import Foundation
import Combine

// MARK: - Token Refresh Models
struct RefreshTokenRequest: Codable {
    let refreshToken: String
    let accessToken: String?
}

struct RefreshTokenResponse: Codable {
    let success: Bool
    let message: String?
    let data: RefreshTokenData?
    let errors: [String]?
    let timestamp: String
}

struct RefreshTokenData: Codable {
    let accessToken: String
    let refreshToken: String
    let expiresIn: Int
    let tokenType: String
}

// MARK: - Token Manager
class TokenManager: ObservableObject {
    static let shared = TokenManager()
    
    @Published var isRefreshing = false
    private var refreshTask: Task<Void, Never>?
    private let refreshLock = NSLock()
    
    private init() {}
    
    // MARK: - Token Storage
    var accessToken: String? {
        get { UserDefaults.standard.string(forKey: "auth_token") }
        set {
            UserDefaults.standard.set(newValue, forKey: "auth_token")
            print(newValue != nil ? "✅ Access token saved" : "🗑️ Access token cleared")
        }
    }
    
    var refreshToken: String? {
        get { UserDefaults.standard.string(forKey: "refresh_token") }
        set {
            UserDefaults.standard.set(newValue, forKey: "refresh_token")
            print(newValue != nil ? "✅ Refresh token saved" : "🗑️ Refresh token cleared")
        }
    }
    
    // MARK: - Token Refresh
    func refreshTokenIfNeeded() async -> Bool {
        return await withCheckedContinuation { continuation in
            refreshLock.lock()
            defer { refreshLock.unlock() }
            
            // If already refreshing, wait for the existing task
            if let existingTask = refreshTask {
                Task {
                    await existingTask.value
                    continuation.resume(returning: accessToken != nil)
                }
                return
            }
            
            // Start new refresh task
            refreshTask = Task {
                let success = await performTokenRefresh()
                await MainActor.run {
                    self.isRefreshing = false
                    self.refreshTask = nil
                }
                continuation.resume(returning: success)
            }
            
            Task {
                await MainActor.run {
                    self.isRefreshing = true
                }
            }
        }
    }
    
    private func performTokenRefresh() async -> Bool {
        guard let currentRefreshToken = refreshToken else {
            print("❌ No refresh token available")
            await clearAllTokens()
            return false
        }
        
        guard let currentAccessToken = accessToken else {
            print("❌ No Access token available")
            await clearAllTokens()
            return false
        }
        
        print("🔄 Attempting to refresh tokens...")
        
        let request = RefreshTokenRequest(refreshToken: currentRefreshToken, accessToken: currentAccessToken)
        
        do {
            guard let requestData = try? JSONEncoder().encode(request) else {
                throw NetworkError.decodingError
            }
            
            let response: RefreshTokenResponse = try await NetworkManager.shared.performTokenRefresh(
                endpoint: "http://192.168.100.76:5206/api/Auth/refresh-token",
                requestData: requestData
            )
            
            if response.success, let tokenData = response.data {
                // Save new tokens
                accessToken = tokenData.accessToken
                refreshToken = tokenData.refreshToken
                
                print("✅ Tokens refreshed successfully")
                return true
            } else {
                print("❌ Token refresh failed: \(response.message ?? "Unknown error")")
                await clearAllTokens()
                return false
            }
            
        } catch {
            print("❌ Token refresh network error: \(error)")
            await clearAllTokens()
            return false
        }
    }
    
    @MainActor
    private func clearAllTokens() {
        accessToken = nil
        refreshToken = nil
        UserDefaults.standard.removeObject(forKey: "user_id")
        UserDefaults.standard.removeObject(forKey: "username")
        UserDefaults.standard.removeObject(forKey: "user_email")
        print("🧹 All tokens and user data cleared")
    }
}

// MARK: - Authentication Error Handler
class AuthErrorHandler: ObservableObject {
    @Published var showAuthError = false
    @Published var authErrorMessage = ""
    
    static let shared = AuthErrorHandler()
    private init() {}
    
    @MainActor
    func handleAuthError(_ error: Error) {
        if case NetworkError.unauthorized = error {
            authErrorMessage = "Oturumunuzun süresi doldu. Lütfen tekrar giriş yapın."
            showAuthError = true
            
            // Automatically logout user
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                self.performAutoLogout()
            }
        }
    }
    
    @MainActor
    private func performAutoLogout() {
        // Clear all stored data
        TokenManager.shared.accessToken = nil
        TokenManager.shared.refreshToken = nil
        UserDefaults.standard.removeObject(forKey: "user_id")
        UserDefaults.standard.removeObject(forKey: "username")
        UserDefaults.standard.removeObject(forKey: "user_email")
        
        // Post notification for app-wide logout
        NotificationCenter.default.post(name: .authenticationExpired, object: nil)
    }
}

// MARK: - Notification Extension
extension Notification.Name {
    static let authenticationExpired = Notification.Name("authenticationExpired")
}
