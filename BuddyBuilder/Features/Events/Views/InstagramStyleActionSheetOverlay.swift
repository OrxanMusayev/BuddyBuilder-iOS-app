// BuddyBuilder/Features/Events/Views/InstagramStyleActionSheet.swift
// YENİ DOSYA - Bu dosyayı oluşturun

import SwiftUI

// MARK: - Instagram Style Action Sheet Overlay
struct InstagramStyleActionSheetOverlay: View {
    @Binding var isPresented: Bool
    let event: Event
    let onShare: () -> Void
    let onEdit: () -> Void
    let onFreeze: () -> Void
    let onDelete: () -> Void
    @EnvironmentObject var localizationManager: LocalizationManager
     
    // Animation state
    @State private var backgroundOpacity: Double = 0
    @State private var cardScale: CGFloat = 1.0
    @State private var cardOffset: CGFloat = 0
    @State private var sheetOffset: CGFloat = UIScreen.main.bounds.height
    
    var body: some View {
        ZStack {
            if isPresented {
                // Background with blur effect
                backgroundOverlay
                
                // Mini event card in center
                miniEventCard
                
                // Action sheet at bottom
                actionSheet
            }
        }
        .ignoresSafeArea(.all)
        .onChange(of: isPresented) { newValue in
            if newValue {
                presentSheet()
            } else {
                dismissSheet()
            }
        }
    }
    
    // MARK: - Background Overlay with Blur
    private var backgroundOverlay: some View {
        ZStack {
            // Blurred background
            Color.black
                .opacity(backgroundOpacity * 0.6)
                .background(.ultraThinMaterial)
                .onTapGesture {
                    dismissSheetAnimated()
                }
            
            // Additional blur effect
            Rectangle()
                .fill(.ultraThinMaterial)
                .opacity(backgroundOpacity * 0.3)
        }
        .ignoresSafeArea(.all)
    }
    
    // MARK: - Mini Event Card (Instagram Style)
    private var miniEventCard: some View {
        VStack(spacing: 0) {
            // Event image
            AsyncImage(url: URL(string: event.imageUrl ?? defaultImageUrl(for: event.sport.name))) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } placeholder: {
                Rectangle()
                    .fill(
                        LinearGradient(
                            colors: [.primaryOrange.opacity(0.3), .primaryOrange.opacity(0.1)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .overlay(
                        Image(systemName: "calendar")
                            .font(.system(size: 20, weight: .light))
                            .foregroundColor(.primaryOrange.opacity(0.6))
                    )
            }
            .frame(height: 80)
            .clipped()
            
            // Event info
            VStack(alignment: .leading, spacing: 6) {
                Text(event.name)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.textPrimary)
                    .lineLimit(1)
                
                HStack(spacing: 8) {
                    HStack(spacing: 4) {
                        Image(systemName: "calendar")
                            .font(.system(size: 10))
                            .foregroundColor(.textSecondary)
                        
                        Text(event.formattedEventDate)
                            .font(.system(size: 10))
                            .foregroundColor(.textSecondary)
                    }
                    
                    HStack(spacing: 4) {
                        Image(systemName: "location")
                            .font(.system(size: 10))
                            .foregroundColor(.textSecondary)
                        
                        Text(event.location)
                            .font(.system(size: 10))
                            .foregroundColor(.textSecondary)
                            .lineLimit(1)
                    }
                    
                    Spacer()
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
        }
        .frame(width: 200)
        .background(Color.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.2), radius: 10, x: 0, y: 5)
        .scaleEffect(cardScale)
        .offset(y: cardOffset)
        .onTapGesture {
            dismissSheetAnimated()
        }
    }
    
    // MARK: - Action Sheet (FIXED: Positioning)
    private var actionSheet: some View {
        VStack {
            Spacer() // Push to bottom
            
            VStack(spacing: 0) {
                // Handle bar
                RoundedRectangle(cornerRadius: 2.5)
                    .fill(Color.textSecondary.opacity(0.3))
                    .frame(width: 36, height: 5)
                    .padding(.top, 12)
                    .padding(.bottom, 20)
                
                // Action buttons with Instagram style
                VStack(spacing: 0) {
                    instagramActionButton(
                        icon: "square.and.arrow.up",
                        title: "events.share".localized(using: localizationManager),
                        action: {
                            onShare()
                            dismissSheetAnimated()
                        }
                    )
                    
                    instagramDivider
                    
                    instagramActionButton(
                        icon: "pencil",
                        title: "events.edit".localized(using: localizationManager),
                        action: {
                            onEdit()
                            dismissSheetAnimated()
                        }
                    )
                    
                    instagramDivider
                    
                    instagramActionButton(
                        icon: "pause.circle",
                        title: "events.freeze".localized(using: localizationManager),
                        action: {
                            onFreeze()
                            dismissSheetAnimated()
                        }
                    )
                    
                    instagramDivider
                    
                    instagramActionButton(
                        icon: "trash",
                        title: "events.delete".localized(using: localizationManager),
                        isDestructive: true,
                        action: {
                            onDelete()
                            dismissSheetAnimated()
                        }
                    )
                }
                .padding(.bottom, 20)
                
                // Cancel button (Instagram style)
                Button(action: {
                    dismissSheetAnimated()
                }) {
                    Text("events.cancel".localized(using: localizationManager))
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.textPrimary)
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(Color.formBackground)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                }
                .padding(.horizontal, 20)
                .padding(.bottom, max(20, UIApplication.shared.connectedScenes
                    .compactMap { $0 as? UIWindowScene }
                    .first?.windows.first?.safeAreaInsets.bottom ?? 0))
            }
            .background(Color.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: 20))
            .shadow(color: .black.opacity(0.15), radius: 20, x: 0, y: -5)
        }
        .offset(y: sheetOffset)
        .gesture(
            DragGesture()
                .onChanged { value in
                    if value.translation.height > 0 {
                        sheetOffset = value.translation.height
                    }
                }
                .onEnded { value in
                    if value.translation.height > 100 {
                        dismissSheetAnimated()
                    } else {
                        withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                            sheetOffset = 0
                        }
                    }
                }
        )
    }
    
    // MARK: - Instagram Style Action Button
    private func instagramActionButton(
        icon: String,
        title: String,
        isDestructive: Bool = false,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(spacing: 16) {
                Image(systemName: icon)
                    .font(.system(size: 20, weight: .regular))
                    .foregroundColor(isDestructive ? .red : .textPrimary)
                    .frame(width: 28, height: 28)
                
                Text(title)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(isDestructive ? .red : .textPrimary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                Spacer()
            }
            .padding(.horizontal, 24)
            .frame(height: 60)
            .background(Color.clear)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private var instagramDivider: some View {
        Rectangle()
            .fill(Color.dynamicBorder.opacity(0.15))
            .frame(height: 0.5)
            .padding(.horizontal, 24)
    }
    
    // MARK: - Animation Methods (FIXED: Initial positioning)
    private func presentSheet() {
        // FIXED: Initial state with better positioning
        backgroundOpacity = 0
        cardScale = 1.0
        cardOffset = 0
        sheetOffset = UIScreen.main.bounds.height // Start completely off screen
        
        withAnimation(.easeOut(duration: 0.4)) {
            backgroundOpacity = 1.0
        }
        
        withAnimation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.1)) {
            cardScale = 0.85
            cardOffset = -120
        }
        
        withAnimation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.2)) {
            sheetOffset = 0 // Slide up to normal position
        }
    }
    
    private func dismissSheet() {
        withAnimation(.easeInOut(duration: 0.3)) {
            backgroundOpacity = 0
            cardScale = 1.0
            cardOffset = 0
            sheetOffset = UIScreen.main.bounds.height
        }
    }
    
    private func dismissSheetAnimated() {
        withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
            backgroundOpacity = 0
            cardScale = 1.0
            cardOffset = 0
            sheetOffset = UIScreen.main.bounds.height
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            isPresented = false
        }
    }
    
    // MARK: - Helper Methods
    private func defaultImageUrl(for sportType: String) -> String {
        switch sportType.lowercased() {
        case "soccer", "football":
            return "https://images.unsplash.com/photo-1574629810360-7efbbe195018"
        case "volleyball":
            return "https://media.istockphoto.com/id/1582215564/photo/women-hands-blocking-volleyball-ball.jpg"
        case "tennis":
            return "https://images.unsplash.com/photo-1622279457486-62dcc4a431d6"
        case "basketball":
            return "https://images.unsplash.com/photo-1546519638-68e109498ffc"
        default:
            return "https://images.unsplash.com/photo-1571019613454-1cb2f99b2d8b"
        }
    }
}


//DEBUGGING
// DEBUG VERSION - Test için basit bir action sheet

import SwiftUI

struct DebugActionSheetOverlay: View {
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
                // Background
                Color.black.opacity(0.5)
                    .ignoresSafeArea(.all)
                    .onTapGesture {
                        isPresented = false
                    }
                
                // TEST: Simple action sheet at bottom
                VStack {
                    Spacer()
                    
                    VStack(spacing: 0) {
                        // Header
                        Text("ACTION SHEET - DEBUG")
                            .font(.headline)
                            .padding()
                            .background(Color.yellow) // Debug color
                        
                        // Actions
                        Button("Share") {
                            onShare()
                            isPresented = false
                        }
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.blue)
                        .foregroundColor(.white)
                        
                        Button("Edit") {
                            onEdit()
                            isPresented = false
                        }
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.green)
                        .foregroundColor(.white)
                        
                        Button("Delete") {
                            onDelete()
                            isPresented = false
                        }
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.red)
                        .foregroundColor(.white)
                        
                        Button("Cancel") {
                            isPresented = false
                        }
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.gray)
                        .foregroundColor(.white)
                    }
                    .background(Color.white)
                    .clipShape(RoundedRectangle(cornerRadius: 20))
                    .padding(.horizontal, 20)
                    .padding(.bottom, 50)
                }
                .transition(.move(edge: .bottom))
            }
        }
        .animation(.easeInOut(duration: 0.3), value: isPresented)
    }
}

// CachedEventsView veya EventsView'da test için kullanın:
/*
// ESKİ:
InstagramStyleActionSheetOverlay(...)

// TEST İÇİN:
DebugActionSheetOverlay(
    isPresented: $showingActionSheet,
    event: event,
    onShare: { handleShareEvent(event) },
    onEdit: { handleEditEvent(event) },
    onFreeze: { handleDeactivateEvent(event) },
    onDelete: { handleDeleteEvent(event) }
)
.environmentObject(localizationManager)
.zIndex(1000)
*/
