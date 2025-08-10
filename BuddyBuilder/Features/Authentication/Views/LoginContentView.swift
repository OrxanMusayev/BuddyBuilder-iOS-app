import SwiftUI

struct LoginContentView: View {
    @EnvironmentObject var authViewModel: AuthenticationViewModel
    @EnvironmentObject var localizationManager: LocalizationManager
    @State private var showRegistration = false
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .topTrailing) {
                // Main login content
                VStack(spacing: 0) {
                    // Top spacing for status bar and language picker
                    Spacer()
                        .frame(height: 120) // Increased to give more space for language picker
                    
                    // App logo with text
                    VStack(spacing: 12) {
                        Image("appstore")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 70, height: 70)
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                        
                        Text("BuddyBuilder")
                            .font(.system(size: 35, weight: .bold, design: .rounded))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [
                                        Color(red: 1.0, green: 0.42, blue: 0.21), // Orange like logo
                                        Color(red: 1.0, green: 0.35, blue: 0.15)  // Slightly darker orange
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .tracking(1.2) // More letter spacing for softer look
                    }
                    .padding(.bottom, 10)
                    
                    // Login title - removed the "Login" text
                    // Error Message Area
                    
                    // Error Message Area
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
                    .padding(.bottom, 20)
                    
                    // Form fields
                    VStack(spacing: 20) {
                        // Username Field
                        CustomTextFieldNoTitle(
                            text: $authViewModel.username,
                            icon: "person.fill",
                            placeholder: "auth.login.username.placeholder".localized(using: localizationManager),
                            hasError: authViewModel.usernameError
                        )
                        
                        // Password Field
                        CustomPasswordFieldNoTitle(
                            text: $authViewModel.password,
                            showPassword: $authViewModel.showPassword,
                            placeholder: "auth.login.password.placeholder".localized(using: localizationManager),
                            hasError: authViewModel.passwordError
                        )
                        
                        // Form Options
                        HStack {
                            // Remember Me
                            HStack(spacing: 10) {
                                Button(action: {
                                    authViewModel.rememberMe.toggle()
                                }) {
                                    Image(systemName: authViewModel.rememberMe ? "checkmark.square.fill" : "square")
                                        .foregroundColor(authViewModel.rememberMe ? .primaryOrange : .secondaryText)
                                        .font(.system(size: 18))
                                }
                                
                                Text("auth.login.remember.me".localized(using: localizationManager))
                                    .font(.system(size: 14))
                                    .foregroundColor(.primaryText)
                                
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
                        
                        // Login Button
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
                            .frame(height: 54)
                            .background(
                                LinearGradient(
                                    colors: [.primaryOrange, Color.primaryOrange.opacity(0.8)],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .clipShape(RoundedRectangle(cornerRadius: 27))
                            .scaleEffect(authViewModel.isLoading ? 0.95 : 1.0)
                            .shadow(color: .primaryOrange.opacity(0.3), radius: 8, x: 0, y: 4)
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
                                .foregroundColor(.secondaryText)
                                .padding(.horizontal, 16)
                            
                            Rectangle()
                                .fill(Color.formBorder)
                                .frame(height: 1)
                        }
                        .padding(.vertical, 24)
                        
                        // Sign Up Section
                        VStack(spacing: 16) {
                            Rectangle()
                                .fill(Color.formBorder)
                                .frame(height: 1)
                            
                            HStack {
                                Text("auth.login.signup.text".localized(using: localizationManager))
                                    .font(.system(size: 15))
                                    .foregroundColor(.secondaryText)
                                
                                Button(action: {
                                    print("🔄 Sign Up button tapped")
                                    showRegistration = true
                                }) {
                                    Text("auth.login.signup.link".localized(using: localizationManager))
                                        .font(.system(size: 15, weight: .semibold))
                                        .foregroundColor(.primaryOrange)
                                }
                            }
                        }
                    }
                    
                    Spacer()
                }
                
                // Language picker - positioned higher, away from logo
                VStack {
                    HStack {
                        Spacer()
                        CompactLanguagePicker(localizationManager: localizationManager)
                            .padding(.top, 30) // Reduced from 50 to move it higher
                            .padding(.trailing, 10)
                    }
                    Spacer()
                }
                .zIndex(1000)
            }
        }
        .fullScreenCover(isPresented: $showRegistration) {
            UpdatedRegistrationView()
                .environmentObject(authViewModel)
                .environmentObject(localizationManager)
        }
        .onReceive(localizationManager.$currentLanguage) { _ in
            // Update UI when language changes
        }
    }
}

#Preview(traits: .sizeThatFitsLayout) {
    NavigationStack {
        LoginContentView()
            .environmentObject(AuthenticationViewModel())
            .environmentObject(LocalizationManager(localizationService: MockLocalizationService()))
    }
}
