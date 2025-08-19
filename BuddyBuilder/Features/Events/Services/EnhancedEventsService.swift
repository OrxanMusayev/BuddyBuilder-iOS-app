// BuddyBuilder/Features/Events/Services/FixedEnhancedEventsService.swift

import Foundation
import Combine

// MARK: - Cache Strategy Enum
enum CacheStrategy {
    case cacheFirst    // Önce cache'i kontrol et, sonra API
    case apiFirst      // Önce API çağır, sonra cache'e kaydet
    case cacheOnly     // Sadece cache'den oku
    case apiOnly       // Sadece API'den çek, cache kullanma
}

// MARK: - Events Load State
enum EventsLoadState {
    case idle
    case loadingFromCache
    case loadingFromAPI
    case refreshingInBackground
    case refreshingManual
    case error(Error)
    case loaded(fromCache: Bool)
}

// MARK: - Enhanced Events Service Protocol
protocol EnhancedEventsServiceProtocol {
    func fetchEventsWithCache(
        filter: EventFilter,
        type: EventsCacheEntry.EventsCacheType,
        strategy: CacheStrategy
    ) -> AnyPublisher<(EventsResponse, Bool), Error> // Bool: fromCache mi?
    
    func refreshEventsManually(
        filter: EventFilter,
        type: EventsCacheEntry.EventsCacheType
    ) -> AnyPublisher<EventsResponse, Error>
    
    var loadState: AnyPublisher<EventsLoadState, Never> { get }
    
    // Base service methods
    func joinEventWithAutoRefresh(eventId: Int) -> AnyPublisher<Bool, Error>
    func leaveEventWithAutoRefresh(eventId: Int) -> AnyPublisher<Bool, Error>
}

// MARK: - Enhanced Events Service Implementation
class EnhancedEventsService: EnhancedEventsServiceProtocol {
    
    // MARK: - Dependencies
    private let cacheService: EventsCacheServiceProtocol
    private let baseEventsService: CompleteEventsService
    
    // MARK: - State Management
    private let loadStateSubject = CurrentValueSubject<EventsLoadState, Never>(.idle)
    var loadState: AnyPublisher<EventsLoadState, Never> {
        loadStateSubject.eraseToAnyPublisher()
    }
    
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initialization
    init(cacheService: EventsCacheServiceProtocol = EventsCacheService.shared,
         baseEventsService: CompleteEventsService? = nil) {
        self.cacheService = cacheService
        self.baseEventsService = baseEventsService ?? CompleteEventsService()
    }
    
    // MARK: - Cache-Integrated Methods
    func fetchEventsWithCache(
        filter: EventFilter,
        type: EventsCacheEntry.EventsCacheType,
        strategy: CacheStrategy = .cacheFirst
    ) -> AnyPublisher<(EventsResponse, Bool), Error> {
        
        switch strategy {
        case .cacheFirst:
            return fetchWithCacheFirstStrategy(filter: filter, type: type)
        case .apiFirst:
            return fetchWithAPIFirstStrategy(filter: filter, type: type)
        case .cacheOnly:
            return fetchFromCacheOnly(type: type)
        case .apiOnly:
            return fetchFromAPIOnly(filter: filter, type: type)
        }
    }
    
    func refreshEventsManually(
        filter: EventFilter,
        type: EventsCacheEntry.EventsCacheType
    ) -> AnyPublisher<EventsResponse, Error> {
        
        loadStateSubject.send(.refreshingManual)
        print("🔄 Manual refresh started for \(type.rawValue)")
        
        return fetchFromAPI(filter: filter, type: type)
            .handleEvents(
                receiveOutput: { [weak self] response in
                    print("✅ Manual refresh API completed - \(response.events.count) events")
                    self?.cacheService.saveEvents(response, for: type)
                    self?.loadStateSubject.send(.loaded(fromCache: false))
                },
                receiveCompletion: { [weak self] completion in
                    if case .failure(let error) = completion {
                        print("❌ Manual refresh failed: \(error)")
                        self?.loadStateSubject.send(.error(error))
                    }
                }
            )
            .eraseToAnyPublisher()
    }
    
    // MARK: - Delegate to Base Service
    func joinEventWithAutoRefresh(eventId: Int) -> AnyPublisher<Bool, Error> {
        return baseEventsService.joinEventWithAutoRefresh(eventId: eventId)
    }
    
    func leaveEventWithAutoRefresh(eventId: Int) -> AnyPublisher<Bool, Error> {
        return baseEventsService.leaveEventWithAutoRefresh(eventId: eventId)
    }
    
    // MARK: - Private Strategy Implementations
    
    private func fetchWithCacheFirstStrategy(
        filter: EventFilter,
        type: EventsCacheEntry.EventsCacheType
    ) -> AnyPublisher<(EventsResponse, Bool), Error> {
        
        // Token kontrolü yap
        let tokenAvailable = TokenManager.shared.accessToken != nil && !TokenManager.shared.accessToken!.isEmpty
        
        // Önce cache'i kontrol et
        if let cachedEntry = cacheService.getCachedEvents(for: type),
           !cachedEntry.isExpired {
            
            print("🎯 Cache hit - returning cached data for \(type.rawValue)")
            loadStateSubject.send(.loaded(fromCache: true))
            
            // Cache'den veri döndür ve token varsa arka planda refresh yap
            return Just((cachedEntry.data, true))
                .setFailureType(to: Error.self)
                .handleEvents(receiveOutput: { _ in
                    // Sadece token varsa arka planda refresh yap
                    if tokenAvailable {
                        self.backgroundRefresh(filter: filter, type: type)
                    } else {
                        print("⚠️ Token not available, skipping background refresh")
                    }
                })
                .eraseToAnyPublisher()
        } else {
            // Cache boş veya expired
            if tokenAvailable {
                // Token var - API'den çek
                print("🌐 Cache miss or expired - fetching from API for \(type.rawValue)")
                loadStateSubject.send(.loadingFromAPI)
                
                return fetchFromAPI(filter: filter, type: type)
                    .handleEvents(
                        receiveOutput: { [weak self] response in
                            self?.cacheService.saveEvents(response, for: type)
                            self?.loadStateSubject.send(.loaded(fromCache: false))
                        },
                        receiveCompletion: { [weak self] completion in
                            if case .failure(let error) = completion {
                                self?.loadStateSubject.send(.error(error))
                            }
                        }
                    )
                    .map { ($0, false) }
                    .eraseToAnyPublisher()
            } else {
                // Token yok - boş veri döndür
                print("⚠️ No token available and no cache, returning empty data for \(type.rawValue)")
                let emptyResponse = EventsResponse(
                    events: [],
                    totalCount: 0,
                    page: 1,
                    pageSize: 10,
                    totalPages: 0
                )
                loadStateSubject.send(.loaded(fromCache: false))
                
                return Just((emptyResponse, false))
                    .setFailureType(to: Error.self)
                    .eraseToAnyPublisher()
            }
        }
    }
    
    private func fetchWithAPIFirstStrategy(
        filter: EventFilter,
        type: EventsCacheEntry.EventsCacheType
    ) -> AnyPublisher<(EventsResponse, Bool), Error> {
        
        loadStateSubject.send(.loadingFromAPI)
        
        return fetchFromAPI(filter: filter, type: type)
            .handleEvents(
                receiveOutput: { [weak self] response in
                    self?.cacheService.saveEvents(response, for: type)
                    self?.loadStateSubject.send(.loaded(fromCache: false))
                },
                receiveCompletion: { [weak self] completion in
                    if case .failure(let error) = completion {
                        // API başarısız olursa cache'i dene
                        if let cachedEntry = self?.cacheService.getCachedEvents(for: type) {
                            print("⚠️ API failed, falling back to cache for \(type.rawValue)")
                            self?.loadStateSubject.send(.loaded(fromCache: true))
                        } else {
                            self?.loadStateSubject.send(.error(error))
                        }
                    }
                }
            )
            .map { ($0, false) }
            .catch { [weak self] error -> AnyPublisher<(EventsResponse, Bool), Error> in
                // API hatası durumunda cache'e fallback
                if let cachedEntry = self?.cacheService.getCachedEvents(for: type) {
                    return Just((cachedEntry.data, true))
                        .setFailureType(to: Error.self)
                        .eraseToAnyPublisher()
                } else {
                    return Fail(error: error).eraseToAnyPublisher()
                }
            }
            .eraseToAnyPublisher()
    }
    
    private func fetchFromCacheOnly(
        type: EventsCacheEntry.EventsCacheType
    ) -> AnyPublisher<(EventsResponse, Bool), Error> {
        
        loadStateSubject.send(.loadingFromCache)
        
        if let cachedEntry = cacheService.getCachedEvents(for: type) {
            loadStateSubject.send(.loaded(fromCache: true))
            return Just((cachedEntry.data, true))
                .setFailureType(to: Error.self)
                .eraseToAnyPublisher()
        } else {
            let error = NetworkError.noData
            loadStateSubject.send(.error(error))
            return Fail(error: error).eraseToAnyPublisher()
        }
    }
    
    private func fetchFromAPIOnly(
        filter: EventFilter,
        type: EventsCacheEntry.EventsCacheType
    ) -> AnyPublisher<(EventsResponse, Bool), Error> {
        
        loadStateSubject.send(.loadingFromAPI)
        
        return fetchFromAPI(filter: filter, type: type)
            .handleEvents(
                receiveOutput: { [weak self] response in
                    self?.cacheService.saveEvents(response, for: type)
                    self?.loadStateSubject.send(.loaded(fromCache: false))
                },
                receiveCompletion: { [weak self] completion in
                    if case .failure(let error) = completion {
                        self?.loadStateSubject.send(.error(error))
                    }
                }
            )
            .map { ($0, false) }
            .eraseToAnyPublisher()
    }
    
    // MARK: - Background Refresh
    private func backgroundRefresh(
        filter: EventFilter,
        type: EventsCacheEntry.EventsCacheType
    ) {
        loadStateSubject.send(.refreshingInBackground)
        
        fetchFromAPI(filter: filter, type: type)
            .sink(
                receiveCompletion: { [weak self] completion in
                    switch completion {
                    case .finished:
                        break
                    case .failure(let error):
                        print("⚠️ Background refresh failed: \(error)")
                        // Background refresh hatası kullanıcıya gösterilmez
                        self?.loadStateSubject.send(.loaded(fromCache: true))
                    }
                },
                receiveValue: { [weak self] response in
                    self?.cacheService.saveEvents(response, for: type)
                    print("✅ Background refresh completed for \(type.rawValue)")
                    
                    // Yeni veri farklıysa kullanıcıya bildir
                    self?.notifyIfDataChanged(newResponse: response, type: type)
                }
            )
            .store(in: &cancellables)
    }
    
    private func notifyIfDataChanged(
        newResponse: EventsResponse,
        type: EventsCacheEntry.EventsCacheType
    ) {
        // Bu method UI'da "yeni veri var" bildirimi için kullanılabilir
        print("🔄 Background refresh completed, checking for changes...")
        
        if let cachedEntry = cacheService.getCachedEvents(for: type) {
            let hasChanges = newResponse.events.count != cachedEntry.data.events.count
            if hasChanges {
                print("🆕 Data changed during background refresh")
                // UI'ya bildirim gönder
                NotificationCenter.default.post(
                    name: .eventsDataRefreshed,
                    object: type
                )
            }
        }
    }
    
    // MARK: - API Methods
    private func fetchFromAPI(
        filter: EventFilter,
        type: EventsCacheEntry.EventsCacheType
    ) -> AnyPublisher<EventsResponse, Error> {
        
        switch type {
        case .allEvents:
            return baseEventsService.fetchEventsWithAutoRefresh(filter: filter)
        case .myEvents:
            return baseEventsService.fetchMyEventsWithAutoRefresh(filter: filter)
        }
    }
}

// MARK: - Notification Names
extension Notification.Name {
    static let eventsDataRefreshed = Notification.Name("eventsDataRefreshed")
}

// MARK: - Mock Implementation for Testing
class MockEnhancedEventsService: EnhancedEventsServiceProtocol {
    private var mockEvents: [Event] = []
    private var shouldFailAPI = false
    private let loadStateSubject = CurrentValueSubject<EventsLoadState, Never>(.idle)
    private var cancellables = Set<AnyCancellable>()
    
    var loadState: AnyPublisher<EventsLoadState, Never> {
        loadStateSubject.eraseToAnyPublisher()
    }
    
    init() {
        setupMockData()
    }
    
    private func setupMockData() {
        // Mock events data for testing
        mockEvents = []
    }
    
    func fetchEventsWithCache(
        filter: EventFilter,
        type: EventsCacheEntry.EventsCacheType,
        strategy: CacheStrategy
    ) -> AnyPublisher<(EventsResponse, Bool), Error> {
        
        loadStateSubject.send(.loadingFromAPI)
        
        return Future { promise in
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                self.loadStateSubject.send(.loaded(fromCache: false))
                
                if self.shouldFailAPI {
                    promise(.failure(NetworkError.serverError(500)))
                } else {
                    let response = EventsResponse(
                        events: self.mockEvents,
                        totalCount: self.mockEvents.count,
                        page: 1,
                        pageSize: 10,
                        totalPages: 1
                    )
                    promise(.success((response, false)))
                }
            }
        }
        .eraseToAnyPublisher()
    }
    
    func refreshEventsManually(
        filter: EventFilter,
        type: EventsCacheEntry.EventsCacheType
    ) -> AnyPublisher<EventsResponse, Error> {
        
        loadStateSubject.send(.refreshingManual)
        
        return Future { promise in
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                self.loadStateSubject.send(.loaded(fromCache: false))
                
                if self.shouldFailAPI {
                    promise(.failure(NetworkError.serverError(500)))
                } else {
                    let response = EventsResponse(
                        events: self.mockEvents,
                        totalCount: self.mockEvents.count,
                        page: 1,
                        pageSize: 10,
                        totalPages: 1
                    )
                    promise(.success(response))
                }
            }
        }
        .eraseToAnyPublisher()
    }
    
    func joinEventWithAutoRefresh(eventId: Int) -> AnyPublisher<Bool, Error> {
        return Just(true)
            .setFailureType(to: Error.self)
            .eraseToAnyPublisher()
    }
    
    func leaveEventWithAutoRefresh(eventId: Int) -> AnyPublisher<Bool, Error> {
        return Just(true)
            .setFailureType(to: Error.self)
            .eraseToAnyPublisher()
    }
    
    func setAPIFailure(_ shouldFail: Bool) {
        shouldFailAPI = shouldFail
    }
    
    func addMockEvent(_ event: Event) {
        mockEvents.append(event)
    }
    
    func clearMockEvents() {
        mockEvents.removeAll()
    }
}
