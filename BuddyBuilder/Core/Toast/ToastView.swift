import SwiftUI

struct EnhancedToastView: View {
    let toast: ToastMessage
    @Binding var isShowing: Bool
    @EnvironmentObject var localizationManager: LocalizationManager
    @State private var dragOffset: CGFloat = 0
    @State private var progress: CGFloat = 1.0
    
    private let displayDuration: TimeInterval = 3.0
    
    var body: some View {
        VStack {
            Spacer()
            
            HStack(spacing: 12) {
                // Message
                Text(localizedMessage)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.leading)
                    .lineLimit(3)
                    .fixedSize(horizontal: false, vertical: true)
                
                Spacer()
                
                // Close
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 18))
                        .foregroundColor(.secondary)
                }
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 14)
            .background(
                ZStack(alignment: .bottomLeading) {
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .fill(.ultraThinMaterial)   // ✅ Artık bir View
                        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                    
                    Rectangle()
                        .fill(toast.type.textColor)
                        .frame(height: 3)
                        .scaleEffect(x: progress, y: 1, anchor: .leading)
                        .animation(.linear(duration: displayDuration), value: progress)
                        .padding(.horizontal, 16)
                        .padding(.bottom, 3)
                }

            )
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            .shadow(color: .black.opacity(0.15), radius: 12, x: 0, y: 6)
            .offset(x: dragOffset)
            .gesture(
                DragGesture()
                    .onChanged { value in
                        dragOffset = value.translation.width
                    }
                    .onEnded { value in
                        if abs(value.translation.width) > 100 {
                            dismiss()
                        } else {
                            withAnimation(.spring()) { dragOffset = 0 }
                        }
                    }
            )
            .padding(.horizontal, 24)
            .padding(.bottom, 40) // floating above bottom
        }
        .transition(.move(edge: .bottom).combined(with: .opacity))
        .onAppear {
            progress = 0
            DispatchQueue.main.asyncAfter(deadline: .now() + displayDuration) {
                if isShowing { dismiss() }
            }
            
            // Haptic feedback
            let generator = UINotificationFeedbackGenerator()
            switch toast.type {
            case .success: generator.notificationOccurred(.success)
            case .error: generator.notificationOccurred(.error)
            default: generator.notificationOccurred(.warning)
            }
        }
    }
    
    private var localizedMessage: String {
        let commonMessages = [
            "Successfully joined the event!": "events.toast.join.success",
            "Successfully left the event!": "events.toast.leave.success",
            "Failed to join the event. Please try again.": "events.toast.join.error",
            "Failed to leave the event. Please try again.": "events.toast.leave.error"
        ]
        if let localizedKey = commonMessages[toast.message] {
            let localized = localizedKey.localized(using: localizationManager)
            return localized != localizedKey ? localized : toast.message
        }
        return toast.message
    }
    
    private func dismiss() {
        withAnimation(.spring()) {
            isShowing = false
            ToastManager.shared.dismissImmediately()
        }
    }
}
