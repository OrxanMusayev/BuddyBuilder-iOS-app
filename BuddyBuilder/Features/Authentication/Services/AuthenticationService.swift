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
}
