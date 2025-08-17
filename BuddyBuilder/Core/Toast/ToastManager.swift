// BuddyBuilder/Core/Toast/ToastManager.swift - FIXED DURATION

import SwiftUI

// MARK: - Toast Manager (Singleton) - FIXED DURATION
class ToastManager: ObservableObject {
    static let shared = ToastManager()
    
    @Published var currentToast: ToastMessage?
    @Published var isShowing = false
    
    private var dismissTimer: Timer?
    
    private init() {}
    
    // FIXED: Default duration increased to 5 seconds
    func show(message: String, type: ToastType, duration: Double = 5.0) {
        print("🍞 ToastManager.show() called with:")
        print("   message: '\(message)'")
        print("   type: \(type)")
        print("   duration: \(duration) seconds")
        
        // Cancel existing timer
        dismissTimer?.invalidate()
        
        // Dismiss current toast if any
        if isShowing {
            print("🍞 Dismissing existing toast...")
            dismiss()
            
            // Small delay before showing new toast
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                self.showNewToast(message: message, type: type, duration: duration)
            }
        } else {
            showNewToast(message: message, type: type, duration: duration)
        }
    }
    
    private func showNewToast(message: String, type: ToastType, duration: Double) {
        print("🍞 Showing new toast...")
        
        // Create new toast
        currentToast = ToastMessage(
            id: UUID(),
            message: message,
            type: type,
            duration: duration
        )
        
        withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
            isShowing = true
        }
        
        print("🍞 Toast animation started, setting up timer for \(duration) seconds")
        
        // FIXED: Use timer instead of DispatchQueue for better control
        dismissTimer = Timer.scheduledTimer(withTimeInterval: duration, repeats: false) { [weak self] _ in
            print("🍞 Timer fired, auto-dismissing toast...")
            self?.dismiss()
        }
    }
    
    func dismiss() {
        print("🍞 ToastManager.dismiss() called")
        
        // Cancel timer
        dismissTimer?.invalidate()
        dismissTimer = nil
        
        withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
            isShowing = false
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            self.currentToast = nil
            print("🍞 Toast cleared from memory")
        }
    }
    
    // MARK: - Manual Dismiss (for swipe or tap)
    func dismissImmediately() {
        print("🍞 ToastManager.dismissImmediately() called")
        
        dismissTimer?.invalidate()
        dismissTimer = nil
        
        withAnimation(.easeOut(duration: 0.2)) {
            isShowing = false
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            self.currentToast = nil
        }
    }
    
    // MARK: - Debug Method
    func debugStatus() {
        print("🍞 ToastManager Debug Status:")
        print("   isShowing: \(isShowing)")
        print("   currentToast: \(currentToast?.message ?? "nil")")
        print("   timer active: \(dismissTimer != nil)")
    }
}

// MARK: - Toast Message Model (Unchanged)
struct ToastMessage: Identifiable {
    let id: UUID
    let message: String
    let type: ToastType
    let duration: Double
}

// MARK: - Toast Type (Unchanged)
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

// MARK: - Global Toast Helper Functions (UPDATED DURATIONS)
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
