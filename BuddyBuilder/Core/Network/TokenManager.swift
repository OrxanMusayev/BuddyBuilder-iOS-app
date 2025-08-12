// BuddyBuilder/Core/Network/TokenManager.swift - TOKEN KAYDETME DÜZELTMESİ

import Foundation
import Combine

// MARK: - Token Refresh Models
struct RefreshTokenRequest: Codable {
    let refreshToken: String
    let accessToken: String?
}

struct RefreshTokenResponse: Codable {
    let isSuccess: Bool
    let data: RefreshTokenData?
    let errorMessage: String?
    let validationErrors: [String]?
}

struct RefreshTokenData: Codable {
    let accessToken: String
    let refreshToken: String
}

// MARK: - Token Manager
class TokenManager: ObservableObject {
    static let shared = TokenManager()
    
    @Published var isRefreshing = false
    private var refreshTask: Task<Bool, Never>?
    private let refreshLock = NSLock()
    
    private init() {}
    
    // MARK: - DÜZELTME: Token Storage with immediate save
    var accessToken: String? {
        get {
            let token = UserDefaults.standard.string(forKey: "auth_token")
            return token
        }
        set {
            // DÜZELTME: Hemen kaydet ve senkronize et
            UserDefaults.standard.set(newValue, forKey: "auth_token")
            UserDefaults.standard.synchronize() // Force immediate save
            print("💾 Access token updated and synchronized: \(newValue?.prefix(20) ?? "nil")...")
        }
    }
    
    var refreshToken: String? {
        get {
            let token = UserDefaults.standard.string(forKey: "refresh_token")
            return token
        }
        set {
            // DÜZELTME: Hemen kaydet ve senkronize et
            UserDefaults.standard.set(newValue, forKey: "refresh_token")
            UserDefaults.standard.synchronize() // Force immediate save
            print("💾 Refresh token updated and synchronized: \(newValue?.prefix(20) ?? "nil")...")
        }
    }
    
    // MARK: - Token Refresh
    func refreshTokenIfNeeded() async -> Bool {
        return await withCheckedContinuation { continuation in
            refreshLock.lock()
            defer { refreshLock.unlock() }
            
            // Eğer zaten refresh yapılıyorsa, mevcut task'i bekle
            if let existingTask = refreshTask {
                Task {
                    let result = await existingTask.value
                    continuation.resume(returning: result)
                }
                return
            }
            
            // Yeni refresh task başlat
            refreshTask = Task {
                let success = await performTokenRefresh()
                await MainActor.run {
                    self.isRefreshing = false
                    self.refreshTask = nil
                }
                continuation.resume(returning: success)
                return success
            }
            
            Task {
                await MainActor.run {
                    self.isRefreshing = true
                }
            }
        }
    }
    
    // MARK: - DÜZELTME: Token refresh implementation
    private func performTokenRefresh() async -> Bool {
        guard let currentRefreshToken = refreshToken,
              !currentRefreshToken.isEmpty else {
            print("❌ No refresh token available")
            await clearAllTokens()
            return false
        }
        
        guard let currentAccessToken = accessToken,
              !currentAccessToken.isEmpty else {
            print("❌ No access token available")
            await clearAllTokens()
            return false
        }
        
        print("🔄 Attempting to refresh tokens...")
        print("🔄 Current tokens before refresh:")
        print("   - Access: \(currentAccessToken.prefix(20))...")
        print("   - Refresh: \(currentRefreshToken.prefix(20))...")
        
        let request = RefreshTokenRequest(
            refreshToken: currentRefreshToken,
            accessToken: currentAccessToken
        )
        
        do {
            guard let requestData = try? JSONEncoder().encode(request) else {
                throw NetworkError.decodingError
            }
            
            print("🔄 Sending refresh request...")
            let response: RefreshTokenResponse = try await NetworkManager.shared.performTokenRefresh(
                endpoint: "http://192.168.100.76:5206/api/Auth/refresh-token",
                requestData: requestData
            )
            
            print("✅ Refresh API response received")
            print("📊 Response isSuccess: \(response.isSuccess)")
            
            if response.isSuccess, let tokenData = response.data {
                print("🎉 Token refresh successful!")
                
                // DÜZELTME: Tokenları hemen güncelle ve verify et
                await updateTokensSafely(
                    newAccessToken: tokenData.accessToken,
                    newRefreshToken: tokenData.refreshToken
                )
                
                return true
            } else {
                let errorMsg = response.errorMessage ?? "Unknown error"
                print("❌ Token refresh failed: \(errorMsg)")
                await clearAllTokens()
                return false
            }
            
        } catch {
            print("❌ Token refresh network error: \(error)")
            
            if let networkError = error as? NetworkError,
               case .unauthorized = networkError {
                print("🔐 Unauthorized during refresh, clearing tokens")
                await clearAllTokens()
            }
            
            return false
        }
    }
    
    // DÜZELTME: Thread-safe token update
    @MainActor
    private func updateTokensSafely(newAccessToken: String, newRefreshToken: String) {
        print("💾 Updating tokens safely...")
        
        let oldAccessToken = accessToken
        let oldRefreshToken = refreshToken
        
        // Update tokens
        accessToken = newAccessToken
        refreshToken = newRefreshToken
        
        // Verify update
        let verifiedAccessToken = accessToken
        let verifiedRefreshToken = refreshToken
        
        print("🔍 Token update verification:")
        print("   - Old Access: \(oldAccessToken?.prefix(20) ?? "nil")...")
        print("   - New Access: \(verifiedAccessToken?.prefix(20) ?? "nil")...")
        print("   - Old Refresh: \(oldRefreshToken?.prefix(20) ?? "nil")...")
        print("   - New Refresh: \(verifiedRefreshToken?.prefix(20) ?? "nil")...")
        
        // Double check UserDefaults
        let udAccessToken = UserDefaults.standard.string(forKey: "auth_token")
        let udRefreshToken = UserDefaults.standard.string(forKey: "refresh_token")
        
        print("🔍 UserDefaults verification:")
        print("   - Access in UD: \(udAccessToken?.prefix(20) ?? "nil")...")
        print("   - Refresh in UD: \(udRefreshToken?.prefix(20) ?? "nil")...")
        
        if verifiedAccessToken == newAccessToken && verifiedRefreshToken == newRefreshToken {
            print("✅ Token update successful and verified!")
        } else {
            print("❌ Token update verification failed!")
        }
    }
    
    @MainActor
    private func clearAllTokens() {
        accessToken = nil
        refreshToken = nil
        UserDefaults.standard.removeObject(forKey: "user_id")
        UserDefaults.standard.removeObject(forKey: "username")
        UserDefaults.standard.removeObject(forKey: "user_email")
        UserDefaults.standard.synchronize()
        print("🧹 All tokens and user data cleared and synchronized")
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
            // Check if refresh is in progress
            let refreshInProgress = TokenManager.shared.isRefreshing
            
            if refreshInProgress {
                print("⚠️ Auth error received but refresh in progress, waiting...")
                return
            }
            
            // Check if we have valid tokens
            let hasValidTokens = TokenManager.shared.accessToken != nil &&
                               TokenManager.shared.refreshToken != nil
            
            if !hasValidTokens {
                print("🔐 No valid tokens available, performing logout")
                authErrorMessage = "Oturumunuzun süresi doldu. Lütfen tekrar giriş yapın."
                showAuthError = true
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                    self.performAutoLogout()
                }
            }
        }
    }
    
    @MainActor
    private func performAutoLogout() {
        TokenManager.shared.accessToken = nil
        TokenManager.shared.refreshToken = nil
        UserDefaults.standard.removeObject(forKey: "user_id")
        UserDefaults.standard.removeObject(forKey: "username")
        UserDefaults.standard.removeObject(forKey: "user_email")
        
        NotificationCenter.default.post(name: .authenticationExpired, object: nil)
    }
}

extension Notification.Name {
    static let authenticationExpired = Notification.Name("authenticationExpired")
}
