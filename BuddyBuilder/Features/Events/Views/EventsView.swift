import SwiftUI

// MARK: - Events View - Modern & Multilingual
struct EventsView: View {
    @StateObject private var eventsViewModel = EventsViewModel()
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
            EventsFilterView(
                selectedType: $eventsViewModel.selectedEventType,
                selectedSport: $eventsViewModel.selectedSport,
                selectedDate: $eventsViewModel.selectedDate,
                onApply: {
                    eventsViewModel.applyFilters()
                    showingFilters = false
                }
            )
            .environmentObject(localizationManager)
        }
        .onAppear {
            if eventsViewModel.events.isEmpty {
                eventsViewModel.loadEvents()
            }
        }
        .onChange(of: selectedTab) { newTab in
            eventsViewModel.changeTab(to: newTab)
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
                        if eventsViewModel.hasActiveFilters {
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
                if eventsViewModel.isLoading {
                    ForEach(0..<5, id: \.self) { _ in
                        EventCardSkeleton()
                    }
                } else if eventsViewModel.filteredEvents.isEmpty {
                    emptyStateView
                } else {
                    ForEach(eventsViewModel.filteredEvents) { event in
                        EventCard(event: event) {
                            // Handle event tap - navigate to event details
                            // TODO: Navigate to event details
                            print("Tapped event: \(event.title)")
                        }
                        .environmentObject(localizationManager)
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 100) // Account for tab bar
        }
        .refreshable {
            await eventsViewModel.refreshEvents()
        }
        .background(Color.formBackground)
    }
    
    // MARK: - Empty State View
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: selectedTab == .all ? "calendar.badge.exclamationmark" : "calendar.badge.clock")
                .font(.system(size: 60, weight: .light))
                .foregroundColor(.textSecondary.opacity(0.5))
            
            Text(eventsViewModel.emptyStateTitle)
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.textPrimary)
                .multilineTextAlignment(.center)
            
            Text(eventsViewModel.emptyStateDescription)
                .font(.system(size: 14, weight: .regular))
                .foregroundColor(.textSecondary)
                .multilineTextAlignment(.center)
                .lineLimit(nil)
            
            if eventsViewModel.hasActiveFilters {
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
}

// MARK: - Preview
#Preview {
    EventsView()
        .environmentObject(LocalizationManager(localizationService: MockLocalizationService()))
}
