import Foundation
import ComposableArchitecture
import SunriseCore

@Reducer
public struct CityListReducer: Sendable {
    @ObservableState
    public struct State: Equatable, Sendable {
        public var cities: [City] = []
        public var selectedCityID: City.ID?
        public var search = CitySearchReducer.State()
        public var isPresentingSearch = false
        /// Snapshot of the last `AppLanguage` we saw at language-change
        /// time. RootReducer compares the incoming settings' language
        /// against this to decide whether `.regeocodeAllCities` should
        /// fire — only when the language actually flipped, not on every
        /// settings save (units changes, etc.).
        public var lastSeenLanguage: AppLanguage = .system

        public init(
            cities: [City] = [],
            selectedCityID: City.ID? = nil,
            search: CitySearchReducer.State = .init(),
            isPresentingSearch: Bool = false,
            lastSeenLanguage: AppLanguage = .system
        ) {
            self.cities = cities
            self.selectedCityID = selectedCityID
            self.search = search
            self.isPresentingSearch = isPresentingSearch
            self.lastSeenLanguage = lastSeenLanguage
        }
    }

    public enum Action: Sendable {
        case onAppear
        case citiesLoaded([City])
        case addCityTapped
        case dismissSearch
        case search(CitySearchReducer.Action)
        case selectCity(City.ID)
        case deleteCity(City.ID)
        case moveCity(IndexSet, Int)
        case persistRequested
        /// Re-resolve every saved city's display name in the device's
        /// current preferred language. Triggered by RootReducer when the
        /// user picks a new language in Settings.
        case regeocodeAllCities
        case cityNameRefreshed(City.ID, String)
        case delegate(Delegate)

        public enum Delegate: Sendable, Equatable {
            case selected(City)
        }
    }

    @Dependency(\.persistenceClient) var persistence
    @Dependency(\.searchClient) var searchClient

    public init() {}

    public var body: some ReducerOf<Self> {
        Scope(state: \.search, action: \.search) {
            CitySearchReducer()
        }

        Reduce { state, action in
            switch action {
            case .onAppear:
                return .run { send in
                    let cities = (try? await persistence.loadCities()) ?? []
                    await send(.citiesLoaded(cities))
                }

            case let .citiesLoaded(cities):
                state.cities = cities
                if state.selectedCityID == nil {
                    state.selectedCityID = cities.first?.id
                }
                return .none

            case .addCityTapped:
                state.isPresentingSearch = true
                state.search = .init()
                return .none

            case .dismissSearch:
                state.isPresentingSearch = false
                return .none

            case let .search(.delegate(.cityResolved(city))):
                if !state.cities.contains(where: { $0.name == city.name && $0.country == city.country }) {
                    state.cities.append(city)
                }
                state.isPresentingSearch = false
                state.selectedCityID = city.id
                return .merge(
                    persistCities(state.cities),
                    .send(.delegate(.selected(city)))
                )

            case .search:
                return .none

            case let .selectCity(id):
                state.selectedCityID = id
                guard let city = state.cities.first(where: { $0.id == id }) else { return .none }
                return .send(.delegate(.selected(city)))

            case let .deleteCity(id):
                state.cities.removeAll { $0.id == id }
                if state.selectedCityID == id {
                    state.selectedCityID = state.cities.first?.id
                }
                return persistCities(state.cities)

            case let .moveCity(indices, destination):
                state.cities.move(fromOffsets: indices, toOffset: destination)
                return persistCities(state.cities)

            case .persistRequested:
                return persistCities(state.cities)

            case .regeocodeAllCities:
                let cities = state.cities.filter { $0.name != "Current Location" }
                guard !cities.isEmpty else { return .none }
                let client = searchClient
                return .run { send in
                    for city in cities {
                        if let updated = await client.localizedName(city.coordinate),
                           !updated.isEmpty,
                           updated != city.name {
                            await send(.cityNameRefreshed(city.id, updated))
                        }
                    }
                }

            case let .cityNameRefreshed(id, name):
                guard let index = state.cities.firstIndex(where: { $0.id == id }) else {
                    return .none
                }
                let original = state.cities[index]
                state.cities[index] = City(
                    id: original.id,
                    name: name,
                    region: original.region,
                    country: original.country,
                    latitude: original.latitude,
                    longitude: original.longitude,
                    timeZoneIdentifier: original.timeZoneIdentifier
                )
                return persistCities(state.cities)

            case .delegate:
                return .none
            }
        }
    }

    private func persistCities(_ cities: [City]) -> Effect<Action> {
        .run { _ in try? await persistence.saveCities(cities: cities) }
    }
}
