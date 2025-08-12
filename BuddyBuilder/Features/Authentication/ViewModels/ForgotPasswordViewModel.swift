// BuddyBuilder/Features/Authentication/ViewModels/ForgotPasswordViewModel.swift

import Foundation
import Combine
import SwiftUI

@MainActor
class ForgotPasswordViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published var currentStep: ForgotPasswordStep = .enterEmail
    @Published var formData = ForgotPasswordFormData()
    @Published var isLoading = false
    @Published var errorMessage: String = ""
    @Published var showError = false
    @Published var showPassword = false
    @Published var showConfirmPassword = false
    
    // Step validation states
    @Published var emailError = false
    @Published var verificationCodeError = false
    @Published var passwordError = false
    @Published var confirmPasswordError = false
    
    // Artık success state'i sadece currentStep ile yönetiliyor
    
    // MARK: - Private Properties
    private let forgotPasswordService: ForgotPasswordServiceProtocol
    private let localizationManager = LocalizationManager.shared
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Computed Properties
    var canProceedToNextStep: Bool {
        switch currentStep {
        case .enterEmail:
            return formData.isValidEmail()
        case .verifyCode:
            let isValid = formData.isValidVerificationCode()
            print("🔍 ViewModel - canProceedToNextStep for verifyCode: \(isValid), code: '\(formData.verificationCode)' (length: \(formData.verificationCode.count))")
            return isValid
        case .resetPassword:
            return formData.isValidPassword() && formData.passwordsMatch()
        case .success:
            return false // No next step
        }
    }
    
    var isLastStep: Bool {
        return currentStep == .resetPassword
    }
    
    // MARK: - Initialization
    init(forgotPasswordService: ForgotPasswordServiceProtocol = ForgotPasswordService()) {
        self.forgotPasswordService = forgotPasswordService
        setupValidationObservers()
        print("🏗️ ForgotPasswordViewModel initialized")
    }
    
    // MARK: - Setup Methods
    private func setupValidationObservers() {
        // Real-time password validation
        formData.$newPassword
            .combineLatest(formData.$confirmPassword)
            .sink { [weak self] (password: String, confirmPassword: String) in
                Task { @MainActor [weak self] in
                    await self?.validatePasswordFields(password: password, confirmPassword: confirmPassword)
                }
            }
            .store(in: &cancellables)
        
        // ENHANCED: Monitor verification code changes
        formData.$verificationCode
            .sink { [weak self] (code: String) in
                print("🔍 ViewModel - Verification code changed: '\(code)' (length: \(code.count))")
                Task { @MainActor [weak self] in
                    self?.verificationCodeError = false
                }
            }
            .store(in: &cancellables)
        
        // Clear field errors when user types
        setupFieldErrorClearingObservers()
    }
    
    @MainActor
    private func validatePasswordFields(password: String, confirmPassword: String) {
        passwordError = !formData.isValidPassword() && !password.isEmpty
        confirmPasswordError = !formData.passwordsMatch() && !confirmPassword.isEmpty
        
        if passwordError {
            if password.count < 8 {
                errorMessage = "validation.password.min_length".localized(using: localizationManager)
            } else if !formData.passwordHasLowercase() {
                errorMessage = "validation.password.lowercase".localized(using: localizationManager)
            } else if !formData.passwordHasUppercase() {
                errorMessage = "validation.password.uppercase".localized(using: localizationManager)
            } else if !formData.passwordHasNumber() {
                errorMessage = "validation.password.number".localized(using: localizationManager)
            } else if !formData.passwordHasSpecialChar() {
                errorMessage = "validation.password.special_char".localized(using: localizationManager)
            }
        } else if confirmPasswordError {
            errorMessage = "validation.password.no_match".localized(using: localizationManager)
        } else if !passwordError && !confirmPasswordError {
            errorMessage = ""
        }
    }
    
    
    private func setupFieldErrorClearingObservers() {
        formData.$email.sink { [weak self] (_: String) in
            Task { @MainActor [weak self] in
                self?.emailError = false
            }
        }.store(in: &cancellables)
        
        formData.$newPassword.sink { [weak self] (_: String) in
            Task { @MainActor [weak self] in
                self?.passwordError = false
            }
        }.store(in: &cancellables)
        
        formData.$confirmPassword.sink { [weak self] (_: String) in
            Task { @MainActor [weak self] in
                self?.confirmPasswordError = false
            }
        }.store(in: &cancellables)
    }
    
    // MARK: - Navigation Methods
    func proceedToNextStep() async {
        print("🔍 ViewModel - proceedToNextStep called for step: \(currentStep)")
        print("🔍 ViewModel - Current verification code: '\(formData.verificationCode)'")
        
        guard canProceedToNextStep else {
            await markCurrentStepErrors()
            return
        }
        
        switch currentStep {
        case .enterEmail:
            requestPasswordReset()
        case .verifyCode:
            verifyEmailCode()
        case .resetPassword:
            resetPassword()
        case .success:
            break // No action needed
        }
    }
    
    // MARK: - API Methods
    private func requestPasswordReset() {
        guard formData.isValidEmail() else {
            markCurrentStepErrors()
            return
        }
        
        print("📧 Requesting password reset for email: \(formData.email)")
        isLoading = true
        errorMessage = ""
        
        forgotPasswordService.requestPasswordReset(email: formData.email)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    self?.isLoading = false
                    switch completion {
                    case .failure(let error):
                        print("❌ Password reset request failed: \(error)")
                        self?.handleError(error)
                    case .finished:
                        print("✅ Password reset request completed")
                    }
                },
                receiveValue: { [weak self] response in
                    if response.success {
                        print("🎉 Password reset request successful")
                        withAnimation(.easeInOut(duration: 0.3)) {
                            self?.currentStep = .verifyCode
                        }
                    } else if let messageKey = response.message {
                        print("❌ Password reset request error: \(messageKey)")
                        Task { @MainActor [weak self] in
                            guard let self = self else { return }
                            self.errorMessage = messageKey.localized(using: self.localizationManager)
                            self.showError = true
                        }
                    }
                }
            )
            .store(in: &cancellables)
    }
    
    private func verifyEmailCode() {
        // ENHANCED VALIDATION AND LOGGING
        print("🔍 ViewModel - Starting verification process")
        print("🔍 ViewModel - Current code: '\(formData.verificationCode)'")
        print("🔍 ViewModel - Code length: \(formData.verificationCode.count)")
        print("🔍 ViewModel - Code validation result: \(formData.isValidVerificationCode())")
        
        // Force unwrap and validate the code one more time
        let codeToSend = formData.verificationCode.trimmingCharacters(in: .whitespacesAndNewlines)
        print("🔍 ViewModel - Trimmed code: '\(codeToSend)'")
        
        guard formData.isValidVerificationCode() && !codeToSend.isEmpty else {
            print("❌ ViewModel - Validation failed")
            markCurrentStepErrors()
            return
        }
        
        print("🔍 ViewModel - Calling service with code: '\(codeToSend)'")
        isLoading = true
        errorMessage = ""
        
        // Use the trimmed code
        forgotPasswordService.verifyEmailWithQueryParam(verificationCode: codeToSend)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    self?.isLoading = false
                    switch completion {
                    case .failure(let error):
                        print("❌ Email verification failed: \(error)")
                        self?.handleError(error)
                    case .finished:
                        print("✅ Email verification completed")
                    }
                },
                receiveValue: { [weak self] response in
                    if response.success {
                        print("🎉 Email verification successful")
                        withAnimation(.easeInOut(duration: 0.3)) {
                            self?.currentStep = .resetPassword
                        }
                    } else if let messageKey = response.message {
                        print("❌ Email verification error: \(messageKey)")
                        Task { @MainActor [weak self] in
                            guard let self = self else { return }
                            self.errorMessage = messageKey.localized(using: self.localizationManager)
                            self.showError = true
                        }
                    }
                }
            )
            .store(in: &cancellables)
    }
    
    private func resetPassword() {
        guard formData.isValidPassword() && formData.passwordsMatch() else {
            markCurrentStepErrors()
            return
        }
        
        print("🔑 Resetting password")
        isLoading = true
        errorMessage = ""
        
        forgotPasswordService.resetPasswordByEmail(
            email: formData.email,
            newPassword: formData.newPassword,
            confirmPassword: formData.confirmPassword
        )
        .receive(on: DispatchQueue.main)
        .sink(
            receiveCompletion: { [weak self] completion in
                self?.isLoading = false
                switch completion {
                case .failure(let error):
                    print("❌ Password reset failed: \(error)")
                    self?.handleError(error)
                case .finished:
                    print("✅ Password reset completed")
                }
            },
            receiveValue: { [weak self] response in
                guard let self = self else { return }
                
                if response.success {
                    print("🎉 Password reset successful")
                    withAnimation(.easeInOut(duration: 0.3)) {
                        self.currentStep = .success
                    }
                } else if let messageKey = response.message {
                    print("❌ Password reset error: \(messageKey)")
                    // API'den gelen message direkt olarak translation key'i olarak kullanılacak
                    Task { @MainActor in
                        self.errorMessage = messageKey.localized(using: self.localizationManager)
                        self.showError = true
                    }
                }
            }
        )
        .store(in: &cancellables)
    }
    
    // MARK: - Validation Methods
    @MainActor
    private func markCurrentStepErrors() {
        switch currentStep {
        case .enterEmail:
            emailError = !formData.isValidEmail()
            if emailError {
                errorMessage = "validation.email.invalid".localized(using: localizationManager)
            }
            
        case .verifyCode:
            verificationCodeError = !formData.isValidVerificationCode()
            if verificationCodeError {
                print("🔍 ViewModel - Marking verification code error, current code: '\(formData.verificationCode)'")
                errorMessage = "validation.verification_code.invalid".localized(using: localizationManager)
            }
            
        case .resetPassword:
            passwordError = !formData.isValidPassword()
            confirmPasswordError = !formData.passwordsMatch()
            
            if passwordError {
                if formData.newPassword.count < 8 {
                    errorMessage = "validation.password.min_length".localized(using: localizationManager)
                } else {
                    errorMessage = "validation.password.requirements".localized(using: localizationManager)
                }
            } else if confirmPasswordError {
                errorMessage = "validation.password.no_match".localized(using: localizationManager)
            }
            
        case .success:
            break
        }
        
        if !canProceedToNextStep {
            showError = true
        }
    }
    
    // MARK: - Helper Methods
    @MainActor
    private func handleError(_ error: Error) {
        let errorKey: String
        if let forgotPasswordError = error as? ForgotPasswordError {
            errorKey = String(describing: forgotPasswordError)
        } else {
            errorKey = "error.general"
        }
        errorMessage = errorKey.localized(using: localizationManager)
        showError = true
        print("❌ Forgot Password Error: \(errorMessage)")
    }
    
    private func clearErrors() {
        emailError = false
        verificationCodeError = false
        passwordError = false
        confirmPasswordError = false
        errorMessage = ""
        showError = false
    }
    
    func resetForm() {
        formData = ForgotPasswordFormData()
        currentStep = .enterEmail
        clearErrors()
        print("🔄 Forgot password form reset")
    }
    
    // MARK: - Resend Verification Code
    func resendVerificationCode() {
        guard currentStep == .verifyCode else { return }
        
        print("🔄 Resending verification code to: \(formData.email)")
        requestPasswordReset()
    }
}
