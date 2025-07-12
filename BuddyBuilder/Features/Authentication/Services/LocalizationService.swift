import Foundation
import Combine

// MARK: - Localization Service Protocol
protocol LocalizationServiceProtocol {
    func fetchLanguages() async throws -> [Language]
    func fetchTranslations(for languageCode: String) async throws -> [String: String]
}

// MARK: - Localization Service Implementation
class LocalizationService: LocalizationServiceProtocol {
    private let baseURL = "http://localhost:5206/api/Localization"
    private let session = URLSession.shared
    
    // MARK: - Fetch Available Languages
    func fetchLanguages() async throws -> [Language] {
        guard let url = URL(string: "\(baseURL)/languages") else {
            throw LocalizationError.networkError("Invalid URL")
        }
        
        do {
            let (data, response) = try await session.data(from: url)
            
            guard let httpResponse = response as? HTTPURLResponse,
                  httpResponse.statusCode == 200 else {
                throw LocalizationError.networkError("Invalid response")
            }
            
            let languages = try JSONDecoder().decode([Language].self, from: data)
            return languages.filter { $0.isActive }
            
        } catch DecodingError.dataCorrupted(let context) {
            throw LocalizationError.decodingError("Data corrupted: \(context.debugDescription)")
        } catch DecodingError.keyNotFound(let key, let context) {
            throw LocalizationError.decodingError("Key '\(key)' not found: \(context.debugDescription)")
        } catch DecodingError.valueNotFound(let value, let context) {
            throw LocalizationError.decodingError("Value '\(value)' not found: \(context.debugDescription)")
        } catch DecodingError.typeMismatch(let type, let context) {
            throw LocalizationError.decodingError("Type '\(type)' mismatch: \(context.debugDescription)")
        } catch {
            throw LocalizationError.networkError(error.localizedDescription)
        }
    }
    
    // MARK: - Fetch Translations for Language
    func fetchTranslations(for languageCode: String) async throws -> [String: String] {
        guard let url = URL(string: "\(baseURL)/translations?language=\(languageCode)") else {
            throw LocalizationError.networkError("Invalid URL")
        }
        
        do {
            let (data, response) = try await session.data(from: url)
            
            guard let httpResponse = response as? HTTPURLResponse,
                  httpResponse.statusCode == 200 else {
                throw LocalizationError.networkError("Invalid response")
            }
            
            let translationResponse = try JSONDecoder().decode(TranslationResponse.self, from: data)
            return translationResponse.translations
            
        } catch DecodingError.dataCorrupted(let context) {
            throw LocalizationError.decodingError("Data corrupted: \(context.debugDescription)")
        } catch DecodingError.keyNotFound(let key, let context) {
            throw LocalizationError.decodingError("Key '\(key)' not found: \(context.debugDescription)")
        } catch DecodingError.valueNotFound(let value, let context) {
            throw LocalizationError.decodingError("Value '\(value)' not found: \(context.debugDescription)")
        } catch DecodingError.typeMismatch(let type, let context) {
            throw LocalizationError.decodingError("Type '\(type)' mismatch: \(context.debugDescription)")
        } catch {
            throw LocalizationError.networkError(error.localizedDescription)
        }
    }
}

// MARK: - Mock Service for Preview/Testing
class MockLocalizationService: LocalizationServiceProtocol {
    func fetchLanguages() async throws -> [Language] {
        return [
            Language(code: "en", name: "English", nativeName: "English", isDefault: true, isActive: true),
            Language(code: "tr", name: "Turkish", nativeName: "Türkçe", isDefault: false, isActive: true),
            Language(code: "az", name: "Azerbaijani", nativeName: "Azərbaycan", isDefault: false, isActive: true)
        ]
    }
    
    func fetchTranslations(for languageCode: String) async throws -> [String: String] {
        // Mock translations for testing
        if languageCode == "tr" {
            return [
                "auth.login": "Giriş Yap",
                "auth.logout": "Çıkış",
                "auth.email": "E-posta",
                "auth.password": "Şifre",
                "auth.login.title": "Giriş Yap",
                "auth.login.username.placeholder": "E-posta veya Kullanıcı Adı",
                "auth.login.password.placeholder": "Şifre",
                "auth.login.remember.me": "Beni Hatırla",
                "auth.login.forgot.password": "Şifremi Unuttum",
                "auth.login.button": "Giriş Yap",
                "auth.login.loading": "Giriş Yapılıyor...",
                "auth.login.signup.text": "Hesabınız yok mu?",
                "auth.login.signup.link": "Kaydol",
                "common.or": "veya"
            ]
        } else {
            return [
                "auth.login": "Login",
                "auth.logout": "Logout",
                "auth.email": "Email",
                "auth.password": "Password",
                "auth.login.title": "Login",
                "auth.login.username.placeholder": "Email or Username",
                "auth.login.password.placeholder": "Password",
                "auth.login.remember.me": "Remember Me",
                "auth.login.forgot.password": "Forgot Password?",
                "auth.login.button": "Login",
                "auth.login.loading": "Logging in...",
                "auth.login.signup.text": "Don't have an account?",
                "auth.login.signup.link": "Sign Up",
                "common.or": "or"
            ]
        }
    }
}
