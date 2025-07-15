//// BuddyBuilder/Features/Events/ViewModels/EnhancedEventsViewModel.swift
//
//import Foundation
//import Combine
//import SwiftUI
//
//class EnhancedEventsViewModel: ObservableObject {
//    // MARK: - Published Properties
//    @Published var events: [Event] = []
//    @Published var isLoading = false
//    @Published var errorMessage: String = ""
//    @Published var showError = false
//    @Published var selectedTab: EventTab = .all
//    @Published var searchText: String = ""
//    @Published var showFilters = false
//    
//    // Filter properties
//    @Published var currentFilter = EventFilter()
//    @Published var selectedEventType: EventType?
//    @Published var selectedSportId: Int?
//    @Published var selectedLocation: String = ""
//    @Published var maxEntryFee: String = ""
//    @Published var showUpcomingOnly: Bool = false
//    @Published var showAvailableOnly: Bool = false
//    @Published var showOpenRegistrationOnly: Bool = false
//    
//    // Pagination
//    @Published var currentPage = 1
//    @Published var totalPages = 1
//    @Published var canLoadMore = false
//    
//    // Additional properties for complete functionality
//    @Published var availableSports: [Sport] = []
//    @Published var eventCategories: [EventCategory] = []
//    @Published var eventLocations: [EventLocation] = []
//    @Published var userNotifications: [EventNotification] = []
//    @Published var userInvitations: [EventInvitation] = []
//    @Published var eventStatistics: EventStatistics?
//    @Published var userPreferences: UserEventPreferences?
//    
//    // Event details
//    @Published var selectedEvent: Event?
//    @Published var eventComments: [EventComment] = []
//    @Published var eventRatings: [EventRating] = []
//    @Published var eventParticipants: [EventParticipant] = []
//    
//    // MARK: - Private Properties
//    private let eventsService: CompleteEventsServiceProtocol
//    private var cancellables = Set<AnyCancellable>()
//    private let debounceInterval: TimeInterval = 0.5
//    
//    // MARK: - Computed Properties
//    var filteredEvents: [Event] {
//        var filtered = events
//        
//        // Apply search filter
//        if !searchText.isEmpty {
//            filtered = filtered.filter { event in
//                event.name.localizedCaseInsensitiveContains(searchText) ||
//                event.description.localizedCaseInsensitiveContains(searchText) ||
//                event.location.localizedCaseInsensitiveContains(searchText) ||
//                event.sport.name.localizedCaseInsensitiveContains(searchText)
//            }
//        }
//        
//        return filtered
//    }
//    
//    var hasActiveFilters: Bool {
//        selectedEventType != nil ||
//        selectedSportId != nil ||
//        !selectedLocation.isEmpty ||
//        !maxEntryFee.isEmpty ||
//        showUpcomingOnly ||
//        showAvailableOnly ||
//        showOpenRegistrationOnly
//    }
//    
//    var unreadNotificationsCount: Int {
//        userNotifications.filter { !$0.isRead }.count
//    }
//    
//    var pendingInvitationsCount: Int {
//        userInvitations.filter { $0.status == .pending }.count
//    }
//    
//    // MARK: - Initialization
//    init(eventsService: CompleteEventsServiceProtocol = MockCompleteEventsService()) {
//        self.eventsService = eventsService
//        setupSearchDebounce()
//        setupFilterObservers()
//        loadInitialData()
//    }
//    
//    // MARK: - Setup Methods
//    private func setupSearchDebounce() {
//        $searchText
//            .debounce(for: .seconds(debounceInterval), scheduler: RunLoop.main)
//            .sink { [weak self] searchTerm in
//                self?.updateSearchFilter(searchTerm)
//            }
//            .store(in: &cancellables)
//    }
//    
//    private func setupFilterObservers() {
//        // Observe tab changes
//        $selectedTab
//            .sink { [weak self] _ in
//                self?.resetPagination()
//                self?.loadEvents()
//            }
//            .store(in: &cancellables)
//        
//        // Observe filter changes
//        Publishers.CombineLatest4(
//            $selectedEventType,
//            $selectedSportId,
//            $showUpcomingOnly,
//            $showAvailableOnly
//        )
//        .debounce(for: .seconds(0.3), scheduler: RunLoop.main)
//        .sink { [weak self] _, _, _, _ in
//            self?.applyFilters()
//        }
//        .store(in: &cancellables)
//    }
//    
//    private func loadInitialData() {
//        Task {
//            await loadSupportingData()
//        }
//    }
//    
//    // MARK: - Core Event Methods
//    func loadEvents(resetPagination: Bool = true) {
//        if resetPagination {
//            self.resetPagination()
//        }
//        
//        guard !isLoading else { return }
//        
//        isLoading = true
//        errorMessage = ""
//        
//        let publisher: AnyPublisher<EventsResponse, Error>
//        
//        switch selectedTab {
//        case .all:
//            publisher = eventsService.fetchEvents(filter: currentFilter)
//        case .my:
//            publisher = eventsService.fetchMyEvents(filter: currentFilter)
//        }
//        
//        publisher
//            .receive(on: DispatchQueue.main)
//            .sink(
//                receiveCompletion: { [weak self] completion in
//                    self?.isLoading = false
//                    switch completion {
//                    case .failure(let error):
//                        self?.handleError(error)
//                    case .finished:
//                        break
//                    }
//                },
//                receiveValue: { [weak self] response in
//                    self?.handleEventsResponse(response, resetPagination: resetPagination)
//                }
//            )
//            .store(in: &cancellables)
//    }
//    
//    func loadMoreEvents() {
//        guard canLoadMore && !isLoading else { return }
//        
//        currentFilter.page = currentPage + 1
//        loadEvents(resetPagination: false)
//    }
//    
//    func refreshEvents() {
//        resetPagination()
//        loadEvents()
//        
//        // Also refresh supporting data
//        Task {
//            await loadSupportingData()
//        }
//    }
//    
//    // MARK: - Event Actions
//    func joinEvent(_ event: Event) {
//        guard !isLoading else { return }
//        
//        isLoading = true
//        eventsService.joinEvent(eventId: event.id)
//            .receive(on: DispatchQueue.main)
//            .sink(
//                receiveCompletion: { [weak self] completion in
//                    self?.isLoading = false
//                    switch completion {
//                    case .failure(let error):
//                        self?.handleError(error)
//                    case .finished:
//                        break
//                    }
//                },
//                receiveValue: { [weak self] success in
//                    if success {
//                        self?.updateEventParticipation(eventId: event.id, isParticipant: true)
//                    }
//                }
//            )
//            .store(in: &cancellables)
//    }
//    
//    func leaveEvent(_ event: Event) {
//        guard !isLoading else { return }
//        
//        isLoading = true
//        eventsService.leaveEvent(eventId: event.id)
//            .receive(on: DispatchQueue.main)
//            .sink(
//                receiveCompletion: { [weak self] completion in
//                    self?.isLoading = false
//                    switch completion {
//                    case .failure(let error):
//                        self?.handleError(error)
//                    case .finished:
//                        break
//                    }
//                },
//                receiveValue: { [weak self] success in
//                    if success {
//                        self?.updateEventParticipation(eventId: event.id, isParticipant: false)
//                    }
//                }
//            )
//            .store(in: &cancellables)
//    }
//    
//    // MARK: - Event Details
//    func loadEventDetails(eventId: Int) {
//        selectedEvent = nil
//        eventComments = []
//        eventRatings = []
//        eventParticipants = []
//        
//        // Load event details
//        eventsService.fetchEventDetails(eventId: eventId)
//            .receive(on: DispatchQueue.main)
//            .sink(
//                receiveCompletion: { [weak self] completion in
//                    if case .failure(let error) = completion {
//                        self?.handleError(error)
//                    }
//                },
//                receiveValue: { [weak self] event in
//                    self?.selectedEvent = event
//                }
//            )
//            .store(in: &cancellables)
//        
//        // Load comments
//        eventsService.fetchEventComments(eventId: eventId)
//            .receive(on: DispatchQueue.main)
//            .sink(
//                receiveCompletion: { _ in },
//                receiveValue: { [weak self] comments in
//                    self?.eventComments = comments
//                }
//            )
//            .store(in: &cancellables)
//        
//        // Load ratings
//        eventsService.fetchEventRatings(eventId: eventId)
//            .receive(on: DispatchQueue.main)
//            .sink(
//                receiveCompletion: { _ in },
//                receiveValue: { [weak self] ratings in
//                    self?.eventRatings = ratings
//                }
//            )
//            .store(in: &cancellables)
//        
//        // Load participants
//        eventsService.fetchEventParticipants(eventId: eventId)
//            .receive(on: DispatchQueue.main)
//            .sink(
//                receiveCompletion: { _ in },
//                receiveValue: { [weak self] participants in
//                    self?.eventParticipants = participants
//                }
//            )
//            .store(in: &cancellables)
//    }
//    
//    // MARK: - Comments & Ratings
//    func addComment(to eventId: Int, comment: String) {
//        eventsService.addEventComment(eventId: eventId, comment: comment)
//            .receive(on: DispatchQueue.main)
//            .sink(
//                receiveCompletion: { [weak self] completion in
//                    if case .failure(let error) = completion {
//                        self?.handleError(error)
//                    }
//                },
//                receiveValue: { [weak self] newComment in
//                    self?.eventComments.append(newComment)
//                }
//            )
//            .store(in: &cancellables)
//    }
//    
//    func rateEvent(_ eventId: Int, rating: Int, review: String? = nil) {
//        eventsService.rateEvent(eventId: eventId, rating: rating, review: review)
//            .receive(on: DispatchQueue.main)
//            .sink(
//                receiveCompletion: { [weak self] completion in
//                    if case .failure(let error) = completion {
//                        self?.handleError(error)
//                    }
//                },
//                receiveValue: { [weak self] newRating in
//                    self?.eventRatings.append(newRating)
//                }
//            )
//            .store(in: &cancellables)
//    }
//    
//    // MARK: - Invitations
//    func inviteUserToEvent(eventId: Int, username: String) {
//        eventsService.inviteToEvent(eventId: eventId, username: username)
//            .receive(on: DispatchQueue.main)
//            .sink(
//                receiveCompletion: { [weak self] completion in
//                    if case .failure(let error) = completion {
//                        self?.handleError(error)
//                    }
//                },
//                receiveValue: { success in
//                    if success {
//                        print("✅ Invitation sent successfully")
//                    }
//                }
//            )
//            .store(in: &cancellables)
//    }
//    
//    func respondToInvitation(invitationId: Int, accepted: Bool) {
//        eventsService.respondToInvitation(invitationId: invitationId, accepted: accepted)
//            .receive(on: DispatchQueue.main)
//            .sink(
//                receiveCompletion: { [weak self] completion in
//                    if case .failure(let error) = completion {
//                        self?.handleError(error)
//                    }
//                },
//                receiveValue: { [weak self] success in
//                    if success {
//                        self?.loadUserInvitations()
//                    }
//                }
//            )
//            .store(in: &cancellables)
//    }
//    
//    func loadUserInvitations() {
//        eventsService.fetchUserInvitations()
//            .receive(on: DispatchQueue.main)
//            .sink(
//                receiveCompletion: { _ in },
//                receiveValue: { [weak self] invitations in
//                    self?.userInvitations = invitations
//                }
//            )
//            .store(in: &cancellables)
//    }
//    
//    // MARK: - Notifications
//    func loadNotifications() {
//        eventsService.fetchEventNotifications()
//            .receive(on: DispatchQueue.main)
//            .sink(
//                receiveCompletion: { _ in },
//                receiveValue: { [weak self] notifications in
//                    self?.userNotifications = notifications
//                }
//            )
//            .store(in: &cancellables)
//    }
//    
//    func markNotificationAsRead(notificationId: Int) {
//        eventsService.markNotificationAsRead(notificationId: notificationId)
//            .receive(on: DispatchQueue.main)
//            .sink(
//                receiveCompletion: { _ in },
//                receiveValue: { [weak self] success in
//                    if success {
//                        if let index = self?.userNotifications.firstIndex(where: { $0.id == notificationId }) {
//                            self?.userNotifications[index] = EventNotification(
//                                id: self?.userNotifications[index].id ?? 0,
//                                eventId: self?.userNotifications[index].eventId ?? 0,
//                                userId: self?.userNotifications[index].userId ?? 0,
//                                type: self?.userNotifications[index].type ?? .eventReminder,
//                                title: self?.userNotifications[index].title ?? "",
//                                message: self?.userNotifications[index].message ?? "",
//                                isRead: true,
//                                createdAt: self?.userNotifications[index].createdAt ?? "",
//                                event: self?.userNotifications[index].event
//                            )
//                        }
//                    }
//                }
//            )
//            .store(in: &cancellables)
//    }
//    
//    // MARK: - Supporting Data
//    @MainActor
//    private func loadSupportingData() async {
//        await withTaskGroup(of: Void.self) { group in
//            group.addTask { [weak self] in
//                await self?.loadAvailableSports()
//            }
//            
//            group.addTask { [weak self] in
//                await self?.loadEventCategories()
//            }
//            
//            group.addTask { [weak self] in
//                await self?.loadEventLocations()
//            }
//            
//            group.addTask { [weak self] in
//                await self?.loadEventStatistics()
//            }
//            
//            group.addTask { [weak self] in
//                await self?.loadUserPreferences()
//            }
//        }
//    }
//    
//    private func loadAvailableSports() async {
//        do {
//            let sports = try await eventsService.fetchAvailableSports().async()
//            await MainActor.run {
//                self.availableSports = sports
//            }
//        } catch {
//            print("❌ Failed to load sports: \(error)")
//        }
//    }
//    
//    private func loadEventCategories() async {
//        do {
//            let categories = try await eventsService.fetchEventCategories().async()
//            await MainActor.run {
//                self.eventCategories = categories
//            }
//        } catch {
//            print("❌ Failed to load categories: \(error)")
//        }
//    }
//    
//    private func loadEventLocations() async {
//        do {
//            let locations = try await eventsService.fetchEventLocations().async()
//            await MainActor.run {
//                self.eventLocations = locations
//            }
//        } catch {
//            print("❌ Failed to load locations: \(error)")
//        }
//    }
//    
//    private func loadEventStatistics() async {
//        do {
//            let stats = try await eventsService.fetchEventStatistics().async()
//            await MainActor.run {
//                self.eventStatistics = stats
//            }
//        } catch {
//            print("❌ Failed to load statistics: \(error)")
//        }
//    }
//    
//    private func loadUserPreferences() async {
//        do {
//            let preferences = try await eventsService.fetchUserEventPreferences().async()
//            await MainActor.run {
//                self.userPreferences = preferences
//            }
//        } catch {
//            print("❌ Failed to load user preferences: \(error)")
//        }
//    }
//    
//    // MARK: - Search & Discovery
//    func searchEvents(query: String) {
//        eventsService.searchEvents(query: query, filters: currentFilter)
//            .receive(on: DispatchQueue.main)
//            .sink(
//                receiveCompletion: { [weak self] completion in
//                    if case .failure(let error) = completion {
//                        self?.handleError(error)
//                    }
//                },
//                receiveValue: { [weak self] searchResult in
//                    self?.events = searchResult.events
//                    print("🔍 Search completed: \(searchResult.totalCount) results for '\(query)'")
//                }
//            )
//            .store(in: &cancellables)
//    }
//    
//    func fetchNearbyEvents(latitude: Double, longitude: Double, radius: Double = 25.0) {
//        eventsService.fetchNearbyEvents(latitude: latitude, longitude: longitude, radius: radius)
//            .receive(on: DispatchQueue.main)
//            .sink(
//                receiveCompletion: { [weak self] completion in
//                    if case .failure(let error) = completion {
//                        self?.handleError(error)
//                    }
//                },
//                receiveValue: { [weak self] nearbyEvents in
//                    print("📍 Found \(nearbyEvents.count) nearby events")
//                    // You might want to handle nearby events differently
//                    // For now, we'll just log them
//                }
//            )
//            .store(in: &cancellables)
//    }
//    
//    // MARK: - Filter Management
//    func applyFilters() {
//        updateCurrentFilter()
//        resetPagination()
//        loadEvents()
//    }
//    
//    func clearFilters() {
//        selectedEventType = nil
//        selectedSportId = nil
//        selectedLocation = ""
//        maxEntryFee = ""
//        showUpcomingOnly = false
//        showAvailableOnly = false
//        showOpenRegistrationOnly = false
//        searchText = ""
//        
//        applyFilters()
//    }
//    
//    // MARK: - User Preferences
//    func updateUserPreferences(_ newPreferences: UserEventPreferences) {
//        eventsService.updateUserEventPreferences(newPreferences)
//            .receive(on: DispatchQueue.main)
//            .sink(
//                receiveCompletion: { [weak self] completion in
//                    if case .failure(let error) = completion {
//                        self?.handleError(error)
//                    }
//                },
//                receiveValue: { [weak self] success in
//                    if success {
//                        self?.userPreferences = newPreferences
//                        print("✅ User preferences updated successfully")
//                    }
//                }
//            )
//            .store(in: &cancellables)
//    }
//    
//    // MARK: - Private Methods
//    private func resetPagination() {
//        currentPage = 1
//        currentFilter.page = 1
//        canLoadMore = false
//    }
//    
//    private func updateSearchFilter(_ searchTerm: String) {
//        currentFilter.searchTerm = searchTerm.isEmpty ? nil : searchTerm
//        applyFilters()
//    }
//    
//    private func updateCurrentFilter() {
//        currentFilter.eventType = selectedEventType
//        currentFilter.sportId = selectedSportId
//        currentFilter.location = selectedLocation.isEmpty ? nil : selectedLocation
//        currentFilter.isUpcoming = showUpcomingOnly ? true : nil
//        currentFilter.hasAvailableSpots = showAvailableOnly ? true : nil
//        currentFilter.isRegistrationOpen = showOpenRegistrationOnly ? true : nil
//        
//        if let maxFeeText = Double(maxEntryFee), !maxEntryFee.isEmpty {
//            currentFilter.maxEntryFee = maxFeeText
//        } else {
//            currentFilter.maxEntryFee = nil
//        }
//    }
//    
//    private func handleEventsResponse(_ response: EventsResponse, resetPagination: Bool) {
//        if resetPagination {
//            events = response.events
//        } else {
//            events.append(contentsOf: response.events)
//        }
//        
//        currentPage = response.page
//        totalPages = response.totalPages
//        canLoadMore = currentPage < totalPages
//        
//        print("📋 Loaded \(response.events.count) events (Page \(currentPage)/\(totalPages))")
//    }
//    
//    private func updateEventParticipation(eventId: Int, isParticipant: Bool) {
//        if let index = events.firstIndex(where: { $0.id == eventId }) {
//            // In a real implementation, you'd update the Event struct
//            // For now, we'll just reload the events
//            loadEvents()
//        }
//    }
//    
//    private func handleError(_ error: Error) {
//        errorMessage = error.localizedDescription
//        showError = true
//        print("❌ Events Error: \(error.localizedDescription)")
//    }
//}
//
//// MARK: - Publisher Extension for Async/Await
//extension Publisher {
//    func async() async throws -> Output {
//        try await withCheckedThrowingContinuation { continuation in
//            var cancellable: AnyCancellable?
//            
//            cancellable = sink(
//                receiveCompletion: { completion in
//                    switch completion {
//                    case .finished:
//                        break
//                    case .failure(let error):
//                        continuation.resume(throwing: error)
//                    }
//                    cancellable?.cancel()
//                },
//                receiveValue: { value in
//                    continuation.resume(returning: value)
//                    cancellable?.cancel()
//                }
//            )
//        }
//    }
//}
//
//// MARK: - Usage Instructions
///*
//Bu enhanced ViewModel şu özellikleri sağlar:
//
//✅ Temel Event Operations
//- Events listeleme (All/My Events)
//- Event'lere katılma/ayrılma
//- Pagination
//- Filtreleme ve arama
//
//✅ Event Details
//- Detaylı event bilgileri
//- Comments sistemi
//- Rating sistemi
//- Participants listesi
//
//✅ Social Features
//- Event invitations
//- User notifications
//- Event comments & ratings
//
//✅ User Experience
//- User preferences
//- Event statistics
//- Nearby events
//- Search functionality
//
//✅ Supporting Data
//- Available sports
//- Event categories
//- Event locations
//- User preferences
//
//Kullanım:
//1. Production'da: EnhancedEventsViewModel(eventsService: CompleteEventsService())
//2. Testing'de: EnhancedEventsViewModel(eventsService: MockCompleteEventsService())
//
//Event sayfasında bu ViewModel'i kullanarak tüm özelliklere erişebilirsiniz:
//
//struct EventsView: View {
//    @StateObject private var viewModel = EnhancedEventsViewModel()
//    
//    var body: some View {
//        // Your UI implementation
//    }
//}
//*/
