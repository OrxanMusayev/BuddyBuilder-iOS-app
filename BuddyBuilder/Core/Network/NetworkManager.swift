// Dosya Yolu: BuddyBuilder/Core/Network/NetworkManager.swift

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
            }
        }
        
        request.timeoutInterval = 30
        
        if let body = body {
            request.httpBody = body
        }
        
        print("🌐 Making request to: \(endpoint)")
        if let headers = headers {
            print("📋 Headers: \(headers)")
        }
        
        return session.dataTaskPublisher(for: request)
            .map { result in
                // HTTP Status Code kontrolü
                if let httpResponse = result.response as? HTTPURLResponse {
                    print("📊 HTTP Status: \(httpResponse.statusCode)")
                }
                
                // Debug: Response'u yazdır
                print("📥 RAW RESPONSE:")
                let responseString = String(data: result.data, encoding: .utf8) ?? "nil"
                print(responseString)
                
                return result.data
            }
            .decode(type: type, decoder: JSONDecoder())
            .catch { error -> AnyPublisher<T, Error> in // Explicit type belirttik
                print("❌ Network Error: \(error)")
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
                return Fail<T, Error>(error: error) // Explicit generic type
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
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Geçersiz URL"
        case .noData:
            return "Veri bulunamadı"
        case .decodingError:
            return "Veri işleme hatası"
        }
    }
}
