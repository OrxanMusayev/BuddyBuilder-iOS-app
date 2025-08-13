// BuddyBuilder/Features/Events/Views/EventsView.swift - CORRECT TAB MAPPING FIX

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

// MARK: - Events View - FIXED TAB TIMING ISSUE
struct EventsView: View {
    @StateObject private var eventsViewModel = EventsViewModel(eventsService: CompleteEventsService())
    @EnvironmentObject var localizationManager: LocalizationManager
    @State private var selectedTab: EventsTab = .all
    @State private var showingFilters = false
    
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
                    
                    // Content based on tab - NO TABVIEW!
                    contentSection
                }
            }
            .navigationBarHidden(true)
        }
        .sheet(isPresented: $showingFilters) {
            GenericEventsFilterView(viewModel: eventsViewModel)
                 .environmentObject(localizationManager)
        }
        .onAppear {
            // Sadece ilk açılışta load et
            if eventsViewModel.events.isEmpty {
                print("🚀 Initial load for tab: \(selectedTab.rawValue)")
                setViewModelTab(selectedTab)
                eventsViewModel.loadEvents()
            }
        }
    }
    
    // MARK: - FIXED: Direct tab setting instead of onChange
    private func setViewModelTab(_ uiTab: EventsTab) {
        let viewModelTab: EventTab = (uiTab == .all) ? .all : .my
        
        print("🔄 Setting ViewModel tab directly: \(uiTab.rawValue) → \(viewModelTab.rawValue)")
        print("🎯 This should call: \(uiTab == .all ? "All Events API" : "My Events API")")
        
        // Directly call changeTab
        eventsViewModel.changeTab(to: viewModelTab)
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
                        
                        // Filter count badge
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
    
    // MARK: - Tab Selection Section - FIXED: Direct button action
    private var tabSelectionSection: some View {
        HStack(spacing: 0) {
            ForEach(EventsTab.allCases, id: \.self) { tab in
                Button(action: {
                    print("🎯 Tab button tapped: \(tab.rawValue)")
                    
                    // FIXED: Direct tab change without animation conflicts
                    selectedTab = tab
                    setViewModelTab(tab)
                    
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
    
    // MARK: - Content Section (Replace TabView with simple content)
    private var contentSection: some View {
        eventsListContent
    }
    
    // MARK: - Events List Content
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
                    
                    // Load more button
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
    
    // MARK: - Load More View
    private var loadMoreView: some View {
        VStack(spacing: 12) {
            if eventsViewModel.isLoading {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .primaryOrange))
                
                Text("events.loading.more".localized(using: localizationManager))
                    .font(.system(size: 14))
                    .foregroundColor(.textSecondary)
            } else {
                Button("events.load.more".localized(using: localizationManager)) {
                    eventsViewModel.loadMoreEvents()
                }
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.primaryOrange)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
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

// MARK: - Preview
#Preview {
    EventsView()
        .environmentObject(LocalizationManager(localizationService: MockLocalizationService()))
}
