// BuddyBuilder/Features/Events/Views/EventsView.swift - PAGINATION FIX

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

// MARK: - Events View - Smooth Swipe Experience + PAGINATION FIX
struct EventsView: View {
    @StateObject private var eventsViewModel = EventsViewModel(eventsService: CompleteEventsService())
    @EnvironmentObject var localizationManager: LocalizationManager
    @State private var selectedTab: EventsTab = .all
    @State private var showingFilters = false
    
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
    
    // MARK: - FIXED: Single Events List Content (shows current tab's data) + PAGINATION
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
                        EventCard(
                            event: event,
                            onJoin: {
                                eventsViewModel.joinEvent(event)
                            },
                            onLeave: {
                                eventsViewModel.leaveEvent(event)
                            }
                        )
                        .environmentObject(localizationManager)
                        .onTapGesture {
                            print("Tapped event: \(event.name)")
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

// MARK: - PAGINATION DEBUG VIEW (Test amaçlı - Production'da kaldırın)
struct LoadMoreDebugView: View {
    @ObservedObject var viewModel: EventsViewModel
    
    var body: some View {
        VStack(spacing: 8) {
            Text("PAGINATION DEBUG")
                .font(.system(size: 10, weight: .bold))
                .foregroundColor(.white)
            
            HStack(spacing: 8) {
                Text("Page: \(viewModel.currentPage)/\(viewModel.totalPages)")
                    .font(.system(size: 9, weight: .medium))
                    .foregroundColor(.white)
                
                Text("Events: \(viewModel.events.count)")
                    .font(.system(size: 9, weight: .medium))
                    .foregroundColor(.white)
                
                Text("Load More: \(viewModel.canLoadMore ? "YES" : "NO")")
                    .font(.system(size: 9, weight: .medium))
                    .foregroundColor(viewModel.canLoadMore ? .green : .red)
            }
        }
        .padding(8)
        .background(Color.black.opacity(0.7))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

// MARK: - Preview
#Preview {
    EventsView()
        .environmentObject(LocalizationManager(localizationService: MockLocalizationService()))
}
