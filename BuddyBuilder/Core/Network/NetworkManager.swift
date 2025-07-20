// BuddyBuilder/Core/Network/NetworkManager.swift

import Foundation
import Combine

class NetworkManager: ObservableObject {
    static let shared = NetworkManager()
    private let session = URLSession.shared
    
    private init() {}
    
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
        
        // Custom headers'ı ekle (varsa)
        if let headers = headers {
            for (key, value) in headers {
                request.addValue(value, forHTTPHeaderField: key)
                print("🔗 Added header: \(key): \(key == "Authorization" ? "\(value.prefix(20))..." : value)")
            }
        }
        
        request.timeoutInterval = 30
        
        if let body = body {
            request.httpBody = body
        }
        
        print("🌐 Making request to: \(endpoint)")
        if method != .GET {
            print("📋 Method: \(method.rawValue)")
        }
        
        return session.dataTaskPublisher(for: request)
            .map { result in
                // HTTP Status Code kontrolü
                if let httpResponse = result.response as? HTTPURLResponse {
                    print("📊 HTTP Status: \(httpResponse.statusCode)")
                    
                    // Authorization errors için özel handling
                    if httpResponse.statusCode == 401 {
                        print("🔐 Unauthorized - Token may be invalid or expired")
                    }
                }
                
                // Debug: Response'u yazdır (sadece başlangıcını)
                if let responseString = String(data: result.data, encoding: .utf8) {
                    let preview = responseString.count > 200 ? String(responseString.prefix(200)) + "..." : responseString
                    print("📥 Response preview: \(preview)")
                }
                
                return result.data
            }
            .decode(type: type, decoder: JSONDecoder())
            .catch { error -> AnyPublisher<T, Error> in
                print("❌ Network Error: \(error)")
                
                // Decoding error'ları için detaylı log
                if let decodingError = error as? DecodingError {
                    switch decodingError {
                    case .keyNotFound(let key, let context):
                        print("🔑 Missing key '\(key.stringValue)' in: \(context.debugDescription)")
                    case .typeMismatch(let type, let context):
                        print("🔀 Type mismatch for type '\(type)' in: \(context.debugDescription)")
                    case .valueNotFound(let type, let context):
                        print("❓ Value not found for type '\(type)' in: \(context.debugDescription)")
                    case .dataCorrupted(let context):
                        print("💥 Data corrupted: \(context.debugDescription)")
                    @unknown default:
                        print("❓ Unknown decoding error: \(decodingError)")
                    }
                }
                
                // URLError'lar için özel handling
                if let urlError = error as? URLError {
                    switch urlError.code {
                    case .notConnectedToInternet:
                        print("📵 No internet connection")
                    case .timedOut:
                        print("⏱️ Request timed out")
                    case .cannotFindHost:
                        print("🔍 Cannot find host")
                    default:
                        print("🌐 URL Error: \(urlError.localizedDescription)")
                    }
                }
                
                return Fail<T, Error>(error: error)
                    .eraseToAnyPublisher()
            }
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

// MARK: - Enhanced Network Manager with Auto-Refresh
extension NetworkManager {
    // New method specifically for token refresh (no auto-retry to avoid infinite loops)
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
        request.timeoutInterval = 10 // Shorter timeout for token refresh
        
        print("🔄 Token refresh request to: \(endpoint)")
        
        let (data, response) = try await session.data(for: request)
        
        // Check HTTP status
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
    
    // Enhanced request method with automatic token refresh
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
                // Add auth header if available
                var finalHeaders = headers ?? [:]
                if let token = TokenManager.shared.accessToken {
                    finalHeaders["Authorization"] = "Bearer \(token)"
                }
                
                // Make the request
                let result = await self.makeRequest(
                    endpoint: endpoint,
                    method: method,
                    body: body,
                    headers: finalHeaders,
                    type: type
                )
                
                switch result {
                case .success(let data):
                    promise(.success(data))
                    
                case .failure(let error):
                    // Check if it's a 401 error and we haven't already retried
                    if case NetworkError.unauthorized = error, retryCount == 0 {
                        print("🔐 Received 401, attempting token refresh...")
                        
                        // Try to refresh token
                        let refreshSuccess = await TokenManager.shared.refreshTokenIfNeeded()
                        
                        if refreshSuccess {
                            print("✅ Token refreshed, retrying original request...")
                            // Retry the original request with new token
                            let retryPublisher = self.requestWithAutoRefresh(
                                endpoint: endpoint,
                                method: method,
                                body: body,
                                headers: headers,
                                type: type,
                                retryCount: 1
                            )
                            
                            // 🔴 BURADA DEĞİŞİKLİK: cancellables set'ini tanımlayalım
                            var cancellables = Set<AnyCancellable>()
                            
                            retryPublisher
                                .sink(
                                    receiveCompletion: { completion in
                                        if case .failure(let retryError) = completion {
                                            promise(.failure(retryError))
                                        }
                                    },
                                    receiveValue: { value in
                                        promise(.success(value))
                                    }
                                )
                                .store(in: &cancellables) // 🔴 ARTIK HATA YOK!
                            
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
    
    // Helper method to make actual network request
    private func makeRequest<T: Codable>(
        endpoint: String,
        method: HTTPMethod,
        body: Data?,
        headers: [String: String],
        type: T.Type
    ) async -> Result<T, Error> {
        
        guard let url = URL(string: endpoint) else {
            return .failure(NetworkError.invalidURL)
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = method.rawValue
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // Add headers
        for (key, value) in headers {
            request.addValue(value, forHTTPHeaderField: key)
        }
        
        if let body = body {
            request.httpBody = body
        }
        
        request.timeoutInterval = 30
        
        do {
            let (data, response) = try await session.data(for: request)
            
            // Check HTTP status
            if let httpResponse = response as? HTTPURLResponse {
                if httpResponse.statusCode == 401 {
                    return .failure(NetworkError.unauthorized)
                } else if httpResponse.statusCode >= 400 {
                    return .failure(NetworkError.serverError(httpResponse.statusCode))
                }
            }
            
            let decodedData = try JSONDecoder().decode(type, from: data)
            return .success(decodedData)
            
        } catch {
            return .failure(error)
        }
    }
}
