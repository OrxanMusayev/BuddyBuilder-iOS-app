// BuddyBuilder/Core/Toast/ToastContainer.swift - STACKED TOASTS

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
                
                VStack(spacing: 12) {
                    ForEach(toastManager.toasts) { toast in
                        EnhancedToastView(
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
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                        .zIndex(1000)
                    }
                }
                .padding(.bottom, 40)
                .padding(.horizontal, 16)
            }
            .ignoresSafeArea(.keyboard, edges: .bottom)
        }
    }
}
