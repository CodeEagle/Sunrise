import Foundation
import ComposableArchitecture
import SunriseCore

/// Backs the weather-history calendar pushed from the Forecast tab. Owns
/// the past-14-day daily forecast set fetched from
/// `WeatherClient.fetchHistoricalDaily(...)`.
///
/// WeatherKit only serves historical data within roughly the last 14 days,
/// so the calendar caps itself at that window; older dates are rendered
/// as disabled cells.
@Reducer
public struct CalendarReducer: Sendable {
    /// WeatherKit historical accepts ~14 days back. The fetched range
    /// `[startDate, endDate)` is half-open, so a 14-day window translates
    /// to `start = today - 14`, `end = today` (UTC midnights).
    public static let lookbackDays = 14

    @ObservableState
    public struct State: Equatable, Sendable {
        public var city: City?
        public var settings: UserSettings = .default
        public var dailies: [DailyForecast] = []
        public var selectedDate: Date?
        public var isLoading: Bool = false
        public var error: String?

        public init(
            city: City? = nil,
            settings: UserSettings = .default,
            dailies: [DailyForecast] = [],
            selectedDate: Date? = nil,
            isLoading: Bool = false,
            error: String? = nil
        ) {
            self.city = city
            self.settings = settings
            self.dailies = dailies
            self.selectedDate = selectedDate
            self.isLoading = isLoading
            self.error = error
        }
    }

    public enum Action: Sendable {
        case onAppear
        case selectDate(Date?)
        case historicalResponse(Result<[DailyForecast], FetchError>)
    }

    public struct FetchError: Error, Equatable, Sendable {
        public let message: String
        public init(_ error: any Error) {
            // Localized description carries the WeatherKit / network
            // failure text users can act on (e.g. "Unable to authenticate
            // — check signing"); String(describing:) just dumps the type
            // name and shows nothing meaningful in the empty-state cell.
            self.message = (error as NSError).localizedDescription
        }
    }

    @Dependency(\.weatherClient) var weatherClient
    @Dependency(\.date) var date

    public init() {}

    public var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .onAppear:
                guard let city = state.city, !state.isLoading else { return .none }
                state.isLoading = true
                state.error = nil
                // WeatherKit's historical range `[startDate, endDate)` is
                // half-open: end is exclusive, so use start of today (UTC)
                // as the end and start of (today - lookbackDays) as the
                // start to fetch exactly `lookbackDays` whole days. UTC
                // alignment is required — the JWT issuer rejects 400 when
                // timestamps don't land on whole-day UTC boundaries.
                var calendar = Calendar(identifier: .gregorian)
                calendar.timeZone = TimeZone(identifier: "UTC") ?? .gmt
                let now = date.now
                let endDate = calendar.startOfDay(for: now)
                guard let startDate = calendar.date(byAdding: .day, value: -Self.lookbackDays, to: endDate) else {
                    state.isLoading = false
                    return .none
                }
                let coordinate = city.coordinate
                return .run { send in
                    do {
                        let dailies = try await weatherClient.fetchHistoricalDaily(coordinate, startDate, endDate)
                        await send(.historicalResponse(.success(dailies)))
                    } catch {
                        await send(.historicalResponse(.failure(FetchError(error))))
                    }
                }

            case let .selectDate(date):
                state.selectedDate = date
                return .none

            case let .historicalResponse(.success(dailies)):
                state.isLoading = false
                state.dailies = dailies.sorted { $0.date > $1.date }
                state.selectedDate = state.dailies.first?.date
                return .none

            case let .historicalResponse(.failure(error)):
                state.isLoading = false
                state.error = error.message
                return .none
            }
        }
    }
}
