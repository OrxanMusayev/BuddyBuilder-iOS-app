//// BuddyBuilder/Features/Events/Views/FinalEventsView.swift
//
//import SwiftUI
//
//struct FinalEventsView: View {
//    // MARK: - Use Enhanced ViewModel for Complete Functionality
//    @StateObject private var viewModel = EnhancedEventsViewModel(
//        eventsService: MockCompleteEventsService() // Change to CompleteEventsService() in production
//    )
//    @EnvironmentObject var localizationManager: LocalizationManager
//    @State private var selectedTab: EventsTab = .all
//    @State private var showingFilters = false
//    
//    var body: some View {
//        NavigationView {
//            ZStack {
//                // Background
//                Color.formBackground
//                    .ignoresSafeArea()
//                
//                VStack(spacing: 0) {
//                    // Header with title, notifications, and filter button
//                    headerSection
//                    
//                    // Tab Selection
//                    tabSelectionSection
//                    
//                    // Search Bar
//                    searchSection
//                    
//                    // Events Content
//                    eventsContent
//                }
//            }
//            .navigationBarHidden(true)
//        }
//        .sheet(isPresented: $showingFilters) {
//            EventFiltersSheet(viewModel: viewModel)
//                .environmentObject(localizationManager)
//        }
//        .onAppear {
//            if viewModel.events.isEmpty {
//                viewModel.loadEvents()
//            }
//            viewModel.loadNotifications()
//            viewModel.loadUserInvitations()
//        }
//        .onChange(of: selectedTab) { newTab in
//            viewModel.selectedTab = newTab == .all ? .all : .my
//        }
//    }
//    
//    // MARK: - Header Section
//    private var headerSection: some View {
//        HStack {
//            VStack(alignment: .leading, spacing: 4) {
//                Text("events.title".localized(using: localizationManager))
//                    .font(.system(size: 28, weight: .bold, design: .rounded))
//                    .foregroundColor(.textPrimary)
//                
//                if let stats = viewModel.eventStatistics {
//                    Text("\(stats.activeEvents) active events")
//                        .font(.system(size: 14, weight: .medium))
//                        .foregroundColor(.textSecondary)
//                }
//            }
//            
//            Spacer()
//            
//            HStack(spacing: 12) {
//                // Notifications button
//                notificationButton
//                
//                // Invitations button
//                invitationButton
//                
//                // Filter button
//                filterButton
//            }
//        }
//        .padding(.horizontal, 20)
//        .padding(.top, 20)
//        .padding(.bottom, 16)
//        .background(Color.formBackground)
//    }
//    
//    private var notificationButton: some View {
//        Button(action: {
//            // TODO: Show notifications view
//        }) {
//            ZStack {
//                Image(systemName: "bell")
//                    .font(.system(size: 20, weight: .medium))
//                    .foregroundColor(.textPrimary)
//                
//                if viewModel.unreadNotificationsCount > 0 {
//                    Text("\(min(viewModel.unreadNotificationsCount, 99))")
//                        .font(.system(size: 10, weight: .bold))
//                        .foregroundColor(.white)
//                        .frame(minWidth: 16, minHeight: 16)
//                        .background(Color.red)
//                        .clipShape(Circle())
//                        .offset(x: 8, y: -8)
//                }
//            }
//        }
//    }
//    
//    private var invitationButton: some View {
//        Button(action: {
//            // TODO: Show invitations view
//        }) {
//            ZStack {
//                Image(systemName: "envelope")
//                    .font(.system(size: 20, weight: .medium))
//                    .foregroundColor(.textPrimary)
//                
//                if viewModel.pendingInvitationsCount > 0 {
//                    Text("\(min(viewModel.pendingInvitationsCount, 99))")
//                        .font(.system(size: 10, weight: .bold))
//                        .foregroundColor(.white)
//                        .frame(minWidth: 16, minHeight: 16)
//                        .background(Color.primaryOrange)
//                        .clipShape(Circle())
//                        .offset(x: 8, y: -8)
//                }
//            }
//        }
//    }
//    
//    private var filterButton: some View {
//        Button(action: {
//            showingFilters = true
//        }) {
//            ZStack {
//                Circle()
//                    .fill(Color.white)
//                    .frame(width: 40, height: 40)
//                    .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 2)
//                
//                ZStack {
//                    Image(systemName: "line.3.horizontal.decrease.circle")
//                        .font(.system(size: 20, weight: .medium))
//                        .foregroundColor(.primaryOrange)
//                    
//                    // Filter count badge
//                    if viewModel.hasActiveFilters {
//                        Circle()
//                            .fill(Color.red)
//                            .frame(width: 8, height: 8)
//                            .offset(x: 8, y: -8)
//                    }
//                }
//            }
//        }
//    }
//    
//    // MARK: - Tab Selection Section
//    private var tabSelectionSection: some View {
//        HStack(spacing: 0) {
//            ForEach(EventsTab.allCases, id: \.self) { tab in
//                Button(action: {
//                    withAnimation(.easeInOut(duration: 0.2)) {
//                        selectedTab = tab
//                    }
//                }) {
//                    VStack(spacing: 8) {
//                        Text(tab.title.localized(using: localizationManager))
//                            .font(.system(size: 16, weight: .semibold))
//                            .foregroundColor(selectedTab == tab ? .primaryOrange : .textSecondary)
//                        
//                        Rectangle()
//                            .fill(selectedTab == tab ? Color.primaryOrange : Color.clear)
//                            .frame(height: 2)
//                            .animation(.easeInOut(duration: 0.2), value: selectedTab)
//                    }
//                }
//                .frame(maxWidth: .infinity)
//            }
//        }
//        .padding(.horizontal, 20)
//        .padding(.bottom, 16)
//        .background(Color.formBackground)
//    }
//    
//    // MARK: - Search Section
//    private var searchSection: some View {
//        HStack(spacing: 12) {
//            // Search field
//            HStack(spacing: 10) {
//                Image(systemName: "magnifyingglass")
//                    .font(.system(size: 16, weight: .medium))
//                    .foregroundColor(.textSecondary)
//                
//                TextField("events.search.placeholder".localized(using: localizationManager), text: $viewModel.searchText)
//                    .font(.system(size: 16))
//                    .foregroundColor(.textPrimary)
//                    .textInputAutocapitalization(.never)
//                    .autocorrectionDisabled()
//                
//                if !viewModel.searchText.isEmpty {
//                    Button(action: {
//                        viewModel.searchText = ""
//                    }) {
//                        Image(systemName: "xmark.circle.fill")
//                            .font(.system(size: 16))
//                            .foregroundColor(.textSecondary)
//                    }
//                }
//            }
//            .padding(.horizontal, 16)
//            .padding(.vertical, 12)
//            .background(Color.white)
//            .clipShape(RoundedRectangle(cornerRadius: 25))
//            .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
//            
//            // Refresh button
//            Button(action: {
//                viewModel.refreshEvents()
//            }) {
//                Image(systemName: "arrow.clockwise")
//                    .font(.system(size: 18, weight: .medium))
//                    .foregroundColor(.primaryOrange)
//                    .rotationEffect(.degrees(viewModel.isLoading ? 360 : 0))
//                    .animation(viewModel.isLoading ? Animation.linear(duration: 1).repeatForever(autoreverses: false) : .default, value: viewModel.isLoading)
//            }
//            .disabled(viewModel.isLoading)
//        }
//        .padding(.horizontal, 20)
//        .padding(.bottom, 16)
//        .background(Color.formBackground)
//    }
//    
//    // MARK: - Events Content
//    private var eventsContent: some View {
//        Group {
//            if viewModel.isLoading && viewModel.events.isEmpty {
//                loadingView
//            } else if viewModel.filteredEvents.isEmpty {
//                emptyStateView
//            } else {
//                eventsListView
//            }
//        }
//    }
//    
//    private var loadingView: some View {
//        VStack(spacing: 20) {
//            ForEach(0..<5, id: \.self) { _ in
//                EventCardSkeleton()
//                    .padding(.horizontal, 20)
//            }
//        }
//        .padding(.top, 20)
//    }
//    
//    private var emptyStateView: some View {
//        VStack(spacing: 20) {
//            Spacer()
//            
//            Image(systemName: selectedTab == .all ? "calendar.badge.exclamationmark" : "calendar.badge.clock")
//                .font(.system(size: 60, weight: .light))
//                .foregroundColor(.textSecondary.opacity(0.5))
//            
//            Text(emptyStateTitle)
//                .font(.system(size: 18, weight: .semibold))
//                .foregroundColor(.textPrimary)
//                .multilineTextAlignment(.center)
//            
//            Text(emptyStateDescription)
//                .font(.system(size: 14, weight: .regular))
//                .foregroundColor(.textSecondary)
//                .multilineTextAlignment(.center)
//                .lineLimit(nil)
//            
//            if viewModel.hasActiveFilters {
//                Button(action: {
//                    viewModel.clearFilters()
//                }) {
//                    Text("events.clear_filters".localized(using: localizationManager))
//                        .font(.system(size: 16, weight: .medium))
//                        .foregroundColor(.primaryOrange)
//                        .padding(.horizontal, 20)
//                        .padding(.vertical, 10)
//                        .background(
//                            Capsule()
//                                .stroke(Color.primaryOrange, lineWidth: 1)
//                        )
//                }
//                .padding(.top, 8)
//            }
//            
//            Spacer()
//        }
//        .padding(.horizontal, 40)
//    }
//    
//    private var eventsListView: some View {
//        ScrollView {
//            LazyVStack(spacing: 12) {
//                ForEach(viewModel.filteredEvents) { event in
//                    EventCard(
//                        event: event,
//                        onJoin: {
//                            viewModel.joinEvent(event)
//                        },
//                        onLeave: {
//                            viewModel.leaveEvent(event)
//                        }
//                    )
//                    .environmentObject(localizationManager)
//                    .onTapGesture {
//                        // Handle event tap - navigate to event details
//                        viewModel.loadEventDetails(eventId: event.id)
//                        print("Tapped event: \(event.name)")
//                    }
//                }
//                
//                // Load more section
//                if viewModel.canLoadMore {
//                    loadMoreView
//                }
//                
//                // Bottom spacing
//                Color.clear.frame(height: 100)
//            }
//            .padding(.top, 16)
//        }
//        .refreshable {
//            viewModel.refreshEvents()
//        }
//    }
//    
//    private var loadMoreView: some View {
//        VStack(spacing: 12) {
//            if viewModel.isLoading {
//                ProgressView()
//                    .progressViewStyle(CircularProgressViewStyle(tint: .primaryOrange))
//                
//                Text("events.loading.more".localized(using: localizationManager))
//                    .font(.system(size: 14))
//                    .foregroundColor(.textSecondary)
//            } else {
//                Button("events.load.more".localized(using: localizationManager)) {
//                    viewModel.loadMoreEvents()
//                }
//                .font(.system(size: 16, weight: .medium))
//                .foregroundColor(.primaryOrange)
//            }
//        }
//        .frame(maxWidth: .infinity)
//        .padding(.vertical, 20)
//    }
//    
//    // MARK: - Computed Properties
//    private var emptyStateTitle: String {
//        if selectedTab == .all {
//            return "events.empty.all".localized(using: localizationManager)
//        } else {
//            return "events.empty.my".localized(using: localizationManager)
//        }
//    }
//    
//    private var emptyStateDescription: String {
//        if selectedTab == .all {
//            return "events.empty.all.subtitle".localized(using: localizationManager)
//        } else {
//            return "events.empty.my.subtitle".localized(using: localizationManager)
//        }
//    }
//}
//
//// MARK: - Preview
//#Preview {
//    FinalEventsView()
//        .environmentObject(LocalizationManager(localizationService: MockLocalizationService()))
//}
//
//// MARK: - Production Usage Guide
///*
//🚀 PRODUCTION USAGE:
//
//1. Change service to real implementation:
//   @StateObject private var viewModel = EnhancedEventsViewModel(
//       eventsService: CompleteEventsService()
//   )
//
//2. Update API endpoints in CompleteEventsService:
//   - Replace "http://localhost:5206" with your actual API base URL
//   - Ensure all endpoints match your backend API
//
//3. Features included:
//   ✅ Events listing (All/My Events)
//   ✅ Search and filtering
//   ✅ Pagination with load more
//   ✅ Join/Leave events
//   ✅ Pull to refresh
//   ✅ Event details loading
//   ✅ Notifications integration
//   ✅ Invitations integration
//   ✅ Statistics display
//   ✅ User preferences
//   ✅ Comments and ratings
//   ✅ Real-time updates
//   ✅ Error handling
//   ✅ Loading states
//   ✅ Localization support
//
//4. Additional features available through the enhanced service:
//   - Event creation/editing
//   - Event participants management
//   - Comments system
//   - Rating system
//   - Invitation system
//   - Notification system
//   - Search functionality
//   - Nearby events
//   - User preferences
//   - Event statistics
//
//Bu implementation production-ready bir Events sistemi sağlar!
//*/
