import SwiftUI

struct LoginContentView: View {
    @EnvironmentObject var authViewModel: AuthenticationViewModel
    @EnvironmentObject var localizationManager: LocalizationManager
    
    var body: some View {
        ZStack {
            // Main Login Form
            loginForm
            
            // Language Picker in top-right corner of the card
            VStack {
                HStack {
                    Spacer()
                    CompactLanguagePicker(localizationManager: localizationManager)
                        .padding(.top, 20)
                        .padding(.trailing, 20)
                }
                Spacer()
            }
        }
        .onReceive(localizationManager.$currentLanguage) { _ in
            // Update UI when language changes
        }
    }
    
    private var loginForm: some View {
        VStack(spacing: 0) {
            // Logo Section
            VStack(spacing: 20) {
                Image(systemName: "figure.run.circle.fill")
                    .font(.system(size: 60))
                    .foregroundColor(.primaryOrange)
                
                Text("auth.login.title".localized(using: localizationManager))
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .foregroundColor(.textPrimary)
            }
            .padding(.bottom, 32)
            .padding(.top, 60) // Space for language picker
            
            // Form Section
            VStack(spacing: 20) {
                // Sabit Error Message Alanı
                VStack {
                    if !authViewModel.validationMessage.isEmpty {
                        HStack {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundColor(.red)
                                .font(.system(size: 14))
                            
                            Text(authViewModel.validationMessage)
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.red)
                            
                            Spacer()
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(Color.red.opacity(0.1))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .transition(.opacity.combined(with: .scale))
                    } else {
                        Color.clear
                            .frame(height: 38)
                    }
                }
                .frame(height: 38)
                .animation(.easeInOut(duration: 0.3), value: authViewModel.validationMessage.isEmpty)
                
                // Username Field - Localized
                CustomTextFieldNoTitle(
                    text: $authViewModel.username,
                    icon: "person.fill",
                    placeholder: "auth.login.username.placeholder".localized(using: localizationManager),
                    hasError: authViewModel.usernameError
                )
                
                // Password Field - Localized
                CustomPasswordFieldNoTitle(
                    text: $authViewModel.password,
                    showPassword: $authViewModel.showPassword,
                    placeholder: "auth.login.password.placeholder".localized(using: localizationManager),
                    hasError: authViewModel.passwordError
                )
                
                // Form Options - Localized
                HStack {
                    // Remember Me
                    HStack(spacing: 10) {
                        Button(action: {
                            authViewModel.rememberMe.toggle()
                        }) {
                            Image(systemName: authViewModel.rememberMe ? "checkmark.square.fill" : "square")
                                .foregroundColor(authViewModel.rememberMe ? .primaryOrange : .textSecondary)
                                .font(.system(size: 18))
                        }
                        
                        Text("auth.login.remember.me".localized(using: localizationManager))
                            .font(.system(size: 14))
                            .foregroundColor(.textPrimary)
                        
                        Spacer()
                    }
                    
                    // Forgot Password
                    Button("auth.login.forgot.password".localized(using: localizationManager)) {
                        // TODO: Implement forgot password
                    }
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.primaryOrange)
                }
                .padding(.vertical, 8)
                
                // Login Button - Localized
                Button(action: {
                    authViewModel.login()
                }) {
                    HStack {
                        if authViewModel.isLoading {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                .scaleEffect(0.8)
                        } else {
                            Image(systemName: "arrow.right.circle.fill")
                                .font(.system(size: 18))
                        }
                        
                        Text(authViewModel.isLoading
                             ? "auth.login.loading".localized(using: localizationManager)
                             : "auth.login.button".localized(using: localizationManager))
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
                    .scaleEffect(authViewModel.isLoading ? 0.95 : 1.0)
                }
                .disabled(authViewModel.isLoading)
                .animation(.easeInOut(duration: 0.2), value: authViewModel.isLoading)
                
                // Divider
                HStack {
                    Rectangle()
                        .fill(Color.formBorder)
                        .frame(height: 1)
                    
                    Text("common.or".localized(using: localizationManager))
                        .font(.system(size: 14))
                        .foregroundColor(.textSecondary)
                        .padding(.horizontal, 16)
                    
                    Rectangle()
                        .fill(Color.formBorder)
                        .frame(height: 1)
                }
                .padding(.vertical, 24)
                
                // Sign Up Section - Localized
                VStack(spacing: 16) {
                    Rectangle()
                        .fill(Color.formBorder)
                        .frame(height: 1)
                    
                    HStack {
                        Text("auth.login.signup.text".localized(using: localizationManager))
                            .font(.system(size: 15))
                            .foregroundColor(.textSecondary)
                        
                        Button("auth.login.signup.link".localized(using: localizationManager)) {
                            // TODO: Navigate to register
                        }
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(.primaryOrange)
                    }
                }
                .padding(.top, 20)
            }
        }
        .padding(32)
        .background(
            RoundedRectangle(cornerRadius: 18)
                .fill(Color.white)
                .shadow(color: .black.opacity(0.1), radius: 15, x: 0, y: 5)
        )
    }
}

#Preview(traits: .sizeThatFitsLayout) {
    LoginContentView()
        .environmentObject(AuthenticationViewModel())
        .environmentObject(LocalizationManager(localizationService: MockLocalizationService()))
        .padding()
}
