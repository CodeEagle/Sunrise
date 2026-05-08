import Foundation
import ComposableArchitecture
import SunriseCore
#if canImport(WidgetKit)
import WidgetKit
#endif

/// The Today tab as a whole — a swipeable pager of city pages. Mirrors the
/// city list maintained by `CityFeature` (RootReducer brokers the sync), owns
/// the loaded `UserSettings`, and resolves the user's current location when
/// they have no saved cities yet.
///
/// Per-city state lives in `TodayPageReducer`; this reducer only orchestrates
/// selection, settings propagation and current-location bootstrap.
@Reducer
public struct TodayReducer: Sendable {
    @ObservableState
    public struct State: Equatable, Sendable {
        public var pages: IdentifiedArrayOf<TodayPageReducer.State>
        public var selectedCityID: City.ID?
        public var settings: UserSettings
        public var isResolvingLocation: Bool

        public var selectedPage: TodayPageReducer.State? {
            guard let id = selectedCityID else { return nil }
            return pages[id: id]
        }

        public init(
            pages: IdentifiedArrayOf<TodayPageReducer.State> = [],
            selectedCityID: City.ID? = nil,
            settings: UserSettings = .default,
            isResolvingLocation: Bool = false
        ) {
            self.pages = pages
            self.selectedCityID = selectedCityID
            self.settings = settings
            self.isResolvingLocation = isResolvingLocation
        }
    }

    public enum Action: Sendable {
        case onAppear
        case settingsLoaded(UserSettings)
        /// Pushed by the parent reducer whenever the canonical city list
        /// changes (loaded from disk, search resolved, deleted, reordered).
        case citiesUpdated(cities: [City], selectedID: City.ID?)
        case selectCity(City.ID)
        case useCurrentLocationTapped
        case currentLocationResolved(Result<City, FetchError>)
        case page(IdentifiedActionOf<TodayPageReducer>)
    }

    public struct FetchError: Error, Equatable, Sendable {
        public let message: String
        public init(_ error: any Error) {
            self.message = String(describing: error)
        }
    }

    @Dependency(\.locationClient) var locationClient
    @Dependency(\.persistenceClient) var persistenceClient

    public init() {}

    public var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .onAppear:
                return .run { send in
                    let settings = (try? await persistenceClient.loadSettings()) ?? .default
                    await send(.settingsLoaded(settings))
                }

            case let .settingsLoaded(settings):
                state.settings = settings
                for id in state.pages.ids {
                    state.pages[id: id]?.settings = settings
                }
                return .none

            case let .citiesUpdated(cities, selectedID):
                let existing = state.pages
                state.pages = IdentifiedArray(uniqueElements: cities.map { city in
                    if var page = existing[id: city.id] {
                        page.city = city
                        page.settings = state.settings
                        return page
                    } else {
                        return TodayPageReducer.State(city: city, settings: state.settings)
                    }
                })
                if let id = selectedID, state.pages[id: id] != nil {
                    state.selectedCityID = id
                } else {
                    state.selectedCityID = state.pages.ids.first
                }
                if state.pages.isEmpty, !state.isResolvingLocation {
                    return .send(.useCurrentLocationTapped)
                }
                if let id = state.selectedCityID {
                    // Re-emit selectCity so the parent reducer can mirror the
                    // (possibly cached) snapshot into forecast / character.
                    return .send(.selectCity(id))
                }
                return .none

            case let .selectCity(id):
                guard state.pages[id: id] != nil else { return .none }
                state.selectedCityID = id
                if let page = state.pages[id: id], page.snapshot == nil, !page.isLoading {
                    return .send(.page(.element(id: id, action: .onAppear)))
                }
                return .none

            case .useCurrentLocationTapped:
                state.isResolvingLocation = true
                return .run { send in
                    do {
                        let coordinate = try await locationClient.currentLocation()
                        let city = City(
                            name: "Current Location",
                            latitude: coordinate.latitude,
                            longitude: coordinate.longitude
                        )
                        await send(.currentLocationResolved(.success(city)))
                    } catch {
                        await send(.currentLocationResolved(.failure(FetchError(error))))
                    }
                }

            case let .currentLocationResolved(.success(city)):
                state.isResolvingLocation = false
                if state.pages[id: city.id] == nil {
                    state.pages.append(TodayPageReducer.State(city: city, settings: state.settings))
                }
                state.selectedCityID = city.id
                return .send(.page(.element(id: city.id, action: .onAppear)))

            case .currentLocationResolved(.failure):
                state.isResolvingLocation = false
                return .none

            case let .page(.element(id, .weatherResponse(.success(snapshot)))):
                // Mirror the selected page's snapshot into App-Group storage so
                // the widget keeps showing the city the user is actively
                // viewing. Off-screen page fetches don't disturb the widget.
                guard id == state.selectedCityID, let city = state.pages[id: id]?.city else {
                    return .none
                }
                return .run { _ in
                    SharedStorage.saveSnapshot(snapshot, city: city)
                    #if canImport(WidgetKit)
                    WidgetCenter.shared.reloadAllTimelines()
                    #endif
                }

            case .page:
                return .none
            }
        }
        .forEach(\.pages, action: \.page) {
            TodayPageReducer()
        }
    }
}
