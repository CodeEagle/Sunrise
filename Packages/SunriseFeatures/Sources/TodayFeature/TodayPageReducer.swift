import Foundation
import ComposableArchitecture
import SunriseCore

/// One city's view in the Today pager. Owns its own snapshot, loading and
/// error state so each page in the swipe stack tracks its fetch independently
/// — matching the system Weather app where the active page can finish loading
/// while the user is already mid-swipe to the next one.
@Reducer
public struct TodayPageReducer: Sendable {
    @ObservableState
    public struct State: Equatable, Identifiable, Sendable {
        public var city: City
        public var snapshot: WeatherSnapshot?
        public var isLoading: Bool
        public var error: String?
        public var settings: UserSettings

        public var id: City.ID { city.id }

        public init(
            city: City,
            snapshot: WeatherSnapshot? = nil,
            isLoading: Bool = false,
            error: String? = nil,
            settings: UserSettings = .default
        ) {
            self.city = city
            self.snapshot = snapshot
            self.isLoading = isLoading
            self.error = error
            self.settings = settings
        }
    }

    public enum Action: Sendable {
        case onAppear
        case refreshTapped
        case retryTapped
        case weatherResponse(Result<WeatherSnapshot, FetchError>)
    }

    public struct FetchError: Error, Equatable, Sendable {
        public let message: String
        public init(_ error: any Error) {
            self.message = String(describing: error)
        }
    }

    @Dependency(\.weatherClient) var weatherClient
    @Dependency(\.persistenceClient) var persistenceClient

    public init() {}

    public var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .onAppear:
                guard state.snapshot == nil, !state.isLoading else { return .none }
                state.isLoading = true
                state.error = nil
                return refresh(for: state.city)

            case .refreshTapped, .retryTapped:
                state.error = nil
                state.isLoading = true
                return refresh(for: state.city)

            case let .weatherResponse(.success(snapshot)):
                state.isLoading = false
                state.snapshot = snapshot
                state.error = nil
                // Roll today's daily forecast into the local history cache
                // so the Calendar can show *something* even when the
                // WeatherKit historical query 400s. Over time this fills
                // in a real running record of what the user saw each day.
                let cityID = state.city.id
                let today = snapshot.daily.first
                return .run { _ in
                    if let today {
                        await persistenceClient.recordHistoricalDay(cityID, today)
                    }
                }

            case let .weatherResponse(.failure(error)):
                state.isLoading = false
                state.error = error.message
                return .none
            }
        }
    }

    private func refresh(for city: City) -> Effect<Action> {
        .run { send in
            do {
                let snapshot = try await weatherClient.fetch(coordinate: city.coordinate)
                await send(.weatherResponse(.success(snapshot)))
            } catch {
                await send(.weatherResponse(.failure(FetchError(error))))
            }
        }
    }
}
