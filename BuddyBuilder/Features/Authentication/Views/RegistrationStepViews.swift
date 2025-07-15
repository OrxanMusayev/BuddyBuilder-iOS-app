// BuddyBuilder/Features/Authentication/Views/RegistrationStepViews.swift

import SwiftUI

// MARK: - Basic Info Step
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
                        
                        Text(viewModel.usernameAvailability.message.localized(using: localizationManager))
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
                        
                        Text(viewModel.emailAvailability.message.localized(using: localizationManager))
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(viewModel.emailAvailability.color)
                    }
                    .padding(.leading, 16)
                }
            }
            
            // First Name
            CustomTextFieldNoTitle(
                text: $viewModel.formData.firstName,
                icon: "person.fill",
                placeholder: "registration.first_name.placeholder".localized(using: localizationManager),
                hasError: viewModel.firstNameError
            )
            
            // Last Name
            CustomTextFieldNoTitle(
                text: $viewModel.formData.lastName,
                icon: "person.fill",
                placeholder: "registration.last_name.placeholder".localized(using: localizationManager),
                hasError: viewModel.lastNameError
            )
            
            // Phone Number
            CustomTextFieldNoTitle(
                text: $viewModel.formData.phoneNumber,
                icon: "phone.fill",
                placeholder: "registration.phone.placeholder".localized(using: localizationManager),
                hasError: viewModel.phoneError
            )
            
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
            
            // Password requirements
            VStack(alignment: .leading, spacing: 4) {
                Text("registration.password.requirements".localized(using: localizationManager))
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.textSecondary)
                
                PasswordRequirementRow(
                    text: "registration.password.min_length".localized(using: localizationManager),
                    isValid: viewModel.formData.password.count >= 6
                )
                
                PasswordRequirementRow(
                    text: "registration.password.match".localized(using: localizationManager),
                    isValid: !viewModel.formData.confirmPassword.isEmpty && viewModel.formData.password == viewModel.formData.confirmPassword
                )
            }
            .padding(.horizontal, 16)
        }
    }
}

// MARK: - Location Step
struct LocationStepView: View {
    @ObservedObject var viewModel: RegistrationViewModel
    @EnvironmentObject var localizationManager: LocalizationManager
    
    var body: some View {
        VStack(spacing: 20) {
            // Country Selection
            VStack(alignment: .leading, spacing: 8) {
                Text("registration.country".localized(using: localizationManager))
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.textPrimary)
                    .padding(.leading, 16)
                
                Menu {
                    ForEach(viewModel.availableCountries) { country in
                        Button(action: {
                            viewModel.formData.selectedCountry = country
                        }) {
                            HStack {
                                Text(country.name)
                                if viewModel.formData.selectedCountry?.id == country.id {
                                    Spacer()
                                    Image(systemName: "checkmark")
                                }
                            }
                        }
                    }
                } label: {
                    HStack(spacing: 12) {
                        Image(systemName: "globe")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.textSecondary)
                            .frame(width: 20)
                        
                        Text(viewModel.formData.selectedCountry?.name ?? "registration.select_country".localized(using: localizationManager))
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
                            .stroke(viewModel.locationError && viewModel.formData.selectedCountry == nil ? Color.red : Color.formBorder, lineWidth: viewModel.locationError && viewModel.formData.selectedCountry == nil ? 2 : 1)
                    )
                }
            }
            
            // City Selection
            VStack(alignment: .leading, spacing: 8) {
                Text("registration.city".localized(using: localizationManager))
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.textPrimary)
                    .padding(.leading, 16)
                
                Menu {
                    ForEach(viewModel.availableCities) { city in
                        Button(action: {
                            viewModel.formData.selectedCity = city
                        }) {
                            HStack {
                                Text(city.name)
                                if viewModel.formData.selectedCity?.id == city.id {
                                    Spacer()
                                    Image(systemName: "checkmark")
                                }
                            }
                        }
                    }
                } label: {
                    HStack(spacing: 12) {
                        Image(systemName: "building.2")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.textSecondary)
                            .frame(width: 20)
                        
                        Text(viewModel.formData.selectedCity?.name ?? "registration.select_city".localized(using: localizationManager))
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
                            .stroke(viewModel.locationError && viewModel.formData.selectedCity == nil ? Color.red : Color.formBorder, lineWidth: viewModel.locationError && viewModel.formData.selectedCity == nil ? 2 : 1)
                    )
                }
                .disabled(viewModel.formData.selectedCountry == nil)
            }
            
            // District
            CustomTextFieldNoTitle(
                text: $viewModel.formData.district,
                icon: "location.fill",
                placeholder: "registration.district.placeholder".localized(using: localizationManager),
                hasError: viewModel.locationError && viewModel.formData.district.isEmpty
            )
        }
    }
}

// MARK: - Sports Preferences Step
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

// MARK: - Profile Step
struct ProfileStepView: View {
    @ObservedObject var viewModel: RegistrationViewModel
    @EnvironmentObject var localizationManager: LocalizationManager
    
    var body: some View {
        VStack(spacing: 20) {
            // Bio
            VStack(alignment: .leading, spacing: 8) {
                Text("registration.bio".localized(using: localizationManager))
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.textPrimary)
                    .padding(.leading, 16)
                
                TextEditor(text: $viewModel.formData.bio)
                    .font(.system(size: 16))
                    .foregroundColor(.textPrimary)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .frame(minHeight: 80)
                    .background(Color.formBackground)
                    .clipShape(RoundedRectangle(cornerRadius: 25))
                    .overlay(
                        RoundedRectangle(cornerRadius: 25)
                            .stroke(viewModel.profileError && viewModel.formData.bio.isEmpty ? Color.red : Color.formBorder, lineWidth: viewModel.profileError && viewModel.formData.bio.isEmpty ? 2 : 1)
                    )
            }
            
            // About Me
            VStack(alignment: .leading, spacing: 8) {
                Text("registration.about_me".localized(using: localizationManager))
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.textPrimary)
                    .padding(.leading, 16)
                
                TextEditor(text: $viewModel.formData.aboutMe)
                    .font(.system(size: 16))
                    .foregroundColor(.textPrimary)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .frame(minHeight: 100)
                    .background(Color.formBackground)
                    .clipShape(RoundedRectangle(cornerRadius: 25))
                    .overlay(
                        RoundedRectangle(cornerRadius: 25)
                            .stroke(viewModel.profileError && viewModel.formData.aboutMe.isEmpty ? Color.red : Color.formBorder, lineWidth: viewModel.profileError && viewModel.formData.aboutMe.isEmpty ? 2 : 1)
                    )
            }
            
            // Notes (Optional)
            VStack(alignment: .leading, spacing: 8) {
                Text("registration.notes.optional".localized(using: localizationManager))
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.textSecondary)
                    .padding(.leading, 16)
                
                TextEditor(text: $viewModel.formData.notes)
                    .font(.system(size: 16))
                    .foregroundColor(.textPrimary)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .frame(minHeight: 60)
                    .background(Color.formBackground)
                    .clipShape(RoundedRectangle(cornerRadius: 25))
                    .overlay(
                        RoundedRectangle(cornerRadius: 25)
                            .stroke(Color.formBorder, lineWidth: 1)
                    )
            }
        }
    }
}

// MARK: - Verification Step
struct VerificationStepView: View {
    @ObservedObject var viewModel: RegistrationViewModel
    @EnvironmentObject var localizationManager: LocalizationManager
    
    var body: some View {
        VStack(spacing: 24) {
            // Success Icon
            ZStack {
                Circle()
                    .fill(Color.primaryOrange.opacity(0.1))
                    .frame(width: 100, height: 100)
                
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 60, weight: .medium))
                    .foregroundColor(.primaryOrange)
            }
            
            // Title
            Text("registration.verification.title".localized(using: localizationManager))
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(.textPrimary)
                .multilineTextAlignment(.center)
            
            // Subtitle
            Text("registration.verification.subtitle".localized(using: localizationManager))
                .font(.system(size: 16))
                .foregroundColor(.textSecondary)
                .multilineTextAlignment(.center)
                .lineLimit(nil)
                .padding(.horizontal, 20)
            
            // Summary Card
            VStack(spacing: 16) {
                RegistrationSummaryRow(
                    label: "registration.summary.name".localized(using: localizationManager),
                    value: "\(viewModel.formData.firstName) \(viewModel.formData.lastName)"
                )
                
                RegistrationSummaryRow(
                    label: "registration.summary.username".localized(using: localizationManager),
                    value: viewModel.formData.userName
                )
                
                RegistrationSummaryRow(
                    label: "registration.summary.email".localized(using: localizationManager),
                    value: viewModel.formData.email
                )
                
                RegistrationSummaryRow(
                    label: "registration.summary.location".localized(using: localizationManager),
                    value: "\(viewModel.formData.selectedCity?.name ?? ""), \(viewModel.formData.selectedCountry?.name ?? "")"
                )
                
                RegistrationSummaryRow(
                    label: "registration.summary.sports".localized(using: localizationManager),
                    value: "\(viewModel.formData.selectedSports.count) sports selected"
                )
            }
            .padding(20)
            .background(Color.formBackground)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.formBorder, lineWidth: 1)
            )
        }
    }
}

// MARK: - Helper Components

// Password Requirement Row
struct PasswordRequirementRow: View {
    let text: String
    let isValid: Bool
    
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: isValid ? "checkmark.circle.fill" : "circle")
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(isValid ? .green : .textSecondary)
            
            Text(text)
                .font(.system(size: 12))
                .foregroundColor(.textSecondary)
            
            Spacer()
        }
    }
}

// Sport Selection Card
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

// Registration Summary Row
struct RegistrationSummaryRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Text(label)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.textSecondary)
            
            Spacer()
            
            Text(value)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.textPrimary)
                .multilineTextAlignment(.trailing)
        }
        .padding(.vertical, 2)
    }
}
