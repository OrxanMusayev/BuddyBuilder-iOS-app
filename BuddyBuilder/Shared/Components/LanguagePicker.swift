import SwiftUI

// MARK: - Compact Language Picker
struct CompactLanguagePicker: View {
    @ObservedObject var localizationManager: LocalizationManager
    @State private var showDropdown = false
    
    var body: some View {
        VStack(alignment: .trailing) {
            languageButton
            
            if showDropdown {
                compactDropdown
            }
        }
        .background(backgroundTapHandler)
    }
    
    // MARK: - Language Button (Shows Language Code)
    private var languageButton: some View {
        Button(action: toggleDropdown) {
            HStack(spacing: 6) {
                Image(systemName: "globe")
                    .font(.system(size: 14, weight: .medium))
                
                Text(currentLanguageCode)
                    .font(.system(size: 13, weight: .bold))
                
                Image(systemName: showDropdown ? "chevron.up" : "chevron.down")
                    .font(.system(size: 11, weight: .medium))
            }
            .foregroundColor(.textPrimary)
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(Color.formBackground)
            .clipShape(RoundedRectangle(cornerRadius: 25))
            .overlay(
                RoundedRectangle(cornerRadius: 25)
                    .stroke(buttonBorderColor, lineWidth: buttonBorderWidth)
            )
            .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
        }
        .disabled(localizationManager.isLoading)
        .scaleEffect(showDropdown ? 0.95 : 1.0)
        .animation(.easeInOut(duration: 0.15), value: showDropdown)
    }
    
    // MARK: - Compact Dropdown
    private var compactDropdown: some View {
        VStack(spacing: 0) {
            ForEach(localizationManager.availableLanguages) { language in
                compactLanguageRow(for: language)
            }
        }
        .background(Color.white.opacity(0.98))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.formBorder.opacity(0.8), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
        .frame(width: 180) // Wider to prevent text wrapping
        .padding(.top, 4)
        .transition(.opacity.combined(with: .scale))
        .zIndex(1000)
    }
    
    // MARK: - Compact Language Row
    private func compactLanguageRow(for language: Language) -> some View {
        Button(action: { selectLanguage(language) }) {
            HStack(spacing: 12) {
                // Language name (native)
                Text(language.nativeName)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.textPrimary)
                    .lineLimit(1)
                
                Spacer()
                
                // Selection indicator
                if isSelected(language) {
                    if localizationManager.isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .primaryOrange))
                            .scaleEffect(0.6)
                    } else {
                        Image(systemName: "checkmark")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(.primaryOrange)
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(isSelected(language) ? Color.primaryOrange.opacity(0.1) : Color.clear)
            )
        }
        .disabled(localizationManager.isLoading)
    }
    
    // MARK: - Helper Properties & Methods
    private var currentLanguageCode: String {
        localizationManager.currentLanguage?.code.uppercased() ?? "EN"
    }
    
    private var buttonBorderColor: Color {
        if showDropdown {
            return .primaryOrange
        } else {
            return .formBorder
        }
    }
    
    private var buttonBorderWidth: CGFloat {
        showDropdown ? 2.0 : 1.0
    }
    
    private func isSelected(_ language: Language) -> Bool {
        localizationManager.currentLanguage?.code == language.code
    }
    
    private func toggleDropdown() {
        withAnimation(.easeInOut(duration: 0.2)) {
            showDropdown.toggle()
        }
    }
    
    private func selectLanguage(_ language: Language) {
        Task {
            await localizationManager.changeLanguage(to: language)
            withAnimation(.easeInOut(duration: 0.2)) {
                showDropdown = false
            }
        }
    }
    
    private var backgroundTapHandler: some View {
        Group {
            if showDropdown {
                Color.clear
                    .contentShape(Rectangle())
                    .onTapGesture {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            showDropdown = false
                        }
                    }
            }
        }
    }
}

// MARK: - Full Language Picker (keeping for other uses)
struct LanguagePicker: View {
    @ObservedObject var localizationManager: LocalizationManager
    @State private var showLanguageSheet = false
    
    var body: some View {
        Button(action: {
            showLanguageSheet.toggle()
        }) {
            HStack(spacing: 8) {
                Image(systemName: "globe")
                    .font(.system(size: 16, weight: .medium))
                
                if let currentLanguage = localizationManager.currentLanguage {
                    Text(currentLanguage.nativeName)
                        .font(.system(size: 14, weight: .medium))
                } else {
                    Text("Language")
                        .font(.system(size: 14, weight: .medium))
                }
                
                Image(systemName: "chevron.down")
                    .font(.system(size: 12, weight: .medium))
            }
            .foregroundColor(.textPrimary)
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(Color.formBackground)
            .clipShape(RoundedRectangle(cornerRadius: 25))
            .overlay(
                RoundedRectangle(cornerRadius: 25)
                    .stroke(Color.formBorder, lineWidth: 1)
            )
            .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
        }
        .disabled(localizationManager.isLoading)
        .opacity(localizationManager.isLoading ? 0.6 : 1.0)
        .sheet(isPresented: $showLanguageSheet) {
            LanguageSelectionSheet(localizationManager: localizationManager)
        }
    }
}

// MARK: - Language Selection Sheet
struct LanguageSelectionSheet: View {
    @ObservedObject var localizationManager: LocalizationManager
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Header
                HStack {
                    Text("Select Language")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(.textPrimary)
                    
                    Spacer()
                    
                    Button("Done") {
                        presentationMode.wrappedValue.dismiss()
                    }
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.primaryOrange)
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
                
                Divider()
                
                // Language List
                ScrollView {
                    LazyVStack(spacing: 0) {
                        ForEach(localizationManager.availableLanguages) { language in
                            LanguageRow(
                                language: language,
                                isSelected: localizationManager.currentLanguage?.code == language.code,
                                isLoading: localizationManager.isLoading
                            ) {
                                Task {
                                    await localizationManager.changeLanguage(to: language)
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                        presentationMode.wrappedValue.dismiss()
                                    }
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 16)
                }
                
                Spacer()
            }
            .background(Color(UIColor.systemBackground))
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }
}

// MARK: - Language Row Component
struct LanguageRow: View {
    let language: Language
    let isSelected: Bool
    let isLoading: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                // Flag placeholder
                Circle()
                    .fill(Color.primaryOrange.opacity(0.2))
                    .frame(width: 32, height: 32)
                    .overlay(
                        Text(String(language.code.prefix(2).uppercased()))
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.primaryOrange)
                    )
                
                // Language Info
                VStack(alignment: .leading, spacing: 2) {
                    Text(language.nativeName)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.textPrimary)
                    
                    Text(language.name)
                        .font(.system(size: 14))
                        .foregroundColor(.textSecondary)
                }
                
                Spacer()
                
                // Selection Indicator
                if isSelected {
                    if isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .primaryOrange))
                            .scaleEffect(0.8)
                    } else {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 20))
                            .foregroundColor(.primaryOrange)
                    }
                }
            }
            .padding(.vertical, 14)
            .padding(.horizontal, 20)
            .background(
                RoundedRectangle(cornerRadius: 25)
                    .fill(isSelected ? Color.primaryOrange.opacity(0.1) : Color.clear)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 25)
                    .stroke(isSelected ? Color.primaryOrange.opacity(0.3) : Color.clear, lineWidth: 1)
            )
        }
        .disabled(isLoading)
        .animation(.easeInOut(duration: 0.2), value: isSelected)
    }
}

// MARK: - Preview
#Preview {
    @StateObject var mockManager = LocalizationManager(localizationService: MockLocalizationService())
    
    VStack(spacing: 20) {
        CompactLanguagePicker(localizationManager: mockManager)
        
        LanguagePicker(localizationManager: mockManager)
    }
    .padding()
    .task {
        await mockManager.initialize()
    }
}
