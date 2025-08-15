// BuddyBuilder/Features/Events/Views/EventsView.swift - COMPLETE UPDATED VERSION

import SwiftUI

// MARK: - Events Tab Enum
enum EventsTab: String, CaseIterable {
    case all = "all"
    case my = "my"
    
    var title: String {
        switch self {
        case .all: return "events.all_events"
        case .my: return "events.my_events"
        }
    }
}

// MARK: - Events View - Complete Updated with Enhanced EventCard
struct EventsView: View {
    @StateObject private var eventsViewModel = EventsViewModel(eventsService: CompleteEventsService())
    @EnvironmentObject var localizationManager: LocalizationManager
    @State private var selectedTab: EventsTab = .all
    @State private var showingFilters = false
    @State private var showingActionSheet = false
    @State private var selectedEventForAction: Event?
    
    // MARK: - Smooth Swipe State
    @GestureState private var dragState = DragState.inactive
    @State private var viewOffset: CGFloat = 0
    @State private var isSwipeInProgress = false
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background
                Color.formBackground
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Header with title and filter button
                    headerSection
                    
                    // Tab Selection
                    tabSelectionSection
                    
                    // Content with smooth swipe gesture - FIXED
                    smoothSwipeableContent
                }
                if showingActionSheet, let event = selectedEventForAction {
                    InstagramStyleActionSheetOverlay(
                        isPresented: $showingActionSheet,
                        event: event,
                        onShare: { handleShareEvent(event) },
                        onEdit: { handleEditEvent(event) },
                        onFreeze: { handleDeactivateEvent(event) },
                        onDelete: { handleDeleteEvent(event) }
                    )
                    .environmentObject(localizationManager)
                    .zIndex(1000)
                }

            }
            .navigationBarHidden(true)
        }
        .sheet(isPresented: $showingFilters) {
            GenericEventsFilterView(viewModel: eventsViewModel)
                 .environmentObject(localizationManager)
        }
        .onAppear {
            if eventsViewModel.events.isEmpty {
                print("🚀 Initial load for tab: \(selectedTab.rawValue)")
                setViewModelTab(selectedTab)
                eventsViewModel.loadEvents()
            }
        }
        
    }
    
    // MARK: - Direct tab setting
    private func setViewModelTab(_ uiTab: EventsTab) {
        let viewModelTab: EventTab = (uiTab == .all) ? .all : .my
        
        print("🔄 Setting ViewModel tab: \(uiTab.rawValue) → \(viewModelTab.rawValue)")
        
        // FIXED: Sadece farklıysa değiştir
        if eventsViewModel.selectedTab != viewModelTab {
            eventsViewModel.changeTab(to: viewModelTab)
        }
    }
    
    // MARK: - Tab switching with smooth animation
    private func switchToTab(_ newTab: EventsTab, animated: Bool = true) {
        guard newTab != selectedTab else { return }
        
        print("🎯 Switching to tab: \(newTab.rawValue)")
        isSwipeInProgress = true
        
        if animated {
            withAnimation(.easeInOut(duration: 0.3)) {
                selectedTab = newTab
                updateViewOffset()
            }
        } else {
            selectedTab = newTab
            updateViewOffset()
        }
        
        setViewModelTab(newTab)
        
        // Reset swipe progress after animation
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            isSwipeInProgress = false
        }
    }
    
    private func updateViewOffset() {
        viewOffset = selectedTab == .all ? 0 : -UIScreen.main.bounds.width
    }
    
    // MARK: - Header Section
    private var headerSection: some View {
        HStack {
            Text("events.title".localized(using: localizationManager))
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .foregroundColor(.textPrimary)
            
            Spacer()
            
            Button(action: {
                showingFilters = true
            }) {
                ZStack {
                    Circle()
                        .fill(Color.white)
                        .frame(width: 40, height: 40)
                        .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 2)
                    
                    ZStack {
                        Image(systemName: "line.3.horizontal.decrease.circle")
                            .font(.system(size: 20, weight: .medium))
                            .foregroundColor(.primaryOrange)
                        
                        if hasActiveFilters {
                            Circle()
                                .fill(Color.red)
                                .frame(width: 8, height: 8)
                                .offset(x: 8, y: -8)
                        }
                    }
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 20)
        .padding(.bottom, 16)
        .background(Color.formBackground)
    }
    
    // MARK: - Tab Selection Section
    private var tabSelectionSection: some View {
        HStack(spacing: 0) {
            ForEach(EventsTab.allCases, id: \.self) { tab in
                Button(action: {
                    print("🎯 Tab button tapped: \(tab.rawValue)")
                    switchToTab(tab)
                }) {
                    VStack(spacing: 8) {
                        Text(tab.title.localized(using: localizationManager))
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(selectedTab == tab ? .primaryOrange : .textSecondary)
                        
                        Rectangle()
                            .fill(selectedTab == tab ? Color.primaryOrange : Color.clear)
                            .frame(height: 2)
                    }
                }
                .frame(maxWidth: .infinity)
            }
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 16)
        .background(Color.formBackground)
        .animation(.easeInOut(duration: 0.2), value: selectedTab)
    }
    
    // MARK: - FIXED: Smooth Swipeable Content
    private var smoothSwipeableContent: some View {
        GeometryReader { geometry in
            ZStack {
                // FIXED: Sadece aktif tab'ın content'ini göster
                eventsListContent
                    .opacity(isSwipeInProgress ? 0.8 : 1.0) // Swipe sırasında hafif fade
                    .animation(.easeInOut(duration: 0.1), value: isSwipeInProgress)
            }
            .frame(width: geometry.size.width)
            .clipped()
            .gesture(
                // FIXED: Daha smooth swipe gesture
                DragGesture(minimumDistance: 20) // Minimum distance ekledik
                    .updating($dragState) { drag, state, _ in
                        // Sadece horizontal movement'i kabul et
                        if abs(drag.translation.width) > abs(drag.translation.height) {
                            state = .dragging(translation: drag.translation)
                        }
                    }
                    .onEnded { value in
                        handleSwipeEnd(value: value, screenWidth: geometry.size.width)
                    }
            )
        }
    }
    
    // MARK: - FIXED: Smooth Swipe Handling
    private func handleSwipeEnd(value: DragGesture.Value, screenWidth: CGFloat) {
        let threshold: CGFloat = screenWidth * 0.2 // Daha düşük threshold
        let dragDistance = value.translation.width
        let dragVelocity = abs(value.translation.width) / max(0.001, abs(value.time.timeIntervalSinceReferenceDate))
        
        // FIXED: Daha akıllı swipe detection
        let shouldSwitch = abs(dragDistance) > threshold || dragVelocity > 800
        
        if shouldSwitch {
            if dragDistance > 0 && selectedTab == .my {
                // Swipe right: My Events → All Events
                switchToTab(.all)
            } else if dragDistance < 0 && selectedTab == .all {
                // Swipe left: All Events → My Events
                switchToTab(.my)
            }
        }
    }
    
    // MARK: - UPDATED: Events List Content with Enhanced EventCard
    private var eventsListContent: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                if eventsViewModel.isLoading && eventsViewModel.events.isEmpty {
                    ForEach(0..<5, id: \.self) { _ in
                        EventCardSkeleton()
                    }
                } else if eventsViewModel.filteredEvents.isEmpty {
                    emptyStateView
                } else {
                    ForEach(eventsViewModel.filteredEvents) { event in
                        // UPDATED: Enhanced EventCard with proper actions based on tab
                        if selectedTab == .all {
                            EventCard.forAllEvents(
                                event: event,
                                onJoin: {
                                    eventsViewModel.joinEvent(event)
                                },
                                onLeave: {
                                    eventsViewModel.leaveEvent(event)
                                },
                                onToggleFavorite: {
                                    handleToggleFavorite(event)
                                }
                            )
                            .environmentObject(localizationManager)
                            .onTapGesture {
                                print("Tapped event: \(event.name)")
                            }
                        } else {
                            EventCard.forMyEvents(
                                event: event,
                                onShare: {
                                    selectedEventForAction = event
                                    showingActionSheet = true
                                },
                                onDelete: {
                                    selectedEventForAction = event
                                    showingActionSheet = true
                                },
                                onEdit: {
                                    selectedEventForAction = event
                                    showingActionSheet = true
                                },
                                onDeactivate: {
                                    selectedEventForAction = event
                                    showingActionSheet = true
                                },
                                onToggleFavorite: {
                                    handleToggleFavorite(event)
                                }
                            )

                            .environmentObject(localizationManager)
                            .onTapGesture {
                                print("Tapped my event: \(event.name)")
                            }
                        }
                    }
                    
                    // PAGINATION: Load More sadece gerektiğinde göster
                    if eventsViewModel.canLoadMore {
                        loadMoreView
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 100)
        }
        .refreshable {
            print("🔄 Pull to refresh - Current tab: \(selectedTab.rawValue)")
            eventsViewModel.refreshEvents()
        }
        .background(Color.formBackground)
    }
    
    // MARK: - Load More View - PAGINATION FIX
    private var loadMoreView: some View {
        VStack(spacing: 12) {
            if eventsViewModel.isLoading {
                // Loading state
                VStack(spacing: 8) {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .primaryOrange))
                    
                    Text("events.loading.more".localized(using: localizationManager))
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.textSecondary)
                }
                .padding(.vertical, 20)
            } else {
                // Load More Button
                Button(action: {
                    print("🔄 Load More tapped - Current page: \(eventsViewModel.currentPage), Total pages: \(eventsViewModel.totalPages)")
                    print("🔄 Can load more: \(eventsViewModel.canLoadMore)")
                    print("🔄 Events count: \(eventsViewModel.events.count)")
                    eventsViewModel.loadMoreEvents()
                }) {
                    HStack(spacing: 8) {
                        Image(systemName: "plus.circle")
                            .font(.system(size: 16, weight: .medium))
                        
                        Text("events.load.more".localized(using: localizationManager))
                            .font(.system(size: 16, weight: .semibold))
                        
                        // PAGINATION DEBUG INFO (development only)
                        Text("(\(eventsViewModel.currentPage)/\(eventsViewModel.totalPages))")
                            .font(.system(size: 12))
                            .foregroundColor(.gray)
                    }
                    .foregroundColor(.primaryOrange)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 25)
                            .fill(Color.primaryOrange.opacity(0.1))
                            .overlay(
                                RoundedRectangle(cornerRadius: 25)
                                    .stroke(Color.primaryOrange, lineWidth: 1.5)
                            )
                    )
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 20)
            }
        }
        .frame(maxWidth: .infinity)
    }
    
    // MARK: - Empty State View
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: selectedTab == .all ? "calendar.badge.exclamationmark" : "calendar.badge.clock")
                .font(.system(size: 60, weight: .light))
                .foregroundColor(.textSecondary.opacity(0.5))
            
            Text(emptyStateTitle)
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.textPrimary)
                .multilineTextAlignment(.center)
            
            Text(emptyStateDescription)
                .font(.system(size: 14, weight: .regular))
                .foregroundColor(.textSecondary)
                .multilineTextAlignment(.center)
                .lineLimit(nil)
            
            if hasActiveFilters {
                Button(action: {
                    eventsViewModel.clearFilters()
                }) {
                    Text("events.clear_filters".localized(using: localizationManager))
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.primaryOrange)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 10)
                        .background(
                            Capsule()
                                .stroke(Color.primaryOrange, lineWidth: 1)
                        )
                }
                .padding(.top, 8)
            }
        }
        .padding(.horizontal, 40)
        .padding(.top, 60)
    }
    
    // MARK: - Computed Properties
    private var hasActiveFilters: Bool {
        eventsViewModel.selectedEventType != nil ||
        eventsViewModel.selectedSportId != nil ||
        !eventsViewModel.selectedLocation.isEmpty ||
        !eventsViewModel.maxEntryFee.isEmpty ||
        eventsViewModel.showUpcomingOnly ||
        eventsViewModel.showAvailableOnly ||
        eventsViewModel.showOpenRegistrationOnly
    }
    
    private var emptyStateTitle: String {
        if selectedTab == .all {
            return "events.empty.all".localized(using: localizationManager)
        } else {
            return "events.empty.my".localized(using: localizationManager)
        }
    }
    
    private var emptyStateDescription: String {
        if selectedTab == .all {
            return "events.empty.all.subtitle".localized(using: localizationManager)
        } else {
            return "events.empty.my.subtitle".localized(using: localizationManager)
        }
    }
}

// MARK: - NEW: Event Action Handlers Extension
extension EventsView {
    
    // MARK: - Event Action Handlers
    private func handleToggleFavorite(_ event: Event) {
        // TODO: Implement favorite toggle logic
        print("Toggle favorite for event: \(event.name)")
        // You can add API call here to toggle favorite status
        // Example: eventsViewModel.toggleFavorite(event.id)
    }
    
    private func handleShareEvent(_ event: Event) {
        print("Share event: \(event.name)")
            
            let shareText = "events.share.text".localized(using: localizationManager)
                .replacingOccurrences(of: "{eventName}", with: event.name)
                .replacingOccurrences(of: "{location}", with: event.location)
                .replacingOccurrences(of: "{date}", with: event.formattedEventDate)
            
            let activityVC = UIActivityViewController(
                activityItems: [shareText],
                applicationActivities: nil
            )
            
            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
               let window = windowScene.windows.first,
               let rootVC = window.rootViewController {
                
                if let popover = activityVC.popoverPresentationController {
                    popover.sourceView = rootVC.view
                    popover.sourceRect = CGRect(x: rootVC.view.bounds.midX, y: rootVC.view.bounds.midY, width: 0, height: 0)
                }
                
                rootVC.present(activityVC, animated: true)
            }
        
    }
    
    private func handleDeleteEvent(_ event: Event) {
        print("Delete event: \(event.name)")
            
            let alert = UIAlertController(
                title: "events.delete.confirm.title".localized(using: localizationManager),
                message: "events.delete.confirm.message".localized(using: localizationManager)
                    .replacingOccurrences(of: "{eventName}", with: event.name),
                preferredStyle: .alert
            )
            
            alert.addAction(UIAlertAction(
                title: "events.delete".localized(using: localizationManager),
                style: .destructive
            ) { _ in
                print("Confirmed delete for: \(event.name)")
                // Implement delete logic here
            })
            
            alert.addAction(UIAlertAction(
                title: "events.cancel".localized(using: localizationManager),
                style: .cancel
            ))
            
            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
               let window = windowScene.windows.first,
               let rootVC = window.rootViewController {
                rootVC.present(alert, animated: true)
            }
        
    }
    
    private func handleEditEvent(_ event: Event) {
        // TODO: Navigate to edit event screen
        print("Edit event: \(event.name)")
        // You can add navigation to edit screen here
        // Example: navigationRouter.navigate(to: .editEvent(event))
        
    }
    
    private func handleDeactivateEvent(_ event: Event) {
        print("Deactivate event: \(event.name)")
            
            let alert = UIAlertController(
                title: "events.freeze.confirm.title".localized(using: localizationManager),
                message: "events.freeze.confirm.message".localized(using: localizationManager)
                    .replacingOccurrences(of: "{eventName}", with: event.name),
                preferredStyle: .alert
            )
            
            alert.addAction(UIAlertAction(
                title: "events.freeze".localized(using: localizationManager),
                style: .default
            ) { _ in
                print("Confirmed deactivate for: \(event.name)")
                // Implement deactivate logic here
            })
            
            alert.addAction(UIAlertAction(
                title: "events.cancel".localized(using: localizationManager),
                style: .cancel
            ))
            
            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
               let window = windowScene.windows.first,
               let rootVC = window.rootViewController {
                rootVC.present(alert, animated: true)
            }
    }
}

// MARK: - Drag State Enum
enum DragState {
    case inactive
    case dragging(translation: CGSize)
    
    var translation: CGSize {
        switch self {
        case .inactive:
            return .zero
        case .dragging(let translation):
            return translation
        }
    }
}

// MARK: - Preview
#Preview {
    EventsView()
        .environmentObject(LocalizationManager(localizationService: MockLocalizationService()))
}
