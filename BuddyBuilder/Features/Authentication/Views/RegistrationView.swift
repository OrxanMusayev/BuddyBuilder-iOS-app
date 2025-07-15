// BuddyBuilder/Features/Authentication/Views/RegistrationView.swift

import SwiftUI

struct RegistrationView: View {
    @StateObject private var viewModel = RegistrationViewModel()
    @EnvironmentObject var authViewModel: AuthenticationViewModel
    @EnvironmentObject var localizationManager: LocalizationManager
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        ZStack {
            // Background
            LoginBackgroundView()
            
            // Main Content - Centered like LoginView
            VStack {
                Spacer()
                
                // Registration Card
                registrationCard
                
                Spacer()
            }
            .padding(.horizontal, 20)
            
            // Success Overlay
            if viewModel.registrationCompleted {
                registrationSuccessOverlay
            }
            
            // Loading Overlay
            if viewModel.isLoading {
                loadingOverlay
            }
            
            // Error Alert
            if viewModel.showError {
                errorAlertOverlay
            }
        }
        .ignoresSafeArea()
        .onChange(of: viewModel.registrationCompleted) { completed in
            if completed {
                // Auto-login after successful registration
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                    authViewModel.isAuthenticated = true
                    dismiss()
                }
            }
        }
    }
    
    // MARK: - Registration Card (Like Login Card)
    private var registrationCard: some View {
        VStack(spacing: 0) {
            // Header Section
            VStack(spacing: 16) {
                // Back Button and Language Picker
                HStack {
                    Button(action: {
                        if viewModel.currentStep == .basicInfo {
                            dismiss()
                        } else {
                            viewModel.goToPreviousStep()
                        }
                    }) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundColor(.textPrimary)
                            .frame(width: 40, height: 40)
                            .background(Color.formBackground.opacity(0.8))
                            .clipShape(Circle())
                    }
                    
                    Spacer()
                    
                    // Language Picker
                    CompactLanguagePicker(localizationManager: localizationManager)
                }
                
                // Title and Progress
                VStack(spacing: 12) {
                    Text("registration.title".localized(using: localizationManager))
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundColor(.textPrimary)
                    
                    Text(viewModel.currentStep.title.localized(using: localizationManager))
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.primaryOrange)
                    
                    // Progress Bar
                    VStack(spacing: 8) {
                        HStack {
                            Text("\(viewModel.currentStep.rawValue + 1)/\(RegistrationStep.allCases.count)")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(.textSecondary)
                            
                            Spacer()
                        }
                        
                        ProgressView(value: viewModel.currentStepProgress)
                            .progressViewStyle(LinearProgressViewStyle(tint: .primaryOrange))
                            .scaleEffect(x: 1, y: 2, anchor: .center)
                            .animation(.easeInOut(duration: 0.3), value: viewModel.currentStepProgress)
                    }
                }
            }
            .padding(.bottom, 24)
            
            // Step Content
            ScrollView {
                VStack(spacing: 24) {
                    // Step Icon
                    ZStack {
                        Circle()
                            .fill(Color.primaryOrange.opacity(0.1))
                            .frame(width: 60, height: 60)
                        
                        Image(systemName: viewModel.currentStep.icon)
                            .font(.system(size: 24, weight: .medium))
                            .foregroundColor(.primaryOrange)
                    }
                    
                    // Step Content
                    Group {
                        switch viewModel.currentStep {
                        case .basicInfo:
                            BasicInfoStepView(viewModel: viewModel)
                                .environmentObject(localizationManager)
                                .transition(.asymmetric(insertion: .move(edge: .trailing), removal: .move(edge: .leading)))
                            
                        case .location:
                            LocationStepView(viewModel: viewModel)
                                .environmentObject(localizationManager)
                                .transition(.asymmetric(insertion: .move(edge: .trailing), removal: .move(edge: .leading)))
                            
                        case .sportsPreferences:
                            SportsPreferencesStepView(viewModel: viewModel)
                                .environmentObject(localizationManager)
                                .transition(.asymmetric(insertion: .move(edge: .trailing), removal: .move(edge: .leading)))
                            
                        case .profile:
                            ProfileStepView(viewModel: viewModel)
                                .environmentObject(localizationManager)
                                .transition(.asymmetric(insertion: .move(edge: .trailing), removal: .move(edge: .leading)))
                            
                        case .verification:
                            VerificationStepView(viewModel: viewModel)
                                .environmentObject(localizationManager)
                                .transition(.asymmetric(insertion: .move(edge: .trailing), removal: .move(edge: .leading)))
                        }
                    }
                    .animation(.easeInOut(duration: 0.3), value: viewModel.currentStep)
                    
                    // Navigation Buttons
                    navigationButtonsSection
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 20)
            }
            .frame(maxHeight: 500) // Limit height like login card
        }
        .padding(32)
        .background(
            RoundedRectangle(cornerRadius: 18)
                .fill(Color.white)
                .shadow(color: .black.opacity(0.1), radius: 15, x: 0, y: 5)
        )
    }
    
    // MARK: - Navigation Buttons Section
    private var navigationButtonsSection: some View {
        VStack(spacing: 12) {
            // Next/Complete Button
            Button(action: {
                viewModel.proceedToNextStep()
            }) {
                HStack {
                    if viewModel.isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .scaleEffect(0.8)
                    } else {
                        if viewModel.isLastStep {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 18))
                        } else {
                            Image(systemName: "arrow.right")
                                .font(.system(size: 18))
                        }
                    }
                    
                    Text(viewModel.isLastStep ?
                         "registration.complete".localized(using: localizationManager) :
                         "registration.next".localized(using: localizationManager))
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
            .animation(.easeInOut(duration: 0.2), value: viewModel.isLoading)
            .animation(.easeInOut(duration: 0.2), value: viewModel.canProceedToNextStep)
            
            // Back to Login (only on first step)
            if viewModel.currentStep == .basicInfo {
                Button(action: {
                    dismiss()
                }) {
                    HStack(spacing: 8) {
                        Image(systemName: "arrow.left")
                            .font(.system(size: 14, weight: .medium))
                        
                        Text("registration.back_to_login".localized(using: localizationManager))
                            .font(.system(size: 15, weight: .medium))
                    }
                    .foregroundColor(.textSecondary)
                }
                .disabled(viewModel.isLoading)
            }
        }
    }
    
    // MARK: - Registration Success Overlay
    private var registrationSuccessOverlay: some View {
        ZStack {
            Color.black.opacity(0.7)
                .ignoresSafeArea()
            
            VStack(spacing: 24) {
                // Success Animation
                ZStack {
                    Circle()
                        .fill(Color.green.opacity(0.1))
                        .frame(width: 120, height: 120)
                        .scaleEffect(viewModel.registrationCompleted ? 1.0 : 0.8)
                    
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 80, weight: .medium))
                        .foregroundColor(.green)
                        .scaleEffect(viewModel.registrationCompleted ? 1.0 : 0.8)
                }
                .animation(.spring(response: 0.6, dampingFraction: 0.8), value: viewModel.registrationCompleted)
                
                VStack(spacing: 12) {
                    Text("registration.success.title".localized(using: localizationManager))
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                    
                    Text("registration.success.subtitle".localized(using: localizationManager))
                        .font(.system(size: 16))
                        .foregroundColor(.white.opacity(0.8))
                        .multilineTextAlignment(.center)
                        .lineLimit(nil)
                }
                .padding(.horizontal, 40)
                
                // Loading indicator for auto-login
                VStack(spacing: 8) {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .scaleEffect(1.2)
                    
                    Text("registration.success.logging_in".localized(using: localizationManager))
                        .font(.system(size: 14))
                        .foregroundColor(.white.opacity(0.7))
                }
            }
            .padding(40)
            .background(
                RoundedRectangle(cornerRadius: 24)
                    .fill(.ultraThinMaterial)
            )
            .padding(.horizontal, 40)
        }
        .transition(.opacity.combined(with: .scale))
    }
    
    // MARK: - Loading Overlay
    private var loadingOverlay: some View {
        ZStack {
            Color.black.opacity(0.3)
                .ignoresSafeArea()
            
            VStack(spacing: 16) {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .primaryOrange))
                    .scaleEffect(1.5)
                
                Text("registration.creating_account".localized(using: localizationManager))
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.textPrimary)
            }
            .padding(32)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(.regularMaterial)
            )
        }
        .transition(.opacity)
    }
    
    // MARK: - Error Alert Overlay
    private var errorAlertOverlay: some View {
        ZStack {
            Color.black.opacity(0.4)
                .ignoresSafeArea()
                .onTapGesture {
                    viewModel.showError = false
                }
            
            VStack(spacing: 20) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 50))
                    .foregroundColor(.red)
                
                Text("registration.error.title".localized(using: localizationManager))
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.textPrimary)
                
                Text(viewModel.errorMessage.localized(using: localizationManager))
                    .font(.system(size: 14))
                    .foregroundColor(.textSecondary)
                    .multilineTextAlignment(.center)
                    .lineLimit(nil)
                
                Button("common.ok".localized(using: localizationManager)) {
                    viewModel.showError = false
                }
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.primaryOrange)
                .padding(.horizontal, 24)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 25)
                        .stroke(Color.primaryOrange, lineWidth: 1)
                )
            }
            .padding(32)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(.regularMaterial)
            )
            .padding(.horizontal, 40)
        }
        .transition(.opacity.combined(with: .scale))
    }
}

#Preview {
    RegistrationView()
        .environmentObject(AuthenticationViewModel())
        .environmentObject(LocalizationManager(localizationService: MockLocalizationService()))
}
