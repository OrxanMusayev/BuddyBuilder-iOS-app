// BuddyBuilder/Features/Events/ViewModels/EventsViewModel.swift - PAGINATION FIX

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
    
    // Pagination - FIXED
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
        // 🔴 REMOVED: setupFilterObservers içindeki $selectedTab observer'ı kaldırdık
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
        // 🔴 REMOVED: $selectedTab observer - bu conflict yaratıyordu
        // Sadece filter değişikliklerini dinle
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
    
    // 🔴 FIXED: changeTab metodu - sadece manuel çağrıldığında çalışır
    func changeTab(to newTab: EventTab) {
        print("🔄 EventsViewModel.changeTab called: \(selectedTab.rawValue) → \(newTab.rawValue)")
        
        // Only change if different
        guard selectedTab != newTab else {
            print("⚠️ Tab is the same, skipping change")
            return
        }
        
        // Update selected tab
        selectedTab = newTab
        print("✅ selectedTab updated to: \(selectedTab.rawValue)")
        
        // Reset and load
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
        
        // PAGINATION DEBUG - UPDATED
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
                    self?.handleEventsResponse(response, resetPagination: resetPagination)
                }
            )
            .store(in: &cancellables)
    }
    
    // MARK: - FIXED: Load More Events with Proper Debug
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
    
    func joinEvent(_ event: Event) {
        guard !isLoading else { return }
        
        isLoading = true
        eventsService.joinEventWithAutoRefresh(eventId: event.id)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    self?.isLoading = false
                    switch completion {
                    case .failure(let error):
                        self?.handleError(error)
                    case .finished:
                        break
                    }
                },
                receiveValue: { [weak self] success in
                    if success {
                        self?.updateEventParticipation(eventId: event.id, isParticipant: true)
                    }
                }
            )
            .store(in: &cancellables)
    }
    
    func leaveEvent(_ event: Event) {
        guard !isLoading else { return }
        
        isLoading = true
        eventsService.leaveEventWithAutoRefresh(eventId: event.id)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    self?.isLoading = false
                    switch completion {
                    case .failure(let error):
                        self?.handleError(error)
                    case .finished:
                        break
                    }
                },
                receiveValue: { [weak self] success in
                    if success {
                        self?.updateEventParticipation(eventId: event.id, isParticipant: false)
                    }
                }
            )
            .store(in: &cancellables)
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
    
    // MARK: - FIXED: Handle Events Response with Detailed Debug
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
        
        if resetPagination {
            events = response.events
            print("   ✅ Events RESET to \(events.count) items")
        } else {
            let oldCount = events.count
            events.append(contentsOf: response.events)
            print("   ✅ Events APPENDED: \(oldCount) + \(response.events.count) = \(events.count)")
        }
        
        // PAGINATION FIX: API response değerlerini kullan
        currentPage = response.page
        totalPages = response.totalPages
        canLoadMore = currentPage < totalPages
        
        print("📥 Final UI State (AFTER):")
        print("   - Final events in UI: \(events.count)")
        print("   - Final current page: \(currentPage)")
        print("   - Final total pages: \(totalPages)")
        print("   - Final can load more: \(canLoadMore)")
        
        // PAGINATION LOGIC CHECK
        if canLoadMore {
            print("✅ PAGINATION: Load More will be SHOWN (page \(currentPage) of \(totalPages))")
        } else {
            print("❌ PAGINATION: Load More will be HIDDEN (all pages loaded)")
        }
        
        print("📥 ===============================================")
    }
    
    private func updateEventParticipation(eventId: Int, isParticipant: Bool) {
        if let index = events.firstIndex(where: { $0.id == eventId }) {
            // In a real implementation, you'd create a new Event struct with updated values
            // For now, we'll just reload the events to get the updated state
            loadEvents()
        }
    }
    
    private func handleError(_ error: Error) {
        errorMessage = error.localizedDescription
        showError = true
        print("❌ Events Error: \(error.localizedDescription)")
    }
}
