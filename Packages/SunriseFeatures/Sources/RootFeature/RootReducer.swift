import Foundation
import ComposableArchitecture
import SunriseCore
import TodayFeature
import ForecastFeature
import CharacterFeature
import ProfileFeature

public enum RootTab: String, Sendable, CaseIterable {
    case today
    case forecast
    case character
    case profile
}

@Reducer
public struct RootReducer: Sendable {
    @ObservableState
    public struct State: Equatable, Sendable {
        public var selectedTab: RootTab = .today
        public var today = TodayReducer.State()
        public var forecast = ForecastReducer.State()
        public var character = CharacterReducer.State()
        public var profile = ProfileReducer.State()

        public init() {}
    }

    public enum Action: Sendable {
        case tabSelected(RootTab)
        case today(TodayReducer.Action)
        case forecast(ForecastReducer.Action)
        case character(CharacterReducer.Action)
        case profile(ProfileReducer.Action)
    }

    public init() {}

    public var body: some ReducerOf<Self> {
        Scope(state: \.today, action: \.today) { TodayReducer() }
        Scope(state: \.forecast, action: \.forecast) { ForecastReducer() }
        Scope(state: \.character, action: \.character) { CharacterReducer() }
        Scope(state: \.profile, action: \.profile) { ProfileReducer() }

        Reduce { state, action in
            switch action {
            case let .tabSelected(tab):
                state.selectedTab = tab
                return .none

            case let .today(.weatherResponse(.success(snapshot))):
                state.forecast.snapshot = snapshot
                state.character.condition = snapshot.current.condition
                return .none

            case let .today(.settingsLoaded(settings)):
                state.forecast.settings = settings
                state.profile.settings = settings
                return .none

            case .today, .forecast, .character, .profile:
                return .none
            }
        }
    }
}
