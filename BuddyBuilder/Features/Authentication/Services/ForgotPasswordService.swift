// BuddyBuilder/Features/Authentication/Services/ForgotPasswordService.swift

import Foundation
import Combine

// MARK: - Forgot Password Service Protocol
protocol ForgotPasswordServiceProtocol {
    func requestPasswordReset(email: String) -> AnyPublisher<ForgotPasswordResponse, Error>
    func verifyEmail(verificationCode: String) -> AnyPublisher<VerifyEmailResponse, Error>
    func resetPassword(newPassword: String, confirmPassword: String) -> AnyPublisher<ResetPasswordResponse, Error>
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
    
    // MARK: - Verify Email Code
    func verifyEmail(verificationCode: String) -> AnyPublisher<VerifyEmailResponse, Error> {
        // URL encode the verification code to handle special characters
        guard let encodedCode = verificationCode.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) else {
            print("❌ Failed to encode verification code")
            return Fail(error: NetworkError.decodingError)
                .eraseToAnyPublisher()
        }
        
        let endpoint = "\(baseURL)/verify-email?verificationCode=\(encodedCode)"
        
        print("🔍 VERIFY EMAIL REQUEST:")
        print("URL: \(endpoint)")
        print("Original Code: \(verificationCode)")
        print("Encoded Code: \(encodedCode)")
        
        return networkManager.request(
            endpoint: endpoint,
            method: .GET,
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
    
    // MARK: - Reset Password
    func resetPassword(newPassword: String, confirmPassword: String) -> AnyPublisher<ResetPasswordResponse, Error> {
        let request = ResetPasswordRequest(newPassword: newPassword, confirmPassword: confirmPassword)
        
        guard let requestData = try? JSONEncoder().encode(request) else {
            print("❌ Failed to encode reset password request")
            return Fail(error: NetworkError.decodingError)
                .eraseToAnyPublisher()
        }
        
        print("🔑 RESET PASSWORD REQUEST:")
        print("URL: \(baseURL)/reset-password-email")
        print("Body: \(String(data: requestData, encoding: .utf8) ?? "nil")")
        
        return networkManager.request(
            endpoint: "\(baseURL)/reset-password-email",
            method: .POST,
            body: requestData,
            type: ResetPasswordResponse.self
        )
        .handleEvents(
            receiveOutput: { response in
                print("✅ Reset password response: success=\(response.success), message=\(response.message ?? "nil")")
            },
            receiveCompletion: { completion in
                if case .failure(let error) = completion {
                    print("❌ Reset password request failed: \(error)")
                }
            }
        )
        .eraseToAnyPublisher()
    }
}

// MARK: - Mock Forgot Password Service (for testing/preview)
class MockForgotPasswordService: ForgotPasswordServiceProtocol {
    func requestPasswordReset(email: String) -> AnyPublisher<ForgotPasswordResponse, Error> {
        print("🧪 MOCK: Requesting password reset for email: \(email)")
        
        // Simulate network delay
        return Just(
            ForgotPasswordResponse(
                success: true,
                message: "Verification code sent to your email",
                data: true,
                errors: nil,
                timestamp: ISO8601DateFormatter().string(from: Date())
            )
        )
        .delay(for: .seconds(1.5), scheduler: RunLoop.main)
        .setFailureType(to: Error.self)
        .eraseToAnyPublisher()
    }
    
    func verifyEmail(verificationCode: String) -> AnyPublisher<VerifyEmailResponse, Error> {
        print("🧪 MOCK: Verifying email with code: \(verificationCode)")
        
        // Simulate success for 6-digit numeric codes, failure for others
        let isValid = verificationCode.count == 6 && verificationCode.allSatisfy { $0.isNumber }
        
        return Just(
            VerifyEmailResponse(
                success: isValid,
                message: isValid ? nil : "Invalid verification code",
                data: isValid,
                errors: nil,
                timestamp: ISO8601DateFormatter().string(from: Date())
            )
        )
        .delay(for: .seconds(1.0), scheduler: RunLoop.main)
        .setFailureType(to: Error.self)
        .eraseToAnyPublisher()
    }
    
    func resetPassword(newPassword: String, confirmPassword: String) -> AnyPublisher<ResetPasswordResponse, Error> {
        print("🧪 MOCK: Resetting password")
        
        // Simulate validation
        let isValid = newPassword == confirmPassword && newPassword.count >= 8
        
        return Just(
            ResetPasswordResponse(
                success: isValid,
                message: isValid ? "Password reset successfully" : "Password validation failed",
                data: isValid,
                errors: nil,
                timestamp: ISO8601DateFormatter().string(from: Date())
            )
        )
        .delay(for: .seconds(1.5), scheduler: RunLoop.main)
        .setFailureType(to: Error.self)
        .eraseToAnyPublisher()
    }
}
