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
}

extension SearchClient: DependencyKey {
    public static var liveValue: SearchClient {
        #if canImport(MapKit)
        let runner = MapKitSearchRunner()
        return SearchClient(
            autocomplete: { query in runner.autocomplete(query: query) },
            resolve: { result in try await runner.resolve(result: result) }
        )
        #else
        return SearchClient(
            autocomplete: { _ in .never },
            resolve: { _ in throw SearchClientError.unsupportedPlatform }
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
        resolve: { _ in .preview }
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
        // MKMapItem.placemark was deprecated in iOS 26. The replacement
        // (`address` / `addressRepresentations`) only exposes preformatted
        // strings, not the structured `administrativeArea` / `country` /
        // `timeZone` we need. Reverse-geocode the location instead, which is
        // how Apple's own samples now populate CLPlacemark fields.
        let placemark = (try? await CLGeocoder().reverseGeocodeLocation(location))?.first
        return City(
            name: item.name ?? result.title,
            region: placemark?.administrativeArea,
            country: placemark?.country,
            latitude: coord.latitude,
            longitude: coord.longitude,
            timeZoneIdentifier: placemark?.timeZone?.identifier
        )
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
