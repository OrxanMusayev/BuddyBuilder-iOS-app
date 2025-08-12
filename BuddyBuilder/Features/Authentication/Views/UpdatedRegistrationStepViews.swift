// BuddyBuilder/Features/Authentication/Views/UpdatedRegistrationStepViews.swift

import SwiftUI

// MARK: - Updated Basic Info Step (Enhanced Password Validation)
struct UpdatedBasicInfoStepView: View {
    @ObservedObject var viewModel: UpdatedRegistrationViewModel
    @EnvironmentObject var localizationManager: LocalizationManager
    
    var body: some View {
        VStack(spacing: 20) {
            // Username Field
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
            
            // Email Field
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
            
            // Password Field
            CustomPasswordFieldNoTitle(
                text: $viewModel.formData.password,
                showPassword: $viewModel.showPassword,
                placeholder: "Password",
                hasError: viewModel.passwordError
            )
            
            // Confirm Password Field
            CustomPasswordFieldNoTitle(
                text: $viewModel.formData.confirmPassword,
                showPassword: $viewModel.showConfirmPassword,
                placeholder: "Confirm Password",
                hasError: viewModel.confirmPasswordError
            )
            
            // Enhanced Password requirements validation (with special character)
            if !viewModel.formData.password.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Password Requirements:")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.textSecondary)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        EnhancedPasswordRequirementRow(
                            text: "At least 8 characters",
                            isValid: viewModel.formData.passwordHasMinLength()
                        )
                        
                        EnhancedPasswordRequirementRow(
                            text: "One lowercase letter (a-z)",
                            isValid: viewModel.formData.passwordHasLowercase()
                        )
                        
                        EnhancedPasswordRequirementRow(
                            text: "One uppercase letter (A-Z)",
                            isValid: viewModel.formData.passwordHasUppercase()
                        )
                        
                        EnhancedPasswordRequirementRow(
                            text: "One number (0-9)",
                            isValid: viewModel.formData.passwordHasNumber()
                        )
                        
                        EnhancedPasswordRequirementRow(
                            text: "One special character (!@#$%^&*)",
                            isValid: viewModel.formData.passwordHasSpecialChar()
                        )
                        
                        // Password match indicator
                        if !viewModel.formData.confirmPassword.isEmpty {
                            EnhancedPasswordRequirementRow(
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

// MARK: - Enhanced Password Requirement Row
struct EnhancedPasswordRequirementRow: View {
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

// MARK: - Location Step View Integration
struct UpdatedLocationStepView: View {
    @ObservedObject var viewModel: UpdatedRegistrationViewModel
    @EnvironmentObject var localizationManager: LocalizationManager
    
    var body: some View {
        LocationStepView(viewModel: viewModel)
            .environmentObject(localizationManager)
    }
}

// MARK: - Updated Sports Preferences Step
struct UpdatedSportsPreferencesStepView: View {
    @ObservedObject var viewModel: UpdatedRegistrationViewModel
    @EnvironmentObject var localizationManager: LocalizationManager
    
    var body: some View {
        VStack(spacing: 0) {
            // Top margin for visual breathing room - INCREASED
            Spacer()
                .frame(height: 40)
            
            VStack(spacing: 24) { // INCREASED spacing
                // Sports Selection Header - FIXED with better spacing
                VStack(alignment: .leading, spacing: 16) { // INCREASED spacing
                    HStack {
                        Text("Select your favorite sports")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.textPrimary)
                        
                        Spacer()
                        
                        Text("(\(viewModel.formData.selectedSports.count))")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.textSecondary)
                    }
                    .padding(.horizontal, 20)
                    
                    if viewModel.sportsError {
                        Text("Please select at least one sport")
                            .font(.system(size: 12))
                            .foregroundColor(.red)
                            .padding(.horizontal, 20)
                    }
                }
                .zIndex(100) // FIXED: Keep header above scrolling content
                
                // Scrollable Sports Grid - FIXED with proper separation
                ScrollView(.vertical, showsIndicators: false) {
                    VStack(spacing: 20) { // ADDED: Extra spacing wrapper
                        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 12) { // REDUCED spacing from 16 to 12
                            ForEach(viewModel.availableSports, id: \.id) { sport in
                                UpdatedSportSelectionCard(
                                    sport: sport,
                                    isSelected: viewModel.formData.selectedSports.contains { $0.sport.id == sport.id },
                                    action: {
                                        viewModel.toggleSportSelection(sport)
                                    }
                                )
                            }
                        }
                        .padding(.horizontal, 8) // INCREASED padding
                        .padding(.top, 10) // ADDED: Top padding to prevent overlap
                    }
                }
                .frame(minHeight: 250, maxHeight: 320) // Adjusted maxHeight to leave more space at bottom
                .background(Color.clear) // ADDED: Explicit background
                .clipped() // Prevent content overflow
            }
            
            // Bottom spacer to prevent button overlap
            Spacer()
                .frame(height: 60) // Increased to add more space before the button
        }
    }
}

// MARK: - Updated Sport Selection Card - FIXED for no overlap
struct UpdatedSportSelectionCard: View {
    let sport: Sport
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 10) {
                // Sport Icon
                ZStack {
                    Circle()
                        .fill(isSelected ? Color.primaryOrange.opacity(0.2) : Color.formBackground)
                        .frame(width: 45, height: 45)
                    
                    Image(systemName: sportIcon(for: sport.name))
                        .font(.system(size: 22, weight: .medium))
                        .foregroundColor(isSelected ? .primaryOrange : .textSecondary)
                }
                
                // Sport Name
                Text(sport.name)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(isSelected ? .primaryOrange : .textPrimary)
                    .lineLimit(2)
                    .multilineTextAlignment(.center)
                    .minimumScaleFactor(0.8)
                    .fixedSize(horizontal: false, vertical: true)
                
                // Selection Indicator
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 14))
                        .foregroundColor(.primaryOrange)
                        .transition(.opacity) // CHANGED: Only opacity transition
                }
            }
            .padding(12)
            .frame(maxWidth: .infinity, minHeight: 120, maxHeight: 120) // FIXED: Exact height
            .background(isSelected ? Color.primaryOrange.opacity(0.1) : Color.formBackground)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(isSelected ? Color.primaryOrange : Color.formBorder, lineWidth: isSelected ? 2 : 1)
            )
            // REMOVED: .scaleEffect - This was causing the overlap!
            .animation(.easeInOut(duration: 0.2), value: isSelected)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private func sportIcon(for sportName: String) -> String {
        switch sportName.lowercased() {
        case "basketball":
            return "basketball.fill"
        case "tennis":
            return "tennis.racket"
        case "soccer", "football":
            return "soccerball"
        case "swimming":
            return "figure.pool.swim"
        case "volleyball":
            return "volleyball.fill"
        case "running":
            return "figure.run"
        case "cycling":
            return "bicycle"
        case "fitness", "gym":
            return "dumbbell.fill"
        case "badminton":
            return "figure.badminton"
        case "boxing":
            return "figure.boxing"
        case "climbing":
            return "figure.climbing"
        case "golf":
            return "figure.golf"
        default:
            return "sportscourt.fill"
        }
    }
}

// MARK: - Custom Text Area Component
struct CustomTextArea: View {
    @Binding var text: String
    let placeholder: String
    let minHeight: CGFloat
    let maxHeight: CGFloat
    
    var body: some View {
        ZStack(alignment: .topLeading) {
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.formBackground)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.formBorder, lineWidth: 1)
                )
            
            VStack {
                if text.isEmpty {
                    HStack {
                        Text(placeholder)
                            .font(.system(size: 16))
                            .foregroundColor(.textSecondary)
                            .padding(.horizontal, 16)
                            .padding(.top, 14)
                        Spacer()
                    }
                }
                
                TextEditor(text: $text)
                    .font(.system(size: 16))
                    .foregroundColor(.textPrimary)
                    .scrollContentBackground(.hidden)
                    .background(Color.clear)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 10)
            }
        }
        .frame(minHeight: minHeight, maxHeight: maxHeight)
    }
}
