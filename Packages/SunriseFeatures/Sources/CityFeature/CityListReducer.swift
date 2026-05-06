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

        public init(
            cities: [City] = [],
            selectedCityID: City.ID? = nil,
            search: CitySearchReducer.State = .init(),
            isPresentingSearch: Bool = false
        ) {
            self.cities = cities
            self.selectedCityID = selectedCityID
            self.search = search
            self.isPresentingSearch = isPresentingSearch
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
        case delegate(Delegate)

        public enum Delegate: Sendable, Equatable {
            case selected(City)
        }
    }

    @Dependency(\.persistenceClient) var persistence

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

            case .delegate:
                return .none
            }
        }
    }

    private func persistCities(_ cities: [City]) -> Effect<Action> {
        .run { _ in try? await persistence.saveCities(cities: cities) }
    }
}
