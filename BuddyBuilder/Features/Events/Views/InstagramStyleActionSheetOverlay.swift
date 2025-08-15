// BuddyBuilder/Features/Events/Views/InstagramStyleActionSheet.swift
// FIXED VERSION - PROPER CARD HEIGHT + SMOOTH DISMISS ANIMATION

import SwiftUI

// MARK: - Instagram Style Action Sheet Overlay (FIXED)
struct InstagramStyleActionSheetOverlay: View {
    @Binding var isPresented: Bool
    let event: Event
    let onShare: () -> Void
    let onEdit: () -> Void
    let onFreeze: () -> Void
    let onDelete: () -> Void
    @EnvironmentObject var localizationManager: LocalizationManager
    
    // Animation state - FIXED: Added proper dismiss animation
    @State private var backgroundOpacity: Double = 0
    @State private var cardScale: CGFloat = 1.0
    @State private var cardOffset: CGFloat = 0
    @State private var cardOpacity: Double = 1.0 // FIXED: Added opacity control
    @State private var sheetOpacity: Double = 0
    @State private var sheetOffset: CGFloat = 100
    
    var body: some View {
        ZStack {
            if isPresented {
                // Background with blur effect
                backgroundOverlay
                
                // Mini event card in center - FIXED: Larger size
                miniEventCard
                
                // Action sheet at bottom
                actionSheet
            }
        }
        .ignoresSafeArea(.all)
        .onAppear {
            if isPresented {
                presentSheet()
            }
        }
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
        Rectangle()
            .fill(.ultraThinMaterial)
            .opacity(backgroundOpacity)
            .onTapGesture {
                dismissSheetAnimated()
            }
            .ignoresSafeArea(.all)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    // MARK: - Mini Event Card (FIXED: Much larger + better proportions)
    private var miniEventCard: some View {
        VStack(spacing: 0) {
            // Event image - FIXED: Optimal image height
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
                            .font(.system(size: 32, weight: .light)) // FIXED: Smaller placeholder icon
                            .foregroundColor(.primaryOrange.opacity(0.6))
                    )
            }
            .frame(height: 170) // FIXED: Reduced from 200 to 170 (balanced size)
            .clipped()
            
            // Event info - FIXED: Balanced content space
            VStack(alignment: .leading, spacing: 12) { // FIXED: Reduced spacing
                Text(event.name)
                    .font(.system(size: 20, weight: .semibold)) // FIXED: Balanced title size
                    .foregroundColor(.textPrimary)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                
                VStack(alignment: .leading, spacing: 8) { // FIXED: Reduced spacing
                    HStack(spacing: 8) {
                        Image(systemName: "calendar")
                            .font(.system(size: 16)) // FIXED: Standard icon size
                            .foregroundColor(.textSecondary)
                            .frame(width: 18) // FIXED: Smaller icon width
                        
                        Text(event.formattedEventDate)
                            .font(.system(size: 15)) // FIXED: Standard text size
                            .foregroundColor(.textSecondary)
                    }
                    
                    HStack(spacing: 8) {
                        Image(systemName: "location")
                            .font(.system(size: 16)) // FIXED: Standard icon size
                            .foregroundColor(.textSecondary)
                            .frame(width: 18) // FIXED: Smaller icon width
                        
                        Text(event.location)
                            .font(.system(size: 15)) // FIXED: Standard text size
                            .foregroundColor(.textSecondary)
                            .lineLimit(1) // FIXED: Back to 1 line for compact size
                    }
                }
            }
            .padding(.horizontal, 24) // FIXED: Balanced horizontal padding
            .padding(.vertical, 18) // FIXED: Reduced vertical padding
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .frame(width: 350) // FIXED: Balanced card width
        .background(Color.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 18)) // FIXED: Slightly larger corner radius
        .shadow(color: .black.opacity(0.25), radius: 15, x: 0, y: 8) // FIXED: Better shadow
        .scaleEffect(cardScale)
        .opacity(cardOpacity) // FIXED: Added opacity control
        .offset(y: cardOffset)
        .position(x: UIScreen.main.bounds.width / 2, y: UIScreen.main.bounds.height / 2 - 100) // FIXED: Better centering
        .onTapGesture {
            dismissSheetAnimated()
        }
    }
    
    // MARK: - Action Sheet
    private var actionSheet: some View {
        VStack(spacing: 0) {
            VStack(spacing: 0) {
                actionButton(
                    icon: "square.and.arrow.up",
                    title: "Share",
                    action: {
                        onShare()
                        dismissSheetAnimated()
                    }
                )
                
                actionDivider
                
                actionButton(
                    icon: "pencil",
                    title: "Edit",
                    action: {
                        onEdit()
                        dismissSheetAnimated()
                    }
                )
                
                actionDivider
                
                actionButton(
                    icon: "pause.circle",
                    title: "Freeze",
                    action: {
                        onFreeze()
                        dismissSheetAnimated()
                    }
                )
                
                actionDivider
                
                actionButton(
                    icon: "trash",
                    title: "Delete",
                    isDestructive: true,
                    action: {
                        onDelete()
                        dismissSheetAnimated()
                    }
                )
            }
            .padding(.vertical, 8)
        }
        .frame(width: 200)
        .background(Color.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.15), radius: 10, x: 0, y: 2)
        .opacity(sheetOpacity)
        .offset(y: sheetOffset)
        .position(
            x: UIScreen.main.bounds.width / 2 - 50,
            y: UIScreen.main.bounds.height / 2 + 140 // FIXED: Adjusted for larger card
        )
        .gesture(
            DragGesture()
                .onChanged { value in
                    if value.translation.height > 0 {
                        sheetOffset = value.translation.height
                    }
                }
                .onEnded { value in
                    if value.translation.height > 60 {
                        dismissSheetAnimated()
                    } else {
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                            sheetOffset = 0
                        }
                    }
                }
        )
    }
    
    // MARK: - Action Button
    private func actionButton(
        icon: String,
        title: String,
        isDestructive: Bool = false,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(spacing: 10) {
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .regular))
                    .foregroundColor(isDestructive ? .red : .textPrimary)
                    .frame(width: 20, height: 20)
                
                Text(title)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(isDestructive ? .red : .textPrimary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                Spacer()
            }
            .padding(.horizontal, 12)
            .frame(height: 44)
            .background(Color.clear)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private var actionDivider: some View {
        Rectangle()
            .fill(Color.dynamicBorder.opacity(0.15))
            .frame(height: 0.5)
            .padding(.horizontal, 12)
    }
    
    // MARK: - Animation Methods (FIXED: Proper dismiss with smooth resize)
    private func presentSheet() {
        // Haptic feedback
        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
        impactFeedback.impactOccurred()
        
        // Reset initial state
        backgroundOpacity = 0
        cardScale = 1.0
        cardOffset = 0
        cardOpacity = 1.0
        sheetOpacity = 0
        sheetOffset = 0
        
        // Present animations
        withAnimation(.easeOut(duration: 0.3)) {
            backgroundOpacity = 1.0
        }
        
        withAnimation(.spring(response: 0.5, dampingFraction: 0.85).delay(0.1)) {
            cardScale = 0.92 // FIXED: Slightly smaller scale for larger card
        }
        
        withAnimation(.spring(response: 0.4, dampingFraction: 0.8).delay(0.15)) {
            sheetOpacity = 1.0
        }
    }
    
    private func dismissSheet() {
        // FIXED: Smooth coordinated dismiss animation
        withAnimation(.easeOut(duration: 0.15)) {
            sheetOpacity = 0
            backgroundOpacity = 0
        }
        
        // FIXED: Card smoothly returns to normal size and fades out
        withAnimation(.spring(response: 0.3, dampingFraction: 0.85)) {
            cardScale = 1.0 // Return to full size
            cardOffset = 0
        }
        
        // FIXED: Fade out card after slight delay for smooth transition
        withAnimation(.easeOut(duration: 0.2).delay(0.1)) {
            cardOpacity = 0
        }
    }
    
    private func dismissSheetAnimated() {
        // FIXED: Smooth coordinated dismiss animation
        withAnimation(.easeOut(duration: 0.15)) {
            sheetOpacity = 0
            backgroundOpacity = 0
        }
        
        // FIXED: Card smoothly grows back to original size
        withAnimation(.spring(response: 0.3, dampingFraction: 0.85)) {
            cardScale = 1.0 // Restore to full original size
            cardOffset = 0
        }
        
        // FIXED: Fade out card for smooth transition back to list
        withAnimation(.easeOut(duration: 0.2).delay(0.1)) {
            cardOpacity = 0
        }
        
        // FIXED: Slightly longer delay to allow smooth animation completion
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
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
            return "https://buddybuilderdevstorage.blob.core.windows.net/profile-images/photo-1546519638-68e109498ffc.jpeg"
        }
    }
}

// MARK: - PREVIEW REMOVED
