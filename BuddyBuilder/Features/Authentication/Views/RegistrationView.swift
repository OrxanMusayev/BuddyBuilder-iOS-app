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
                
                // Main Content - NO ScrollView, fixed height
                VStack(spacing: 0) {
                    Spacer(minLength: 80)
                    
                    // Registration Card - Takes most space
                    registrationCard
                        .frame(maxHeight: .infinity)
                        .padding(.horizontal, 20)
                    
                    Spacer(minLength: 50)
                }
                
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
        }
        .ignoresSafeArea()
        .navigationBarBackButtonHidden(true)
        .onChange(of: viewModel.registrationCompleted) { completed in
            if completed {
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                    authViewModel.isAuthenticated = true
                    dismiss()
                }
            }
        }
    }
    
    // MARK: - Main Registration Card
    private var registrationCard: some View {
        VStack(spacing: 0) {
            // Header Section - Inside Card
            cardHeader
                .padding(.bottom, 24)
            
            // Custom Step Icon/Visual
            customStepVisual
                .padding(.bottom, 20)
            
            // Step Content
            VStack(spacing: 16) {
                Group {
                    switch viewModel.currentStep {
                    case .basicInfo:
                        CompactBasicInfoStepView(viewModel: viewModel)
                            .environmentObject(localizationManager)
                        
                    case .location:
                        CompactLocationStepView(viewModel: viewModel)
                            .environmentObject(localizationManager)
                        
                    case .sportsPreferences:
                        CompactSportsPreferencesStepView(viewModel: viewModel)
                            .environmentObject(localizationManager)
                        
                    case .profile:
                        CompactProfileStepView(viewModel: viewModel)
                            .environmentObject(localizationManager)
                        
                    case .verification:
                        CompactVerificationStepView(viewModel: viewModel)
                            .environmentObject(localizationManager)
                    }
                }
                .animation(.easeInOut(duration: 0.3), value: viewModel.currentStep)
            }
            .frame(maxHeight: .infinity)
            
            // Navigation Buttons
            navigationButtonsSection
                .padding(.top, 20)
        }
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 18)
                .fill(Color.white)
                .shadow(color: .black.opacity(0.1), radius: 15, x: 0, y: 5)
        )
    }
    
    // MARK: - Card Header (Back button, Language, Progress inside card)
    private var cardHeader: some View {
        VStack(spacing: 16) {
            // Top row: Back button and Language picker
            HStack {
                // Back Button
                Button(action: {
                    dismiss()
                }) {
                    HStack(spacing: 8) {
                        Image(systemName: "arrow.left")
                            .font(.system(size: 14, weight: .medium))
                        
                        Text("Back")
                            .font(.system(size: 14, weight: .medium))
                    }
                    .foregroundColor(.primaryOrange)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color.primaryOrange.opacity(0.1))
                    )
                }
                
                Spacer()
                
                // Language Picker - Now inside card, dropdown will go down
                CompactLanguagePicker(localizationManager: localizationManager)
            }
            
            // Progress Section with smooth line
            VStack(spacing: 12) {
                // Progress Line
                ZStack(alignment: .leading) {
                    // Background line
                    RoundedRectangle(cornerRadius: 2)
                        .fill(Color.gray.opacity(0.2))
                        .frame(height: 4)
                    
                    // Progress line with gradient
                    RoundedRectangle(cornerRadius: 2)
                        .fill(
                            LinearGradient(
                                colors: [.primaryOrange, .primaryOrange.opacity(0.7)],
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
                        .foregroundColor(.textSecondary)
                    
                    Spacer()
                    
                    Text(viewModel.currentStep.title.localized(using: localizationManager))
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.primaryOrange)
                }
            }
        }
    }
    
    // MARK: - Custom Step Visual (Unique designs for each step)
    private var customStepVisual: some View {
        Group {
            switch viewModel.currentStep {
            case .basicInfo:
                UserCreationVisual()
            case .location:
                LocationVisual()
            case .sportsPreferences:
                SportsVisual()
            case .profile:
                ProfileVisual()
            case .verification:
                SuccessVisual()
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
                viewModel.proceedToNextStep()
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
                    viewModel.goToPreviousStep()
                }) {
                    HStack(spacing: 6) {
                        Image(systemName: "arrow.left")
                            .font(.system(size: 12, weight: .medium))
                        
                        Text("Previous")
                            .font(.system(size: 14, weight: .medium))
                    }
                    .foregroundColor(.textSecondary)
                }
                .disabled(viewModel.isLoading)
            }
        }
    }
    
    // MARK: - Overlays
    private var registrationSuccessOverlay: some View {
        ZStack {
            Color.black.opacity(0.7)
                .ignoresSafeArea()
            
            VStack(spacing: 24) {
                SuccessVisual()
                    .scaleEffect(1.5)
                
                VStack(spacing: 12) {
                    Text("Welcome to BuddyBuilder!")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                    
                    Text("Your account has been created successfully")
                        .font(.system(size: 16))
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
    }
    
    private var loadingOverlay: some View {
        ZStack {
            Color.black.opacity(0.3)
                .ignoresSafeArea()
            
            VStack(spacing: 16) {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .primaryOrange))
                    .scaleEffect(1.5)
                
                Text("Creating your account...")
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
                
                Text("Registration Error")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.textPrimary)
                
                Text(viewModel.errorMessage)
                    .font(.system(size: 14))
                    .foregroundColor(.textSecondary)
                    .multilineTextAlignment(.center)
                    .lineLimit(nil)
                
                Button("OK") {
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

// MARK: - Custom Step Visuals
struct UserCreationVisual: View {
    @State private var isAnimating = false
    
    var body: some View {
        ZStack {
            // Background circles
            Circle()
                .fill(LinearGradient(colors: [.blue.opacity(0.1), .purple.opacity(0.1)], startPoint: .topLeading, endPoint: .bottomTrailing))
                .frame(width: 80, height: 80)
                .scaleEffect(isAnimating ? 1.1 : 1.0)
            
            Circle()
                .fill(LinearGradient(colors: [.primaryOrange.opacity(0.2), .pink.opacity(0.2)], startPoint: .topLeading, endPoint: .bottomTrailing))
                .frame(width: 60, height: 60)
                .scaleEffect(isAnimating ? 0.9 : 1.0)
            
            // User icon with sparkles
            ZStack {
                Image(systemName: "person.fill")
                    .font(.system(size: 28, weight: .medium))
                    .foregroundColor(.primaryOrange)
                
                // Floating sparkles
                ForEach(0..<3, id: \.self) { index in
                    Image(systemName: "sparkle")
                        .font(.system(size: 8))
                        .foregroundColor(.primaryOrange.opacity(0.8))
                        .offset(
                            x: cos(Double(index) * 2 * .pi / 3) * 25,
                            y: sin(Double(index) * 2 * .pi / 3) * 25
                        )
                        .scaleEffect(isAnimating ? 1.2 : 0.8)
                        .opacity(isAnimating ? 1.0 : 0.6)
                        .animation(
                            .easeInOut(duration: 1.5)
                                .repeatForever(autoreverses: true)
                                .delay(Double(index) * 0.2),
                            value: isAnimating
                        )
                }
            }
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true)) {
                isAnimating = true
            }
        }
    }
}

struct LocationVisual: View {
    @State private var isAnimating = false
    
    var body: some View {
        ZStack {
            // Map background
            RoundedRectangle(cornerRadius: 16)
                .fill(LinearGradient(colors: [.green.opacity(0.1), .blue.opacity(0.1)], startPoint: .topLeading, endPoint: .bottomTrailing))
                .frame(width: 70, height: 50)
            
            // Pin with bounce animation
            VStack(spacing: 2) {
                Image(systemName: "mappin.and.ellipse")
                    .font(.system(size: 28, weight: .medium))
                    .foregroundColor(.red)
                    .scaleEffect(isAnimating ? 1.1 : 1.0)
                    .offset(y: isAnimating ? -2 : 0)
            }
            
            // Ripple effect
            Circle()
                .stroke(Color.red.opacity(0.3), lineWidth: 2)
                .frame(width: isAnimating ? 60 : 30, height: isAnimating ? 60 : 30)
                .opacity(isAnimating ? 0.0 : 0.8)
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 1.5).repeatForever()) {
                isAnimating = true
            }
        }
    }
}

struct SportsVisual: View {
    @State private var isAnimating = false
    
    var body: some View {
        HStack(spacing: 8) {
            // Sports equipment icons floating
            ForEach(["basketball.fill", "tennis.racket", "figure.run"], id: \.self) { icon in
                Image(systemName: icon)
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(.primaryOrange)
                    .scaleEffect(isAnimating ? 1.2 : 1.0)
                    .rotationEffect(.degrees(isAnimating ? 10 : -10))
                    .animation(
                        .easeInOut(duration: 1.0)
                            .repeatForever(autoreverses: true)
                            .delay(Double.random(in: 0...0.5)),
                        value: isAnimating
                    )
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            Capsule()
                .fill(LinearGradient(colors: [.primaryOrange.opacity(0.1), .pink.opacity(0.1)], startPoint: .leading, endPoint: .trailing))
        )
        .onAppear {
            isAnimating = true
        }
    }
}

struct ProfileVisual: View {
    @State private var isAnimating = false
    
    var body: some View {
        ZStack {
            // Profile card background
            RoundedRectangle(cornerRadius: 12)
                .fill(LinearGradient(colors: [.primaryOrange.opacity(0.1), .purple.opacity(0.1)], startPoint: .topLeading, endPoint: .bottomTrailing))
                .frame(width: 80, height: 60)
                .rotationEffect(.degrees(isAnimating ? 2 : -2))
            
            VStack(spacing: 4) {
                // Profile picture
                Circle()
                    .fill(Color.primaryOrange.opacity(0.3))
                    .frame(width: 24, height: 24)
                    .overlay(
                        Image(systemName: "person.fill")
                            .font(.system(size: 12))
                            .foregroundColor(.primaryOrange)
                    )
                
                // Profile lines
                HStack(spacing: 2) {
                    Rectangle()
                        .fill(Color.primaryOrange.opacity(0.6))
                        .frame(width: 20, height: 2)
                        .clipShape(Capsule())
                    
                    Rectangle()
                        .fill(Color.primaryOrange.opacity(0.4))
                        .frame(width: 15, height: 2)
                        .clipShape(Capsule())
                }
                
                Rectangle()
                    .fill(Color.primaryOrange.opacity(0.3))
                    .frame(width: 25, height: 2)
                    .clipShape(Capsule())
            }
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true)) {
                isAnimating = true
            }
        }
    }
}

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

// MARK: - Compact Step Views
struct CompactBasicInfoStepView: View {
    @ObservedObject var viewModel: RegistrationViewModel
    @EnvironmentObject var localizationManager: LocalizationManager
    
    var body: some View {
        VStack(spacing: 14) {
            CustomTextFieldNoTitle(
                text: $viewModel.formData.userName,
                icon: "person.fill",
                placeholder: "Username",
                hasError: viewModel.usernameError
            )
            
            CustomTextFieldNoTitle(
                text: $viewModel.formData.email,
                icon: "envelope.fill",
                placeholder: "Email",
                hasError: viewModel.emailError
            )
            
            CustomPasswordFieldNoTitle(
                text: $viewModel.formData.password,
                showPassword: $viewModel.showPassword,
                placeholder: "Password",
                hasError: viewModel.passwordError
            )
            
            CustomPasswordFieldNoTitle(
                text: $viewModel.formData.confirmPassword,
                showPassword: $viewModel.showConfirmPassword,
                placeholder: "Confirm Password",
                hasError: viewModel.confirmPasswordError
            )
        }
    }
}

struct CompactLocationStepView: View {
    @ObservedObject var viewModel: RegistrationViewModel
    @EnvironmentObject var localizationManager: LocalizationManager
    
    var body: some View {
        VStack(spacing: 14) {
            // Country Selection
            Menu {
                ForEach(viewModel.availableCountries) { country in
                    Button(country.name) {
                        viewModel.formData.selectedCountry = country
                    }
                }
            } label: {
                HStack(spacing: 12) {
                    Image(systemName: "globe")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.textSecondary)
                        .frame(width: 20)
                    
                    Text(viewModel.formData.selectedCountry?.name ?? "Select Country")
                        .font(.system(size: 16))
                        .foregroundColor(viewModel.formData.selectedCountry != nil ? .textPrimary : .textSecondary)
                    
                    Spacer()
                    
                    Image(systemName: "chevron.down")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.textSecondary)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 14)
                .background(Color.formBackground)
                .clipShape(RoundedRectangle(cornerRadius: 25))
                .overlay(
                    RoundedRectangle(cornerRadius: 25)
                        .stroke(Color.formBorder, lineWidth: 1)
                )
            }
            
            // City Selection
            Menu {
                ForEach(viewModel.availableCities) { city in
                    Button(city.name) {
                        viewModel.formData.selectedCity = city
                    }
                }
            } label: {
                HStack(spacing: 12) {
                    Image(systemName: "building.2")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.textSecondary)
                        .frame(width: 20)
                    
                    Text(viewModel.formData.selectedCity?.name ?? "Select City")
                        .font(.system(size: 16))
                        .foregroundColor(viewModel.formData.selectedCity != nil ? .textPrimary : .textSecondary)
                    
                    Spacer()
                    
                    Image(systemName: "chevron.down")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.textSecondary)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 14)
                .background(Color.formBackground)
                .clipShape(RoundedRectangle(cornerRadius: 25))
                .overlay(
                    RoundedRectangle(cornerRadius: 25)
                        .stroke(Color.formBorder, lineWidth: 1)
                )
            }
            .disabled(viewModel.formData.selectedCountry == nil)
            
            // District field - now optional with placeholder text showing it's optional
            CustomTextFieldNoTitle(
                text: $viewModel.formData.district,
                icon: "location.fill",
                placeholder: "District (Optional)",
                hasError: false // Removed error checking since it's optional
            )
        }
    }
}

struct CompactSportsPreferencesStepView: View {
    @ObservedObject var viewModel: RegistrationViewModel
    @EnvironmentObject var localizationManager: LocalizationManager
    
    var body: some View {
        VStack(spacing: 16) {
            Text("Select your favorite sports (\(viewModel.formData.selectedSports.count))")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.textPrimary)
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 8) {
                ForEach(viewModel.availableSports.prefix(6), id: \.id) { sport in
                    CompactSportCard(
                        sport: sport,
                        isSelected: viewModel.formData.selectedSports.contains { $0.sport.id == sport.id },
                        action: {
                            viewModel.toggleSportSelection(sport)
                        }
                    )
                }
            }
        }
    }
}

struct CompactSportCard: View {
    let sport: Sport
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: sportIcon(for: sport.name))
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(isSelected ? .primaryOrange : .textSecondary)
                
                Text(sport.name)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(isSelected ? .primaryOrange : .textPrimary)
                    .lineLimit(1)
            }
            .padding(12)
            .frame(maxWidth: .infinity, minHeight: 80)
            .background(isSelected ? Color.primaryOrange.opacity(0.1) : Color.formBackground)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Color.primaryOrange : Color.formBorder, lineWidth: isSelected ? 2 : 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private func sportIcon(for sportName: String) -> String {
        switch sportName.lowercased() {
        case "basketball": return "basketball.fill"
        case "tennis": return "tennis.racket"
        case "soccer": return "soccerball"
        case "swimming": return "figure.pool.swim"
        case "volleyball": return "volleyball.fill"
        case "running": return "figure.run"
        case "cycling": return "bicycle"
        case "fitness": return "dumbbell.fill"
        default: return "sportscourt.fill"
        }
    }
}

struct CompactProfileStepView: View {
    @ObservedObject var viewModel: RegistrationViewModel
    @EnvironmentObject var localizationManager: LocalizationManager
    
    var body: some View {
        VStack(spacing: 14) {
            // Bio
            VStack(alignment: .leading, spacing: 8) {
                Text("Tell us about yourself")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.textPrimary)
                    .padding(.leading, 16)
                
                TextEditor(text: $viewModel.formData.bio)
                    .font(.system(size: 16))
                    .foregroundColor(.textPrimary)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .frame(height: 80)
                    .background(Color.formBackground)
                    .clipShape(RoundedRectangle(cornerRadius: 20))
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(Color.formBorder, lineWidth: 1)
                    )
            }
            
            // About Me
            VStack(alignment: .leading, spacing: 8) {
                Text("Your sports story")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.textPrimary)
                    .padding(.leading, 16)
                
                TextEditor(text: $viewModel.formData.aboutMe)
                    .font(.system(size: 16))
                    .foregroundColor(.textPrimary)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .frame(height: 80)
                    .background(Color.formBackground)
                    .clipShape(RoundedRectangle(cornerRadius: 20))
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(Color.formBorder, lineWidth: 1)
                    )
            }
        }
    }
}

struct CompactVerificationStepView: View {
    @ObservedObject var viewModel: RegistrationViewModel
    @EnvironmentObject var localizationManager: LocalizationManager
    
    var body: some View {
        VStack(spacing: 20) {
            VStack(spacing: 12) {
                Text("Almost Done!")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.textPrimary)
                    .multilineTextAlignment(.center)
                
                Text("Review your information and complete registration")
                    .font(.system(size: 14))
                    .foregroundColor(.textSecondary)
                    .multilineTextAlignment(.center)
            }
            
            // Summary card with fixed colors
            VStack(spacing: 12) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Username")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(.secondary)
                        Text(viewModel.formData.userName)
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.primary)
                    }
                    Spacer()
                    VStack(alignment: .trailing, spacing: 4) {
                        Text("Sports")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(.secondary)
                        Text("\(viewModel.formData.selectedSports.count) selected")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.primaryOrange)
                    }
                }
                
                Divider()
                    .background(Color.gray.opacity(0.3))
                
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Email")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(.secondary)
                        Text(viewModel.formData.email)
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.primary)
                            .lineLimit(1)
                    }
                    Spacer()
                    VStack(alignment: .trailing, spacing: 4) {
                        Text("Location")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(.secondary)
                        Text(viewModel.formData.selectedCity?.name ?? "Not set")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.primary)
                    }
                }
            }
            .padding(16)
            .background(Color(UIColor.systemGray6))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color(UIColor.systemGray4), lineWidth: 1)
            )
        }
    }
}
