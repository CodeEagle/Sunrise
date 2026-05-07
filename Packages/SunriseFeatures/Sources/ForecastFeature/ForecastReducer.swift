import Foundation
import ComposableArchitecture
import SunriseCore

@Reducer
public struct ForecastReducer: Sendable {
    @ObservableState
    public struct State: Equatable, Sendable {
        public var snapshot: WeatherSnapshot?
        public var settings: UserSettings = .default
        public var selectedCity: City?
        public init(snapshot: WeatherSnapshot? = nil, settings: UserSettings = .default, selectedCity: City? = nil) {
            self.snapshot = snapshot
            self.settings = settings
            self.selectedCity = selectedCity
        }
    }

    public enum Action: Sendable {
        case snapshotUpdated(WeatherSnapshot?)
        case settingsUpdated(UserSettings)
        case citySelected(City?)
    }

    public init() {}

    public var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case let .snapshotUpdated(snapshot):
                state.snapshot = snapshot
                return .none
            case let .settingsUpdated(settings):
                state.settings = settings
                return .none
            case let .citySelected(city):
                state.selectedCity = city
                return .none
            }
        }
    }
}
