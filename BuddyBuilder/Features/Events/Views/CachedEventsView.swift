// BuddyBuilder/Features/Events/Views/CachedEventsView.swift

import SwiftUI

struct CachedEventsView: View {
    @StateObject private var viewModel = CachedEventsViewModel()
    @EnvironmentObject var localizationManager: LocalizationManager
    @State private var selectedTab: EventsTab = .all
    @State private var showingFilters = false
    @State private var showRefreshHint = false
    
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
                    
                    // Content based on loading state
                    contentSection
                }
            }
            .navigationBarHidden(true)
            .refreshable {
                await performManualRefresh()
            }
        }
        .sheet(isPresented: $showingFilters) {
            GenericEventsFilterView(viewModel: viewModel)
                .environmentObject(localizationManager)
        }
        .onAppear {
            handleViewAppear()
        }
        .onChange(of: selectedTab) { oldValue, newTab in
            let viewModelTab: EventTab = newTab == .all ? .all : .my
            viewModel.changeTab(to: viewModelTab)
        }
        .alert("Error", isPresented: $viewModel.showError) {
            Button("OK") {
                viewModel.showError = false
            }
        } message: {
            Text(viewModel.errorMessage)
        }
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
                    withAnimation(.easeInOut(duration: 0.2)) {
                        selectedTab = tab
                    }
                }) {
                    VStack(spacing: 8) {
                        Text(tab.title.localized(using: localizationManager))
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(selectedTab == tab ? .primaryOrange : .textSecondary)
                        
                        Rectangle()
                            .fill(selectedTab == tab ? Color.primaryOrange : Color.clear)
                            .frame(height: 2)
                            .animation(.easeInOut(duration: 0.2), value: selectedTab)
                    }
                }
                .frame(maxWidth: .infinity)
            }
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 16)
        .background(Color.formBackground)
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
    
    // MARK: - Content Section
    private var contentSection: some View {
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
    }
    
    // MARK: - Skeleton Loading View
    private var skeletonLoadingView: some View {
        VStack(spacing: 20) {
            // Loading indicator
            VStack(spacing: 16) {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .primaryOrange))
                    .scaleEffect(1.2)
                
                Text("Loading events...")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.textSecondary)
            }
            .padding(.top, 40)
            
            // Skeleton cards
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
            // Main events list
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
    
    private var eventsListView: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                ForEach(viewModel.filteredEvents) { event in
                    EventCard(
                        event: event,
                        onJoin: {
                            viewModel.joinEvent(event)
                        },
                        onLeave: {
                            viewModel.leaveEvent(event)
                        }
                    )
                    .environmentObject(localizationManager)
                    .transition(.scale.combined(with: .opacity))
                }
                
                // Load more section
                if viewModel.canLoadMore {
                    loadMoreView
                }
                
                // Bottom spacing
                Color.clear.frame(height: 100)
            }
            .padding(.horizontal, 20)
            .padding(.top, 16)
        }
        .animation(.easeInOut(duration: 0.3), value: viewModel.filteredEvents.count)
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
    
    private var loadMoreView: some View {
        VStack(spacing: 12) {
            if viewModel.uiLoadingState.isLoading {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .primaryOrange))
                
                Text("events.loading.more".localized(using: localizationManager))
                    .font(.system(size: 14))
                    .foregroundColor(.textSecondary)
            } else {
                Button("events.load.more".localized(using: localizationManager)) {
                    viewModel.loadMoreEvents()
                }
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.primaryOrange)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
    }
    
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

// MARK: - Preview
#Preview {
    CachedEventsView()
        .environmentObject(LocalizationManager(localizationService: MockLocalizationService()))
}
