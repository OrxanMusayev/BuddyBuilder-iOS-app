// BuddyBuilder/Features/Events/ViewModels/CachedEventsViewModel.swift - PAGINATION FIX

import Foundation
import Combine
import SwiftUI

// MARK: - Loading State for UI
enum UILoadingState {
    case idle
    case showingSkeleton        // İlk yükleme veya cache boş
    case showingCached         // Cache'den veri gösteriliyor
    case refreshingBackground  // Arka planda güncelleme
    case refreshingManual     // Manuel refresh
    case error(String)
    
    var isLoading: Bool {
        switch self {
        case .showingSkeleton, .refreshingManual:
            return true
        default:
            return false
        }
    }
    
    var showSkeleton: Bool {
        if case .showingSkeleton = self {
            return true
        }
        return false
    }
    
    var showBackgroundRefresh: Bool {
        if case .refreshingBackground = self {
            return true
        }
        return false
    }
}

// MARK: - Cached Events ViewModel
class CachedEventsViewModel: EventsFilterProtocol {
    
    // MARK: - Published Properties
    @Published var events: [Event] = []
    @Published var uiLoadingState: UILoadingState = .idle
    @Published var selectedTab: EventTab = .all
    @Published var searchText: String = ""
    @Published var showFilters = false
    @Published var showError = false
    @Published var errorMessage = ""
    
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
    
    // Background refresh indicator
    @Published var hasNewDataAvailable = false
    @Published var backgroundRefreshProgress: Double = 0.0
    
    // MARK: - Private Properties
    private let eventsService: EnhancedEventsServiceProtocol
    private let cacheService: EventsCacheServiceProtocol
    private var cancellables = Set<AnyCancellable>()
    private let debounceInterval: TimeInterval = 0.5
    
    // MARK: - Computed Properties
    var filteredEvents: [Event] {
        var filtered = events
        
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
    
    private var currentCacheType: EventsCacheEntry.EventsCacheType {
        selectedTab == .all ? .allEvents : .myEvents
    }
    
    // MARK: - Initialization
    init(eventsService: EnhancedEventsServiceProtocol? = nil) {
        // Production'da gerçek servis, test'de mock servis kullan
        if let providedService = eventsService {
            self.eventsService = providedService
        } else {
            self.eventsService = EnhancedEventsService()
        }
        
        self.cacheService = EventsCacheService.shared
        
        setupObservers()
        setupSearchDebounce()
        setupFilterObservers()
        setupBackgroundRefreshNotifications()
    }
    
    // MARK: - Setup Methods
    private func setupObservers() {
        // Service load state'i dinle
        eventsService.loadState
            .receive(on: DispatchQueue.main)
            .sink { [weak self] loadState in
                self?.handleLoadStateChange(loadState)
            }
            .store(in: &cancellables)
        
        // Tab değişikliklerini dinle
        $selectedTab
            .sink { [weak self] newTab in
                print("📊 CachedEventsViewModel: selectedTab changed to \(newTab.rawValue)")
                self?.handleTabChange()
            }
            .store(in: &cancellables)
    }
    
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
    
    private func setupBackgroundRefreshNotifications() {
        NotificationCenter.default.publisher(for: .eventsDataRefreshed)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] notification in
                if let cacheType = notification.object as? EventsCacheEntry.EventsCacheType,
                   cacheType == self?.currentCacheType {
                    self?.handleNewDataAvailable()
                }
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Load State Handling
    private func handleLoadStateChange(_ loadState: EventsLoadState) {
        switch loadState {
        case .idle:
            uiLoadingState = .idle
            
        case .loadingFromCache:
            uiLoadingState = .showingCached
            
        case .loadingFromAPI:
            if events.isEmpty {
                uiLoadingState = .showingSkeleton
            }
            
        case .refreshingInBackground:
            uiLoadingState = .refreshingBackground
            startBackgroundRefreshAnimation()
            
        case .refreshingManual:
            uiLoadingState = .refreshingManual
            
        case .error(let error):
            handleError(error)
            
        case .loaded(let fromCache):
            if fromCache {
                uiLoadingState = .showingCached
            } else {
                uiLoadingState = .idle
            }
            hasNewDataAvailable = false
            backgroundRefreshProgress = 0.0
        }
    }
    
    private func handleTabChange() {
        resetPagination()
        loadEvents(strategy: .cacheFirst)
    }
    
    private func handleNewDataAvailable() {
        hasNewDataAvailable = true
        
        // Auto-update after 3 seconds if user doesn't manually refresh
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) { [weak self] in
            if self?.hasNewDataAvailable == true {
                self?.loadEventsFromCache()
            }
        }
    }
    
    // 🔴 FIXED: changeTab method with debug logging
    func changeTab(to newTab: EventTab) {
        print("🔄 CachedEventsViewModel.changeTab called with: \(newTab.rawValue)")
        print("📊 Current selectedTab: \(selectedTab.rawValue)")
        
        // Only change if different
        guard selectedTab != newTab else {
            print("⚠️ Tab is the same, skipping change")
            return
        }
        
        // Update selected tab
        selectedTab = newTab
        print("✅ selectedTab updated to: \(selectedTab.rawValue)")
        
        // handleTabChange will be called automatically via $selectedTab observer
    }
    
    // MARK: - Public Methods
    func loadEvents(strategy: CacheStrategy = .cacheFirst, resetPagination: Bool = true) {
        if resetPagination {
            self.resetPagination()
        }
        
        updateCurrentFilter()
        
        print("🌐 Loading cached events for tab: \(selectedTab.rawValue) with strategy: \(strategy)")
        print("   Page: \(currentFilter.page)")
        print("   PageSize: \(currentFilter.pageSize)")
        print("   Reset pagination: \(resetPagination)")
        
        eventsService.fetchEventsWithCache(
            filter: currentFilter,
            type: currentCacheType,
            strategy: strategy
        )
        .receive(on: DispatchQueue.main)
        .sink(
            receiveCompletion: { [weak self] completion in
                if case .failure(let error) = completion {
                    print("❌ Cached events loading failed: \(error)")
                    self?.handleError(error)
                }
            },
            receiveValue: { [weak self] (response, fromCache) in
                print("📥 Received \(response.events.count) cached events for tab: \(self?.selectedTab.rawValue ?? "unknown")")
                self?.handleEventsResponse(response, resetPagination: resetPagination)
                
                if fromCache {
                    print("📱 Loaded \(response.events.count) events from cache")
                } else {
                    print("🌐 Loaded \(response.events.count) events from API")
                }
            }
        )
        .store(in: &cancellables)
    }
    
    func refreshEventsManually() {
        hasNewDataAvailable = false
        
        eventsService.refreshEventsManually(
            filter: currentFilter,
            type: currentCacheType
        )
        .receive(on: DispatchQueue.main)
        .sink(
            receiveCompletion: { [weak self] completion in
                if case .failure(let error) = completion {
                    self?.handleError(error)
                }
            },
            receiveValue: { [weak self] response in
                self?.handleEventsResponse(response, resetPagination: true)
                print("🔄 Manual refresh completed - \(response.events.count) events")
            }
        )
        .store(in: &cancellables)
    }
    
    func loadEventsFromCache() {
        loadEvents(strategy: .cacheOnly)
        hasNewDataAvailable = false
    }
    
    func joinEvent(_ event: Event) {
        guard case .idle = uiLoadingState else { return }
        
        eventsService.joinEventWithAutoRefresh(eventId: event.id)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    if case .failure(let error) = completion {
                        self?.handleError(error)
                    }
                },
                receiveValue: { [weak self] success in
                    if success {
                        self?.updateEventParticipation(eventId: event.id, isParticipant: true)
                        // Cache'i güncelle
                        self?.invalidateCache()
                    }
                }
            )
            .store(in: &cancellables)
    }
    
    func leaveEvent(_ event: Event) {
        guard case .idle = uiLoadingState else { return }
        
        eventsService.leaveEventWithAutoRefresh(eventId: event.id)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    if case .failure(let error) = completion {
                        self?.handleError(error)
                    }
                },
                receiveValue: { [weak self] success in
                    if success {
                        self?.updateEventParticipation(eventId: event.id, isParticipant: false)
                        // Cache'i güncelle
                        self?.invalidateCache()
                    }
                }
            )
            .store(in: &cancellables)
    }
    
    // MARK: - FIXED: Load More Events with Proper Debug
    func loadMoreEvents() {
        guard canLoadMore,
              case .idle = uiLoadingState else {
            print("❌ Cannot load more:")
            print("   canLoadMore: \(canLoadMore)")
            print("   uiLoadingState: \(uiLoadingState)")
            print("   currentPage: \(currentPage)")
            print("   totalPages: \(totalPages)")
            return
        }
        
        print("📄 Loading more cached events...")
        print("   Current page: \(currentPage)")
        print("   Total pages: \(totalPages)")
        print("   Current events count: \(events.count)")
        print("   Filter page before increment: \(currentFilter.page)")
        
        currentFilter.page = currentPage + 1
        print("   Filter page after increment: \(currentFilter.page)")
        
        loadEvents(strategy: .apiFirst, resetPagination: false)
    }
    
    func applyFilters() {
        updateCurrentFilter()
        resetPagination()
        loadEvents(strategy: .apiFirst) // Filtre değişikliklerinde API'yi zorla
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
    
    // MARK: - Cache Management
    func invalidateCache() {
        cacheService.clearCacheForType(currentCacheType)
    }
    
    func clearAllCache() {
        cacheService.clearCache()
    }
    
    func getCacheInfo() -> String {
        if let age = cacheService.getCacheAge(for: currentCacheType) {
            let minutes = Int(age / 60)
            return "Cache: \(minutes) min old"
        } else {
            return "Cache: Empty"
        }
    }
    
    // MARK: - Private Methods
    private func resetPagination() {
        print("🔄 Resetting cached pagination...")
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
        print("📥 ========== HANDLING CACHED EVENTS RESPONSE ==========")
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
        // Event listesini güncelle ve yeni veri çek
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            self?.loadEvents(strategy: .apiFirst)
        }
    }
    
    private func handleError(_ error: Error) {
        errorMessage = error.localizedDescription
        showError = true
        uiLoadingState = .error(error.localizedDescription)
        print("❌ Cached Events Error: \(error.localizedDescription)")
    }
    
    private func startBackgroundRefreshAnimation() {
        backgroundRefreshProgress = 0.0
        
        Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] timer in
            guard let self = self else {
                timer.invalidate()
                return
            }
            
            if case .refreshingBackground = self.uiLoadingState {
                self.backgroundRefreshProgress += 0.05
                if self.backgroundRefreshProgress >= 1.0 {
                    timer.invalidate()
                }
            } else {
                timer.invalidate()
            }
        }
    }
}
