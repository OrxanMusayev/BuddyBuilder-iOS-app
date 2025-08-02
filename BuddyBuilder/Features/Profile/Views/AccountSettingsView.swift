// BuddyBuilder/Features/Profile/Views/AccountSettingsView.swift

import SwiftUI

// MARK: - Account Settings View Model
class AccountSettingsViewModel: ObservableObject {
    @Published var isLoading = false
    @Published var errorMessage: String = ""
    @Published var showError = false
    @Published var showDeleteConfirmation = false
    
    func handleError(_ message: String) {
        errorMessage = message
        showError = true
        print("❌ Account Settings Error: \(message)")
    }
    
    func deleteAccount() {
        // TODO: Implement account deletion
        print("🗑️ Delete account requested")
    }
}

// MARK: - Account Settings Menu Item Model
struct AccountSettingsMenuItem {
    let id: String
    let title: String
    let customIcon: String
    let iconColor: Color
    let backgroundColor: Color
    let action: () -> Void
    let isDestructive: Bool
}

// MARK: - Account Settings View
struct AccountSettingsView: View {
    @StateObject private var viewModel = AccountSettingsViewModel()
    @EnvironmentObject var localizationManager: LocalizationManager
    @Environment(\.dismiss) var dismiss
    @State private var navigateToPersonalDetails = false
    @State private var navigateToChangePassword = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Background
                LoginBackgroundView()
                
                VStack(spacing: 0) {
                    // Custom Header
                    customHeader
                    
                    // Account Settings Content
                    accountSettingsContent
                }
            }
        }
        .navigationBarHidden(true)
        .navigationDestination(isPresented: $navigateToPersonalDetails) {
            // TODO: PersonalDetailsView() - Will be created next
            Text("Personal Details View")
                .navigationBarHidden(true)
        }
        .navigationDestination(isPresented: $navigateToChangePassword) {
            // TODO: ChangePasswordView() - Will be created next
            Text("Change Password View")
                .navigationBarHidden(true)
        }
        .alert("account.delete.confirmation.title".localized(using: localizationManager), isPresented: $viewModel.showDeleteConfirmation) {
            Button("common.cancel".localized(using: localizationManager), role: .cancel) { }
            Button("account.delete.confirmation.confirm".localized(using: localizationManager), role: .destructive) {
                viewModel.deleteAccount()
            }
        } message: {
            Text("account.delete.confirmation.message".localized(using: localizationManager))
        }
        .alert("account.error.title".localized(using: localizationManager), isPresented: $viewModel.showError) {
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
                Text("account.title".localized(using: localizationManager))
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
        .background(Color.white.opacity(0.95))
    }
    
    // MARK: - Account Settings Content
    private var accountSettingsContent: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Account Menu (header kaldırıldı)
                accountMenu
                
                Spacer(minLength: 40)
            }
            .padding(.horizontal, 20)
            .padding(.top, 20)
        }
    }
    
    // MARK: - Account Menu
    private var accountMenu: some View {
        VStack(spacing: 0) {
            ForEach(Array(accountMenuItems.enumerated()), id: \.offset) { index, item in
                AccountMenuItemView(item: item)
                
                if index < accountMenuItems.count - 1 {
                    AccountMenuDivider()
                }
            }
        }
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .shadow(color: .black.opacity(0.05), radius: 10, x: 0, y: 4)
    }
    
    // MARK: - Account Menu Items Configuration
    private var accountMenuItems: [AccountSettingsMenuItem] {
        [
            AccountSettingsMenuItem(
                id: "personal_details",
                title: "account.menu.personal_details".localized(using: localizationManager),
                customIcon: "doc.text.image", // Modern document icon
                iconColor: .cyan,
                backgroundColor: Color.cyan.opacity(0.1),
                action: {
                    navigateToPersonalDetails = true
                },
                isDestructive: false
            ),
            AccountSettingsMenuItem(
                id: "change_password",
                title: "account.menu.change_password".localized(using: localizationManager),
                customIcon: "lock.shield", // Modern security shield
                iconColor: .indigo,
                backgroundColor: Color.indigo.opacity(0.1),
                action: {
                    navigateToChangePassword = true
                },
                isDestructive: false
            ),
            AccountSettingsMenuItem(
                id: "delete_account",
                title: "account.menu.delete_account".localized(using: localizationManager),
                customIcon: "xmark.octagon", // Modern warning octagon
                iconColor: .red,
                backgroundColor: Color.red.opacity(0.1),
                action: {
                    viewModel.showDeleteConfirmation = true
                },
                isDestructive: true
            )
        ]
    }
}

// MARK: - Account Menu Item View
struct AccountMenuItemView: View {
    let item: AccountSettingsMenuItem
    
    var body: some View {
        Button(action: item.action) {
            HStack(spacing: 16) {
                // Tüm iconlar için sadece outline (içi boş) siyah icon
                Image(systemName: getOutlineIcon(item.customIcon))
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(item.isDestructive ? .red : .black)
                    .frame(width: 24, height: 24)
                
                // Title
                Text(item.title)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(item.isDestructive ? .red : .textPrimary)
                    .lineLimit(1)
                
                Spacer()
                
                // Arrow (only for non-destructive items)
                if !item.isDestructive {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.textSecondary)
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    // Icon'ları outline (içi boş) versiyonlarına çevir
    private func getOutlineIcon(_ icon: String) -> String {
        switch icon {
        case "doc.text.image":
            return "doc.text"
        case "lock.shield":
            return "lock"
        case "xmark.octagon":
            return "xmark.octagon"
        default:
            return icon
        }
    }
}

// MARK: - Account Menu Divider
struct AccountMenuDivider: View {
    var body: some View {
        Divider()
            .padding(.leading, 60) // Icon width'e göre ayarlandı (24 + 16 + 20)
            .background(Color.formBorder.opacity(0.2))
    }
}

// MARK: - Account Settings Localization Keys Extension
extension String {
    // Account Keys
    static let accountTitle = "account.title"
    static let accountErrorTitle = "account.error.title"
    
    // Account Menu Items
    static let accountMenuPersonalDetails = "account.menu.personal_details"
    static let accountMenuChangePassword = "account.menu.change_password"
    static let accountMenuDeleteAccount = "account.menu.delete_account"
    
    // Delete Account Confirmation
    static let accountDeleteConfirmationTitle = "account.delete.confirmation.title"
    static let accountDeleteConfirmationMessage = "account.delete.confirmation.message"
    static let accountDeleteConfirmationConfirm = "account.delete.confirmation.confirm"
}

// MARK: - Preview
#Preview {
    AccountSettingsView()
        .environmentObject(LocalizationManager())
}
