import Foundation
import ComposableArchitecture
import SunriseCore

/// Backs the weather-history calendar pushed from the Forecast tab.
///
/// **WeatherKit doesn't ship a historical observations API** — only
/// current + 10-day forecast. `WeatherQuery.daily(startDate:endDate:)`
/// is for narrowing the future window; calling it with past dates
/// returns HTTP 400 from the JWT issuer. So the entire calendar
/// surface runs off a local rolling history that the Today tab fills
/// in opportunistically (`PersistenceClient.recordHistoricalDay`)
/// every time the user fetches weather.
///
/// First-time empty state explains "open Weather a few times to fill
/// the calendar in"; once at least one Today fetch has landed for a
/// city, the calendar starts populating.
@Reducer
public struct CalendarReducer: Sendable {
    /// Display-window cap. The local cache itself retains ~35 days
    /// (see PersistenceClient) but we only render the most recent
    /// 14 to keep the list scannable.
    public static let lookbackDays = 14

    @ObservableState
    public struct State: Equatable, Sendable {
        public var city: City?
        public var settings: UserSettings = .default
        public var dailies: [DailyForecast] = []
        public var selectedDate: Date?
        public var isLoading: Bool = false

        public init(
            city: City? = nil,
            settings: UserSettings = .default,
            dailies: [DailyForecast] = [],
            selectedDate: Date? = nil,
            isLoading: Bool = false
        ) {
            self.city = city
            self.settings = settings
            self.dailies = dailies
            self.selectedDate = selectedDate
            self.isLoading = isLoading
        }
    }

    public enum Action: Sendable {
        case onAppear
        case selectDate(Date?)
        case historyLoaded([DailyForecast])
    }

    @Dependency(\.persistenceClient) var persistenceClient
    @Dependency(\.date) var date

    public init() {}

    public var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .onAppear:
                guard let city = state.city, !state.isLoading else { return .none }
                state.isLoading = true
                var calendar = Calendar(identifier: .gregorian)
                calendar.timeZone = TimeZone(identifier: "UTC") ?? .gmt
                let now = date.now
                let startOfTodayUTC = calendar.startOfDay(for: now)
                guard let endDate = calendar.date(byAdding: .day, value: -1, to: startOfTodayUTC),
                      let startDate = calendar.date(byAdding: .day, value: -Self.lookbackDays, to: endDate) else {
                    state.isLoading = false
                    return .none
                }
                let cityID = city.id
                return .run { send in
                    let entries = await persistenceClient.loadHistoricalRange(cityID, startDate, endDate)
                    await send(.historyLoaded(entries))
                }

            case let .selectDate(date):
                state.selectedDate = date
                return .none

            case let .historyLoaded(dailies):
                state.isLoading = false
                state.dailies = dailies.sorted { $0.date > $1.date }
                state.selectedDate = state.dailies.first?.date
                return .none
            }
        }
    }
}
