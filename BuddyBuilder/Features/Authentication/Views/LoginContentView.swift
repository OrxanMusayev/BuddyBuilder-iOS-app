// BuddyBuilder/Features/Authentication/Views/LoginContentView.swift
// UPDATED: Fixed UI positioning, keyboard behavior, and button animation

import SwiftUI

struct LoginContentView: View {
    @EnvironmentObject var authViewModel: AuthenticationViewModel
    @EnvironmentObject var localizationManager: LocalizationManager
    @State private var showRegistration = false
    @State private var showForgotPassword = false
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .topTrailing) {
                // Background tap gesture for keyboard dismissal - FIXED: Full coverage
                Color.clear
                    .contentShape(Rectangle())
                    .onTapGesture {
                        hideKeyboard()
                    }
                    .ignoresSafeArea()
                
                // Main login content
                VStack(spacing: 0) {
                    // Top spacing for status bar and language picker
                    Spacer()
                        .frame(height: 60)
                    
                    // App logo only - REMOVED: BuddyBuilder text
                    Image("appstore")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 70, height: 70)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .padding(.bottom, 20) // Further reduced from 30
                    
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
                    .padding(.bottom, 20) // Reduced from 30
                    
                    // Form fields - MOVED UP
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
                                print("🔑 Forgot Password button tapped")
                                showForgotPassword = true
                            }
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.primaryOrange)
                        }
                        .padding(.vertical, 8)
                        
                        // Login Button - FIXED: Stable animation
                        Button(action: {
                            hideKeyboard() // Dismiss keyboard before login
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
                            .shadow(color: .primaryOrange.opacity(0.3), radius: 8, x: 0, y: 4)
                        }
                        .disabled(authViewModel.isLoading)
                        // REMOVED: Scale animation that was causing jumping
                        .animation(.none, value: authViewModel.isLoading) // Disable animation on loading state
                    }
                    
                        Spacer()
                    
                    // Bottom Section
                    VStack(spacing: 16) {
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
                        
                        // Sign Up Section
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
                    .padding(.bottom, 16)
                }
                .padding(.horizontal, 20)
                
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
        .fullScreenCover(isPresented: $showForgotPassword) {
            ForgotPasswordView()
                .environmentObject(localizationManager)
        }
        .onReceive(localizationManager.$currentLanguage) { _ in
            // Update UI when language changes
        }
    }
    
    // MARK: - Enhanced Keyboard Dismissal
    private func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}

// MARK: - REMOVED: Old dismissKeyboardOnTap extension since we're handling it manually

#Preview(traits: .sizeThatFitsLayout) {
    NavigationStack {
        LoginContentView()
            .environmentObject(AuthenticationViewModel())
            .environmentObject(LocalizationManager(localizationService: MockLocalizationService()))
    }
}
// MARK: - Dismiss Keyboard Extension
extension View {
    func dismissKeyboardOnTap() -> some View {
        self.onTapGesture {
            UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
        }
    }
}

