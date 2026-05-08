import Foundation
import CoreLocation
import Dependencies
import DependenciesMacros

#if canImport(MapKit)
import MapKit
#endif

public struct CitySearchResult: Hashable, Sendable, Identifiable {
    public let id: String
    public let title: String
    public let subtitle: String

    public init(id: String, title: String, subtitle: String) {
        self.id = id
        self.title = title
        self.subtitle = subtitle
    }
}

@DependencyClient
public struct SearchClient: Sendable {
    /// Streams autocomplete results as the user types. Cancelling the consuming
    /// task tears down the underlying completer.
    public var autocomplete: @Sendable (_ query: String) -> AsyncStream<[CitySearchResult]> = { _ in .never }

    /// Resolves a search result to a fully populated City (with coordinate).
    public var resolve: @Sendable (_ result: CitySearchResult) async throws -> City

    /// Reverse-geocode a coordinate to a localised display name. Used to
    /// re-fetch saved-city names when the user picks a new language —
    /// MapKit serves names in the device's current preferred language.
    public var localizedName: @Sendable (_ coordinate: CLLocationCoordinate2D) async -> String?
}

extension SearchClient: DependencyKey {
    public static var liveValue: SearchClient {
        #if canImport(MapKit)
        let runner = MapKitSearchRunner()
        return SearchClient(
            autocomplete: { query in runner.autocomplete(query: query) },
            resolve: { result in try await runner.resolve(result: result) },
            localizedName: { coordinate in await runner.localizedName(coordinate: coordinate) }
        )
        #else
        return SearchClient(
            autocomplete: { _ in .never },
            resolve: { _ in throw SearchClientError.unsupportedPlatform },
            localizedName: { _ in nil }
        )
        #endif
    }

    public static let previewValue = SearchClient(
        autocomplete: { query in
            AsyncStream { continuation in
                let mock = [
                    CitySearchResult(id: "shanghai", title: "Shanghai", subtitle: "China"),
                    CitySearchResult(id: "tokyo", title: "Tokyo", subtitle: "Japan"),
                    CitySearchResult(id: "newyork", title: "New York", subtitle: "United States")
                ].filter { query.isEmpty || $0.title.localizedCaseInsensitiveContains(query) }
                continuation.yield(mock)
                continuation.finish()
            }
        },
        resolve: { _ in .preview },
        localizedName: { _ in nil }
    )

    public static let testValue = SearchClient()
}

public extension DependencyValues {
    var searchClient: SearchClient {
        get { self[SearchClient.self] }
        set { self[SearchClient.self] = newValue }
    }
}

public enum SearchClientError: Error, Sendable {
    case unsupportedPlatform
    case noResult
}

#if canImport(MapKit)
private final class MapKitSearchRunner: NSObject, @unchecked Sendable {
    private let lock = NSLock()
    private var continuations: [UUID: AsyncStream<[CitySearchResult]>.Continuation] = [:]
    private var completers: [UUID: Completer] = [:]

    func autocomplete(query: String) -> AsyncStream<[CitySearchResult]> {
        let id = UUID()
        return AsyncStream { continuation in
            let completer = Completer(query: query) { results in
                continuation.yield(results)
            }
            self.lock.lock()
            self.completers[id] = completer
            self.continuations[id] = continuation
            self.lock.unlock()

            continuation.onTermination = { [weak self] _ in
                self?.lock.lock()
                self?.completers[id] = nil
                self?.continuations[id] = nil
                self?.lock.unlock()
            }
        }
    }

    func resolve(result: CitySearchResult) async throws -> City {
        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = "\(result.title), \(result.subtitle)"
        request.resultTypes = [.address, .pointOfInterest]
        let search = MKLocalSearch(request: request)
        let response = try await search.start()
        guard let item = response.mapItems.first else {
            throw SearchClientError.noResult
        }
        let location = item.location
        let coord = location.coordinate
        // Reverse-geocode for region / country / timeZone hints. iOS 26
        // deprecates `CLGeocoder.reverseGeocodeLocation` in favour of
        // MKReverseGeocodingRequest; that path doesn't expose
        // administrativeArea / country on MKAddress (only `fullAddress` /
        // `shortAddress`). Until MapKit grows the structured surface we
        // ship `nil` for those — City already treats them as optional.
        let timeZone = await timeZone(for: location)
        return City(
            name: item.name ?? result.title,
            region: nil,
            country: nil,
            latitude: coord.latitude,
            longitude: coord.longitude,
            timeZoneIdentifier: timeZone?.identifier
        )
    }

    /// Resolve the time zone at the requested location via the iOS 26
    /// MKReverseGeocodingRequest path. Returns nil on failure (callers
    /// fall back to the device-local time zone).
    private func timeZone(for location: CLLocation) async -> TimeZone? {
        guard let request = MKReverseGeocodingRequest(location: location) else {
            return nil
        }
        do {
            let mapItems = try await request.mapItems
            return mapItems.first?.timeZone
        } catch {
            return nil
        }
    }

    /// Pull a localised place name for the requested coordinate via
    /// MKReverseGeocodingRequest. MapKit returns names in the device's
    /// current preferred language (read from `AppleLanguages`), so the
    /// result tracks whichever language the user has just picked in
    /// Settings. Returns nil on failure or when the response is empty.
    func localizedName(coordinate: CLLocationCoordinate2D) async -> String? {
        let location = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
        guard let request = MKReverseGeocodingRequest(location: location) else { return nil }
        do {
            let mapItems = try await request.mapItems
            return mapItems.first?.name
        } catch {
            return nil
        }
    }
}

private final class Completer: NSObject, MKLocalSearchCompleterDelegate, @unchecked Sendable {
    private let completer: MKLocalSearchCompleter
    private let onUpdate: ([CitySearchResult]) -> Void

    init(query: String, onUpdate: @escaping ([CitySearchResult]) -> Void) {
        // MKLocalSearchCompleter pins its delegate callbacks to the run loop of
        // the thread that initialised it (same convention as CLLocationManager —
        // see LocationClient.swift). TCA `.run` effects execute on a background
        // TaskExecutor with no run loop, so a completer constructed there would
        // silently never call `completerDidUpdateResults` and the autocomplete
        // AsyncStream would never yield.
        self.onUpdate = onUpdate
        if Thread.isMainThread {
            self.completer = MKLocalSearchCompleter()
        } else {
            self.completer = DispatchQueue.main.sync { MKLocalSearchCompleter() }
        }
        super.init()
        let bind = { [unowned self] in
            self.completer.delegate = self
            self.completer.resultTypes = [.address]
            self.completer.queryFragment = query
        }
        if Thread.isMainThread {
            bind()
        } else {
            DispatchQueue.main.sync(execute: bind)
        }
    }

    func completerDidUpdateResults(_ completer: MKLocalSearchCompleter) {
        let results = completer.results.map {
            CitySearchResult(id: $0.title + "|" + $0.subtitle, title: $0.title, subtitle: $0.subtitle)
        }
        onUpdate(results)
    }

    func completer(_ completer: MKLocalSearchCompleter, didFailWithError error: Error) {
        onUpdate([])
    }
}
#endif
