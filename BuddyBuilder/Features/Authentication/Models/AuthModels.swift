// Dosya Yolu: BuddyBuilder/Features/Authentication/Models/AuthModels.swift

import Foundation

// Login Request Model
struct LoginRequest: Codable {
    let userName: String
    let password: String
    let rememberMe: Bool
}

// API Response Wrapper
struct APIResponse<T: Codable>: Codable {
    let success: Bool
    let message: String?
    let data: T?
    let errors: [String]?
    let timestamp: String
}

// Login Data (API'nin data field'ında dönen exact bilgiler)
struct LoginData: Codable {
    let userId: Int
    let username: String
    let email: String
    let accessToken: String
    let refreshToken: String
    let loginTime: String
    
    // Computed property - token'a kolay erişim için
    var token: String {
        return accessToken
    }
}

// Login Response Type
typealias LoginResponse = APIResponse<LoginData>

// User Model (LoginData'dan türetilmiş)
struct User: Codable {
    let id: Int
    let username: String
    let email: String
    
    init(from loginData: LoginData) {
        self.id = loginData.userId
        self.username = loginData.username
        self.email = loginData.email
    }
}


// Logout Request Model
struct LogoutRequest: Codable {
    let refreshToken: String
}

// Empty Response Model (logout genellikle void döner)
struct EmptyResponse: Codable {
    // Boş struct - sadece decode işlemi için
}
