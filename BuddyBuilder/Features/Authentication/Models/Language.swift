import Foundation

// MARK: - Language Model
struct Language: Codable, Identifiable, Equatable {
    let id = UUID()
    let code: String
    let name: String
    let nativeName: String
    let isDefault: Bool
    let isActive: Bool
    
    enum CodingKeys: String, CodingKey {
        case code, name, nativeName, isDefault, isActive
    }
}

// MARK: - Translation Response Model
struct TranslationResponse: Codable {
    let language: String
    let translations: [String: String]
}

// MARK: - Localization Error
enum LocalizationError: Error, LocalizedError {
    case networkError(String)
    case decodingError(String)
    case noTranslationsFound
    case languageNotSupported(String)
    
    var errorDescription: String? {
        switch self {
        case .networkError(let message):
            return "Network error: \(message)"
        case .decodingError(let message):
            return "Decoding error: \(message)"
        case .noTranslationsFound:
            return "No translations found"
        case .languageNotSupported(let code):
            return "Language '\(code)' is not supported"
        }
    }
}
