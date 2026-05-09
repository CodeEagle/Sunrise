import Foundation
import ComposableArchitecture
import SunriseCore

/// Backs the weather-history calendar pushed from the Forecast tab.
///
/// Tries WeatherKit's `fetchHistoricalDaily` first, then merges in any
/// locally cached entries (`PersistenceClient.loadHistoricalRange`)
/// the Today tab has accumulated over previous launches. The local
/// cache is the safety net: WeatherKit's historical query 400s in our
/// account setup, so the cache may end up being the only data we
/// actually display.
@Reducer
public struct CalendarReducer: Sendable {
    /// WeatherKit historical accepts ~14 days back. The fetched range
    /// `[startDate, endDate)` is half-open; the local-cache lookup uses
    /// the same window so the merge stays consistent.
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
        case historicalResponse([DailyForecast], remoteError: String?)
    }

    @Dependency(\.weatherClient) var weatherClient
    @Dependency(\.persistenceClient) var persistenceClient
    @Dependency(\.date) var date

    public init() {}

    public var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .onAppear:
                guard let city = state.city, !state.isLoading else { return .none }
                state.isLoading = true
                state.error = nil
                // WeatherKit's historical query rejects an `endDate` of
                // today's UTC midnight with a 400 — the JWT issuer treats
                // "today" as not-yet-historical even though the timestamp
                // is technically past. End at yesterday's UTC midnight
                // and trail back `lookbackDays` from there.
                var calendar = Calendar(identifier: .gregorian)
                calendar.timeZone = TimeZone(identifier: "UTC") ?? .gmt
                let now = date.now
                let startOfTodayUTC = calendar.startOfDay(for: now)
                guard let endDate = calendar.date(byAdding: .day, value: -1, to: startOfTodayUTC),
                      let startDate = calendar.date(byAdding: .day, value: -Self.lookbackDays, to: endDate) else {
                    state.isLoading = false
                    return .none
                }
                let coordinate = city.coordinate
                let cityID = city.id
                return .run { send in
                    // Run the remote fetch and the local cache load in
                    // parallel; merge results favouring remote when both
                    // cover the same date.
                    async let remote: [DailyForecast]? = {
                        do {
                            return try await weatherClient.fetchHistoricalDaily(coordinate, startDate, endDate)
                        } catch {
                            return nil
                        }
                    }()
                    async let cached = persistenceClient.loadHistoricalRange(cityID, startDate, endDate)
                    let remoteResult = await remote
                    let cachedResult = await cached
                    let merged = mergeByDay(remote: remoteResult ?? [], cached: cachedResult)
                    let remoteFailureMessage = remoteResult == nil
                        ? String(localized: "calendar.remote_unavailable",
                                 defaultValue: "WeatherKit historical unavailable — showing locally cached days only.")
                        : nil
                    await send(.historicalResponse(merged, remoteError: remoteFailureMessage))
                }

            case let .selectDate(date):
                state.selectedDate = date
                return .none

            case let .historicalResponse(dailies, remoteError):
                state.isLoading = false
                state.dailies = dailies.sorted { $0.date > $1.date }
                state.selectedDate = state.dailies.first?.date
                state.error = state.dailies.isEmpty ? remoteError : nil
                return .none
            }
        }
    }
}

/// Combine remote daily forecasts with the locally cached set. Entries
/// are deduped by start-of-day UTC; the remote value wins when both
/// sources cover the same date (WeatherKit's record is closer to the
/// actual observation than the daily-forecast snapshot we cache from
/// the Today tab).
private func mergeByDay(remote: [DailyForecast], cached: [DailyForecast]) -> [DailyForecast] {
    var calendar = Calendar(identifier: .gregorian)
    calendar.timeZone = TimeZone(identifier: "UTC") ?? .gmt
    var byDay: [Date: DailyForecast] = [:]
    for entry in cached {
        byDay[calendar.startOfDay(for: entry.date)] = entry
    }
    for entry in remote {
        byDay[calendar.startOfDay(for: entry.date)] = entry
    }
    return Array(byDay.values)
}
