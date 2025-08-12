// Dosya Yolu: BuddyBuilder/Features/Authentication/Services/AuthenticationService.swift

import Foundation
import Combine

class AuthenticationService {
    private let networkManager = NetworkManager.shared
    private let baseURL = "http://192.168.100.76:5206/api/Auth"
    
    func login(userName: String, password: String, rememberMe: Bool) -> AnyPublisher<LoginResponse, Error> {
        let loginRequest = LoginRequest(
            userName: userName,
            password: password,
            rememberMe: rememberMe
        )
        
        guard let requestData = try? JSONEncoder().encode(loginRequest) else {
            print("❌ Failed to encode login request")
            return Fail(error: NetworkError.decodingError)
                .eraseToAnyPublisher()
        }
        
        // Debug: Request'i yazdır
        print("🚀 LOGIN REQUEST:")
        print("URL: \(baseURL)/login")
        print("Body: \(String(data: requestData, encoding: .utf8) ?? "nil")")
        
        return networkManager.request(
            endpoint: "\(baseURL)/login",
            method: .POST,
            body: requestData,
            type: LoginResponse.self
        )
    }
    
    func logout(refreshToken: String, accessToken: String) -> AnyPublisher<Void, Error> {
        let logoutURL = "\(baseURL)/logout?refreshToken=\(refreshToken)"
        
                // Access token'ı header olarak ekle
                let headers = [
                    "Authorization": "Bearer \(accessToken)"
                ]
                
                // Debug: Request'i yazdır
                print("🚀 LOGOUT REQUEST:")
                print("URL: \(logoutURL)")
                print("Headers: \(headers)")
                
                return networkManager.request(
                    endpoint: logoutURL,
                    method: .POST,
                    body: nil,
                    headers: headers,
                    type: EmptyResponse.self
                )
                .catch { error -> AnyPublisher<EmptyResponse, Error> in
                    // Eğer JSON decode hatası ise ve HTTP status code başarılıysa, ignore et
                    if let decodingError = error as? DecodingError {
                        print("⚠️ Logout response boş - bu normal (EmptyResponse expected)")
                        return Just(EmptyResponse())
                            .setFailureType(to: Error.self)
                            .eraseToAnyPublisher()
                    }
                    return Fail(error: error)
                        .eraseToAnyPublisher()
                }
                .handleEvents(receiveOutput: { _ in
                        // ✅ İşte burada cache temizliği yapılır
                        CentralCacheManager.shared.clearUserData()
                        print("🧹 Cleared user-related cache on logout")
                    })
                .map { _ in () }
                .eraseToAnyPublisher()
    }
    
    func register(_ request: RegistrationRequest) -> AnyPublisher<RegistrationResponse, Error> {
            guard let requestData = try? JSONEncoder().encode(request) else {
                print("❌ Failed to encode registration request")
                return Fail(error: NetworkError.decodingError)
                    .eraseToAnyPublisher()
            }
            
            // Debug: Request'i yazdır
            print("🚀 REGISTRATION REQUEST:")
            print("URL: \(baseURL)/register")
            print("Body: \(String(data: requestData, encoding: .utf8) ?? "nil")")
            
            return networkManager.request(
                endpoint: "\(baseURL)/register",
                method: .POST,
                body: requestData,
                type: RegistrationResponse.self
            )
        }
}

// BU KODLARI AuthenticationService.swift DOSYASININ SONUNA EKLEYİN

// MARK: - Token Refresh Support
extension AuthenticationService {
    func loginWithTokenSave(userName: String, password: String, rememberMe: Bool) -> AnyPublisher<LoginResponse, Error> {
        let loginRequest = LoginRequest(
            userName: userName,
            password: password,
            rememberMe: rememberMe
        )
        
        guard let requestData = try? JSONEncoder().encode(loginRequest) else {
            print("❌ Failed to encode login request")
            return Fail(error: NetworkError.decodingError)
                .eraseToAnyPublisher()
        }
        
        // Debug: Request'i yazdır
        print("🚀 LOGIN REQUEST WITH TOKEN SAVE:")
        print("URL: \(baseURL)/login")
        print("Body: \(String(data: requestData, encoding: .utf8) ?? "nil")")
        
        return networkManager.request(
            endpoint: "\(baseURL)/login",
            method: .POST,
            body: requestData,
            type: LoginResponse.self
        )
        .handleEvents(
            receiveOutput: { response in
                if response.success, let loginData = response.data {
                    // Save tokens using TokenManager
                    TokenManager.shared.accessToken = loginData.accessToken
                    TokenManager.shared.refreshToken = loginData.refreshToken
                    print("💾 Tokens saved via TokenManager")
                }
            }
        )
        .eraseToAnyPublisher()
    }
}
