// BuddyBuilder/Core/Toast/ToastContainer.swift - IMPROVED STACKED TOASTS

import SwiftUI

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
            
            VStack {
                Spacer()
                
                // FIXED: Compact spacing for multiple toasts
                VStack(spacing: 8) { // Reduced from 12 to 8
                    ForEach(toastManager.toasts) { toast in
                        CompactToastView(
                            toast: toast,
                            isShowing: Binding(
                                get: { toastManager.toasts.contains(toast) },
                                set: { newValue in
                                    if !newValue {
                                        toastManager.dismiss(toast)
                                    }
                                }
                            )
                        )
                        .environmentObject(localizationManager)
                        .transition(.asymmetric(
                            insertion: .move(edge: .bottom).combined(with: .opacity),
                            removal: .opacity.combined(with: .scale(scale: 0.8))
                        ))
                        .zIndex(Double(1000 - toast.hashValue % 100)) // Unique z-index for each toast
                    }
                }
                .padding(.bottom, 40)
                .padding(.horizontal, 16)
            }
            .ignoresSafeArea(.keyboard, edges: .bottom)
        }
    }
}

// MARK: - Compact Toast View for Multiple Toasts
struct CompactToastView: View {
    let toast: ToastMessage
    @Binding var isShowing: Bool
    @EnvironmentObject var localizationManager: LocalizationManager
    @State private var dragOffset: CGFloat = 0
    @State private var progress: CGFloat = 1.0
    @State private var isExpanded = false
    
    private let displayDuration: TimeInterval = 3.0
    private let maxLines: Int = 2
    
    var body: some View {
        HStack(spacing: 10) {
            // Icon - Smaller for compact view
            Image(systemName: toast.type.iconName)
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(toast.type.textColor)
                .frame(width: 20, height: 20)
                .background(
                    Circle()
                        .fill(toast.type.textColor.opacity(0.15))
                )
            
            // Message - Compact with expandable option
            VStack(alignment: .leading, spacing: 2) {
                Text(localizedMessage)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.leading)
                    .lineLimit(isExpanded ? nil : maxLines)
                    .fixedSize(horizontal: false, vertical: true)
                    .animation(.easeInOut(duration: 0.2), value: isExpanded)
                
                // Show expand button if text is truncated
                if isTextTruncated {
                    Button(action: {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            isExpanded.toggle()
                        }
                    }) {
                        Text(isExpanded ? "Show less" : "Show more")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(toast.type.backgroundColor)
                    }
                }
            }
            
            Spacer()
            
            // Close button - Smaller
            Button {
                dismiss()
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 16))
                    .foregroundColor(.secondary)
            }
        }
        .padding(.horizontal, 14) // Reduced padding
        .padding(.vertical, 10)   // Reduced padding
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous)) // Smaller radius
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(toast.type.backgroundColor.opacity(0.3), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4) // Lighter shadow
        .offset(x: dragOffset)
        .scaleEffect(isShowing ? 1.0 : 0.8)
        .opacity(isShowing ? 1.0 : 0.0)
        .gesture(
            DragGesture()
                .onChanged { value in
                    dragOffset = value.translation.width
                }
                .onEnded { value in
                    if abs(value.translation.width) > 100 {
                        dismiss()
                    } else {
                        withAnimation(.spring()) {
                            dragOffset = 0
                        }
                    }
                }
        )
        .overlay(
            // Progress bar - Thinner
            Rectangle()
                .fill(toast.type.backgroundColor)
                .frame(height: 2) // Thinner progress bar
                .scaleEffect(x: progress, y: 1, anchor: .leading)
                .animation(.linear(duration: displayDuration), value: progress),
            alignment: .bottom
        )
        .onAppear {
            withAnimation(.easeOut(duration: 0.3)) {
                isShowing = true
            }
            
            progress = 0
            
            DispatchQueue.main.asyncAfter(deadline: .now() + displayDuration) {
                if isShowing {
                    dismiss()
                }
            }
            
            // Haptic feedback
            let generator = UINotificationFeedbackGenerator()
            switch toast.type {
            case .success: generator.notificationOccurred(.success)
            case .error: generator.notificationOccurred(.error)
            default: generator.notificationOccurred(.warning)
            }
        }
        .onTapGesture {
            // Tap to expand/collapse long messages
            if isTextTruncated {
                withAnimation(.easeInOut(duration: 0.2)) {
                    isExpanded.toggle()
                }
            }
        }
    }
    
    private var localizedMessage: String {
        let commonMessages = [
            "Successfully joined the event!": "events.toast.join.success",
            "Successfully left the event!": "events.toast.leave.success",
            "Failed to join the event. Please try again.": "events.toast.join.error",
            "Failed to leave the event. Please try again.": "events.toast.leave.error",
            "Your skill level is above the maximum allowed for this event": "events.toast.skill.too_high",
            "Your skill level is below the minimum allowed for this event": "events.toast.skill.too_low",
            "This event is full. No more spots available.": "events.toast.event.full",
            "Registration for this event has closed.": "events.toast.registration.closed"
        ]
        
        if let localizedKey = commonMessages[toast.message] {
            let localized = localizedKey.localized(using: localizationManager)
            return localized != localizedKey ? localized : toast.message
        }
        return toast.message
    }
    
    private var isTextTruncated: Bool {
        // Estimate if text would be truncated (rough calculation)
        let font = UIFont.systemFont(ofSize: 14, weight: .medium)
        let maxWidth: CGFloat = UIScreen.main.bounds.width - 120 // Account for padding and icon
        let size = localizedMessage.boundingRect(
            with: CGSize(width: maxWidth, height: .greatestFiniteMagnitude),
            options: [.usesLineFragmentOrigin, .usesFontLeading],
            attributes: [.font: font],
            context: nil
        )
        
        let lineHeight = font.lineHeight
        return size.height > lineHeight * CGFloat(maxLines)
    }
    
    private func dismiss() {
        withAnimation(.easeOut(duration: 0.2)) {
            isShowing = false
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            ToastManager.shared.dismiss(toast)
        }
    }
}

// MARK: - Toast Message Extensions for Hashable
extension ToastMessage: Hashable {
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
        hasher.combine(message)
        hasher.combine(type.hashValue)
    }
    
    static func == (lhs: ToastMessage, rhs: ToastMessage) -> Bool {
        return lhs.id == rhs.id
    }
}

extension ToastType: Hashable {
    func hash(into hasher: inout Hasher) {
        hasher.combine(self.iconName)
    }
}
