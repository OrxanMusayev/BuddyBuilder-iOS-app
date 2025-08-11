// BuddyBuilder/Features/Authentication/Views/ForgotPasswordView.swift

import SwiftUI

struct ForgotPasswordView: View {
    @StateObject private var viewModel = ForgotPasswordViewModel()
    @EnvironmentObject var localizationManager: LocalizationManager
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Background
                LoginBackgroundView()
                    .ignoresSafeArea(.all)
                
                // Main Content
                VStack(spacing: 0) {
                    // Header Section
                    headerSection
                        .padding(.horizontal, 20)
                        .padding(.top, 80)
                    
                    // Step Visual
                    stepVisual
                        .padding(.bottom, 30)
                    
                    // Step Content
                    ScrollView(showsIndicators: false) {
                        VStack(spacing: 24) {
                            currentStepContent
                        }
                        .padding(.horizontal, 20)
                    }
                    .frame(maxHeight: .infinity)
                    
                    // Navigation Buttons
                    if viewModel.currentStep != .success {
                        navigationButtonsSection
                            .padding(.horizontal, 20)
                            .padding(.bottom, 40)
                    }
                }
                .opacity(showOverlays ? 0.3 : 1.0)
                .disabled(showOverlays)
                
                // Overlays
                if viewModel.isLoading {
                    loadingOverlay
                }
                
                if viewModel.showError {
                    errorAlertOverlay
                }
            }
        }
        .ignoresSafeArea()
        .navigationBarBackButtonHidden(true)
        .dismissKeyboardOnTap() // NEW: Dismiss keyboard when tapping anywhere
        .onChange(of: viewModel.isCompleted) { completed in
            if completed {
                // Auto-dismiss after success
                DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                    dismiss()
                }
            }
        }
    }
    
    // MARK: - Computed Properties
    private var showOverlays: Bool {
        viewModel.isLoading || viewModel.showError
    }
    
    // MARK: - Header Section
    private var headerSection: some View {
        VStack(spacing: 16) {
            // Top Row: Back button
            HStack {
                Button(action: {
                    if !viewModel.isLoading {
                        if viewModel.currentStep == .enterEmail {
                            dismiss()
                        } else {
                            // Remove previous step functionality - only allow dismiss from first step
                            // For other steps, users can only go forward or dismiss completely
                            dismiss()
                        }
                    }
                }) {
                    Image(systemName: "arrow.left")
                        .font(.system(size: 20, weight: .medium))
                        .foregroundColor(.primaryOrange)
                }
                .disabled(viewModel.isLoading)
                
                Spacer()
            }
            
            // Title Section
            VStack(spacing: 8) {
                Text(viewModel.currentStep.title.localized(using: localizationManager))
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(.black)
                
                Text(viewModel.currentStep.subtitle.localized(using: localizationManager))
                    .font(.system(size: 14))
                    .foregroundColor(.black.opacity(0.7))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 20)
            }
        }
    }
    
    // MARK: - Step Visual
    private var stepVisual: some View {
        ZStack {
            Circle()
                .fill(
                    RadialGradient(
                        colors: [.primaryOrange.opacity(0.3), .primaryOrange.opacity(0.1)],
                        center: .center,
                        startRadius: 10,
                        endRadius: 40
                    )
                )
                .frame(width: 80, height: 80)
            
            Image(systemName: viewModel.currentStep.icon)
                .font(.system(size: 32, weight: .medium))
                .foregroundColor(.primaryOrange)
        }
        .animation(.easeInOut(duration: 0.3), value: viewModel.currentStep)
    }
    
    // MARK: - Current Step Content
    @ViewBuilder
    private var currentStepContent: some View {
        switch viewModel.currentStep {
        case .enterEmail:
            EnterEmailStepView(viewModel: viewModel)
                .environmentObject(localizationManager)
            
        case .verifyCode:
            VerifyCodeStepView(viewModel: viewModel)
                .environmentObject(localizationManager)
            
        case .resetPassword:
            ResetPasswordStepView(viewModel: viewModel)
                .environmentObject(localizationManager)
            
        case .success:
            SuccessStepView(viewModel: viewModel)
                .environmentObject(localizationManager)
        }
    }
    
    // MARK: - Navigation Buttons
    private var navigationButtonsSection: some View {
        VStack(spacing: 12) {
            // Main Action Button
            Button(action: {
                viewModel.proceedToNextStep()
            }) {
                HStack {
                    if viewModel.isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .scaleEffect(0.8)
                    } else {
                        Image(systemName: buttonIcon)
                            .font(.system(size: 16))
                    }
                    
                    Text(buttonTitle)
                        .font(.system(size: 16, weight: .semibold))
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 50)
                .background(
                    LinearGradient(
                        colors: [.primaryOrange, Color.primaryOrange.opacity(0.8)],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .clipShape(RoundedRectangle(cornerRadius: 25))
                .scaleEffect(viewModel.isLoading ? 0.95 : 1.0)
                .opacity(viewModel.canProceedToNextStep ? 1.0 : 0.6)
            }
            .disabled(!viewModel.canProceedToNextStep || viewModel.isLoading)
            
            // Previous button removed as requested
        }
    }
    
    // MARK: - Button Properties
    private var buttonIcon: String {
        switch viewModel.currentStep {
        case .enterEmail:
            return "paperplane.fill"
        case .verifyCode:
            return "checkmark.circle.fill"
        case .resetPassword:
            return "lock.rotation"
        case .success:
            return "checkmark"
        }
    }
    
    private var buttonTitle: String {
        switch viewModel.currentStep {
        case .enterEmail:
            return "Send Code"
        case .verifyCode:
            return "Verify Code"
        case .resetPassword:
            return "Reset Password"
        case .success:
            return "Done"
        }
    }
    
    // MARK: - Overlays
    private var loadingOverlay: some View {
        ZStack {
            Color.black.opacity(0.5)
                .ignoresSafeArea()
            
            VStack(spacing: 16) {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .primaryOrange))
                    .scaleEffect(1.5)
                
                Text(loadingMessage)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.white)
            }
            .padding(32)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(.ultraThinMaterial)
            )
        }
        .transition(.opacity)
        .zIndex(999)
    }
    
    private var loadingMessage: String {
        switch viewModel.currentStep {
        case .enterEmail:
            return "Sending verification code..."
        case .verifyCode:
            return "Verifying code..."
        case .resetPassword:
            return "Resetting password..."
        case .success:
            return ""
        }
    }
    
    private var errorAlertOverlay: some View {
        ZStack {
            Color.black.opacity(0.6)
                .ignoresSafeArea()
                .onTapGesture {
                    clearError()
                }
            
            VStack(spacing: 20) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 50))
                    .foregroundColor(.red)
                
                Text("Error")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.white)
                
                Text(viewModel.errorMessage)
                    .font(.system(size: 14))
                    .foregroundColor(.white.opacity(0.8))
                    .multilineTextAlignment(.center)
                    .lineLimit(nil)
                
                Button("OK") {
                    clearError()
                }
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.primaryOrange)
                .padding(.horizontal, 24)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 25)
                        .fill(.white)
                )
            }
            .padding(32)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(.ultraThinMaterial)
            )
            .padding(.horizontal, 40)
        }
        .transition(.opacity.combined(with: .scale))
        .zIndex(998)
    }
    
    // MARK: - Helper Methods
    private func clearError() {
        withAnimation(.easeInOut(duration: 0.3)) {
            viewModel.showError = false
            viewModel.errorMessage = ""
        }
    }
}

// MARK: - Step Views

// MARK: - Enter Email Step
struct EnterEmailStepView: View {
    @ObservedObject var viewModel: ForgotPasswordViewModel
    @EnvironmentObject var localizationManager: LocalizationManager
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Enter the email address associated with your account and we'll send you a verification code to reset your password.")
                .font(.system(size: 14))
                .foregroundColor(.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 20)
            
            CustomTextFieldNoTitle(
                text: $viewModel.formData.email,
                icon: "envelope.fill",
                placeholder: "Enter your email address",
                hasError: viewModel.emailError
            )
            .textInputAutocapitalization(.never)
            .autocorrectionDisabled()
            .keyboardType(.emailAddress)
        }
    }
}

// MARK: - Verify Code Step
struct VerifyCodeStepView: View {
    @ObservedObject var viewModel: ForgotPasswordViewModel
    @EnvironmentObject var localizationManager: LocalizationManager
    
    var body: some View {
        VStack(spacing: 24) {
            VStack(spacing: 12) {
                Text("We've sent a verification code to:")
                    .font(.system(size: 14))
                    .foregroundColor(.textSecondary)
                
                Text(viewModel.formData.email)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.primaryOrange)
            }
            .multilineTextAlignment(.center)
            .padding(.horizontal, 20)
            
            CustomTextFieldNoTitle(
                text: $viewModel.formData.verificationCode,
                icon: "number.circle.fill",
                placeholder: "Enter verification code",
                hasError: viewModel.verificationCodeError
            )
            .keyboardType(.numberPad)
            .textInputAutocapitalization(.never)
            .autocorrectionDisabled()
            .onReceive(viewModel.formData.$verificationCode) { newValue in
                // Only allow numeric input
                let filtered = newValue.filter { $0.isNumber }
                if filtered != newValue {
                    viewModel.formData.verificationCode = filtered
                }
            }
            
            // Resend Code Button
            Button(action: {
                viewModel.resendVerificationCode()
            }) {
                HStack(spacing: 6) {
                    Image(systemName: "arrow.clockwise")
                        .font(.system(size: 14))
                    
                    Text("Resend Code")
                        .font(.system(size: 14, weight: .medium))
                }
                .foregroundColor(.primaryOrange)
            }
            .disabled(viewModel.isLoading)
        }
    }
}

// MARK: - Reset Password Step
struct ResetPasswordStepView: View {
    @ObservedObject var viewModel: ForgotPasswordViewModel
    @EnvironmentObject var localizationManager: LocalizationManager
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Create a new password for your account. Make sure it's strong and secure.")
                .font(.system(size: 14))
                .foregroundColor(.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 20)
            
            // New Password Field
            CustomPasswordFieldNoTitle(
                text: $viewModel.formData.newPassword,
                showPassword: $viewModel.showPassword,
                placeholder: "New Password",
                hasError: viewModel.passwordError
            )
            
            // Confirm Password Field
            CustomPasswordFieldNoTitle(
                text: $viewModel.formData.confirmPassword,
                showPassword: $viewModel.showConfirmPassword,
                placeholder: "Confirm New Password",
                hasError: viewModel.confirmPasswordError
            )
            
            // Password Requirements
            if !viewModel.formData.newPassword.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Password Requirements:")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.textSecondary)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        ForgotPasswordRequirementRow(
                            text: "At least 8 characters",
                            isValid: viewModel.formData.passwordHasMinLength()
                        )
                        
                        ForgotPasswordRequirementRow(
                            text: "One lowercase letter (a-z)",
                            isValid: viewModel.formData.passwordHasLowercase()
                        )
                        
                        ForgotPasswordRequirementRow(
                            text: "One uppercase letter (A-Z)",
                            isValid: viewModel.formData.passwordHasUppercase()
                        )
                        
                        ForgotPasswordRequirementRow(
                            text: "One number (0-9)",
                            isValid: viewModel.formData.passwordHasNumber()
                        )
                        
                        ForgotPasswordRequirementRow(
                            text: "One special character (!@#$%^&*)",
                            isValid: viewModel.formData.passwordHasSpecialChar()
                        )
                        
                        // Password match indicator
                        if !viewModel.formData.confirmPassword.isEmpty {
                            ForgotPasswordRequirementRow(
                                text: "Passwords match",
                                isValid: viewModel.formData.passwordsMatch()
                            )
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(Color.formBackground.opacity(0.5))
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.formBorder.opacity(0.3), lineWidth: 1)
                )
            }
        }
    }
}

// MARK: - Success Step
struct SuccessStepView: View {
    @ObservedObject var viewModel: ForgotPasswordViewModel
    @EnvironmentObject var localizationManager: LocalizationManager
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        VStack(spacing: 32) {
            // Success Animation
            SuccessPasswordResetVisual()
                .scaleEffect(1.2)
            
            VStack(spacing: 16) {
                Text("Password Reset Successfully!")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundColor(.green)
                    .multilineTextAlignment(.center)
                
                Text("Your password has been updated. You can now login with your new password.")
                    .font(.system(size: 14))
                    .foregroundColor(.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 20)
            }
            
            // Back to Login Button
            Button(action: {
                dismiss()
            }) {
                HStack {
                    Image(systemName: "arrow.left")
                        .font(.system(size: 16))
                    
                    Text("Back to Login")
                        .font(.system(size: 16, weight: .semibold))
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 50)
                .background(
                    LinearGradient(
                        colors: [.green, Color.green.opacity(0.8)],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .clipShape(RoundedRectangle(cornerRadius: 25))
            }
        }
        .padding(.horizontal, 20)
    }
}

// MARK: - Password Requirement Row
struct ForgotPasswordRequirementRow: View {
    let text: String
    let isValid: Bool
    
    var body: some View {
        HStack(spacing: 8) {
            ZStack {
                Circle()
                    .fill(isValid ? Color.green : Color.textSecondary.opacity(0.3))
                    .frame(width: 16, height: 16)
                    .scaleEffect(isValid ? 1.1 : 1.0)
                    .animation(.easeInOut(duration: 0.2), value: isValid)
                
                Image(systemName: isValid ? "checkmark" : "circle")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(isValid ? .white : .textSecondary)
                    .scaleEffect(isValid ? 1.2 : 1.0)
                    .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isValid)
            }
            
            Text(text)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(isValid ? .green : .textSecondary)
                .animation(.easeInOut(duration: 0.2), value: isValid)
            
            Spacer()
        }
        .padding(.horizontal, 4)
        .animation(.easeInOut(duration: 0.3), value: isValid)
    }
}

// MARK: - Success Visual
struct SuccessPasswordResetVisual: View {
    @State private var isAnimating = false
    
    var body: some View {
        ZStack {
            // Success burst background
            ForEach(0..<8, id: \.self) { index in
                Rectangle()
                    .fill(LinearGradient(colors: [.green, .green.opacity(0.3)], startPoint: .leading, endPoint: .trailing))
                    .frame(width: 25, height: 2)
                    .offset(x: 12)
                    .rotationEffect(.degrees(Double(index) * 45))
                    .scaleEffect(isAnimating ? 1.2 : 0.8)
                    .opacity(isAnimating ? 1.0 : 0.6)
            }
            
            // Central lock with checkmark
            ZStack {
                Circle()
                    .fill(LinearGradient(colors: [.green, .green.opacity(0.8)], startPoint: .topLeading, endPoint: .bottomTrailing))
                    .frame(width: 45, height: 45)
                
                Image(systemName: "lock.rotation.open")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.white)
            }
            .scaleEffect(isAnimating ? 1.1 : 1.0)
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true)) {
                isAnimating = true
            }
        }
    }
}
