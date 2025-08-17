// BuddyBuilder/Core/Toast/ToastView.swift - FIXED DISMISS

import SwiftUI

// MARK: - Enhanced Toast View - FIXED
struct EnhancedToastView: View {
    let toast: ToastMessage
    @Binding var isShowing: Bool
    @EnvironmentObject var localizationManager: LocalizationManager
    @State private var dragOffset: CGFloat = 0
    
    var body: some View {
        HStack(spacing: 12) {
            // Icon
            Image(systemName: toast.type.iconName)
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(toast.type.textColor)
                .frame(width: 24, height: 24)
            
            // Message
            Text(localizedMessage)
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(toast.type.textColor)
                .multilineTextAlignment(.leading)
                .lineLimit(3)
                .fixedSize(horizontal: false, vertical: true)
            
            Spacer()
            
            // Close button
            Button(action: {
                print("🍞 Toast close button tapped")
                ToastManager.shared.dismissImmediately() // FIXED: Use immediate dismiss
            }) {
                Image(systemName: "xmark")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(toast.type.textColor.opacity(0.8))
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(toast.type.backgroundColor)
                .shadow(color: .black.opacity(0.25), radius: 12, x: 0, y: 6)
        )
        .padding(.horizontal, 20)
        .offset(x: dragOffset)
        .gesture(
            DragGesture()
                .onChanged { value in
                    if abs(value.translation.width) > abs(value.translation.height) {
                        dragOffset = value.translation.width
                    }
                }
                .onEnded { value in
                    // FIXED: Lower threshold for easier dismiss
                    if abs(value.translation.width) > 80 {
                        print("🍞 Toast swiped to dismiss")
                        ToastManager.shared.dismissImmediately()
                    } else {
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                            dragOffset = 0
                        }
                    }
                }
        )
        .onTapGesture {
            // FIXED: Optional tap to dismiss (comment out if you don't want this)
            // print("🍞 Toast tapped to dismiss")
            // ToastManager.shared.dismissImmediately()
        }
        .onAppear {
            print("🍞 Toast appeared: '\(toast.message)'")
            
            // Haptic feedback when toast appears
            let impactFeedback = UIImpactFeedbackGenerator(style: toast.type.hapticType)
            impactFeedback.impactOccurred()
        }
        .onDisappear {
            print("🍞 Toast disappeared")
        }
    }
    
    private var localizedMessage: String {
        // Try to localize common messages
        let commonMessages = [
            "Successfully joined the event!": "events.toast.join.success",
            "Successfully left the event!": "events.toast.leave.success",
            "Failed to join the event. Please try again.": "events.toast.join.error",
            "Failed to leave the event. Please try again.": "events.toast.leave.error",
            "Your skill level doesn't match the event requirements.": "events.toast.skill.mismatch",
            "You don't meet the requirements for this event.": "events.toast.requirements.error",
            "You're already registered for this event.": "events.toast.already.registered",
            "This event is full. No more spots available.": "events.toast.event.full",
            "Registration for this event has closed.": "events.toast.registration.closed",
            "Event not found. It may have been deleted.": "events.toast.event.not.found",
            "You don't have permission to perform this action.": "events.toast.unauthorized",
            "Network error. Please check your connection.": "events.toast.network.error"
        ]
        
        // Check if we have a localized version
        if let localizedKey = commonMessages[toast.message] {
            let localized = localizedKey.localized(using: localizationManager)
            // If localization returned the key (not found), use original message
            return localized != localizedKey ? localized : toast.message
        }
        
        return toast.message
    }
}

// MARK: - Toast Container for App Level - FIXED
struct ToastContainer<Content: View>: View {
    let content: Content
    @StateObject private var toastManager = ToastManager.shared
    @EnvironmentObject var localizationManager: LocalizationManager
    
    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }
    
    var body: some View {
        ZStack {
            content
            
            // Toast overlay
            if toastManager.isShowing, let toast = toastManager.currentToast {
                VStack {
                    Spacer()
                    
                    EnhancedToastView(
                        toast: toast,
                        isShowing: $toastManager.isShowing
                    )
                    .environmentObject(localizationManager)
                    .transition(.asymmetric(
                        insertion: .move(edge: .bottom).combined(with: .opacity),
                        removal: .move(edge: .bottom).combined(with: .opacity)
                    ))
                    .animation(.spring(response: 0.5, dampingFraction: 0.8), value: toastManager.isShowing)
                    .zIndex(1000)
                    
                    // FIXED: Better bottom spacing
                    Color.clear.frame(height: 120) // Increased from 100 to 120
                }
                .ignoresSafeArea(.keyboard, edges: .bottom)
            }
        }
        .onReceive(toastManager.$isShowing) { isShowing in
            print("🍞 ToastContainer - isShowing changed to: \(isShowing)")
        }
    }
}
