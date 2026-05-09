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
/// in opportunistically (`PersistenceClient.recordHistoricalDay` +
/// `recordHistoricalHours`) every time the user fetches weather.
/// Entries are kept forever so users can scroll back through their
/// full personal history.
@Reducer
public struct CalendarReducer: Sendable {
    @ObservableState
    public struct State: Equatable, Sendable {
        public var city: City?
        public var settings: UserSettings = .default
        public var dailies: [DailyForecast] = []
        public var selectedDate: Date?
        /// Hourly entries cached for the currently-selected day, sorted
        /// ascending. The Today snapshot's hourly array is forward-
        /// looking from the moment of fetch, so the breakdown is
        /// usually partial — empty if the user only ever opened the
        /// app at the very end of that day.
        public var selectedHours: [HourlyForecast] = []
        public var isLoading: Bool = false

        public init(
            city: City? = nil,
            settings: UserSettings = .default,
            dailies: [DailyForecast] = [],
            selectedDate: Date? = nil,
            selectedHours: [HourlyForecast] = [],
            isLoading: Bool = false
        ) {
            self.city = city
            self.settings = settings
            self.dailies = dailies
            self.selectedDate = selectedDate
            self.selectedHours = selectedHours
            self.isLoading = isLoading
        }
    }

    public enum Action: Sendable {
        case onAppear
        case selectDate(Date?)
        case historyLoaded([DailyForecast])
        case hoursLoaded(Date, [HourlyForecast])
    }

    @Dependency(\.persistenceClient) var persistenceClient

    public init() {}

    public var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .onAppear:
                guard let city = state.city, !state.isLoading else { return .none }
                state.isLoading = true
                let cityID = city.id
                return .run { send in
                    let entries = await persistenceClient.loadAllHistorical(cityID)
                    await send(.historyLoaded(entries))
                }

            case let .selectDate(date):
                state.selectedDate = date
                state.selectedHours = []
                guard let date, let cityID = state.city?.id else { return .none }
                return .run { send in
                    let hours = await persistenceClient.loadHistoricalHours(cityID, date)
                    await send(.hoursLoaded(date, hours))
                }

            case let .historyLoaded(dailies):
                state.isLoading = false
                state.dailies = dailies.sorted { $0.date > $1.date }
                let firstDate = state.dailies.first?.date
                state.selectedDate = firstDate
                guard let firstDate, let cityID = state.city?.id else {
                    state.selectedHours = []
                    return .none
                }
                return .run { send in
                    let hours = await persistenceClient.loadHistoricalHours(cityID, firstDate)
                    await send(.hoursLoaded(firstDate, hours))
                }

            case let .hoursLoaded(date, hours):
                // Guard: user might have flipped to another day before
                // this load completed.
                guard let selected = state.selectedDate,
                      Calendar.utc.isDate(selected, inSameDayAs: date) else {
                    return .none
                }
                state.selectedHours = hours
                return .none
            }
        }
    }
}

private extension Calendar {
    static let utc: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "UTC") ?? .gmt
        return calendar
    }()
}
