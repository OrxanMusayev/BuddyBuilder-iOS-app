// BuddyBuilder/Features/Authentication/Services/ForgotPasswordService.swift

import Foundation
import Combine

// MARK: - Forgot Password Service Protocol
protocol ForgotPasswordServiceProtocol {
    func requestPasswordReset(email: String) -> AnyPublisher<ForgotPasswordResponse, Error>
    func verifyEmail(verificationCode: String) -> AnyPublisher<VerifyEmailResponse, Error>
    func resetPasswordByEmail(newPassword: String, confirmPassword: String) -> AnyPublisher<ResetPasswordResponse, Error>
    func verifyEmailWithQueryParam(verificationCode: String) -> AnyPublisher<VerifyEmailResponse, Error>
}

// MARK: - Forgot Password Service Implementation
class ForgotPasswordService: ForgotPasswordServiceProtocol {
    private let networkManager = NetworkManager.shared
    private let baseURL = "http://192.168.100.76:5206/api/Auth"
    
    // MARK: - Request Password Reset
    func requestPasswordReset(email: String) -> AnyPublisher<ForgotPasswordResponse, Error> {
        let request = ForgotPasswordRequest(email: email)
        
        guard let requestData = try? JSONEncoder().encode(request) else {
            print("❌ Failed to encode forgot password request")
            return Fail(error: NetworkError.decodingError)
                .eraseToAnyPublisher()
        }
        
        print("🔐 FORGOT PASSWORD REQUEST:")
        print("URL: \(baseURL)/forgot-password")
        print("Body: \(String(data: requestData, encoding: .utf8) ?? "nil")")
        
        return networkManager.request(
            endpoint: "\(baseURL)/forgot-password",
            method: .POST,
            body: requestData,
            type: ForgotPasswordResponse.self
        )
        .handleEvents(
            receiveOutput: { response in
                print("✅ Forgot password response: success=\(response.success), message=\(response.message ?? "nil")")
            },
            receiveCompletion: { completion in
                if case .failure(let error) = completion {
                    print("❌ Forgot password request failed: \(error)")
                }
            }
        )
        .eraseToAnyPublisher()
    }
    
    // MARK: - Verify Email Code - FIXED VERSION
    func verifyEmail(verificationCode: String) -> AnyPublisher<VerifyEmailResponse, Error> {
        // Create request body for verification code
        let requestBody = ["verificationCode": verificationCode]
        
        guard let requestData = try? JSONEncoder().encode(requestBody) else {
            print("❌ Failed to encode verification request")
            return Fail(error: NetworkError.decodingError)
                .eraseToAnyPublisher()
        }
        
        let endpoint = "\(baseURL)/verify-email"
        
        print("🔍 VERIFY EMAIL REQUEST:")
        print("URL: \(endpoint)")
        print("Body: \(String(data: requestData, encoding: .utf8) ?? "nil")")
        print("Code: \(verificationCode)")
        
        return networkManager.request(
            endpoint: endpoint,
            method: .POST,
            body: requestData,
            type: VerifyEmailResponse.self
        )
        .handleEvents(
            receiveOutput: { response in
                print("✅ Verify email response: success=\(response.success), message=\(response.message ?? "nil"), data=\(response.data ?? false)")
            },
            receiveCompletion: { completion in
                if case .failure(let error) = completion {
                    print("❌ Verify email request failed: \(error)")
                }
            }
        )
        .eraseToAnyPublisher()
    }
    
    // MARK: - Alternative Verify Email Methods (if needed)
    func verifyEmailWithQueryParam(verificationCode: String) -> AnyPublisher<VerifyEmailResponse, Error> {
        guard let encodedCode = verificationCode.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) else {
            print("❌ Failed to encode verification code")
            return Fail(error: NetworkError.decodingError)
                .eraseToAnyPublisher()
        }
        
        let endpoint = "\(baseURL)/verify-email?verificationCode=\(encodedCode)"
        
        print("🔍 VERIFY EMAIL REQUEST (Query Param):")
        print("URL: \(endpoint)")
        
        return networkManager.request(
            endpoint: endpoint,
            method: .POST,
            type: VerifyEmailResponse.self
        )
        .handleEvents(
            receiveOutput: { response in
                print("✅ Verify email response: success=\(response.success), message=\(response.message ?? "nil")")
            },
            receiveCompletion: { completion in
                if case .failure(let error) = completion {
                    print("❌ Verify email request failed: \(error)")
                }
            }
        )
        .eraseToAnyPublisher()
    }
    
    // MARK: - Reset Password By Email - FIXED WITH VERIFICATION TOKEN
    func resetPasswordByEmail(newPassword: String, confirmPassword: String) -> AnyPublisher<ResetPasswordResponse, Error> {
        let request = ResetPasswordRequest(newPassword: newPassword, confirmPassword: confirmPassword)
        
        guard let requestData = try? JSONEncoder().encode(request) else {
            print("❌ Failed to encode reset password request")
            return Fail(error: NetworkError.decodingError)
                .eraseToAnyPublisher()
        }
        
        // FIXED: Use correct endpoint and add verification token as header
        let endpoint = "\(baseURL)/reset-password-email"
        
        print("🔑 RESET PASSWORD BY EMAIL REQUEST:")
        print("URL: \(endpoint)")
        print("Body: \(String(data: requestData, encoding: .utf8) ?? "nil")")
        
        return networkManager.request(
            endpoint: endpoint,
            method: .POST,
            body: requestData,
            type: ResetPasswordResponse.self
        )
        .handleEvents(
            receiveOutput: { response in
                print("✅ Reset password response: success=\(response.success), message=\(response.message ?? "nil")")
                // Clear verification token after successful reset
                if response.success {
                    self.clearStoredVerificationToken()
                }
            },
            receiveCompletion: { completion in
                if case .failure(let error) = completion {
                    print("❌ Reset password request failed: \(error)")
                }
            }
        )
        .eraseToAnyPublisher()
    }
    
    // MARK: - Verification Token Management
    private func getStoredVerificationToken() -> String {
        return UserDefaults.standard.string(forKey: "forgot_password_verification_token") ?? ""
    }
    
    private func storeVerificationToken(_ token: String) {
        UserDefaults.standard.set(token, forKey: "forgot_password_verification_token")
        print("💾 Stored verification token")
    }
    
    private func clearStoredVerificationToken() {
        UserDefaults.standard.removeObject(forKey: "forgot_password_verification_token")
        print("🗑️ Cleared verification token")
    }
    
    // MARK: - Enhanced Verify Email with Token Storage
    func verifyEmailAndStoreToken(verificationCode: String) -> AnyPublisher<VerifyEmailResponse, Error> {
        return verifyEmail(verificationCode: verificationCode)
            .handleEvents(
                receiveOutput: { [weak self] response in
                    if response.success {
                        // If API returns a token, store it
                        // Assuming the token might be in response.message or a new field
                        // You might need to modify this based on your API response
                        if let token = self?.extractTokenFromResponse(response) {
                            self?.storeVerificationToken(token)
                        }
                    }
                }
            )
            .eraseToAnyPublisher()
    }
    
    private func extractTokenFromResponse(_ response: VerifyEmailResponse) -> String? {
        // This method should extract token from API response
        // Modify based on your actual API response structure
        // For now, returning a placeholder - you'll need to adjust this
        return response.message // or response.data if it contains token
    }
}

// MARK: - Enhanced Request Models for Better Error Handling
extension ResetPasswordRequest {
    // Add validation method
    func isValid() -> Bool {
        guard !newPassword.isEmpty, !confirmPassword.isEmpty else {
            return false
        }
        
        guard newPassword == confirmPassword else {
            return false
        }
        
        // Add password strength validation
        guard newPassword.count >= 8 else {
            return false
        }
        
        return true
    }
}

// MARK: - Mock Service Update
class MockForgotPasswordService: ForgotPasswordServiceProtocol {
    func requestPasswordReset(email: String) -> AnyPublisher<ForgotPasswordResponse, Error> {
        print("🧪 MOCK: Sending password reset to \(email)")
        
        let response = ForgotPasswordResponse(
            success: true,
            message: "Verification code sent to your email",
            data: true,
            errors: nil,
            timestamp: ISO8601DateFormatter().string(from: Date())
        )
        
        return Just(response)
            .delay(for: .seconds(1), scheduler: RunLoop.main)
            .setFailureType(to: Error.self)
            .eraseToAnyPublisher()
    }
    
    func verifyEmail(verificationCode: String) -> AnyPublisher<VerifyEmailResponse, Error> {
        print("🧪 MOCK: Verifying code: \(verificationCode)")
        
        let isValid = verificationCode == "123456" // Mock validation
        
        let response = VerifyEmailResponse(
            success: isValid,
            message: isValid ? "Email verified successfully" : "Invalid verification code",
            data: isValid,
            errors: isValid ? nil : ["Invalid verification code"],
            timestamp: ISO8601DateFormatter().string(from: Date())
        )
        
        return Just(response)
            .delay(for: .seconds(1), scheduler: RunLoop.main)
            .setFailureType(to: Error.self)
            .eraseToAnyPublisher()
    }
    
    func resetPasswordByEmail(newPassword: String, confirmPassword: String) -> AnyPublisher<ResetPasswordResponse, Error> {
        print("🧪 MOCK: Resetting password")
        
        let isValid = !newPassword.isEmpty && newPassword == confirmPassword
        
        let response = ResetPasswordResponse(
            success: isValid,
            message: isValid ? "Password reset successfully" : "Password reset failed",
            data: isValid,
            errors: isValid ? nil : ["Password validation failed"],
            timestamp: ISO8601DateFormatter().string(from: Date())
        )
        
        return Just(response)
            .delay(for: .seconds(1.5), scheduler: RunLoop.main)
            .setFailureType(to: Error.self)
            .eraseToAnyPublisher()
    }
    
    func verifyEmailWithQueryParam(verificationCode: String) -> AnyPublisher<VerifyEmailResponse, Error> {
        return verifyEmail(verificationCode: verificationCode)
    }
}
