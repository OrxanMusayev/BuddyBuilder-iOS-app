import Foundation
import SwiftUI
import Combine

// MARK: - Localization Manager
class LocalizationManager: ObservableObject {
    // MARK: - Published Properties
    @Published var currentLanguage: Language? = nil
    @Published var availableLanguages: [Language] = []
    @Published var translations: [String: String] = [:]
    @Published var isLoading: Bool = false
    @Published var errorMessage: String? = nil
    
    // MARK: - Private Properties
    private let localizationService: LocalizationServiceProtocol
    private let userDefaults = UserDefaults.standard
    private let languageKey = "selectedLanguage"
    
    // MARK: - Initialization
    init(localizationService: LocalizationServiceProtocol = LocalizationService()) {
        self.localizationService = localizationService
        print("🌍 LocalizationManager initialized")
    }
    
    // MARK: - Setup Methods
    @MainActor
    func initialize() async {
        print("🚀 Initializing LocalizationManager...")
        await loadAvailableLanguages()
        await loadSavedLanguageOrDefault()
    }
    
    // MARK: - Language Management
    @MainActor
    func loadAvailableLanguages() async {
        isLoading = true
        errorMessage = nil
        
        do {
            let languages = try await localizationService.fetchLanguages()
            availableLanguages = languages
            print("✅ Loaded \(languages.count) languages")
        } catch {
            errorMessage = error.localizedDescription
            print("❌ Failed to load languages: \(error.localizedDescription)")
            
            // Fallback to default language if API fails
            availableLanguages = [
                Language(code: "en", name: "English", nativeName: "English", isDefault: true, isActive: true)
            ]
        }
        
        isLoading = false
    }
    
    @MainActor
    func loadSavedLanguageOrDefault() async {
        let savedLanguageCode = userDefaults.string(forKey: languageKey)
        
        let targetLanguage: Language
        
        if let savedCode = savedLanguageCode,
           let savedLanguage = availableLanguages.first(where: { $0.code == savedCode }) {
            targetLanguage = savedLanguage
            print("📱 Using saved language: \(savedCode)")
        } else {
            targetLanguage = availableLanguages.first(where: { $0.isDefault }) ?? availableLanguages.first!
            print("🎯 Using default language: \(targetLanguage.code)")
        }
        
        await changeLanguage(to: targetLanguage)
    }
    
    @MainActor
    func changeLanguage(to language: Language) async {
        print("🔄 Changing language to: \(language.code)")
        isLoading = true
        errorMessage = nil
        
        do {
            let newTranslations = try await localizationService.fetchTranslations(for: language.code)
            
            // Update state
            currentLanguage = language
            translations = newTranslations
            
            // Save to UserDefaults
            userDefaults.set(language.code, forKey: languageKey)
            
            print("✅ Language changed successfully to \(language.code)")
            print("📚 Loaded \(newTranslations.count) translations")
            
        } catch {
            errorMessage = error.localizedDescription
            print("❌ Failed to change language: \(error.localizedDescription)")
        }
        
        isLoading = false
    }
    
    // MARK: - Translation Methods
    @MainActor
    func translate(_ key: String, defaultValue: String? = nil) -> String {
        if let translation = translations[key] {
            return translation
        }
        
        let fallback = defaultValue ?? key
        print("⚠️ Missing translation for key: '\(key)', using fallback: '\(fallback)'")
        return fallback
    }
    
    // MARK: - Utility Methods
    @MainActor
    func refresh() async {
        await loadAvailableLanguages()
        if let current = currentLanguage {
            await changeLanguage(to: current)
        }
    }
    
    @MainActor
    func resetToDefault() async {
        if let defaultLanguage = availableLanguages.first(where: { $0.isDefault }) {
            await changeLanguage(to: defaultLanguage)
        }
    }
}

// MARK: - Environment Key
struct LocalizationManagerKey: EnvironmentKey {
    @MainActor static let defaultValue = LocalizationManager()
}

extension EnvironmentValues {
    var localizationManager: LocalizationManager {
        get { self[LocalizationManagerKey.self] }
        set { self[LocalizationManagerKey.self] = newValue }
    }
}
