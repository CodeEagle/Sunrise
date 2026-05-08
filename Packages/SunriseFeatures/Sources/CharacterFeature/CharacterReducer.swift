import Foundation
import ComposableArchitecture
import SunriseCore

@Reducer
public struct CharacterReducer: Sendable {
    @ObservableState
    public struct State: Equatable, Sendable {
        public var condition: WeatherCondition = .clear

        public init(condition: WeatherCondition = .clear) {
            self.condition = condition
        }
    }

    public enum Action: Sendable {
        case conditionUpdated(WeatherCondition)
    }

    public init() {}

    public var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case let .conditionUpdated(condition):
                state.condition = condition
                return .none
            }
        }
    }
}
