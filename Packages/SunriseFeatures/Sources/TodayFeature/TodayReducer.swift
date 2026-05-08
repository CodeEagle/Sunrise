import Foundation
import ComposableArchitecture
import SunriseCore
#if canImport(WidgetKit)
import WidgetKit
#endif

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
        /// Surfaced by the error-state retry button. The first
        /// `useCurrentLocationTapped` effect is gone by the time the user
        /// flips Settings → Privacy → Location Services back on, so without
        /// a manual re-trigger the screen stays stuck on the error message.
        case retryTapped
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
                return .run { send in
                    let settings = (try? await persistenceClient.loadSettings()) ?? .default
                    await send(.settingsLoaded(settings))
                }

            case .refreshTapped:
                return refresh(for: state.selectedCity)

            case .retryTapped:
                state.error = nil
                state.isLoading = true
                if let city = state.selectedCity {
                    return refresh(for: city)
                } else {
                    return .send(.useCurrentLocationTapped)
                }

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
                let city = state.selectedCity
                return .run { _ in
                    if let city {
                        SharedStorage.saveSnapshot(snapshot, city: city)
                    }
                    #if canImport(WidgetKit)
                    WidgetCenter.shared.reloadAllTimelines()
                    #endif
                }

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
