// BuddyBuilder/Features/Events/Views/CachedEventsView.swift - COMPLETE UPDATED VERSION

import SwiftUI

struct CachedEventsView: View {
    @StateObject private var viewModel = CachedEventsViewModel()
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
                    // Header with cache status
                    headerSection
                    
                    // Tab Selection
                    tabSelectionSection
                    
                    // Search Bar
                    searchSection
                    
                    // Smooth Swipeable Content - FIXED
                    smoothSwipeableContent
                }
            }
            .navigationBarHidden(true)
        }
        .sheet(isPresented: $showingFilters) {
            GenericEventsFilterView(viewModel: viewModel)
                .environmentObject(localizationManager)
        }
        .onAppear {
            handleViewAppear()
        }
        .alert("Error", isPresented: $viewModel.showError) {
            Button("OK") {
                viewModel.showError = false
            }
        } message: {
            Text(viewModel.errorMessage)
        }
    }
    
    // MARK: - Tab switching with smooth animation
    private func switchToTab(_ newTab: EventsTab, animated: Bool = true) {
        guard newTab != selectedTab else { return }
        
        print("🔄 CachedEvents switching to tab: \(newTab.rawValue)")
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
        
        let viewModelTab: EventTab = (newTab == .all) ? .all : .my
        
        // FIXED: Sadece farklıysa değiştir
        if viewModel.selectedTab != viewModelTab {
            viewModel.changeTab(to: viewModelTab)
        }
        
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
            VStack(alignment: .leading, spacing: 4) {
                Text("events.title".localized(using: localizationManager))
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundColor(.textPrimary)
                
                // Cache status indicator
                HStack(spacing: 8) {
                    cacheStatusIndicator
                    
                    if viewModel.hasNewDataAvailable {
                        newDataIndicator
                    }
                }
            }
            
            Spacer()
            
            HStack(spacing: 12) {
                // Cache info button
                cacheInfoButton
                
                // Filter button
                filterButton
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 20)
        .padding(.bottom, 16)
        .background(Color.formBackground)
    }
    
    private var cacheStatusIndicator: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(cacheStatusColor)
                .frame(width: 8, height: 8)
            
            Text(cacheStatusText)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.textSecondary)
        }
    }
    
    private var cacheStatusColor: Color {
        switch viewModel.uiLoadingState {
        case .showingCached:
            return .green
        case .refreshingBackground:
            return .orange
        case .showingSkeleton, .refreshingManual:
            return .red
        case .error:
            return .red
        default:
            return .gray
        }
    }
    
    private var cacheStatusText: String {
        switch viewModel.uiLoadingState {
        case .showingCached:
            return "From Cache"
        case .refreshingBackground:
            return "Updating..."
        case .showingSkeleton:
            return "Loading..."
        case .refreshingManual:
            return "Refreshing..."
        case .error:
            return "Error"
        default:
            return viewModel.getCacheInfo()
        }
    }
    
    private var newDataIndicator: some View {
        Button(action: {
            viewModel.loadEventsFromCache()
        }) {
            HStack(spacing: 4) {
                Image(systemName: "arrow.clockwise")
                    .font(.system(size: 10, weight: .medium))
                
                Text("New data")
                    .font(.system(size: 10, weight: .medium))
            }
            .foregroundColor(.white)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(Color.primaryOrange)
            .clipShape(Capsule())
        }
        .transition(.scale.combined(with: .opacity))
        .animation(.spring(response: 0.5, dampingFraction: 0.7), value: viewModel.hasNewDataAvailable)
    }
    
    private var cacheInfoButton: some View {
        Button(action: {
            showCacheInfo()
        }) {
            Image(systemName: "info.circle")
                .font(.system(size: 18, weight: .medium))
                .foregroundColor(.textSecondary)
        }
    }
    
    private var filterButton: some View {
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
                    
                    if viewModel.hasActiveFilters {
                        Circle()
                            .fill(Color.red)
                            .frame(width: 8, height: 8)
                            .offset(x: 8, y: -8)
                    }
                }
            }
        }
    }
    
    // MARK: - Tab Selection Section
    private var tabSelectionSection: some View {
        HStack(spacing: 0) {
            ForEach(EventsTab.allCases, id: \.self) { tab in
                Button(action: {
                    print("🎯 CachedEvents Tab button tapped: \(tab.rawValue)")
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
    
    // MARK: - Search Section
    private var searchSection: some View {
        HStack(spacing: 12) {
            // Search field
            HStack(spacing: 10) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.textSecondary)
                
                TextField("events.search.placeholder".localized(using: localizationManager), text: $viewModel.searchText)
                    .font(.system(size: 16))
                    .foregroundColor(.textPrimary)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                
                if !viewModel.searchText.isEmpty {
                    Button(action: {
                        viewModel.searchText = ""
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 16))
                            .foregroundColor(.textSecondary)
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: 25))
            .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
            
            // Manual refresh button
            refreshButton
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 16)
        .background(Color.formBackground)
    }
    
    private var refreshButton: some View {
        Button(action: {
            viewModel.refreshEventsManually()
        }) {
            ZStack {
                if case .refreshingManual = viewModel.uiLoadingState {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .primaryOrange))
                        .scaleEffect(0.8)
                } else {
                    Image(systemName: "arrow.clockwise")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(.primaryOrange)
                }
            }
        }
        .disabled(viewModel.uiLoadingState.isLoading)
        .opacity(viewModel.uiLoadingState.isLoading ? 0.6 : 1.0)
    }
    
    // MARK: - FIXED: Smooth Swipeable Content
    private var smoothSwipeableContent: some View {
        GeometryReader { geometry in
            ZStack {
                // FIXED: Sadece aktif tab'ın content'ini göster
                contentBasedOnState
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
    
    // MARK: - FIXED: Single Content Based on State (shows current tab's data)
    private var contentBasedOnState: some View {
        Group {
            switch viewModel.uiLoadingState {
            case .showingSkeleton:
                skeletonLoadingView
                
            case .error(let errorMessage):
                errorView(errorMessage)
                
            default:
                eventsContentView
            }
        }
        .refreshable {
            await performManualRefresh()
        }
    }
    
    // MARK: - Skeleton Loading View
    private var skeletonLoadingView: some View {
        VStack(spacing: 20) {
            VStack(spacing: 16) {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .primaryOrange))
                    .scaleEffect(1.2)
                
                Text("Loading events...")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.textSecondary)
            }
            .padding(.top, 40)
            
            LazyVStack(spacing: 12) {
                ForEach(0..<5, id: \.self) { _ in
                    EventCardSkeleton()
                }
            }
            .padding(.horizontal, 20)
            
            Spacer()
        }
        .transition(.opacity)
    }
    
    // MARK: - Error View
    private func errorView(_ message: String) -> some View {
        VStack(spacing: 20) {
            Spacer()
            
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 50, weight: .light))
                .foregroundColor(.red.opacity(0.6))
            
            Text("Error")
                .font(.system(size: 20, weight: .semibold))
                .foregroundColor(.textPrimary)
            
            Text(message)
                .font(.system(size: 14))
                .foregroundColor(.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
            
            Button("Try Again") {
                viewModel.loadEvents(strategy: .apiFirst)
            }
            .font(.system(size: 16, weight: .medium))
            .foregroundColor(.white)
            .padding(.horizontal, 24)
            .padding(.vertical, 12)
            .background(Color.primaryOrange)
            .clipShape(RoundedRectangle(cornerRadius: 20))
            
            Spacer()
        }
        .transition(.opacity)
    }
    
    // MARK: - Events Content View
    private var eventsContentView: some View {
        ZStack(alignment: .top) {
            if viewModel.filteredEvents.isEmpty {
                emptyStateView
            } else {
                eventsListView
            }
            
            // Background refresh indicator
            if case .refreshingBackground = viewModel.uiLoadingState {
                backgroundRefreshIndicator
            }
        }
    }
    
    // MARK: - UPDATED: Events List View with Enhanced EventCard
    private var eventsListView: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                ForEach(viewModel.filteredEvents) { event in
                    // UPDATED: Enhanced EventCard with proper actions based on tab
                    if selectedTab == .all {
                        EventCard.forAllEvents(
                            event: event,
                            onJoin: {
                                viewModel.joinEvent(event)
                            },
                            onLeave: {
                                viewModel.leaveEvent(event)
                            },
                            onToggleFavorite: {
                                handleToggleFavorite(event)
                            }
                        )
                        .environmentObject(localizationManager)
                        .transition(.scale.combined(with: .opacity))
                    } else {
                        EventCard.forMyEvents(
                            event: event,
                            onShare: {
                                handleShareEvent(event)
                            },
                            onDelete: {
                                handleDeleteEvent(event)
                            },
                            onEdit: {
                                handleEditEvent(event)
                            },
                            onDeactivate: {
                                handleDeactivateEvent(event)
                            },
                            onToggleFavorite: {
                                handleToggleFavorite(event)
                            }
                        )
                        .environmentObject(localizationManager)
                        .transition(.scale.combined(with: .opacity))
                    }
                }
                
                // PAGINATION: Load More sadece gerektiğinde göster
                if viewModel.canLoadMore {
                    loadMoreView
                }
                
                Color.clear.frame(height: 100)
            }
            .padding(.horizontal, 20)
            .padding(.top, 16)
        }
        .animation(.easeInOut(duration: 0.3), value: viewModel.filteredEvents.count)
    }
    
    // MARK: - Load More View - PAGINATION FIX
    private var loadMoreView: some View {
        VStack(spacing: 12) {
            if viewModel.uiLoadingState.isLoading {
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
                    print("🔄 Cached Load More tapped - Current page: \(viewModel.currentPage), Total pages: \(viewModel.totalPages)")
                    print("🔄 Can load more: \(viewModel.canLoadMore)")
                    print("🔄 Events count: \(viewModel.events.count)")
                    viewModel.loadMoreEvents()
                }) {
                    HStack(spacing: 8) {
                        Image(systemName: "plus.circle")
                            .font(.system(size: 16, weight: .medium))
                        
                        Text("events.load.more".localized(using: localizationManager))
                            .font(.system(size: 16, weight: .semibold))
                        
                        // PAGINATION DEBUG INFO (development only)
                        Text("(\(viewModel.currentPage)/\(viewModel.totalPages))")
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
    
    private var backgroundRefreshIndicator: some View {
        VStack {
            HStack(spacing: 8) {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .primaryOrange))
                    .scaleEffect(0.6)
                
                Text("Updating...")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.textSecondary)
                
                Spacer()
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 8)
            .background(
                Color.primaryOrange.opacity(0.1)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            )
            .padding(.horizontal, 20)
            .transition(.move(edge: .top).combined(with: .opacity))
            
            Spacer()
        }
    }
    
    // MARK: - Empty State View
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Spacer()
            
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
            
            if viewModel.hasActiveFilters {
                Button(action: {
                    viewModel.clearFilters()
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
            
            Spacer()
        }
        .padding(.horizontal, 40)
        .transition(.opacity)
    }
    
    // MARK: - Helper Methods
    private func handleViewAppear() {
        if viewModel.events.isEmpty {
            viewModel.loadEvents(strategy: .cacheFirst)
        }
    }
    
    @MainActor
    private func performManualRefresh() async {
        viewModel.refreshEventsManually()
        
        // Wait for completion
        try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 second
    }
    
    private func showCacheInfo() {
        let alert = UIAlertController(
            title: "Cache Information",
            message: """
            Current cache status: \(viewModel.getCacheInfo())
            
            Cache Strategy:
            • First load: Cache → API if empty
            • Tab switch: Cache → Background API
            • Manual refresh: Force API
            • Filters: Force API
            
            Pagination:
            • Page: \(viewModel.currentPage)/\(viewModel.totalPages)
            • Events: \(viewModel.events.count)
            • Can Load More: \(viewModel.canLoadMore ? "YES" : "NO")
            
            Actions:
            """,
            preferredStyle: .actionSheet
        )
        
        alert.addAction(UIAlertAction(title: "Clear Cache", style: .destructive) { _ in
            viewModel.clearAllCache()
            viewModel.loadEvents(strategy: .apiFirst)
        })
        
        alert.addAction(UIAlertAction(title: "Load from Cache", style: .default) { _ in
            viewModel.loadEventsFromCache()
        })
        
        alert.addAction(UIAlertAction(title: "Force API Refresh", style: .default) { _ in
            viewModel.loadEvents(strategy: .apiOnly)
        })
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first {
            window.rootViewController?.present(alert, animated: true)
        }
    }
    
    // MARK: - Computed Properties
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
extension CachedEventsView {
    
    // MARK: - Event Action Handlers
    private func handleToggleFavorite(_ event: Event) {
        print("Toggle favorite for event: \(event.name)")
        // Add your favorite toggle logic here
        // Example: viewModel.toggleFavorite(event.id)
    }
    
    private func handleShareEvent(_ event: Event) {
        let shareText = "events.share.text".localized(using: localizationManager)
            .replacingOccurrences(of: "{eventName}", with: event.name)
            .replacingOccurrences(of: "{location}", with: event.location)
            .replacingOccurrences(of: "{date}", with: event.formattedEventDate)
        
        let activityVC = UIActivityViewController(
            activityItems: [shareText],
            applicationActivities: nil
        )
        
        // For iPad compatibility
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
            print("Delete event: \(event.name)")
            // Implement your delete logic here
            // viewModel.deleteEvent(event.id)
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
        print("Edit event: \(event.name)")
        // Add navigation to edit screen
        // Example: navigationRouter.navigate(to: .editEvent(event))
    }
    
    private func handleDeactivateEvent(_ event: Event) {
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
            print("Deactivate event: \(event.name)")
            // Implement your deactivate logic here
            // viewModel.deactivateEvent(event.id)
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

// MARK: - Preview
#Preview {
    CachedEventsView()
        .environmentObject(LocalizationManager(localizationService: MockLocalizationService()))
}
