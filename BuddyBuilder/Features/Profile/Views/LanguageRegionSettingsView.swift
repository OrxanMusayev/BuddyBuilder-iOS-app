// BuddyBuilder/Features/Profile/Views/LanguageRegionSettingsView.swift

import SwiftUI

// MARK: - Language Region Settings View Model
class LanguageRegionSettingsViewModel: ObservableObject {
    @Published var isLoading = false
    @Published var errorMessage: String = ""
    @Published var showError = false
    @Published var currentLanguage = "English"
    @Published var currentRegion = "United States"
    
    func handleError(_ message: String) {
        errorMessage = message
        showError = true
        print("❌ Language Region Settings Error: \(message)")
    }
}

// MARK: - Language Region Menu Item Model
struct LangRegionItem {
    let id: String
    let title: String
    let currentValue: String
    let customIcon: String
    let iconColor: Color
    let backgroundColor: Color
    let action: () -> Void
}

// MARK: - Language Region Settings View
struct LanguageRegionSettingsView: View {
    @StateObject private var viewModel = LanguageRegionSettingsViewModel()
    @EnvironmentObject var localizationManager: LocalizationManager
    @Environment(\.dismiss) var dismiss
    @State private var navigateToChangeLanguage = false
    @State private var navigateToChangeRegion = false
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Custom Header
                customHeader
                
                // Language Region Content
                languageRegionContent
            }
            .background(Color.dynamicBackground)
            .navigationDestination(isPresented: $navigateToChangeLanguage) {
                // TODO: ChangeLanguageView() - Will be created next
                Text("Change Language View")
                    .navigationBarHidden(true)
            }
            .navigationDestination(isPresented: $navigateToChangeRegion) {
                // TODO: ChangeRegionView() - Will be created next
                Text("Change Region View")
                    .navigationBarHidden(true)
            }
        }
        .navigationBarHidden(true)
        .alert("language.error.title".localized(using: localizationManager), isPresented: $viewModel.showError) {
            Button("common.ok".localized(using: localizationManager)) { }
        } message: {
            Text(viewModel.errorMessage)
        }
    }
    
    // MARK: - Custom Header
    private var customHeader: some View {
        VStack(spacing: 16) {
            HStack {
                // Back button - sadece ok işareti
                Button(action: { dismiss() }) {
                    Image(systemName: "arrow.left")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.primaryOrange)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                }
                
                Spacer()
                
                // Title
                Text("language.title".localized(using: localizationManager))
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundColor(.textPrimary)
                
                Spacer()
                
                // Balance space for back button
                HStack { }
                    .frame(width: 44) // ok işaretinin genişliği kadar
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .background(Color.cardBackground)
    }
    
    // MARK: - Language Region Content
    private var languageRegionContent: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Language Region Menu
                languageRegionMenu
                
                Spacer(minLength: 40)
            }
            .padding(.horizontal, 20)
            .padding(.top, 20)
        }
    }
    
    // MARK: - Language Region Menu
    private var languageRegionMenu: some View {
        VStack(spacing: 0) {
            ForEach(languageRegionMenuItems, id: \.id) { item in
                LangRegionMenuItemView(item: item)
                
                if item.id != languageRegionMenuItems.last?.id {
                    LangRegionMenuDivider()
                }
            }
        }
        .background(Color.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .shadow(color: .dynamicShadow, radius: 10, x: 0, y: 4)
    }
    
    // MARK: - Language Region Menu Items Configuration
    private var languageRegionMenuItems: [LangRegionItem] {
        [
            LangRegionItem(
                id: "change_language",
                title: "language.menu.change_language".localized(using: localizationManager),
                currentValue: viewModel.currentLanguage,
                customIcon: "globe.asia.australia",
                iconColor: .mint,
                backgroundColor: Color.mint.opacity(0.1),
                action: {
                    navigateToChangeLanguage = true
                }
            ),
            LangRegionItem(
                id: "change_region",
                title: "language.menu.change_region".localized(using: localizationManager),
                currentValue: viewModel.currentRegion,
                customIcon: "location.magnifyingglass",
                iconColor: .teal,
                backgroundColor: Color.teal.opacity(0.1),
                action: {
                    navigateToChangeRegion = true
                }
            )
        ]
    }
}

// MARK: - Language Region Menu Item View
struct LangRegionMenuItemView: View {
    let item: LangRegionItem
    
    var body: some View {
        Button(action: item.action) {
            HStack(spacing: 16) {
                // Outline (içi boş) siyah iconlar
                Image(systemName: getOutlineIcon(item.customIcon))
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(.textPrimary)
                    .frame(width: 24, height: 24)
                
                // Content
                VStack(alignment: .leading, spacing: 2) {
                    Text(item.title)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.textPrimary)
                        .lineLimit(1)
                    
                    Text(item.currentValue)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.textSecondary)
                        .lineLimit(1)
                }
                
                Spacer()
                
                // Arrow
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.textSecondary)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    // Icon'ları outline (içi boş) versiyonlarına çevir
    private func getOutlineIcon(_ icon: String) -> String {
        switch icon {
        case "globe.asia.australia":
            return "globe"
        case "location.magnifyingglass":
            return "location"
        default:
            return icon
        }
    }
}

// MARK: - Language Region Menu Divider
struct LangRegionMenuDivider: View {
    var body: some View {
        Divider()
            .padding(.leading, 60) // Icon width'e göre ayarlandı (24 + 16 + 20)
            .background(Color.formBorder.opacity(0.2))
    }
}

// MARK: - Language Region Localization Keys Extension
extension String {
    // Language Region Keys
    static let languageTitle = "language.title"
    static let languageErrorTitle = "language.error.title"
    
    // Language Region Menu Items
    static let languageMenuChangeLanguage = "language.menu.change_language"
    static let languageMenuChangeRegion = "language.menu.change_region"
}

// MARK: - Preview
#Preview {
    LanguageRegionSettingsView()
        .environmentObject(LocalizationManager())
}
