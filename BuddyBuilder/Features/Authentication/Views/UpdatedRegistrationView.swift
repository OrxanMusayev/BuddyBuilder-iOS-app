// BuddyBuilder/Features/Authentication/Views/UpdatedRegistrationView.swift

import SwiftUI

struct UpdatedRegistrationView: View {
    @StateObject private var viewModel = UpdatedRegistrationViewModel()
    @EnvironmentObject var authViewModel: AuthenticationViewModel
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
                    // Header Section - FIXED: No pushing down content
                    headerSection
                        .padding(.horizontal, 20)
                        .padding(.top, 80)
                    
                    // Custom Step Visual
                    customStepVisual
                        .padding(.bottom, 20)
                    
                    // Step Content - Scrollable
                    ScrollView(showsIndicators: false) {
                        VStack(spacing: 20) {
                            Group {
                                switch viewModel.currentStep {
                                case .basicInfo:
                                    UpdatedBasicInfoStepView(viewModel: viewModel)
                                        .environmentObject(localizationManager)
                                    
                                case .location:
                                    UpdatedLocationStepView(viewModel: viewModel)
                                        .environmentObject(localizationManager)
                                    
                                case .sportsPreferences:
                                    UpdatedSportsPreferencesStepView(viewModel: viewModel)
                                        .environmentObject(localizationManager)
                                }
                            }
                            .animation(.easeInOut(duration: 0.3), value: viewModel.currentStep)
                        }
                        .padding(.horizontal, 20)
                    }
                    .frame(maxHeight: .infinity)
                    .clipped()
                    
                    // Navigation Buttons
                    navigationButtonsSection
                        .padding(.horizontal, 20)
                        .padding(.bottom, 40)
                }
                .opacity(showOverlays ? 0.3 : 1.0)
                .disabled(showOverlays)
                
                // Language picker - SEPARATE OVERLAY LIKE IN LOGIN
                VStack {
                    HStack {
                        Spacer()
                        CompactLanguagePicker(localizationManager: localizationManager)
                            .disabled(viewModel.isLoading)
                            .padding(.top, 80) // Aligned with back button
                            .padding(.trailing, 20)
                    }
                    Spacer()
                }
                .zIndex(1001) // Higher than header
                
                // Overlays
                if viewModel.registrationCompleted {
                    registrationSuccessOverlay
                }
                
                if viewModel.isLoading && !viewModel.registrationCompleted {
                    loadingOverlay
                }
                
                if viewModel.showError {
                    errorAlertOverlay
                }
            }
        }
        .ignoresSafeArea()
        .navigationBarBackButtonHidden(true)
        .onChange(of: viewModel.registrationCompleted) { completed in
            if completed {
                print("🎉 Registration completed, starting redirect timer...")
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                    print("🔄 Redirecting to main app...")
                    withAnimation(.easeInOut(duration: 0.3)) {
                        authViewModel.isAuthenticated = true
                    }
                    
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        dismiss()
                    }
                }
            }
        }
    }
    
    // MARK: - Computed Properties
    private var showOverlays: Bool {
        viewModel.isLoading || viewModel.registrationCompleted || viewModel.showError
    }
    
    // MARK: - Header Section - FIXED VERSION WITHOUT LANGUAGE PICKER
    private var headerSection: some View {
        VStack(spacing: 16) {
            // Top Row: Only Back button now - language picker moved to separate overlay
            HStack {
                // Back Button
                Button(action: {
                    if !viewModel.isLoading {
                        if viewModel.currentStep == .basicInfo {
                            dismiss()
                        } else {
                            viewModel.goToPreviousStep()
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
            .frame(height: 32) // Fixed height to prevent layout shifts
            
            // Progress Section
            VStack(spacing: 12) {
                // Progress Line
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 2)
                        .fill(Color.white.opacity(0.4))
                        .frame(height: 4)
                    
                    RoundedRectangle(cornerRadius: 2)
                        .fill(
                            LinearGradient(
                                colors: [.primaryOrange, .primaryOrange.opacity(0.8)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: CGFloat(viewModel.currentStep.rawValue + 1) / CGFloat(UpdatedRegistrationStep.allCases.count) * UIScreen.main.bounds.width * 0.7, height: 4)
                        .animation(.easeInOut(duration: 0.5), value: viewModel.currentStep)
                }
                .frame(maxWidth: .infinity)
                
                // Current step info
                HStack {
                    Text("Step \(viewModel.currentStep.rawValue + 1) of \(UpdatedRegistrationStep.allCases.count)")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.black)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                    
                    Spacer()
                    
                    Text(viewModel.currentStep.title.localized(using: localizationManager))
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.black)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                }
            }
        }
    }
    
    // MARK: - Custom Step Visual
    private var customStepVisual: some View {
        Group {
            switch viewModel.currentStep {
            case .basicInfo:
                UserCreationVisual()
            case .location:
                LocationVisual()
            case .sportsPreferences:
                SportsVisual()
            }
        }
        .frame(height: 80)
        .animation(.easeInOut(duration: 0.5), value: viewModel.currentStep)
    }
    
    // MARK: - Navigation Buttons
    private var navigationButtonsSection: some View {
        VStack(spacing: 12) {
            // Next/Complete Button
            Button(action: {
                handleNextButtonTap()
            }) {
                HStack {
                    if viewModel.isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .scaleEffect(0.8)
                    } else {
                        if viewModel.isLastStep {
                            Image(systemName: "sparkles")
                                .font(.system(size: 16))
                        } else {
                            Image(systemName: "arrow.right")
                                .font(.system(size: 16))
                        }
                    }
                    
                    Text(viewModel.isLastStep ? "Complete Registration" : "Continue")
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
            
            // Back Button (only when not first step)
            if viewModel.currentStep != .basicInfo {
                Button(action: {
                    if !viewModel.isLoading {
                        viewModel.goToPreviousStep()
                    }
                }) {
                    HStack(spacing: 6) {
                        Image(systemName: "arrow.left")
                            .font(.system(size: 12, weight: .medium))
                        
                        Text("Previous")
                            .font(.system(size: 14, weight: .medium))
                    }
                    .foregroundColor(.primaryOrange)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                    .background(
                        RoundedRectangle(cornerRadius: 20)
                            .fill(Color.white)
                            .shadow(color: .primaryOrange.opacity(0.2), radius: 4, x: 0, y: 2)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(Color.primaryOrange.opacity(0.3), lineWidth: 1)
                    )
                }
                .disabled(viewModel.isLoading)
            }
        }
    }
    
    // MARK: - Button Action Handler
    private func handleNextButtonTap() {
        print("📱 Next button tapped - Current step: \(viewModel.currentStep), Can proceed: \(viewModel.canProceedToNextStep)")
        
        guard viewModel.canProceedToNextStep && !viewModel.isLoading else {
            print("⚠️ Cannot proceed - validation failed or already loading")
            return
        }
        
        viewModel.proceedToNextStep()
    }
    
    // MARK: - Overlays
    private var registrationSuccessOverlay: some View {
        ZStack {
            Color.black.opacity(0.8)
                .ignoresSafeArea()
            
            VStack(spacing: 24) {
                SuccessVisual()
                    .scaleEffect(1.5)
                
                VStack(spacing: 12) {
                    Text("Welcome to BuddyBuilder!")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                    
                    Text("Your account has been created successfully")
                        .font(.system(size: 14))
                        .foregroundColor(.white.opacity(0.8))
                        .multilineTextAlignment(.center)
                }
                .padding(.horizontal, 40)
                
                VStack(spacing: 8) {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .scaleEffect(1.2)
                    
                    Text("Logging you in...")
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
        .zIndex(1000)
    }
    
    private var loadingOverlay: some View {
        ZStack {
            Color.black.opacity(0.5)
                .ignoresSafeArea()
            
            VStack(spacing: 16) {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .primaryOrange))
                    .scaleEffect(1.5)
                
                Text("Creating your account...")
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
                
                Text("Registration Error")
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
