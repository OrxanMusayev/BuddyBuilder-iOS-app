// BuddyBuilder/Features/Authentication/Views/RegistrationView.swift

import SwiftUI

struct RegistrationView: View {
    @StateObject private var viewModel = RegistrationViewModel()
    @EnvironmentObject var authViewModel: AuthenticationViewModel
    @EnvironmentObject var localizationManager: LocalizationManager
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Background
                LoginBackgroundView()
                    .ignoresSafeArea(.all)
                
                // Main Content - Full Screen Layout (No Card)
                VStack(spacing: 0) {
                    // Header Section - Top of screen
                    headerSection
                        .padding(.horizontal, 20)
                        .padding(.top, 60) // Safe area top padding
                    
                    // Custom Step Icon/Visual
                    customStepVisual
                        .padding(.bottom, 20)
                    
                    // Step Content - Scrollable if needed
                    ScrollView(showsIndicators: false) {
                        VStack(spacing: 20) {
                            Group {
                                switch viewModel.currentStep {
                                case .basicInfo:
                                    CompactBasicInfoStepView(viewModel: viewModel)
                                        .environmentObject(localizationManager)
                                    
                                case .sportsPreferences:
                                    CompactSportsPreferencesStepView(viewModel: viewModel)
                                        .environmentObject(localizationManager)
                                }
                            }
                            .animation(.easeInOut(duration: 0.3), value: viewModel.currentStep)
                        }
                        .padding(.horizontal, 20)
                    }
                    .frame(maxHeight: .infinity)
                    
                    // Navigation Buttons - Bottom of screen
                    navigationButtonsSection
                        .padding(.horizontal, 20)
                        .padding(.bottom, 40) // Safe area bottom padding
                }
                .opacity(showOverlays ? 0.3 : 1.0)
                .disabled(showOverlays)
                
                // Success Overlay
                if viewModel.registrationCompleted {
                    registrationSuccessOverlay
                }
                
                // Loading Overlay
                if viewModel.isLoading && !viewModel.registrationCompleted {
                    loadingOverlay
                }
                
                // Error Alert
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
                    
                    // Small delay to ensure animation completes
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        dismiss()
                    }
                }
            }
        }
        .onChange(of: authViewModel.isAuthenticated) { isAuth in
            // Safety check: if somehow auth state changes, dismiss
            if isAuth {
                print("🔐 Auth state changed to authenticated, dismissing registration")
                dismiss()
            }
        }
        .onChange(of: viewModel.isLoading) { loading in
            print("🔄 Loading state changed: \(loading)")
        }
        .onChange(of: viewModel.showError) { showError in
            print("❌ Error state changed: \(showError)")
        }
    }
    
    // MARK: - Computed Properties
    private var showOverlays: Bool {
        viewModel.isLoading || viewModel.registrationCompleted || viewModel.showError
    }
    
    // MARK: - Header Section (No Card Background)
    private var headerSection: some View {
        VStack(spacing: 16) {
            // Top row: Back button and Language picker
            HStack {
                // Back Button - Simple orange arrow (no background)
                Button(action: {
                    if !viewModel.isLoading {
                        dismiss()
                    }
                }) {
                    Image(systemName: "arrow.left")
                        .font(.system(size: 20, weight: .medium))
                        .foregroundColor(.primaryOrange)
                }
                .disabled(viewModel.isLoading)
                
                Spacer()
                
                // Language Picker
                CompactLanguagePicker(localizationManager: localizationManager)
                    .disabled(viewModel.isLoading)
            }
            
            // Progress Section with smooth line
            VStack(spacing: 12) {
                // Progress Line
                ZStack(alignment: .leading) {
                    // Background line
                    RoundedRectangle(cornerRadius: 2)
                        .fill(Color.white.opacity(0.4))
                        .frame(height: 4)
                    
                    // Progress line with gradient
                    RoundedRectangle(cornerRadius: 2)
                        .fill(
                            LinearGradient(
                                colors: [.primaryOrange, .primaryOrange.opacity(0.8)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: CGFloat(viewModel.currentStep.rawValue + 1) / CGFloat(RegistrationStep.allCases.count) * UIScreen.main.bounds.width * 0.7, height: 4)
                        .animation(.easeInOut(duration: 0.5), value: viewModel.currentStep)
                }
                .frame(maxWidth: .infinity)
                
                // Current step info
                HStack {
                    Text("Step \(viewModel.currentStep.rawValue + 1) of \(RegistrationStep.allCases.count)")
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
                    .foregroundColor(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(
                        RoundedRectangle(cornerRadius: 20)
                            .fill(Color.white.opacity(0.2))
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
            SuccessVisualModern()
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

// MARK: - User Creation Visual - STABLE VERSION (No Animation, No Sparkles)
struct UserCreationVisual: View {
    var body: some View {
        ZStack {
            // Static background circle
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
            
            // Main content
            ZStack {
                // Document background
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.white)
                    .frame(width: 40, height: 50)
                    .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
                
                // Document lines - STATIC
                VStack(spacing: 3) {
                    ForEach(0..<4, id: \.self) { _ in
                        RoundedRectangle(cornerRadius: 0.5)
                            .fill(Color.gray.opacity(0.3))
                            .frame(width: 28, height: 2)
                    }
                }
                .offset(y: -5)
                
                // Pencil - STATIC (no animation)
                ZStack {
                    RoundedRectangle(cornerRadius: 2)
                        .fill(
                            LinearGradient(
                                colors: [.primaryOrange, .primaryOrange.opacity(0.8)],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .frame(width: 3, height: 20)
                    
                    Circle()
                        .fill(Color.primaryOrange)
                        .frame(width: 4, height: 4)
                        .offset(y: -12)
                }
                .rotationEffect(.degrees(-30))
                .offset(x: 15, y: 15)
                
                // NO SPARKLES - completely removed
            }
        }
    }
}

// MARK: - Sports Visual - NEW MODERN DESIGN
struct SportsVisual: View {
    var body: some View {
        ZStack {
            // Background circle (consistent with UserCreationVisual)
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
            
            // Main content
            ZStack {
                // Modern card background
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.white)
                    .frame(width: 45, height: 45)
                    .shadow(color: .black.opacity(0.1), radius: 6, x: 0, y: 3)
                
                // Sport icons grid (2x2)
                VStack(spacing: 4) {
                    HStack(spacing: 4) {
                        Image(systemName: "basketball.fill")
                            .font(.system(size: 8, weight: .medium))
                            .foregroundColor(.primaryOrange)
                        
                        Image(systemName: "tennis.racket")
                            .font(.system(size: 8, weight: .medium))
                            .foregroundColor(.primaryOrange.opacity(0.7))
                    }
                    
                    HStack(spacing: 4) {
                        Image(systemName: "figure.run")
                            .font(.system(size: 8, weight: .medium))
                            .foregroundColor(.primaryOrange.opacity(0.7))
                        
                        Image(systemName: "dumbbell.fill")
                            .font(.system(size: 8, weight: .medium))
                            .foregroundColor(.primaryOrange)
                    }
                }
                
                // Selection indicator (bottom right corner)
                Circle()
                    .fill(Color.primaryOrange)
                    .frame(width: 12, height: 12)
                    .overlay(
                        Image(systemName: "checkmark")
                            .font(.system(size: 6, weight: .bold))
                            .foregroundColor(.white)
                    )
                    .offset(x: 14, y: 14)
            }
        }
    }
}

// MARK: - Success Visual Component (from RegistrationView.swift)

struct SuccessVisual: View {
    @State private var isAnimating = false
    
    var body: some View {
        ZStack {
            // Success burst background
            ForEach(0..<8, id: \.self) { index in
                Rectangle()
                    .fill(LinearGradient(colors: [.green, .green.opacity(0.3)], startPoint: .leading, endPoint: .trailing))
                    .frame(width: 30, height: 3)
                    .offset(x: 15)
                    .rotationEffect(.degrees(Double(index) * 45))
                    .scaleEffect(isAnimating ? 1.2 : 0.8)
                    .opacity(isAnimating ? 1.0 : 0.6)
            }
            
            // Central checkmark
            Circle()
                .fill(LinearGradient(colors: [.green, .green.opacity(0.8)], startPoint: .topLeading, endPoint: .bottomTrailing))
                .frame(width: 50, height: 50)
                .overlay(
                    Image(systemName: "checkmark")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.white)
                )
                .scaleEffect(isAnimating ? 1.1 : 1.0)
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true)) {
                isAnimating = true
            }
        }
    }
}

// MARK: - Static Success Visual (Alternative - No Animation)
struct SuccessVisualStatic: View {
    var body: some View {
        ZStack {
            // Static success burst background
            ForEach(0..<8, id: \.self) { index in
                Rectangle()
                    .fill(LinearGradient(colors: [.green, .green.opacity(0.3)], startPoint: .leading, endPoint: .trailing))
                    .frame(width: 30, height: 3)
                    .offset(x: 15)
                    .rotationEffect(.degrees(Double(index) * 45))
            }
            
            // Static central checkmark
            Circle()
                .fill(LinearGradient(colors: [.green, .green.opacity(0.8)], startPoint: .topLeading, endPoint: .bottomTrailing))
                .frame(width: 50, height: 50)
                .overlay(
                    Image(systemName: "checkmark")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.white)
                )
        }
    }
}

// MARK: - Modern Success Visual (Alternative Design)
struct SuccessVisualModern: View {
    var body: some View {
        ZStack {
            // Modern circular background
            Circle()
                .fill(
                    RadialGradient(
                        colors: [.green.opacity(0.2), .green.opacity(0.05)],
                        center: .center,
                        startRadius: 10,
                        endRadius: 40
                    )
                )
                .frame(width: 80, height: 80)
            
            // Success badge
            ZStack {
                Circle()
                    .fill(Color.white)
                    .frame(width: 50, height: 50)
                    .shadow(color: .green.opacity(0.3), radius: 8, x: 0, y: 4)
                
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 32, weight: .medium))
                    .foregroundColor(.green)
            }
        }
    }
}
