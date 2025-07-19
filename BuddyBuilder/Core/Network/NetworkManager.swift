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
