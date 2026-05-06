import Foundation
import ComposableArchitecture
import SunriseCore

@Reducer
public struct TodayReducer: Sendable {
    @ObservableState
    public struct State: Equatable, Sendable {
        public var selectedCity: City?
        public var snapshot: WeatherSnapshot?
        public var isLoading: Bool = false
        public var error: String?
        public var settings: UserSettings = .default

        public init(
            selectedCity: City? = nil,
            snapshot: WeatherSnapshot? = nil,
            isLoading: Bool = false,
            error: String? = nil,
            settings: UserSettings = .default
        ) {
            self.selectedCity = selectedCity
            self.snapshot = snapshot
            self.isLoading = isLoading
            self.error = error
            self.settings = settings
        }
    }

    public enum Action: Sendable {
        case onAppear
        case refreshTapped
        case useCurrentLocationTapped
        case citySelected(City)
        case weatherResponse(Result<WeatherSnapshot, FetchError>)
        case currentLocationResolved(Result<City, FetchError>)
        case settingsLoaded(UserSettings)
    }

    public struct FetchError: Error, Equatable, Sendable {
        public let message: String
        public init(_ error: any Error) {
            self.message = String(describing: error)
        }
    }

    @Dependency(\.weatherClient) var weatherClient
    @Dependency(\.locationClient) var locationClient
    @Dependency(\.persistenceClient) var persistenceClient

    public init() {}

    public var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .onAppear:
                return .merge(
                    .run { send in
                        let settings = (try? await persistenceClient.loadSettings()) ?? .default
                        await send(.settingsLoaded(settings))
                    },
                    state.selectedCity == nil
                        ? .send(.useCurrentLocationTapped)
                        : refresh(for: state.selectedCity)
                )

            case .refreshTapped:
                return refresh(for: state.selectedCity)

            case .useCurrentLocationTapped:
                state.isLoading = true
                state.error = nil
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

            case let .citySelected(city):
                state.selectedCity = city
                return refresh(for: city)

            case let .currentLocationResolved(.success(city)):
                state.selectedCity = city
                return refresh(for: city)

            case let .currentLocationResolved(.failure(error)):
                state.isLoading = false
                state.error = error.message
                return .none

            case let .weatherResponse(.success(snapshot)):
                state.isLoading = false
                state.snapshot = snapshot
                state.error = nil
                return .none

            case let .weatherResponse(.failure(error)):
                state.isLoading = false
                state.error = error.message
                return .none

            case let .settingsLoaded(settings):
                state.settings = settings
                return .none
            }
        }
    }

    private func refresh(for city: City?) -> Effect<Action> {
        guard let city else { return .none }
        return .run { send in
            do {
                let snapshot = try await weatherClient.fetch(coordinate: city.coordinate)
                await send(.weatherResponse(.success(snapshot)))
            } catch {
                await send(.weatherResponse(.failure(FetchError(error))))
            }
        }
    }
}
