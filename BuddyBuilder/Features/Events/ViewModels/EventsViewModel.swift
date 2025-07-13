import SwiftUI
import Foundation

// MARK: - Events View Model
@MainActor
class EventsViewModel: ObservableObject {
    @Published var events: [Event] = []
    @Published var filteredEvents: [Event] = []
    @Published var selectedTab: EventsTab = .all
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    // Filter properties
    @Published var selectedEventType: EventType?
    @Published var selectedSport: Sport?
    @Published var selectedDate: DateFilter?
    
    private let eventsService: EventsServiceProtocol
    
    init(eventsService: EventsServiceProtocol = EventsService()) {
        self.eventsService = eventsService
        loadEvents()
    }
    
    // MARK: - Public Methods
    
    func loadEvents() {
        isLoading = true
        errorMessage = nil
        
        Task {
            do {
                let loadedEvents: [Event]
                
                switch selectedTab {
                case .all:
                    loadedEvents = try await eventsService.fetchEvents()
                case .my:
                    loadedEvents = try await eventsService.fetchMyEvents()
                }
                
                await MainActor.run {
                    self.events = loadedEvents
                    self.applyFilters()
                    self.isLoading = false
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = error.localizedDescription
                    self.isLoading = false
                    print("Error loading events: \(error.localizedDescription)")
                }
            }
        }
    }
    
    func refreshEvents() async {
        do {
            let loadedEvents: [Event]
            
            switch selectedTab {
            case .all:
                loadedEvents = try await eventsService.fetchEvents()
            case .my:
                loadedEvents = try await eventsService.fetchMyEvents()
            }
            
            await MainActor.run {
                self.events = loadedEvents
                self.applyFilters()
            }
        } catch {
            await MainActor.run {
                self.errorMessage = error.localizedDescription
                print("Error refreshing events: \(error.localizedDescription)")
            }
        }
    }
    
    func applyFilters() {
        var filtered = events
        
        // Filter by event type
        if let eventType = selectedEventType {
            filtered = filtered.filter { $0.type == eventType }
        }
        
        // Filter by sport
        if let sport = selectedSport {
            filtered = filtered.filter { $0.sport == sport }
        }
        
        // Filter by date
        if let dateFilter = selectedDate {
            let dateRange = dateFilter.dateRange
            filtered = filtered.filter { event in
                event.date >= dateRange.start && event.date < dateRange.end
            }
        }
        
        // Sort by date (upcoming first)
        filtered.sort { $0.date < $1.date }
        
        filteredEvents = filtered
    }
    
    func joinEvent(_ eventId: String) async {
        do {
            let success = try await eventsService.joinEvent(eventId)
            if success {
                await refreshEvents()
            }
        } catch {
            await MainActor.run {
                self.errorMessage = error.localizedDescription
                print("Error joining event: \(error.localizedDescription)")
            }
        }
    }
    
    func leaveEvent(_ eventId: String) async {
        do {
            let success = try await eventsService.leaveEvent(eventId)
            if success {
                await refreshEvents()
            }
        } catch {
            await MainActor.run {
                self.errorMessage = error.localizedDescription
                print("Error leaving event: \(error.localizedDescription)")
            }
        }
    }
    
    func clearFilters() {
        selectedEventType = nil
        selectedSport = nil
        selectedDate = nil
        applyFilters()
    }
    
    func changeTab(to tab: EventsTab) {
        guard selectedTab != tab else { return }
        
        selectedTab = tab
        events = []
        filteredEvents = []
        loadEvents()
    }
    
    // MARK: - Computed Properties
    
    var hasActiveFilters: Bool {
        selectedEventType != nil || selectedSport != nil || selectedDate != nil
    }
    
    var filterCount: Int {
        var count = 0
        if selectedEventType != nil { count += 1 }
        if selectedSport != nil { count += 1 }
        if selectedDate != nil { count += 1 }
        return count
    }
    
    var emptyStateTitle: String {
        switch selectedTab {
        case .all:
            return hasActiveFilters ? "No events match your filters" : "No events available"
        case .my:
            return hasActiveFilters ? "No events match your filters" : "You haven't joined any events yet"
        }
    }
    
    var emptyStateDescription: String {
        switch selectedTab {
        case .all:
            return hasActiveFilters ? "Try adjusting your filters to find more events" : "Check back later for new events or create your own!"
        case .my:
            return hasActiveFilters ? "Try adjusting your filters to see your events" : "Join some events to see them here"
        }
    }
}
