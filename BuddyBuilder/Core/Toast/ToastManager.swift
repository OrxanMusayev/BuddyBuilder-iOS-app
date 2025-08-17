// BuddyBuilder/Core/Toast/ToastManager.swift - STACKED TOASTS

import SwiftUI

// MARK: - Toast Manager (Singleton) - STACKED
class ToastManager: ObservableObject {
    static let shared = ToastManager()
    
    @Published var toasts: [ToastMessage] = []
    private var dismissTimers: [UUID: Timer] = [:]
    
    private init() {}
    
    // MARK: - Show Toast
    func show(message: String, type: ToastType, duration: Double = 5.0) {
        let toast = ToastMessage(
            id: UUID(),
            message: message,
            type: type,
            duration: duration
        )
        
        withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
            toasts.append(toast)
        }
        
        print("🍞 Showing new toast: '\(message)' (duration \(duration)s)")
        
        // Schedule auto-dismiss
        let timer = Timer.scheduledTimer(withTimeInterval: duration, repeats: false) { [weak self] _ in
            self?.dismiss(toast)
        }
        dismissTimers[toast.id] = timer
    }
    
    // MARK: - Dismiss Specific Toast
    func dismiss(_ toast: ToastMessage) {
        print("🍞 Dismissing toast: '\(toast.message)'")
        dismissTimers[toast.id]?.invalidate()
        dismissTimers.removeValue(forKey: toast.id)
        
        withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
            toasts.removeAll { $0.id == toast.id }
        }
    }
    
    // MARK: - Immediate Dismiss (all)
    func dismissImmediately() {
        print("🍞 Dismissing all toasts immediately")
        dismissTimers.values.forEach { $0.invalidate() }
        dismissTimers.removeAll()
        
        withAnimation(.easeOut(duration: 0.2)) {
            toasts.removeAll()
        }
    }
    
    // MARK: - Debug
    func debugStatus() {
        print("🍞 ToastManager Debug Status:")
        print("   active toasts: \(toasts.count)")
        for toast in toasts {
            print("   - \(toast.message) (\(toast.id))")
        }
    }
}

// MARK: - Toast Message Model
struct ToastMessage: Identifiable, Equatable {
    let id: UUID
    let message: String
    let type: ToastType
    let duration: Double
}

// MARK: - Toast Type
enum ToastType {
    case success
    case error
    case warning
    case info
    
    var backgroundColor: Color {
        switch self {
        case .success: return .green
        case .error: return .red
        case .warning: return .orange
        case .info: return .blue
        }
    }
    
    var iconName: String {
        switch self {
        case .success: return "checkmark.circle.fill"
        case .error: return "xmark.circle.fill"
        case .warning: return "exclamationmark.triangle.fill"
        case .info: return "info.circle.fill"
        }
    }
    
    var textColor: Color {
        return .white
    }
    
    var hapticType: UIImpactFeedbackGenerator.FeedbackStyle {
        switch self {
        case .success: return .light
        case .error: return .heavy
        case .warning: return .medium
        case .info: return .light
        }
    }
}

// MARK: - Global Toast Helpers
extension View {
    func showSuccessToast(_ message: String) {
        ToastManager.shared.show(message: message, type: .success, duration: 4.0)
    }
    
    func showErrorToast(_ message: String) {
        ToastManager.shared.show(message: message, type: .error, duration: 6.0)
    }
    
    func showWarningToast(_ message: String) {
        ToastManager.shared.show(message: message, type: .warning, duration: 5.0)
    }
    
    func showInfoToast(_ message: String) {
        ToastManager.shared.show(message: message, type: .info, duration: 4.0)
    }
}
