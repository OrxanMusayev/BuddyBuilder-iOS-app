// BuddyBuilder/Core/Network/NetworkManager.swift - RETRY TOKEN DÜZELTMESİ

import Foundation
import Combine

class NetworkManager: ObservableObject {
    static let shared = NetworkManager()
    private let session = URLSession.shared
    
    private init() {}
    
    // MARK: - DÜZELTME: Enhanced request with proper token refresh
    func requestWithAutoRefresh<T: Codable>(
        endpoint: String,
        method: HTTPMethod = .GET,
        body: Data? = nil,
        headers: [String: String]? = nil,
        type: T.Type,
        retryCount: Int = 0
    ) -> AnyPublisher<T, Error> {
        
        return Future<T, Error> { promise in
            Task {
                do {
                    // DÜZELTME: Her seferinde fresh token al
                    let currentToken = TokenManager.shared.accessToken
                    print("🔵 Current token for request: \(currentToken?.prefix(20) ?? "nil")...")
                    
                    // Headers hazırla
                    var finalHeaders = headers ?? [:]
                    if let token = currentToken {
                        finalHeaders["Authorization"] = "Bearer \(token)"
                    }
                    
                    // Request yap
                    let result = try await self.makeAsyncRequest(
                        endpoint: endpoint,
                        method: method,
                        body: body,
                        headers: finalHeaders,
                        type: type
                    )
                    
                    promise(.success(result))
                    
                } catch {
                    // 401 hatası ve henüz retry yapılmadıysa
                    if case NetworkError.unauthorized = error, retryCount == 0 {
                        print("🔐 Received 401, attempting token refresh...")
                        
                        // Token refresh
                        let refreshSuccess = await TokenManager.shared.refreshTokenIfNeeded()
                        
                        if refreshSuccess {
                            print("✅ Token refreshed successfully, retrying original request...")
                            
                            
                            do {
                                // DÜZELTME: Refresh'ten sonra yeni token'ı al
                                let freshToken = TokenManager.shared.accessToken
                                print("🔄 Fresh token for retry: \(freshToken?.prefix(20) ?? "nil")...")
                                
                                guard let newToken = freshToken, !newToken.isEmpty else {
                                    print("❌ No fresh token available after refresh!")
                                    promise(.failure(NetworkError.unauthorized))
                                    return
                                }
                                
                                // DÜZELTME: Yeni headers ile retry
                                var retryHeaders = headers ?? [:]
                                retryHeaders["Authorization"] = "Bearer \(newToken)"
                                
                                print("🔄 Retrying request with NEW token...")
                                let retryResult = try await self.makeAsyncRequest(
                                    endpoint: endpoint,
                                    method: method,
                                    body: body,
                                    headers: retryHeaders,
                                    type: type
                                )
                                
                                print("✅ RETRY SUCCESSFUL!")
                                promise(.success(retryResult))
                                
                            } catch {
                                print("❌ RETRY FAILED: \(error)")
                                promise(.failure(error))
                            }
                            
                        } else {
                            print("❌ Token refresh failed, user needs to login again")
                            promise(.failure(NetworkError.unauthorized))
                        }
                        
                    } else {
                        promise(.failure(error))
                    }
                }
            }
        }
        .eraseToAnyPublisher()
    }
    
    // MARK: - Async network request helper
    private func makeAsyncRequest<T: Codable>(
        endpoint: String,
        method: HTTPMethod,
        body: Data?,
        headers: [String: String],
        type: T.Type
    ) async throws -> T {
        
        guard let url = URL(string: endpoint) else {
            throw NetworkError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = method.rawValue
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // Add headers
        for (key, value) in headers {
            request.addValue(value, forHTTPHeaderField: key)
            
            if key == "Authorization" {
                print("🔐 Using Authorization header: \(value.prefix(25))...")
            }
        }
        
        if let body = body {
            request.httpBody = body
        }
        
        request.timeoutInterval = 30
        
        let (data, response) = try await session.data(for: request)
        
        // Check HTTP status
        if let httpResponse = response as? HTTPURLResponse {
            print("📊 Response Status: \(httpResponse.statusCode) for \(endpoint)")
            
            if httpResponse.statusCode == 401 {
                print("🔴 401 UNAUTHORIZED!")
                throw NetworkError.unauthorized
            } else if httpResponse.statusCode >= 400 {
                throw NetworkError.serverError(httpResponse.statusCode)
            }
        }
        
        let decodedData = try JSONDecoder().decode(type, from: data)
        return decodedData
    }
    
    // MARK: - Token refresh API call
    func performTokenRefresh<T: Codable>(
        endpoint: String,
        requestData: Data,
        type: T.Type = T.self
    ) async throws -> T {
        guard let url = URL(string: endpoint) else {
            throw NetworkError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = requestData
        request.timeoutInterval = 10
        
        print("🔄 Token refresh request to: \(endpoint)")
        
        let (data, response) = try await session.data(for: request)
        
        if let httpResponse = response as? HTTPURLResponse {
            print("📊 Token refresh HTTP Status: \(httpResponse.statusCode)")
            
            if httpResponse.statusCode == 401 {
                throw NetworkError.unauthorized
            }
        }
        
        // Debug response
        if let responseString = String(data: data, encoding: .utf8) {
            let preview = responseString.count > 200 ? String(responseString.prefix(200)) + "..." : responseString
            print("📥 Token refresh response: \(preview)")
        }
        
        return try JSONDecoder().decode(type, from: data)
    }
    
    // MARK: - Simple request (for login without auto-refresh)
    func request<T: Codable>(
        endpoint: String,
        method: HTTPMethod = .GET,
        body: Data? = nil,
        headers: [String: String]? = nil,
        type: T.Type
    ) -> AnyPublisher<T, Error> {
        guard let url = URL(string: endpoint) else {
            print("❌ Invalid URL: \(endpoint)")
            return Fail(error: NetworkError.invalidURL)
                .eraseToAnyPublisher()
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = method.rawValue
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        if let headers = headers {
            for (key, value) in headers {
                request.addValue(value, forHTTPHeaderField: key)
            }
        }
        
        request.timeoutInterval = 30
        
        if let body = body {
            request.httpBody = body
        }
        
        return session.dataTaskPublisher(for: request)
            .map { result in
                if let httpResponse = result.response as? HTTPURLResponse {
                    print("📊 HTTP Status: \(httpResponse.statusCode)")
                }
                return result.data
            }
            .decode(type: type, decoder: JSONDecoder())
            .receive(on: DispatchQueue.main)
            .eraseToAnyPublisher()
    }
}

enum HTTPMethod: String {
    case GET = "GET"
    case POST = "POST"
    case PUT = "PUT"
    case DELETE = "DELETE"
}

enum NetworkError: Error, LocalizedError {
    case invalidURL
    case noData
    case decodingError
    case unauthorized
    case serverError(Int)
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid URL"
        case .noData:
            return "No data received"
        case .decodingError:
            return "Data decoding error"
        case .unauthorized:
            return "Unauthorized - Please login again"
        case .serverError(let code):
            return "Server error with code: \(code)"
        }
    }
}
