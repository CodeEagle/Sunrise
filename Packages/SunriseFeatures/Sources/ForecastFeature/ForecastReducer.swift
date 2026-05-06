import Foundation
import ComposableArchitecture
import SunriseCore

@Reducer
public struct ForecastReducer: Sendable {
    @ObservableState
    public struct State: Equatable, Sendable {
        public var snapshot: WeatherSnapshot?
        public var settings: UserSettings = .default
        public init(snapshot: WeatherSnapshot? = nil, settings: UserSettings = .default) {
            self.snapshot = snapshot
            self.settings = settings
        }
    }

    public enum Action: Sendable {
        case snapshotUpdated(WeatherSnapshot?)
        case settingsUpdated(UserSettings)
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
            }
        }
    }
}
