// BuddyBuilder/Features/Events/Views/EventsView.swift

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

// MARK: - Events View - Modern & Multilingual
struct EventsView: View {
    @StateObject private var eventsViewModel = EventsViewModel(eventsService: CompleteEventsService()) // Change to EventsService() in production
    @EnvironmentObject var localizationManager: LocalizationManager
    @State private var selectedTab: EventsTab = .all
    @State private var showingFilters = false
    @State private var dragOffset: CGFloat = 0
    @State private var isDragging = false
    
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
                    
                    // Events List with TabView for swipe
                    eventsTabView
                }
            }
            .navigationBarHidden(true)
        }
        .sheet(isPresented: $showingFilters) {
            EventsFilterView(viewModel: eventsViewModel)
                .environmentObject(localizationManager)
        }
        .onAppear {
            if eventsViewModel.events.isEmpty {
                eventsViewModel.loadEvents()
            }
        }
        .onChange(of: selectedTab) { oldValue, newTab in
            let viewModelTab: EventTab = newTab == .all ? .all : .my
            eventsViewModel.changeTab(to: viewModelTab) // Direct method call
        }
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
    
    // MARK: - Events Tab View with Swipe
    private var eventsTabView: some View {
        TabView(selection: $selectedTab) {
            // All Events Tab
            eventsListContent
                .tag(EventsTab.all)
            
            // My Events Tab
            eventsListContent
                .tag(EventsTab.my)
        }
        .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
        .animation(.easeInOut(duration: 0.2), value: selectedTab)
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
                            // Handle event tap - navigate to event details
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
            .padding(.bottom, 100) // Account for tab bar
        }
        .refreshable {
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
//
//// MARK: - Simple Events Filter View
//struct EventsFilterView: View {
//    @ObservedObject var viewModel: EventsViewModel
//    @EnvironmentObject var localizationManager: LocalizationManager
//    @Environment(\.presentationMode) var presentationMode
//    
//    var body: some View {
//        NavigationView {
//            EventFiltersSheet(viewModel: viewModel)
//                .environmentObject(localizationManager)
//                .navigationTitle("Filters")
//                .navigationBarTitleDisplayMode(.inline)
//                .navigationBarItems(
//                    leading: Button("Clear All") {
//                        viewModel.clearFilters()
//                        presentationMode.wrappedValue.dismiss()
//                    },
//                    trailing: Button("Done") {
//                        presentationMode.wrappedValue.dismiss()
//                    }
//                )
//        }
//    }
//}

// MARK: - Preview
#Preview {
    EventsView()
        .environmentObject(LocalizationManager(localizationService: MockLocalizationService()))
}
