import Foundation
import ComposableArchitecture
import SunriseCore

/// Drives the Sunny tab. Holds enough of the current weather context
/// to compose a dynamic speech-bubble line and pick a portrait variant
/// keyed by (condition, dayPeriod) — RootReducer pushes these in
/// whenever the selected city's snapshot changes.
@Reducer
public struct CharacterReducer: Sendable {
    @ObservableState
    public struct State: Equatable, Sendable {
        public var condition: WeatherCondition = .clear
        public var dayPeriod: DayPeriod = .day
        public var cityName: String?
        public var temperature: Temperature?
        public var sunrise: Date?
        public var sunset: Date?
        public var alerts: [WeatherAlert] = []

        public init(
            condition: WeatherCondition = .clear,
            dayPeriod: DayPeriod = .day,
            cityName: String? = nil,
            temperature: Temperature? = nil,
            sunrise: Date? = nil,
            sunset: Date? = nil,
            alerts: [WeatherAlert] = []
        ) {
            self.condition = condition
            self.dayPeriod = dayPeriod
            self.cityName = cityName
            self.temperature = temperature
            self.sunrise = sunrise
            self.sunset = sunset
            self.alerts = alerts
        }
    }

    public enum Action: Sendable {
        case conditionUpdated(WeatherCondition)
        /// Syncs the full set of fields needed to render the bubble +
        /// portrait variant. Called from the parent reducer whenever the
        /// selected page's snapshot lands.
        case contextUpdated(
            condition: WeatherCondition,
            dayPeriod: DayPeriod,
            cityName: String?,
            temperature: Temperature?,
            sunrise: Date?,
            sunset: Date?,
            alerts: [WeatherAlert]
        )
    }

    public init() {}

    public var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case let .conditionUpdated(condition):
                state.condition = condition
                return .none

            case let .contextUpdated(condition, dayPeriod, cityName, temperature, sunrise, sunset, alerts):
                state.condition = condition
                state.dayPeriod = dayPeriod
                state.cityName = cityName
                state.temperature = temperature
                state.sunrise = sunrise
                state.sunset = sunset
                state.alerts = alerts
                return .none
            }
        }
    }
}
