// BuddyBuilder/Features/Events/Models/JoinEventResponse.swift

import Foundation

struct JoinEventResponse: Codable {
    let message: String
    
    var isSuccess: Bool {
        // API başarılı bir mesaj döndürdüğünde true dön
        return !message.isEmpty
    }
}
