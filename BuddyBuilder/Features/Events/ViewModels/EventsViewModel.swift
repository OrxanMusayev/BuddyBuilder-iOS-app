// BuddyBuilder/Features/Events/ViewModels/EventsViewModel.swift - FIXED INITIAL STATE VERSION

import Foundation
import Combine
import SwiftUI

protocol EventsFilterProtocol: ObservableObject {
    // Filter properties
    var selectedEventType: EventType? { get set }
    var selectedSportId: Int? { get set }
    var selectedLocation: String { get set }
    var maxEntryFee: String { get set }
    var showUpcomingOnly: Bool { get set }
    var showAvailableOnly: Bool { get set }
    var showOpenRegistrationOnly: Bool { get set }
    
    // Computed properties
    var hasActiveFilters: Bool { get }
    
    // Methods
    func applyFilters()
    func clearFilters()
}

class EventsViewModel: EventsFilterProtocol {
    // MARK: - Published Properties
    @Published var events: [Event] = []
    @Published var isLoading = false
    @Published var errorMessage: String = ""
    @Published var showError = false
    @Published var selectedTab: EventTab = .all
    @Published var searchText: String = ""
    @Published var showFilters = false
    
    // Filter properties
    @Published var currentFilter = EventFilter()
    @Published var selectedEventType: EventType?
    @Published var selectedSportId: Int?
    @Published var selectedLocation: String = ""
    @Published var maxEntryFee: String = ""
    @Published var showUpcomingOnly: Bool = false
    @Published var showAvailableOnly: Bool = false
    @Published var showOpenRegistrationOnly: Bool = false
    
    // Pagination
    @Published var currentPage = 1
    @Published var totalPages = 1
    @Published var canLoadMore = false
    
    // MARK: - Private Properties
    private let eventsService: EventsServiceProtocol
    private var cancellables = Set<AnyCancellable>()
    private let debounceInterval: TimeInterval = 0.5
    
    // MARK: - Computed Properties
    var filteredEvents: [Event] {
        var filtered = events
        
        // Apply search filter
        if !searchText.isEmpty {
            filtered = filtered.filter { event in
                event.name.localizedCaseInsensitiveContains(searchText) ||
                event.description.localizedCaseInsensitiveContains(searchText) ||
                event.location.localizedCaseInsensitiveContains(searchText) ||
                event.sport.name.localizedCaseInsensitiveContains(searchText)
            }
        }
        
        return filtered
    }
    
    var hasActiveFilters: Bool {
        selectedEventType != nil ||
        selectedSportId != nil ||
        !selectedLocation.isEmpty ||
        !maxEntryFee.isEmpty ||
        showUpcomingOnly ||
        showAvailableOnly ||
        showOpenRegistrationOnly
    }
    
    // MARK: - Initialization
    init(eventsService: EventsServiceProtocol = CompleteEventsService()) {
        self.eventsService = eventsService
        setupSearchDebounce()
        setupFilterObservers()
    }
    
    // MARK: - Setup Methods
    private func setupSearchDebounce() {
        $searchText
            .debounce(for: .seconds(debounceInterval), scheduler: RunLoop.main)
            .sink { [weak self] searchTerm in
                self?.updateSearchFilter(searchTerm)
            }
            .store(in: &cancellables)
    }
    
    private func setupFilterObservers() {
        Publishers.CombineLatest4(
            $selectedEventType,
            $selectedSportId,
            $showUpcomingOnly,
            $showAvailableOnly
        )
        .debounce(for: .seconds(0.3), scheduler: RunLoop.main)
        .sink { [weak self] _, _, _, _ in
            self?.applyFilters()
        }
        .store(in: &cancellables)
    }
    
    // MARK: - Tab Management
    func changeTab(to newTab: EventTab) {
        print("🔄 EventsViewModel.changeTab called: \(selectedTab.rawValue) → \(newTab.rawValue)")
        
        guard selectedTab != newTab else {
            print("⚠️ Tab is the same, skipping change")
            return
        }
        
        selectedTab = newTab
        print("✅ selectedTab updated to: \(selectedTab.rawValue)")
        
        resetPagination()
        loadEvents()
    }
    
    // MARK: - Public Methods
    func loadEvents(resetPagination: Bool = true) {
        if resetPagination {
            self.resetPagination()
        }
        
        guard !isLoading else {
            print("⚠️ Already loading, skipping request")
            return
        }
        
        isLoading = true
        errorMessage = ""
        
        updateCurrentFilter()
        
        print("🌐 Loading events for tab: \(selectedTab.rawValue)")
        print("   Page: \(currentFilter.page)")
        print("   PageSize: \(currentFilter.pageSize)")
        print("   Reset pagination: \(resetPagination)")
        
        let publisher: AnyPublisher<EventsResponse, Error>
        
        switch selectedTab {
        case .all:
            print("📡 Calling fetchEventsWithAutoRefresh for ALL events")
            publisher = eventsService.fetchEventsWithAutoRefresh(filter: currentFilter)
        case .my:
            print("📡 Calling fetchMyEventsWithAutoRefresh for MY events")
            publisher = eventsService.fetchMyEventsWithAutoRefresh(filter: currentFilter)
        }
        
        publisher
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    self?.isLoading = false
                    switch completion {
                    case .failure(let error):
                        print("❌ Events loading failed: \(error)")
                        self?.handleError(error)
                    case .finished:
                        print("✅ Events loading completed")
                        break
                    }
                },
                receiveValue: { [weak self] response in
                    print("📥 Received \(response.events.count) events for tab: \(self?.selectedTab.rawValue ?? "unknown")")
                    
                    // FIXED: Log detailed event state information
                    for (index, event) in response.events.enumerated() {
                        print("📋 Event \(index + 1): \(event.name)")
                        print("   ID: \(event.id)")
                        print("   isParticipant: \(event.isParticipant)")
                        print("   canJoin: \(event.canJoin)")
                        print("   currentParticipants: \(event.currentParticipants)")
                        print("   maxParticipants: \(event.maxParticipants)")
                        
                        // FIXED: Validate data consistency
                        if event.isParticipant && event.canJoin {
                            print("⚠️ WARNING: Event \(event.id) has inconsistent state - both isParticipant and canJoin are true")
                        }
                    }
                    
                    self?.handleEventsResponse(response, resetPagination: resetPagination)
                }
            )
            .store(in: &cancellables)
    }
    
    // MARK: - Load More Events
    func loadMoreEvents() {
        guard canLoadMore && !isLoading else {
            print("❌ Cannot load more:")
            print("   canLoadMore: \(canLoadMore)")
            print("   isLoading: \(isLoading)")
            print("   currentPage: \(currentPage)")
            print("   totalPages: \(totalPages)")
            return
        }
        
        print("📄 Loading more events...")
        print("   Current page: \(currentPage)")
        print("   Total pages: \(totalPages)")
        print("   Current events count: \(events.count)")
        print("   Filter page before increment: \(currentFilter.page)")
        
        currentFilter.page = currentPage + 1
        print("   Filter page after increment: \(currentFilter.page)")
        
        loadEvents(resetPagination: false)
    }
    
    func refreshEvents() {
        print("🔄 Refresh events for current tab: \(selectedTab.rawValue)")
        resetPagination()
        loadEvents()
    }
    
    // MARK: - FIXED: Join/Leave Events with Better State Validation
    func joinEvent(_ event: Event) {
        guard !isLoading else {
            print("⚠️ ViewModel: Already loading, skipping join request")
            return
        }
        
        // FIXED: Pre-validate state
        print("🚀 ViewModel: Starting joinEvent for \(event.id)")
        print("   Current event.isParticipant: \(event.isParticipant)")
        print("   Current event.canJoin: \(event.canJoin)")
        
        if event.isParticipant {
            print("⚠️ WARNING: Trying to join event where user is already participant")
        }
        
        if !event.canJoin {
            print("⚠️ WARNING: Trying to join event where canJoin is false")
        }
        
        isLoading = true
        
        eventsService.joinEventWithAutoRefresh(eventId: event.id)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    print("📋 ViewModel: Join completion received")
                    self?.isLoading = false
                    
                    switch completion {
                    case .failure(let error):
                        print("❌ ViewModel: Join failed: \(error.localizedDescription)")
                        self?.handleError(error)
                    case .finished:
                        break
                    }
                },
                receiveValue: { [weak self] success in
                    print("📥 ViewModel: Join response - Success: \(success)")
                    
                    if success {
                        print("✅ ViewModel: Join successful, performing optimistic update...")
                        self?.performOptimisticUpdate(eventId: event.id, joined: true)
                        
                        // Schedule data refresh to sync with server
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                            print("🔄 ViewModel: Performing sync refresh after join")
                            self?.loadEvents(resetPagination: false)
                        }
                    } else {
                        print("❌ ViewModel: Join failed")
                    }
                }
            )
            .store(in: &cancellables)
    }
    
    func leaveEvent(_ event: Event) {
        guard !isLoading else {
            print("⚠️ ViewModel: Already loading, skipping leave request")
            return
        }
        
        // FIXED: Pre-validate state
        print("🚀 ViewModel: Starting leaveEvent for \(event.id)")
        print("   Current event.isParticipant: \(event.isParticipant)")
        print("   Current event.canJoin: \(event.canJoin)")
        
        if !event.isParticipant {
            print("⚠️ WARNING: Trying to leave event where user is not participant")
        }
        
        isLoading = true
        
        eventsService.leaveEventWithAutoRefresh(eventId: event.id)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    print("📋 ViewModel: Leave completion received")
                    self?.isLoading = false
                    
                    switch completion {
                    case .failure(let error):
                        print("❌ ViewModel: Leave failed: \(error.localizedDescription)")
                        self?.handleError(error)
                    case .finished:
                        break
                    }
                },
                receiveValue: { [weak self] success in
                    print("📥 ViewModel: Leave response - Success: \(success)")
                    
                    if success {
                        print("✅ ViewModel: Leave successful, performing optimistic update...")
                        self?.performOptimisticUpdate(eventId: event.id, joined: false)
                        
                        // Schedule data refresh to sync with server
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                            print("🔄 ViewModel: Performing sync refresh after leave")
                            self?.loadEvents(resetPagination: false)
                        }
                    } else {
                        print("❌ ViewModel: Leave failed")
                    }
                }
            )
            .store(in: &cancellables)
    }
    
    // MARK: - FIXED: Optimistic Update with Better State Management
    private func performOptimisticUpdate(eventId: Int, joined: Bool) {
        guard let index = events.firstIndex(where: { $0.id == eventId }) else {
            print("⚠️ ViewModel: Event \(eventId) not found for optimistic update")
            return
        }
        
        print("🔄 ViewModel: Performing optimistic update for event \(eventId)")
        
        let currentEvent = events[index]
        print("   Before update:")
        print("      isParticipant: \(currentEvent.isParticipant)")
        print("      canJoin: \(currentEvent.canJoin)")
        print("      currentParticipants: \(currentEvent.currentParticipants)")
        
        // Calculate new participant count
        let newCurrentParticipants = joined ?
            currentEvent.currentParticipants + 1 :
            max(0, currentEvent.currentParticipants - 1)
        
        // Create updated event with proper state
        let updatedEvent = currentEvent.withUpdatedParticipation(
            isParticipant: joined,
            currentParticipants: newCurrentParticipants
        )
        
        print("   After update:")
        print("      isParticipant: \(updatedEvent.isParticipant)")
        print("      canJoin: \(updatedEvent.canJoin)")
        print("      currentParticipants: \(updatedEvent.currentParticipants)")
        
        // Update the event in the array
        events[index] = updatedEvent
        
        print("   ✅ Optimistic update completed")
        
        // Force UI update
        DispatchQueue.main.async { [weak self] in
            self?.objectWillChange.send()
        }
    }
    
    func applyFilters() {
        updateCurrentFilter()
        resetPagination()
        loadEvents()
    }
    
    func clearFilters() {
        selectedEventType = nil
        selectedSportId = nil
        selectedLocation = ""
        maxEntryFee = ""
        showUpcomingOnly = false
        showAvailableOnly = false
        showOpenRegistrationOnly = false
        searchText = ""
        
        applyFilters()
    }
    
    // MARK: - Private Methods
    private func resetPagination() {
        print("🔄 Resetting pagination...")
        currentPage = 1
        currentFilter.page = 1
        canLoadMore = false
        print("   Reset to: page=1, canLoadMore=false")
    }
    
    private func updateSearchFilter(_ searchTerm: String) {
        currentFilter.searchTerm = searchTerm.isEmpty ? nil : searchTerm
        applyFilters()
    }
    
    private func updateCurrentFilter() {
        currentFilter.eventType = selectedEventType
        currentFilter.sportId = selectedSportId
        currentFilter.location = selectedLocation.isEmpty ? nil : selectedLocation
        currentFilter.isUpcoming = showUpcomingOnly ? true : nil
        currentFilter.hasAvailableSpots = showAvailableOnly ? true : nil
        currentFilter.isRegistrationOpen = showOpenRegistrationOnly ? true : nil
        
        if let maxFeeText = Double(maxEntryFee), !maxEntryFee.isEmpty {
            currentFilter.maxEntryFee = maxFeeText
        } else {
            currentFilter.maxEntryFee = nil
        }
    }
    
    // MARK: - FIXED: Handle Events Response with State Validation
    private func handleEventsResponse(_ response: EventsResponse, resetPagination: Bool) {
        print("📥 ========== HANDLING EVENTS RESPONSE ==========")
        print("📥 API Response Details:")
        print("   - Response page: \(response.page)")
        print("   - Response total pages: \(response.totalPages)")
        print("   - Response events count: \(response.events.count)")
        print("   - Response total count: \(response.totalCount)")
        print("   - Reset pagination: \(resetPagination)")
        
        print("📥 Current UI State (BEFORE):")
        print("   - Current events in UI: \(events.count)")
        print("   - Current page: \(currentPage)")
        print("   - Total pages: \(totalPages)")
        print("   - Can load more: \(canLoadMore)")
        
        // FIXED: Store events with validation
        let validatedEvents = response.events.map { event in
            validateEventState(event)
        }
        
        if resetPagination {
            events = validatedEvents
            print("   ✅ Events RESET to \(events.count) items")
        } else {
            let oldCount = events.count
            events.append(contentsOf: validatedEvents)
            print("   ✅ Events APPENDED: \(oldCount) + \(validatedEvents.count) = \(events.count)")
        }
        
        // Update pagination info
        currentPage = response.page
        totalPages = response.totalPages
        canLoadMore = currentPage < totalPages
        
        print("📥 Final UI State (AFTER):")
        print("   - Final events in UI: \(events.count)")
        print("   - Final current page: \(currentPage)")
        print("   - Final total pages: \(totalPages)")
        print("   - Final can load more: \(canLoadMore)")
        
        if canLoadMore {
            print("✅ PAGINATION: Load More will be SHOWN (page \(currentPage) of \(totalPages))")
        } else {
            print("❌ PAGINATION: Load More will be HIDDEN (all pages loaded)")
        }
        
        print("📥 ===============================================")
        
        // FIXED: Force UI update after state validation
        DispatchQueue.main.async { [weak self] in
            self?.objectWillChange.send()
        }
    }
    
    // MARK: - FIXED: Event State Validation
    private func validateEventState(_ event: Event) -> Event {
        print("🔍 Validating event state for: \(event.name) (ID: \(event.id))")
        print("   Original state: isParticipant=\(event.isParticipant), canJoin=\(event.canJoin)")
        
        // FIXED: Log potential issues
        if event.isParticipant && event.canJoin {
            print("⚠️ INCONSISTENT STATE: Event \(event.id) has both isParticipant=true and canJoin=true")
            print("   This should not happen - user cannot join an event they're already in")
        }
        
        if !event.isParticipant && !event.canJoin && event.currentParticipants < event.maxParticipants {
            print("⚠️ POTENTIAL ISSUE: Event \(event.id) has available spots but canJoin=false")
            print("   currentParticipants: \(event.currentParticipants), maxParticipants: \(event.maxParticipants)")
        }
        
        // Return the event as-is for now (server should provide correct state)
        print("   Final state: isParticipant=\(event.isParticipant), canJoin=\(event.canJoin)")
        return event
    }
    
    private func handleError(_ error: Error) {
        errorMessage = error.localizedDescription
        showError = true
        print("❌ Events Error: \(error.localizedDescription)")
    }
}
