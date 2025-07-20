// BuddyBuilder/Features/Authentication/Views/RegistrationStepViews.swift

import SwiftUI

// MARK: - Basic Info Step (Only Essential Fields)
struct BasicInfoStepView: View {
    @ObservedObject var viewModel: RegistrationViewModel
    @EnvironmentObject var localizationManager: LocalizationManager
    
    var body: some View {
        VStack(spacing: 20) {
            // Username Field
            VStack(alignment: .leading, spacing: 8) {
                CustomTextFieldNoTitle(
                    text: $viewModel.formData.userName,
                    icon: "person.fill",
                    placeholder: "registration.username.placeholder".localized(using: localizationManager),
                    hasError: viewModel.usernameError
                )
                
                // Username availability indicator
                if !viewModel.formData.userName.isEmpty && viewModel.formData.userName.count >= 3 {
                    HStack(spacing: 6) {
                        if viewModel.usernameAvailability == .checking {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .orange))
                                .scaleEffect(0.6)
                        } else {
                            Image(systemName: viewModel.usernameAvailability.icon)
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(viewModel.usernameAvailability.color)
                        }
                        
                        Text(viewModel.usernameAvailability.usernameMessage(using: localizationManager))
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(viewModel.usernameAvailability.color)
                    }
                    .padding(.leading, 16)
                }
            }
            
            // Email Field
            VStack(alignment: .leading, spacing: 8) {
                CustomTextFieldNoTitle(
                    text: $viewModel.formData.email,
                    icon: "envelope.fill",
                    placeholder: "registration.email.placeholder".localized(using: localizationManager),
                    hasError: viewModel.emailError
                )
                
                // Email availability indicator
                if !viewModel.formData.email.isEmpty && viewModel.formData.email.contains("@") {
                    HStack(spacing: 6) {
                        if viewModel.emailAvailability == .checking {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .orange))
                                .scaleEffect(0.6)
                        } else {
                            Image(systemName: viewModel.emailAvailability.icon)
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(viewModel.emailAvailability.color)
                        }
                        
                        Text(viewModel.emailAvailability.emailMessage(using: localizationManager))
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(viewModel.emailAvailability.color)
                    }
                    .padding(.leading, 16)
                }
            }
            
            // Password Field
            CustomPasswordFieldNoTitle(
                text: $viewModel.formData.password,
                showPassword: $viewModel.showPassword,
                placeholder: "registration.password.placeholder".localized(using: localizationManager),
                hasError: viewModel.passwordError
            )
            
            // Confirm Password Field
            CustomPasswordFieldNoTitle(
                text: $viewModel.formData.confirmPassword,
                showPassword: $viewModel.showConfirmPassword,
                placeholder: "registration.confirm_password.placeholder".localized(using: localizationManager),
                hasError: viewModel.confirmPasswordError
            )
            
            // Enhanced Password requirements validation
            if !viewModel.formData.password.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("registration.password.requirements".localized(using: localizationManager))
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.textSecondary)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        PasswordRequirementRow(
                            text: "registration.password.min_8_chars".localized(using: localizationManager),
                            isValid: viewModel.formData.passwordHasMinLength()
                        )
                        
                        PasswordRequirementRow(
                            text: "registration.password.lowercase".localized(using: localizationManager),
                            isValid: viewModel.formData.passwordHasLowercase()
                        )
                        
                        PasswordRequirementRow(
                            text: "registration.password.uppercase".localized(using: localizationManager),
                            isValid: viewModel.formData.passwordHasUppercase()
                        )
                        
                        PasswordRequirementRow(
                            text: "registration.password.number".localized(using: localizationManager),
                            isValid: viewModel.formData.passwordHasNumber()
                        )
                        
                        // Password match indicator (only show if confirm password is not empty)
                        if !viewModel.formData.confirmPassword.isEmpty {
                            PasswordRequirementRow(
                                text: "registration.password.match".localized(using: localizationManager),
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

// MARK: - Sports Preferences Step (Original Simple Version)
struct SportsPreferencesStepView: View {
    @ObservedObject var viewModel: RegistrationViewModel
    @EnvironmentObject var localizationManager: LocalizationManager
    
    var body: some View {
        VStack(spacing: 20) {
            // Overall Experience Level
            VStack(alignment: .leading, spacing: 12) {
                Text("registration.overall_experience".localized(using: localizationManager))
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.textPrimary)
                    .padding(.leading, 16)
                
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 8) {
                    ForEach(RegistrationExperienceLevel.allCases, id: \.self) { level in
                        Button(action: {
                            viewModel.formData.overallExperienceLevel = level
                        }) {
                            VStack(spacing: 8) {
                                Text(level.displayName.localized(using: localizationManager))
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(viewModel.formData.overallExperienceLevel == level ? .white : .textPrimary)
                                
                                Text(level.description.localized(using: localizationManager))
                                    .font(.system(size: 11))
                                    .foregroundColor(viewModel.formData.overallExperienceLevel == level ? .white.opacity(0.8) : .textSecondary)
                                    .multilineTextAlignment(.center)
                                    .lineLimit(2)
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 12)
                            .frame(minHeight: 80)
                            .background(viewModel.formData.overallExperienceLevel == level ? Color.primaryOrange : Color.formBackground)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(viewModel.formData.overallExperienceLevel == level ? Color.primaryOrange : Color.formBorder, lineWidth: 1)
                            )
                        }
                    }
                }
            }
            
            // Sports Selection
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text("registration.select_sports".localized(using: localizationManager))
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.textPrimary)
                    
                    Spacer()
                    
                    Text("(\(viewModel.formData.selectedSports.count))")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.textSecondary)
                }
                .padding(.leading, 16)
                
                if viewModel.sportsError {
                    Text("registration.error.select_at_least_one_sport".localized(using: localizationManager))
                        .font(.system(size: 12))
                        .foregroundColor(.red)
                        .padding(.leading, 16)
                }
                
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 8) {
                    ForEach(viewModel.availableSports, id: \.id) { sport in
                        SportSelectionCard(
                            sport: sport,
                            isSelected: viewModel.formData.selectedSports.contains { $0.sport.id == sport.id },
                            action: {
                                viewModel.toggleSportSelection(sport)
                            }
                        )
                        .environmentObject(localizationManager)
                    }
                }
            }
        }
    }
}

// MARK: - Helper Components

// Enhanced Password Requirement Row with Animation
struct PasswordRequirementRow: View {
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

// Sport Selection Card (Original Version)
struct SportSelectionCard: View {
    let sport: Sport
    let isSelected: Bool
    let action: () -> Void
    @EnvironmentObject var localizationManager: LocalizationManager
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 12) {
                // Sport Icon
                ZStack {
                    Circle()
                        .fill(isSelected ? Color.primaryOrange.opacity(0.2) : Color.formBackground)
                        .frame(width: 50, height: 50)
                    
                    Image(systemName: sportIcon(for: sport.name))
                        .font(.system(size: 24, weight: .medium))
                        .foregroundColor(isSelected ? .primaryOrange : .textSecondary)
                }
                
                // Sport Name
                Text(sport.name)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(isSelected ? .primaryOrange : .textPrimary)
                    .lineLimit(1)
                
                // Selection Indicator
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 16))
                        .foregroundColor(.primaryOrange)
                }
            }
            .padding(16)
            .frame(maxWidth: .infinity, minHeight: 120)
            .background(isSelected ? Color.primaryOrange.opacity(0.1) : Color.formBackground)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(isSelected ? Color.primaryOrange : Color.formBorder, lineWidth: isSelected ? 2 : 1)
            )
            .scaleEffect(isSelected ? 1.02 : 1.0)
            .animation(.easeInOut(duration: 0.2), value: isSelected)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private func sportIcon(for sportName: String) -> String {
        switch sportName.lowercased() {
        case "basketball":
            return "basketball"
        case "tennis":
            return "tennis.racket"
        case "soccer":
            return "soccerball"
        case "swimming":
            return "figure.pool.swim"
        case "volleyball":
            return "volleyball"
        case "running":
            return "figure.run"
        case "cycling":
            return "bicycle"
        case "fitness":
            return "dumbbell"
        default:
            return "sportscourt"
        }
    }
}

// MARK: - Compact Versions for RegistrationView

// Compact Basic Info Step with Enhanced Password Validation
struct CompactBasicInfoStepView: View {
    @ObservedObject var viewModel: RegistrationViewModel
    @EnvironmentObject var localizationManager: LocalizationManager
    
    var body: some View {
        VStack(spacing: 14) {
            // Username Field with availability check
            VStack(alignment: .leading, spacing: 8) {
                CustomTextFieldNoTitle(
                    text: $viewModel.formData.userName,
                    icon: "person.fill",
                    placeholder: "Username",
                    hasError: viewModel.usernameError
                )
                
                // Username availability indicator
                if !viewModel.formData.userName.isEmpty && viewModel.formData.userName.count >= 3 {
                    HStack(spacing: 6) {
                        if viewModel.usernameAvailability == .checking {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .orange))
                                .scaleEffect(0.6)
                        } else {
                            Image(systemName: viewModel.usernameAvailability.icon)
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(viewModel.usernameAvailability.color)
                        }
                        
                        Text(viewModel.usernameAvailability.usernameMessage(using: localizationManager))
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(viewModel.usernameAvailability.color)
                    }
                    .padding(.leading, 16)
                }
            }
            
            // Email Field with availability check
            VStack(alignment: .leading, spacing: 8) {
                CustomTextFieldNoTitle(
                    text: $viewModel.formData.email,
                    icon: "envelope.fill",
                    placeholder: "Email",
                    hasError: viewModel.emailError
                )
                
                // Email availability indicator
                if !viewModel.formData.email.isEmpty && viewModel.formData.email.contains("@") {
                    HStack(spacing: 6) {
                        if viewModel.emailAvailability == .checking {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .orange))
                                .scaleEffect(0.6)
                        } else {
                            Image(systemName: viewModel.emailAvailability.icon)
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(viewModel.emailAvailability.color)
                        }
                        
                        Text(viewModel.emailAvailability.emailMessage(using: localizationManager))
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(viewModel.emailAvailability.color)
                    }
                    .padding(.leading, 16)
                }
            }
            
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
            
            // Enhanced Compact Password Requirements
            if !viewModel.formData.password.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Password Requirements:")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.textSecondary)
                    
                    // Grid layout for requirements
                    LazyVGrid(columns: [
                        GridItem(.flexible()),
                        GridItem(.flexible())
                    ], spacing: 6) {
                        CompactPasswordIndicator(
                            isValid: viewModel.formData.passwordHasMinLength(),
                            text: "8+ chars"
                        )
                        
                        CompactPasswordIndicator(
                            isValid: viewModel.formData.passwordHasLowercase(),
                            text: "a-z"
                        )
                        
                        CompactPasswordIndicator(
                            isValid: viewModel.formData.passwordHasUppercase(),
                            text: "A-Z"
                        )
                        
                        CompactPasswordIndicator(
                            isValid: viewModel.formData.passwordHasNumber(),
                            text: "0-9"
                        )
                    }
                    
                    // Password match indicator (full width)
                    if !viewModel.formData.confirmPassword.isEmpty {
                        CompactPasswordIndicator(
                            isValid: viewModel.formData.passwordsMatch(),
                            text: "Passwords match"
                        )
                    }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .background(Color.formBackground.opacity(0.5))
                .clipShape(RoundedRectangle(cornerRadius: 10))
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(Color.formBorder.opacity(0.3), lineWidth: 1)
                )
            }
        }
    }
}

// MARK: - Compact Sports Preferences Step - SCROLLABLE VERSION
struct CompactSportsPreferencesStepView: View {
    @ObservedObject var viewModel: RegistrationViewModel
    @EnvironmentObject var localizationManager: LocalizationManager
    
    var body: some View {
        VStack(spacing: 16) {
            // Header (fixed)
            Text("Select your favorite sports (\(viewModel.formData.selectedSports.count))")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.textPrimary)
            
            // Scrollable Sports Grid
            ScrollView {
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 8) {
                    ForEach(viewModel.availableSports, id: \.id) { sport in
                        CompactSportCard(
                            sport: sport,
                            isSelected: viewModel.formData.selectedSports.contains { $0.sport.id == sport.id },
                            action: {
                                viewModel.toggleSportSelection(sport)
                            }
                        )
                    }
                }
                .padding(.horizontal, 4)
            }
            .frame(maxHeight: 300) // Limit height to make it scrollable
        }
    }
}

// Simple Compact Sport Card
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
            .scaleEffect(isSelected ? 1.05 : 1.0)
            .animation(.easeInOut(duration: 0.2), value: isSelected)
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

// MARK: - Enhanced Compact Password Indicator
struct CompactPasswordIndicator: View {
    let isValid: Bool
    let text: String
    
    var body: some View {
        HStack(spacing: 4) {
            ZStack {
                Circle()
                    .fill(isValid ? Color.green : Color.textSecondary.opacity(0.3))
                    .frame(width: 12, height: 12)
                    .scaleEffect(isValid ? 1.1 : 1.0)
                
                Image(systemName: isValid ? "checkmark" : "circle")
                    .font(.system(size: 8, weight: .bold))
                    .foregroundColor(isValid ? .white : .textSecondary)
                    .scaleEffect(isValid ? 1.2 : 1.0)
            }
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isValid)
            
            Text(text)
                .font(.system(size: 10, weight: .medium))
                .foregroundColor(isValid ? .green : .textSecondary)
                .lineLimit(1)
            
            Spacer(minLength: 0)
        }
        .animation(.easeInOut(duration: 0.2), value: isValid)
    }
}
