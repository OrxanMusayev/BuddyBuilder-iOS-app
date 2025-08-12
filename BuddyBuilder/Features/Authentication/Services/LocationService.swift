// BuddyBuilder/Features/Authentication/Services/LocationService.swift - SIMPLIFIED VERSION

import Foundation
import CoreLocation
import Combine

// MARK: - Location Service Protocol
protocol LocationServiceProtocol {
    func searchLocations(searchTerm: String, languageCode: String) -> AnyPublisher<[LocationItem], Error>
    func requestLocationPermission() async -> Bool
    func getCurrentLocation() async -> CLLocation?
    func checkCurrentPermissionStatus() -> CLAuthorizationStatus
}

// MARK: - Simplified Location Service Implementation
class LocationService: NSObject, LocationServiceProtocol, CLLocationManagerDelegate {
    private let networkManager = NetworkManager.shared
    private let baseURL = "http://192.168.100.76:5206/api/Location"
    private let locationManager = CLLocationManager()
    
    @Published private var currentLocationSubject = PassthroughSubject<CLLocation?, Never>()
    @Published private var permissionGranted = false
    
    private var locationContinuation: CheckedContinuation<CLLocation?, Never>?
    private var permissionContinuation: CheckedContinuation<Bool, Never>?
    private var locationTimeoutTask: Task<Void, Never>?
    
    // OPTIMIZED: Location cache
    private var cachedLocation: CLLocation?
    private var lastLocationTime: Date?
    private let locationCacheTimeout: TimeInterval = 30 // 30 seconds cache
    
    override init() {
        super.init()
        setupLocationManager()
    }
    
    // MARK: - Setup Location Manager
    private func setupLocationManager() {
        locationManager.delegate = self
        
        // OPTIMIZED: Best performance settings
        locationManager.desiredAccuracy = kCLLocationAccuracyHundredMeters // Balanced accuracy vs speed
        locationManager.distanceFilter = 50 // Only update if moved 50 meters
        
        // OPTIMIZED: Activity type for better performance
        if #available(iOS 6.0, *) {
            locationManager.activityType = .other // General purpose
        }
        
        print("📍 LocationManager optimized for balanced performance")
    }
    
    // MARK: - Check current permission status
    func checkCurrentPermissionStatus() -> CLAuthorizationStatus {
        return locationManager.authorizationStatus
    }
    
    // MARK: - Location Autocomplete (unchanged)
    func searchLocations(searchTerm: String, languageCode: String) -> AnyPublisher<[LocationItem], Error> {
        guard searchTerm.count >= 3 else {
            return Just([])
                .setFailureType(to: Error.self)
                .eraseToAnyPublisher()
        }
        
        let encodedSearchTerm = searchTerm.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? searchTerm
        let endpoint = "\(baseURL)/autocomplete?LanguageCode=\(languageCode)&SearchTerm=\(encodedSearchTerm)&Limit=5"
        
        print("🔍 Searching locations for: '\(searchTerm)' in \(languageCode)")
        
        return networkManager.request(
            endpoint: endpoint,
            method: .GET,
            type: LocationResponse.self
        )
        .compactMap { response in
            response.success ? response.data : []
        }
        .catch { error -> AnyPublisher<[LocationItem], Error> in
            print("❌ Location search error: \(error)")
            return Just([])
                .setFailureType(to: Error.self)
                .eraseToAnyPublisher()
        }
        .eraseToAnyPublisher()
    }
    
    // MARK: - Location Permission
    func requestLocationPermission() async -> Bool {
        print("🔐 Requesting location permission...")
        
        return await withCheckedContinuation { continuation in
            permissionContinuation = continuation
            
            switch locationManager.authorizationStatus {
            case .notDetermined:
                print("📍 Permission not determined - requesting...")
                locationManager.requestWhenInUseAuthorization()
            case .authorizedWhenInUse, .authorizedAlways:
                print("✅ Permission already granted")
                continuation.resume(returning: true)
                permissionContinuation = nil
            case .denied, .restricted:
                print("❌ Permission denied/restricted")
                continuation.resume(returning: false)
                permissionContinuation = nil
            @unknown default:
                print("❓ Unknown permission status")
                continuation.resume(returning: false)
                permissionContinuation = nil
            }
        }
    }
    
    // MARK: - SIMPLIFIED: Get Current Location with Cache
    func getCurrentLocation() async -> CLLocation? {
        print("📍 Getting current location...")
        
        // Check authorization first
        guard locationManager.authorizationStatus == .authorizedWhenInUse ||
              locationManager.authorizationStatus == .authorizedAlways else {
            print("❌ Location permission not granted")
            return nil
        }
        
        // OPTIMIZED: Return cached location if recent enough
        if let cachedLocation = cachedLocation,
           let lastTime = lastLocationTime,
           Date().timeIntervalSince(lastTime) < locationCacheTimeout {
            print("💾 Returning cached location (age: \(Date().timeIntervalSince(lastTime))s)")
            return cachedLocation
        }
        
        // OPTIMIZED: Try to get last known location first (instant)
        if let lastKnownLocation = locationManager.location,
           lastKnownLocation.timestamp.timeIntervalSinceNow > -300 { // Less than 5 minutes old
            print("⚡ Using last known location (age: \(abs(lastKnownLocation.timestamp.timeIntervalSinceNow))s)")
            cacheLocation(lastKnownLocation)
            return lastKnownLocation
        }
        
        // SIMPLIFIED: Request fresh location with simple timeout
        return await requestFreshLocationWithTimeout()
    }
    
    // MARK: - SIMPLIFIED: Request Fresh Location with Simple Timeout
    private func requestFreshLocationWithTimeout() async -> CLLocation? {
        return await withCheckedContinuation { continuation in
            locationContinuation = continuation
            
            // Start location updates
            print("🔄 Starting location updates for fresh location...")
            locationManager.startUpdatingLocation()
            
            // SIMPLIFIED: Simple timeout using Task
            locationTimeoutTask = Task { [weak self] in
                try? await Task.sleep(nanoseconds: 15_000_000_000) // 15 seconds
                
                await MainActor.run { [weak self] in
                    if self?.locationContinuation != nil {
                        print("⏰ Location request timed out after 15 seconds")
                        self?.locationManager.stopUpdatingLocation()
                        self?.locationContinuation?.resume(returning: nil)
                        self?.locationContinuation = nil
                    }
                }
            }
            
            // BACKUP: Also try requestLocation as fallback after 2 seconds
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) { [weak self] in
                if self?.locationContinuation != nil {
                    print("🔄 Trying requestLocation as backup...")
                    self?.locationManager.requestLocation()
                }
            }
        }
    }
    
    // MARK: - Cache Management
    private func cacheLocation(_ location: CLLocation) {
        cachedLocation = location
        lastLocationTime = Date()
        print("💾 Cached location: \(location.coordinate.latitude), \(location.coordinate.longitude)")
    }
    
    private func clearLocationCache() {
        cachedLocation = nil
        lastLocationTime = nil
        print("🗑️ Cleared location cache")
    }
    
    // MARK: - CLLocationManagerDelegate
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        
        print("✅ Location updated: \(location.coordinate.latitude), \(location.coordinate.longitude)")
        print("📊 Accuracy: \(location.horizontalAccuracy)m, Age: \(abs(location.timestamp.timeIntervalSinceNow))s")
        
        // OPTIMIZED: Accept location with reasonable accuracy
        let isAccurate = location.horizontalAccuracy < 500 // Accept up to 500m accuracy
        let isRecent = abs(location.timestamp.timeIntervalSinceNow) < 60 // Less than 1 minute old
        
        if isAccurate && isRecent {
            cacheLocation(location)
            locationManager.stopUpdatingLocation() // IMPORTANT: Stop to save battery
            
            // Cancel timeout task
            locationTimeoutTask?.cancel()
            locationTimeoutTask = nil
            
            locationContinuation?.resume(returning: location)
            locationContinuation = nil
        } else {
            print("⚠️ Location not accurate enough or too old, waiting for better fix...")
            print("   Accuracy: \(location.horizontalAccuracy)m (need < 500m)")
            print("   Age: \(abs(location.timestamp.timeIntervalSinceNow))s (need < 60s)")
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("❌ Location error: \(error.localizedDescription)")
        
        locationManager.stopUpdatingLocation() // Stop on error
        
        // Cancel timeout task
        locationTimeoutTask?.cancel()
        locationTimeoutTask = nil
        
        locationContinuation?.resume(returning: nil)
        locationContinuation = nil
    }
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        print("🔄 Location authorization changed: \(status.rawValue)")
        
        // Post notification for permission change
        NotificationCenter.default.post(
            name: .locationPermissionChanged,
            object: nil,
            userInfo: ["status": status]
        )
        
        switch status {
        case .authorizedWhenInUse, .authorizedAlways:
            print("✅ Location permission granted")
            permissionContinuation?.resume(returning: true)
        case .denied, .restricted:
            print("❌ Location permission denied")
            clearLocationCache() // Clear cache when permission denied
            permissionContinuation?.resume(returning: false)
        case .notDetermined:
            print("⏳ Location permission still not determined")
            return
        @unknown default:
            print("❓ Unknown location permission status")
            permissionContinuation?.resume(returning: false)
        }
        
        permissionContinuation = nil
    }
    
    // MARK: - Memory Management
    deinit {
        locationManager.stopUpdatingLocation()
        locationTimeoutTask?.cancel()
        print("🧹 LocationService deinitialized")
    }
}

// MARK: - Notification extension
extension Notification.Name {
    static let locationPermissionChanged = Notification.Name("locationPermissionChanged")
}

// MARK: - Mock Location Service (Faster for Development/Testing)
class MockLocationService: LocationServiceProtocol {
    func checkCurrentPermissionStatus() -> CLAuthorizationStatus {
        return .authorizedWhenInUse
    }
    
    func searchLocations(searchTerm: String, languageCode: String) -> AnyPublisher<[LocationItem], Error> {
        print("🧪 MOCK: Searching for '\(searchTerm)' in \(languageCode)")
        
        let mockLocations = [
            LocationItem(
                locationId: "1",
                countryCode: "Turkey",
                cityCode: "Istanbul",
                countryName: "Türkiye",
                cityName: "İstanbul",
                displayText: "İstanbul, Türkiye"
            ),
            LocationItem(
                locationId: "2",
                countryCode: "Azerbaijan",
                cityCode: "Baku",
                countryName: "Azerbaycan",
                cityName: "Bakü",
                displayText: "Bakü, Azerbaycan"
            ),
            LocationItem(
                locationId: "3",
                countryCode: "Georgia",
                cityCode: "Tbilisi",
                countryName: "Gürcistan",
                cityName: "Tiflis",
                displayText: "Tiflis, Gürcistan"
            )
        ].filter { $0.displayText.lowercased().contains(searchTerm.lowercased()) }
        
        return Just(mockLocations)
            .delay(for: .milliseconds(300), scheduler: RunLoop.main)
            .setFailureType(to: Error.self)
            .eraseToAnyPublisher()
    }
    
    func requestLocationPermission() async -> Bool {
        print("🧪 MOCK: Location permission granted instantly")
        // Simulate very fast permission grant for development
        try? await Task.sleep(nanoseconds: 200_000_000) // 0.2 seconds
        return true
    }
    
    func getCurrentLocation() async -> CLLocation? {
        print("🧪 MOCK: Getting location instantly")
        // Simulate very fast location for development
        try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
        
        // Return Baku coordinates as mock
        return CLLocation(latitude: 40.4093, longitude: 49.8671)
    }
}
