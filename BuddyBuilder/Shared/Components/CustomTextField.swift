// BuddyBuilder/Shared/Components/CustomTextField.swift (Updated)
import SwiftUI

// MARK: - Custom Text Field (No Title) - Dark Mode Adaptive
struct CustomTextFieldNoTitle: View {
    @Binding var text: String
    let icon: String
    let placeholder: String
    var hasError: Bool = false
    var isDisabled: Bool = false
    
    @FocusState private var isFocused: Bool
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        HStack(spacing: 12) {
            // Icon
            Image(systemName: icon)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(iconColor)
                .frame(width: 20)
            
            // Text Field
            TextField(placeholder, text: $text)
                .font(.system(size: 16))
                .foregroundColor(.primaryText)
                .focused($isFocused)
                .disabled(isDisabled)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(backgroundColor)
        .clipShape(RoundedRectangle(cornerRadius: 25))
        .overlay(
            RoundedRectangle(cornerRadius: 25)
                .stroke(borderColor, lineWidth: borderWidth)
        )
        .animation(.easeInOut(duration: 0.2), value: isFocused)
        .animation(.easeInOut(duration: 0.2), value: hasError)
    }
    
    // MARK: - Computed Properties (Dark Mode Adaptive)
    private var iconColor: Color {
        if hasError {
            return .errorRed
        } else if isFocused {
            return .primaryOrange // Focus olduğunda primary orange kalsın
        } else {
            return .secondaryText // Normal durumda secondary text (adaptive)
        }
    }
    
    private var backgroundColor: Color {
        if isDisabled {
            return Color.formBackground.opacity(0.5)
        } else {
            return Color.formBackground
        }
    }
    
    private var borderColor: Color {
        if hasError {
            return .errorRed
        } else if isFocused {
            return .primaryOrange
        } else {
            return .dynamicBorder
        }
    }
    
    private var borderWidth: CGFloat {
        if hasError || isFocused {
            return 2.0
        } else {
            return 1.0
        }
    }
}

// MARK: - Custom Password Field (No Title) - FIXED VERSION
struct CustomPasswordFieldNoTitle: View {
    @Binding var text: String
    @Binding var showPassword: Bool
    let placeholder: String
    var hasError: Bool = false
    var isDisabled: Bool = false
    
    @FocusState private var isFocused: Bool
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        HStack(spacing: 12) {
            // Lock Icon
            Image(systemName: "lock.fill")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(iconColor)
                .frame(width: 20)
            
            // FIXED: Stable password field container
            ZStack(alignment: .leading) {
                // Placeholder
                if text.isEmpty {
                    TextField(placeholder, text: $text)
                        .font(.system(size: 16))
                        .foregroundColor(.primaryText)
                        .focused($isFocused)
                        .disabled(isDisabled)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                }
                
                // FIXED: Always use TextField, manually handle security
                TextField("", text: $text)
                    .font(.system(size: 16))
                    .foregroundColor(showPassword ? .primaryText : .clear) // Hide text when secure
                    .focused($isFocused)
                    .disabled(isDisabled)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .textContentType(.password)
                
                // FIXED: Manual secure text overlay
                if !showPassword && !text.isEmpty {
                    HStack {
                        Text(String(repeating: "•", count: text.count))
                            .font(.system(size: 18, weight: .medium))
                            .foregroundColor(.primaryText)
                            .allowsHitTesting(false)
                        Spacer()
                    }
                }
            }
            
            // Show/Hide Password Button
            Button(action: {
                showPassword.toggle()
            }) {
                Image(systemName: showPassword ? "eye.slash.fill" : "eye.fill")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.secondaryText)
            }
            .disabled(isDisabled)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(backgroundColor)
        .clipShape(RoundedRectangle(cornerRadius: 25))
        .overlay(
            RoundedRectangle(cornerRadius: 25)
                .stroke(borderColor, lineWidth: borderWidth)
        )
        .animation(.easeInOut(duration: 0.2), value: isFocused)
        .animation(.easeInOut(duration: 0.2), value: hasError)
        // REMOVED: Animation on showPassword to prevent jumping
        .animation(.none, value: showPassword)
    }
    
    // MARK: - Computed Properties (Dark Mode Adaptive)
    private var iconColor: Color {
        if hasError {
            return .errorRed
        } else if isFocused {
            return .primaryOrange // Focus olduğunda primary orange kalsın
        } else {
            return .secondaryText // Normal durumda secondary text (adaptive)
        }
    }
    
    private var backgroundColor: Color {
        if isDisabled {
            return Color.formBackground.opacity(0.5)
        } else {
            return Color.formBackground
        }
    }
    
    private var borderColor: Color {
        if hasError {
            return .errorRed
        } else if isFocused {
            return .primaryOrange
        } else {
            return .dynamicBorder
        }
    }
    
    private var borderWidth: CGFloat {
        if hasError || isFocused {
            return 2.0
        } else {
            return 1.0
        }
    }
}

// MARK: - Login Background View
// BuddyBuilder/Shared/Components/CustomTextField.swift (LoginBackgroundView kısmı)
struct LoginBackgroundView: View {
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        ZStack {
            // Ana adaptive background
            Color.dynamicBackground
                .ignoresSafeArea(.all)
            
            // Conditional gradient overlay
            if colorScheme == .light {
                // Light mode - subtle warm gradient
                LinearGradient(
                    colors: [
                        Color.primaryOrange.opacity(0.08),
                        Color.blue.opacity(0.06),
                        Color.purple.opacity(0.04)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
            } else {
                // Dark mode - minimal accent gradient
                LinearGradient(
                    colors: [
                        Color.primaryOrange.opacity(0.03),
                        Color.blue.opacity(0.02),
                        Color.clear
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
            }
            
            // Subtle radial highlights (adaptive opacity)
            RadialGradient(
                colors: [
                    Color.primaryOrange.opacity(colorScheme == .light ? 0.05 : 0.02),
                    Color.clear
                ],
                center: UnitPoint(x: 0.8, y: 0.2),
                startRadius: 0,
                endRadius: 200
            )
            .ignoresSafeArea()
        }
    }
}

// MARK: - Preview
#Preview {
    VStack(spacing: 20) {
        CustomTextFieldNoTitle(
            text: .constant(""),
            icon: "person.fill",
            placeholder: "Username or Email"
        )
        
        CustomTextFieldNoTitle(
            text: .constant("Error State"),
            icon: "person.fill",
            placeholder: "Username or Email",
            hasError: true
        )
        
        CustomPasswordFieldNoTitle(
            text: .constant(""),
            showPassword: .constant(false),
            placeholder: "Password"
        )
        
        CustomPasswordFieldNoTitle(
            text: .constant("Password with error"),
            showPassword: .constant(false),
            placeholder: "Password",
            hasError: true
        )
    }
    .padding()
    .background(LoginBackgroundView())
}
