// Dosya Yolu: BuddyBuilder/Features/Authentication/ViewModels/AuthenticationViewModel.swift

import Foundation
import Combine
import SwiftUI

class AuthenticationViewModel: ObservableObject {
    @EnvironmentObject var localizationManager: LocalizationManager
    @Published var isAuthenticated = false {
        didSet {
            print("🔄 isAuthenticated didSet: \(oldValue) -> \(isAuthenticated)")
        }
    }
    @Published var isLoading = false
    @Published var errorMessage: String = ""
    @Published var showError = false
    
    // Form validation için error state'leri
    @Published var usernameError = false
    @Published var passwordError = false
    @Published var validationMessage: String = ""
    
    // Form fields
    @Published var username: String = ""
    @Published var password: String = ""
    @Published var rememberMe: Bool = false
    @Published var showPassword: Bool = false
    
    private let authService = AuthenticationService()
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        print("🏗️ AuthenticationViewModel initialized")
        
        // Username değiştiğinde username error'ını temizle
        $username
            .sink { [weak self] _ in
                self?.usernameError = false
                if !(self?.username.isEmpty ?? true) && !(self?.password.isEmpty ?? true) {
                    self?.validationMessage = ""
                }
            }
            .store(in: &cancellables)
        
        // Password değiştiğinde password error'ını temizle
        $password
            .sink { [weak self] _ in
                self?.passwordError = false
                if !(self?.username.isEmpty ?? true) && !(self?.password.isEmpty ?? true) {
                    self?.validationMessage = ""
                }
            }
            .store(in: &cancellables)
    }
    
    // Uygulama başlatıldığında önceki login'i kontrol et
    func checkExistingLogin() {
        print("🔍 Checking for existing login...")
        
        // Kaydedilmiş token'ı kontrol et
        if let savedToken = UserDefaults.standard.string(forKey: "auth_token"),
           !savedToken.isEmpty {
            
            print("💾 Found saved token, attempting auto-login...")
            
            // Token varsa kullanıcıyı otomatik login yap
            DispatchQueue.main.async { [weak self] in
                print("🔄 Setting isAuthenticated = true for auto-login")
                self?.isAuthenticated = true
                print("✅ isAuthenticated set to: \(self?.isAuthenticated ?? false)")
            }
            
            // Debug: Kaydedilmiş user bilgilerini yazdır
            let userId = UserDefaults.standard.integer(forKey: "user_id")
            let username = UserDefaults.standard.string(forKey: "username")
            let email = UserDefaults.standard.string(forKey: "user_email")
            
            print("👤 Auto-login successful:")
            print("   User ID: \(userId)")
            print("   Username: \(username ?? "nil")")
            print("   Email: \(email ?? "nil")")
            
        } else {
            print("❌ No saved token found, showing login screen")
            DispatchQueue.main.async { [weak self] in
                self?.isAuthenticated = false
            }
        }
    }
    
    
    func login() {
        // Validation'ı resetle
        resetValidation()
        
        // Field validation
        if username.isEmpty {
            usernameError = true
        }
        
        if password.isEmpty {
            passwordError = true
        }
        
        // Eğer herhangi bir field boşsa validation mesajı göster
        if username.isEmpty || password.isEmpty {
            validationMessage = "auth.login.validation.required"
            return
        }
        
        isLoading = true
        validationMessage = ""
        
        print("🔐 Starting login for user: \(username)")
        
        authService.login(userName: username, password: password, rememberMe: rememberMe)
            .sink(
                receiveCompletion: { [weak self] completion in
                    DispatchQueue.main.async {
                        self?.isLoading = false
                        switch completion {
                        case .failure(let error):
                            print("❌ Login failed with error: \(error)")
                            self?.validationMessage = "auth.login.error.connection" + ": \(error.localizedDescription)"
                        case .finished:
                            print("✅ Login request completed")
                            break
                        }
                    }
                },
                receiveValue: { [weak self] response in
                    DispatchQueue.main.async {
                        if response.success, let loginData = response.data {
                            print("🎉 Login successful!")
                            self?.isAuthenticated = true
                            self?.saveToken(loginData.accessToken)
                            self?.saveUserInfo(loginData)
                            self?.validationMessage = ""
                        } else {
                            let errorMsg = response.message ?? "auth.login.validation.required"
                            print("❌ Login failed: \(errorMsg)")
                            self?.validationMessage = errorMsg
                        }
                    }
                }
            )
            .store(in: &cancellables)
    }
    
    private func resetValidation() {
        usernameError = false
        passwordError = false
        validationMessage = ""
    }
    
    private func saveToken(_ token: String) {
        UserDefaults.standard.set(token, forKey: "auth_token")
        print("💾 Token saved successfully")
    }
    
    private func saveUserInfo(_ loginData: LoginData) {
        UserDefaults.standard.set(loginData.userId, forKey: "user_id")
        UserDefaults.standard.set(loginData.username, forKey: "username")
        UserDefaults.standard.set(loginData.email, forKey: "user_email")
        UserDefaults.standard.set(loginData.isProfileComplete, forKey: "is_profile_complete")
        UserDefaults.standard.set(loginData.refreshToken, forKey: "refresh_token")
        print("💾 User info saved successfully")
    }
    
    func logout() {
        print("👋 Logging out user...")
        print("Current isAuthenticated: \(isAuthenticated)")
         
        let refreshToken = UserDefaults.standard.string(forKey: "refresh_token") ?? ""
        let accessToken = UserDefaults.standard.string(forKey: "auth_token") ?? ""
        
        authService.logout(refreshToken: refreshToken, accessToken: accessToken)
            .sink(
                receiveCompletion: { completion in
                    switch completion {
                    case .finished:
                        print("✅ Logout başarılı")
                    case .failure(let error):
                        print("❌ Logout hatası: \(error)")
                    }
                },
                receiveValue: {
                    DispatchQueue.main.async { [weak self] in
                        self?.isAuthenticated = false
                        self?.performLocalLogout()
                    }
                }
            )
            .store(in: &cancellables)
        
       
        
        // Authentication state'i değiştir

        print("✅ User logged out and data cleared")
    }
    
    // Token geçerliliğini kontrol et
    func validateToken() -> Bool {
        guard let token = UserDefaults.standard.string(forKey: "auth_token"),
              !token.isEmpty else {
            return false
        }
        return true
    }
    
    private func performLocalLogout() {
        print("🧹 Performing local logout...")
        
        // UserDefaults'tan tüm kullanıcı verilerini temizle
        UserDefaults.standard.removeObject(forKey: "auth_token")
        UserDefaults.standard.removeObject(forKey: "refresh_token")
        UserDefaults.standard.removeObject(forKey: "user_id")
        UserDefaults.standard.removeObject(forKey: "username")
        UserDefaults.standard.removeObject(forKey: "user_email")
        UserDefaults.standard.removeObject(forKey: "is_profile_complete")
        
        // Form alanlarını temizle
        username = ""
        password = ""
        rememberMe = false
        showPassword = false
        
        // Error state'lerini temizle
        resetValidation()
        errorMessage = ""
        showError = false
        
        // Authentication state'ini güncelle - bu LoginView'a yönlendirecek
        isAuthenticated = false
        
        print("🔄 Setting isAuthenticated to false...")
            print("Current thread: \(Thread.isMainThread ? "Main" : "Background")")
            isAuthenticated = false
            print("✅ isAuthenticated set to: \(isAuthenticated)")
            
            print("✅ Local logout completed, should redirect to LoginView")
        
        print("✅ Local logout completed, redirecting to LoginView")
        print("New isAuthenticated: \(isAuthenticated)")
    }
}
