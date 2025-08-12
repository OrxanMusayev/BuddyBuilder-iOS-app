// BuddyBuilder/Features/Authentication/Models/ForgotPasswordModels.swift

import Foundation

// MARK: - Forgot Password Request
struct ForgotPasswordRequest: Codable {
    let email: String
}

// MARK: - Reset Password Request
struct ResetPasswordRequest: Codable {
    let email: String
    let newPassword: String
    let confirmPassword: String
}

// MARK: - Forgot Password Response
typealias ForgotPasswordResponse = APIResponse<Bool>

// MARK: - Verify Email Response
typealias VerifyEmailResponse = APIResponse<Bool>

// MARK: - Reset Password Response
typealias ResetPasswordResponse = APIResponse<Bool>

// MARK: - Forgot Password Step Enum
enum ForgotPasswordStep: Int, CaseIterable {
    case enterEmail = 0
    case verifyCode = 1
    case resetPassword = 2
    case success = 3
    
    var title: String {
        switch self {
        case .enterEmail:
            return "forgot_password.step.enter_email"
        case .verifyCode:
            return "forgot_password.step.verify_code"
        case .resetPassword:
            return "forgot_password.step.reset_password"
        case .success:
            return "forgot_password.step.success"
        }
    }
    
    var subtitle: String {
        switch self {
        case .enterEmail:
            return "forgot_password.step.enter_email.subtitle"
        case .verifyCode:
            return "forgot_password.step.verify_code.subtitle"
        case .resetPassword:
            return "forgot_password.step.reset_password.subtitle"
        case .success:
            return "forgot_password.step.success.subtitle"
        }
    }
    
    var icon: String {
        switch self {
        case .enterEmail:
            return "envelope.fill"
        case .verifyCode:
            return "checkmark.seal.fill"
        case .resetPassword:
            return "lock.fill"
        case .success:
            return "checkmark.circle.fill"
        }
    }
}

// MARK: - Forgot Password Form Data
class ForgotPasswordFormData: ObservableObject {
    @Published var email: String = ""
    @Published var verificationCode: String = ""
    @Published var newPassword: String = ""
    @Published var confirmPassword: String = ""
    
    // MARK: - Validation Methods
    func isValidEmail() -> Bool {
        let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}"
        let emailTest = NSPredicate(format:"SELF MATCHES %@", emailRegex)
        return emailTest.evaluate(with: email)
    }
    
    func isValidVerificationCode() -> Bool {
        return !verificationCode.isEmpty && verificationCode.count >= 6 && verificationCode.allSatisfy { $0.isNumber }
    }
    
    func isValidPassword() -> Bool {
        guard newPassword.count >= 8 else { return false }
        
        let hasLowercase = newPassword.range(of: "[a-z]", options: .regularExpression) != nil
        let hasUppercase = newPassword.range(of: "[A-Z]", options: .regularExpression) != nil
        let hasNumber = newPassword.range(of: "[0-9]", options: .regularExpression) != nil
        let hasSpecialChar = newPassword.range(of: "[!@#$%^&*(),.?\":{}|<>]", options: .regularExpression) != nil
        
        return hasLowercase && hasUppercase && hasNumber && hasSpecialChar
    }
    
    func passwordsMatch() -> Bool {
        return !confirmPassword.isEmpty && newPassword == confirmPassword
    }
    
    // Password requirement checks for UI indicators
    func passwordHasMinLength() -> Bool {
        return newPassword.count >= 8
    }
    
    func passwordHasLowercase() -> Bool {
        return newPassword.range(of: "[a-z]", options: .regularExpression) != nil
    }
    
    func passwordHasUppercase() -> Bool {
        return newPassword.range(of: "[A-Z]", options: .regularExpression) != nil
    }
    
    func passwordHasNumber() -> Bool {
        return newPassword.range(of: "[0-9]", options: .regularExpression) != nil
    }
    
    func passwordHasSpecialChar() -> Bool {
        return newPassword.range(of: "[!@#$%^&*(),.?\":{}|<>]", options: .regularExpression) != nil
    }
}

// MARK: - Forgot Password Error Enum
enum ForgotPasswordError: Error, LocalizedError {
    case invalidEmail
    case emailNotFound
    case invalidVerificationCode
    case passwordValidationFailed
    case passwordMismatch
    case networkError(String)
    case unknown
    
    var errorDescription: String? {
        switch self {
        case .invalidEmail:
            return "forgot_password.error.invalid_email"
        case .emailNotFound:
            return "forgot_password.error.email_not_found"
        case .invalidVerificationCode:
            return "forgot_password.error.invalid_verification_code"
        case .passwordValidationFailed:
            return "forgot_password.error.password_validation_failed"
        case .passwordMismatch:
            return "forgot_password.error.password_mismatch"
        case .networkError(let message):
            return "forgot_password.error.network: \(message)"
        case .unknown:
            return "forgot_password.error.unknown"
        }
    }
}
