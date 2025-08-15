// BuddyBuilder/Features/Events/Views/ScreenLevelActionSheet.swift
// YENİ DOSYA - Bu dosyayı oluşturun

import SwiftUI

// MARK: - Corner Radius Extension
extension View {
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape(RoundedCorner(radius: radius, corners: corners))
    }
}

struct RoundedCorner: Shape {
    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners

    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: corners,
            cornerRadii: CGSize(width: radius, height: radius)
        )
        return Path(path.cgPath)
    }
}

// MARK: - Screen Level Action Sheet Overlay
struct ScreenLevelActionSheetOverlay: View {
    @Binding var isPresented: Bool
    let event: Event
    let onShare: () -> Void
    let onEdit: () -> Void
    let onFreeze: () -> Void
    let onDelete: () -> Void
    @EnvironmentObject var localizationManager: LocalizationManager
    
    var body: some View {
        ZStack {
            if isPresented {
                // Background overlay - Tüm ekranı kaplar
                Color.black.opacity(0.4)
                    .ignoresSafeArea(.all)
                    .onTapGesture {
                        withAnimation(.easeOut(duration: 0.3)) {
                            isPresented = false
                        }
                    }
                    .transition(.opacity)
                
                // Action sheet - Ekranın tam altından çıkar
                VStack {
                    Spacer()
                    actionSheetContent
                }
                .transition(.move(edge: .bottom))
            }
        }
        .animation(.easeInOut(duration: 0.3), value: isPresented)
    }
    
    private var actionSheetContent: some View {
        VStack(spacing: 0) {
            // Header
            VStack(spacing: 8) {
                RoundedRectangle(cornerRadius: 2.5)
                    .fill(Color.textSecondary.opacity(0.3))
                    .frame(width: 36, height: 5)
                    .padding(.top, 12)
                
                Text(event.name)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.textPrimary)
                    .lineLimit(2)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 20)
                
                Text("events.choose.action".localized(using: localizationManager))
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.textSecondary)
                    .padding(.bottom, 8)
            }
            .padding(.bottom, 16)
            
            // Action buttons
            VStack(spacing: 0) {
                actionButton(
                    icon: "square.and.arrow.up",
                    title: "events.share".localized(using: localizationManager),
                    action: {
                        onShare()
                        dismissSheet()
                    }
                )
                
                actionDivider
                
                actionButton(
                    icon: "pencil",
                    title: "events.edit".localized(using: localizationManager),
                    action: {
                        onEdit()
                        dismissSheet()
                    }
                )
                
                actionDivider
                
                actionButton(
                    icon: "pause.circle",
                    title: "events.freeze".localized(using: localizationManager),
                    action: {
                        onFreeze()
                        dismissSheet()
                    }
                )
                
                actionDivider
                
                actionButton(
                    icon: "trash",
                    title: "events.delete".localized(using: localizationManager),
                    isDestructive: true,
                    action: {
                        onDelete()
                        dismissSheet()
                    }
                )
            }
            .padding(.bottom, 16)
            
            // Cancel button
            Button(action: {
                dismissSheet()
            }) {
                Text("events.cancel".localized(using: localizationManager))
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.textPrimary)
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background(Color.cardBackground)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .padding(.horizontal, 20)
            .padding(.bottom, max(20, UIApplication.shared.connectedScenes
                .compactMap { $0 as? UIWindowScene }
                .first?.windows.first?.safeAreaInsets.bottom ?? 0))
        }
        .background(Color.cardBackground)
        .cornerRadius(20, corners: [.topLeft, .topRight])
        .shadow(color: .dynamicShadow.opacity(0.2), radius: 20, x: 0, y: -5)
    }
    
    private func actionButton(
        icon: String,
        title: String,
        isDestructive: Bool = false,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(spacing: 16) {
                Image(systemName: icon)
                    .font(.system(size: 18, weight: .regular))
                    .foregroundColor(isDestructive ? .red : .textPrimary)
                    .frame(width: 24, height: 24)
                
                Text(title)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(isDestructive ? .red : .textPrimary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                Spacer()
            }
            .padding(.horizontal, 20)
            .frame(height: 56)
            .background(Color.clear)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private var actionDivider: some View {
        Rectangle()
            .fill(Color.dynamicBorder.opacity(0.2))
            .frame(height: 0.5)
            .padding(.horizontal, 20)
    }
    
    private func dismissSheet() {
        withAnimation(.easeOut(duration: 0.3)) {
            isPresented = false
        }
    }
}
