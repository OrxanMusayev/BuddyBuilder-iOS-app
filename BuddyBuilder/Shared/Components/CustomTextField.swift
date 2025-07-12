import SwiftUI

// MARK: - Custom Text Field (No Title)
struct CustomTextFieldNoTitle: View {
    @Binding var text: String
    let icon: String
    let placeholder: String
    var hasError: Bool = false
    var isDisabled: Bool = false
    
    @FocusState private var isFocused: Bool
    
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
                .foregroundColor(.textPrimary)
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
    
    // MARK: - Computed Properties
    private var iconColor: Color {
        if hasError {
            return .red
        } else if isFocused {
            return .primaryOrange
        } else {
            return .textSecondary
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
            return .red
        } else if isFocused {
            return .primaryOrange
        } else {
            return .formBorder
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

// MARK: - Custom Password Field (No Title)
struct CustomPasswordFieldNoTitle: View {
    @Binding var text: String
    @Binding var showPassword: Bool
    let placeholder: String
    var hasError: Bool = false
    var isDisabled: Bool = false
    
    @FocusState private var isFocused: Bool
    
    var body: some View {
        HStack(spacing: 12) {
            // Lock Icon
            Image(systemName: "lock.fill")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(iconColor)
                .frame(width: 20)
            
            // Password Field
            Group {
                if showPassword {
                    TextField(placeholder, text: $text)
                } else {
                    SecureField(placeholder, text: $text)
                }
            }
            .font(.system(size: 16))
            .foregroundColor(.textPrimary)
            .focused($isFocused)
            .disabled(isDisabled)
            .textInputAutocapitalization(.never)
            .autocorrectionDisabled()
            
            // Show/Hide Password Button
            Button(action: {
                showPassword.toggle()
            }) {
                Image(systemName: showPassword ? "eye.slash.fill" : "eye.fill")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.textSecondary)
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
        .animation(.easeInOut(duration: 0.2), value: showPassword)
    }
    
    // MARK: - Computed Properties
    private var iconColor: Color {
        if hasError {
            return .red
        } else if isFocused {
            return .primaryOrange
        } else {
            return .textSecondary
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
            return .red
        } else if isFocused {
            return .primaryOrange
        } else {
            return .formBorder
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
struct LoginBackgroundView: View {
    var body: some View {
        LinearGradient(
            colors: [
                Color.primaryOrange.opacity(0.1),
                Color.blue.opacity(0.1),
                Color.purple.opacity(0.1)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()
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
