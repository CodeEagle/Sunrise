import Foundation
import CoreLocation
import Dependencies
import DependenciesMacros

public enum LocationAuthorizationStatus: Sendable, Equatable {
    case notDetermined
    case denied
    case restricted
    case authorizedWhenInUse
    case authorizedAlways
}

@DependencyClient
public struct LocationClient: Sendable {
    public var authorizationStatus: @Sendable () -> LocationAuthorizationStatus = { .notDetermined }
    public var requestWhenInUseAuthorization: @Sendable () async -> LocationAuthorizationStatus = { .notDetermined }
    public var currentLocation: @Sendable () async throws -> CLLocationCoordinate2D
}

extension LocationClient: DependencyKey {
    public static var liveValue: LocationClient {
        let manager = LocationManagerActor()
        return LocationClient(
            authorizationStatus: { manager.currentAuthorizationStatus() },
            requestWhenInUseAuthorization: { await manager.requestWhenInUseAuthorization() },
            currentLocation: { try await manager.currentLocation() }
        )
    }

    public static let previewValue = LocationClient(
        authorizationStatus: { .authorizedWhenInUse },
        requestWhenInUseAuthorization: { .authorizedWhenInUse },
        currentLocation: { CLLocationCoordinate2D(latitude: 31.2304, longitude: 121.4737) } // Shanghai
    )

    public static let testValue = LocationClient()
}

public extension DependencyValues {
    var locationClient: LocationClient {
        get { self[LocationClient.self] }
        set { self[LocationClient.self] = newValue }
    }
}

public enum LocationClientError: Error, Sendable {
    case authorizationDenied
    case unavailable
    case timeout
}

private final class LocationManagerActor: NSObject, CLLocationManagerDelegate, @unchecked Sendable {
    private let manager = CLLocationManager()
    private var authorizationContinuation: CheckedContinuation<LocationAuthorizationStatus, Never>?
    private var locationContinuation: CheckedContinuation<CLLocationCoordinate2D, Error>?
    private let lock = NSLock()

    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyHundredMeters
    }

    func currentAuthorizationStatus() -> LocationAuthorizationStatus {
        Self.map(manager.authorizationStatus)
    }

    func requestWhenInUseAuthorization() async -> LocationAuthorizationStatus {
        let status = manager.authorizationStatus
        if status != .notDetermined {
            return Self.map(status)
        }
        return await withCheckedContinuation { continuation in
            lock.lock()
            authorizationContinuation = continuation
            lock.unlock()
            manager.requestWhenInUseAuthorization()
        }
    }

    func currentLocation() async throws -> CLLocationCoordinate2D {
        switch manager.authorizationStatus {
        case .denied, .restricted:
            throw LocationClientError.authorizationDenied
        case .notDetermined:
            _ = await requestWhenInUseAuthorization()
        default:
            break
        }

        return try await withCheckedThrowingContinuation { continuation in
            lock.lock()
            locationContinuation = continuation
            lock.unlock()
            manager.requestLocation()
        }
    }

    // MARK: CLLocationManagerDelegate

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        lock.lock()
        let continuation = authorizationContinuation
        authorizationContinuation = nil
        lock.unlock()
        continuation?.resume(returning: Self.map(manager.authorizationStatus))
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        lock.lock()
        let continuation = locationContinuation
        locationContinuation = nil
        lock.unlock()
        continuation?.resume(returning: location.coordinate)
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        lock.lock()
        let continuation = locationContinuation
        locationContinuation = nil
        lock.unlock()
        continuation?.resume(throwing: error)
    }

    private static func map(_ status: CLAuthorizationStatus) -> LocationAuthorizationStatus {
        switch status {
        case .notDetermined: return .notDetermined
        case .denied: return .denied
        case .restricted: return .restricted
        case .authorizedWhenInUse: return .authorizedWhenInUse
        case .authorizedAlways: return .authorizedAlways
        @unknown default: return .notDetermined
        }
    }
}
