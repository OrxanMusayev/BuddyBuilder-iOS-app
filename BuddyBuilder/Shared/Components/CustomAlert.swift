// BuddyBuilder/Shared/Components/CustomAlert.swift

import SwiftUI

struct CustomAlert: View {
    let title: String
    let message: String
    let buttonText: String
    let onButtonTap: () -> Void
    @Binding var isPresented: Bool
    @EnvironmentObject var localizationManager: LocalizationManager
    
    var body: some View {
        ZStack {
            // Background overlay
            Color.black.opacity(0.4)
                .ignoresSafeArea()
                .onTapGesture {
                    // Allow dismissing by tapping outside
                    isPresented = false
                }
            
            // Alert container
            VStack(spacing: 0) {
                // Title and message
                VStack(spacing: 16) {
                    // Title
                    Text(title)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.primaryText)
                        .multilineTextAlignment(.center)
                    
                    // Message
                    Text(message)
                        .font(.system(size: 16, weight: .regular))
                        .foregroundColor(.secondaryText)
                        .multilineTextAlignment(.center)
                        .lineLimit(nil)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(.horizontal, 24)
                .padding(.top, 24)
                .padding(.bottom, 20)
                
                // Divider
                Rectangle()
                    .fill(Color.gray.opacity(0.3))
                    .frame(height: 0.5)
                
                // Button
                Button(action: {
                    onButtonTap()
                    isPresented = false
                }) {
                    Text(buttonText)
                        .font(.system(size: 17, weight: .medium))
                        .foregroundColor(.primaryOrange)
                        .frame(maxWidth: .infinity)
                        .frame(height: 44)
                        .background(Color.clear)
                }
                .buttonStyle(PlainButtonStyle())
            }
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(Color.cardBackground)
                    .shadow(color: .black.opacity(0.15), radius: 20, x: 0, y: 10)
            )
            .frame(maxWidth: 300)
            .padding(.horizontal, 40)
        }
        .transition(.asymmetric(
            insertion: .scale(scale: 0.8).combined(with: .opacity),
            removal: .scale(scale: 0.9).combined(with: .opacity)
        ))
        .animation(.spring(response: 0.5, dampingFraction: 0.8), value: isPresented)
    }
}

// MARK: - View Modifier for Custom Alert
struct CustomAlertModifier: ViewModifier {
    @Binding var isPresented: Bool
    let title: String
    let message: String
    let buttonText: String
    let onButtonTap: () -> Void
    
    func body(content: Content) -> some View {
        content
            .overlay(
                Group {
                    if isPresented {
                        CustomAlert(
                            title: title,
                            message: message,
                            buttonText: buttonText,
                            onButtonTap: onButtonTap,
                            isPresented: $isPresented
                        )
                        .zIndex(999)
                    }
                }
            )
    }
}

// MARK: - View Extension
extension View {
    func customAlert(
        isPresented: Binding<Bool>,
        title: String,
        message: String,
        buttonText: String = "OK",
        onButtonTap: @escaping () -> Void = {}
    ) -> some View {
        self.modifier(
            CustomAlertModifier(
                isPresented: isPresented,
                title: title,
                message: message,
                buttonText: buttonText,
                onButtonTap: onButtonTap
            )
        )
    }
}

#Preview {
    VStack {
        Text("Preview Content")
            .padding()
    }
    .customAlert(
        isPresented: .constant(true),
        title: "Error",
        message: "This is a sample error message that demonstrates how the custom alert looks.",
        buttonText: "OK"
    )
}
