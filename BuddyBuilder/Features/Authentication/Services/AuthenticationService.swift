// Dosya Yolu: BuddyBuilder/Features/Authentication/Services/AuthenticationService.swift

import Foundation
import Combine

class AuthenticationService {
    private let networkManager = NetworkManager.shared
    private let baseURL = "http://127.0.0.1:5206/api/Auth"
    
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
                .map { _ in () }
                .eraseToAnyPublisher()
    }
}
