import SwiftUI
// API Response Wrapper
struct APIResponse<T: Codable>: Codable {
    let success: Bool
    let message: String?
    let data: T?
    let errors: [String]?
    let timestamp: String
    
    var userFriendlyMessage: String {
        if success {
            return message ?? "Operation completed successfully"
        } else {
            return message ?? "An unexpected error occurred"
        }
    }
}

struct APIError: Error, LocalizedError {
    let message: String
    let isSuccess: Bool
    let originalResponse: String?
    
    var errorDescription: String? {
        return message
    }
    
    var localizedDescription: String {
        return message
    }
    
    init(message: String, isSuccess: Bool = false, originalResponse: String? = nil) {
        self.message = message
        self.isSuccess = isSuccess
        self.originalResponse = originalResponse
    }
}
