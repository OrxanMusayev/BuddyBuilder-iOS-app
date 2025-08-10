// BuddyBuilder/Features/Authentication/Services/LocationService.swift

import Foundation
import CoreLocation
import Combine

// MARK: - Location Service Protocol
protocol LocationServiceProtocol {
    func searchLocations(searchTerm: String, languageCode: String) -> AnyPublisher<[LocationItem], Error>
    func requestLocationPermission() async -> Bool
    func getCurrentLocation() async -> CLLocation?
    func checkCurrentPermissionStatus() -> CLAuthorizationStatus // NEW
}

// MARK: - Location Service Implementation
class LocationService: NSObject, LocationServiceProtocol, CLLocationManagerDelegate {
    private let networkManager = NetworkManager.shared
    private let baseURL = "http://192.168.100.76:5206/api/Location"
    private let locationManager = CLLocationManager()
    
    @Published private var currentLocationSubject = PassthroughSubject<CLLocation?, Never>()
    @Published private var permissionGranted = false
    
    private var locationContinuation: CheckedContinuation<CLLocation?, Never>?
    private var permissionContinuation: CheckedContinuation<Bool, Never>?
    
    override init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
    }
    
    // MARK: - NEW: Check current permission status
    func checkCurrentPermissionStatus() -> CLAuthorizationStatus {
        return locationManager.authorizationStatus
    }
    
    // MARK: - Location Autocomplete
    func searchLocations(searchTerm: String, languageCode: String) -> AnyPublisher<[LocationItem], Error> {
        guard searchTerm.count >= 3 else {
            return Just([])
                .setFailureType(to: Error.self)
                .eraseToAnyPublisher()
        }
        
        let encodedSearchTerm = searchTerm.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? searchTerm
        let endpoint = "\(baseURL)/autocomplete?LanguageCode=\(languageCode)&SearchTerm=\(encodedSearchTerm)&Limit=5"
        
        print("🔍 Searching locations for: '\(searchTerm)' in \(languageCode)")
        print("📍 Request URL: \(endpoint)")
        
        return networkManager.request(
            endpoint: endpoint,
            method: .GET,
            type: LocationResponse.self
        )
        .handleEvents(
            receiveOutput: { response in
                print("✅ Location search response: success=\(response.success), count=\(response.data?.count ?? 0)")
                if let locations = response.data, !locations.isEmpty {
                    let displayTexts = locations.map { $0.displayText }
                    print("📍 Found locations: \(displayTexts)")
                }
            },
            receiveCompletion: { completion in
                if case .failure(let error) = completion {
                    print("❌ Location search failed: \(error)")
                }
            }
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
        return await withCheckedContinuation { continuation in
            permissionContinuation = continuation
            
            switch locationManager.authorizationStatus {
            case .notDetermined:
                locationManager.requestWhenInUseAuthorization()
            case .authorizedWhenInUse, .authorizedAlways:
                continuation.resume(returning: true)
                permissionContinuation = nil
            case .denied, .restricted:
                continuation.resume(returning: false)
                permissionContinuation = nil
            @unknown default:
                continuation.resume(returning: false)
                permissionContinuation = nil
            }
        }
    }
    
    // MARK: - Get Current Location
    func getCurrentLocation() async -> CLLocation? {
        guard locationManager.authorizationStatus == .authorizedWhenInUse ||
              locationManager.authorizationStatus == .authorizedAlways else {
            print("❌ Location permission not granted")
            return nil
        }
        
        return await withCheckedContinuation { continuation in
            locationContinuation = continuation
            locationManager.requestLocation()
        }
    }
    
    // MARK: - CLLocationManagerDelegate
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        
        print("✅ Location updated: \(location.coordinate.latitude), \(location.coordinate.longitude)")
        locationContinuation?.resume(returning: location)
        locationContinuation = nil
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("❌ Location error: \(error)")
        locationContinuation?.resume(returning: nil)
        locationContinuation = nil
    }
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        print("🔄 Location authorization changed: \(status.rawValue)")
        
        // ENHANCED: Post notification for permission change
        NotificationCenter.default.post(
            name: .locationPermissionChanged,
            object: nil,
            userInfo: ["status": status]
        )
        
        switch status {
        case .authorizedWhenInUse, .authorizedAlways:
            permissionContinuation?.resume(returning: true)
        case .denied, .restricted:
            permissionContinuation?.resume(returning: false)
        case .notDetermined:
            // Wait for user decision
            return
        @unknown default:
            permissionContinuation?.resume(returning: false)
        }
        
        permissionContinuation = nil
    }
}

// MARK: - NEW: Notification extension
extension Notification.Name {
    static let locationPermissionChanged = Notification.Name("locationPermissionChanged")
}

// MARK: - Mock Location Service
class MockLocationService: LocationServiceProtocol {
    func checkCurrentPermissionStatus() -> CLAuthorizationStatus {
        return .authorizedWhenInUse // Mock always authorized
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
        print("🧪 MOCK: Location permission requested")
        try? await Task.sleep(nanoseconds: 1_000_000_000) // 1 second delay
        return true
    }
    
    func getCurrentLocation() async -> CLLocation? {
        print("🧪 MOCK: Getting current location")
        try? await Task.sleep(nanoseconds: 1_000_000_000) // 1 second delay
        // Return Baku coordinates as mock
        return CLLocation(latitude: 40.4093, longitude: 49.8671)
    }
}
