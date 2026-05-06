import Foundation
import ComposableArchitecture
import SunriseCore

public enum CharacterMood: String, Codable, Sendable, CaseIterable {
    case happy, calm, tender, worried, excited, shy
}

@Reducer
public struct CharacterReducer: Sendable {
    @ObservableState
    public struct State: Equatable, Sendable {
        public var condition: WeatherCondition = .clear
        public var mood: CharacterMood = .happy
        public var sunshinePoints: Int = 0

        public init(condition: WeatherCondition = .clear, mood: CharacterMood = .happy, sunshinePoints: Int = 0) {
            self.condition = condition
            self.mood = mood
            self.sunshinePoints = sunshinePoints
        }
    }

    public enum Action: Sendable {
        case conditionUpdated(WeatherCondition)
        case moodSelected(CharacterMood)
        case awardSunshine(Int)
    }

    public init() {}

    public var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case let .conditionUpdated(condition):
                state.condition = condition
                return .none
            case let .moodSelected(mood):
                state.mood = mood
                return .none
            case let .awardSunshine(amount):
                state.sunshinePoints += amount
                return .none
            }
        }
    }
}
