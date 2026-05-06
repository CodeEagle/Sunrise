import Foundation
import ComposableArchitecture
import SunriseCore
import TodayFeature
import ForecastFeature
import CharacterFeature
import ProfileFeature
import CityFeature

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
        public var cityList = CityListReducer.State()
        public var isPresentingCityList = false

        public init() {}
    }

    public enum Action: Sendable {
        case appLaunched
        case tabSelected(RootTab)
        case presentCityList
        case dismissCityList
        case today(TodayReducer.Action)
        case forecast(ForecastReducer.Action)
        case character(CharacterReducer.Action)
        case profile(ProfileReducer.Action)
        case cityList(CityListReducer.Action)
    }

    public init() {}

    public var body: some ReducerOf<Self> {
        Scope(state: \.today, action: \.today) { TodayReducer() }
        Scope(state: \.forecast, action: \.forecast) { ForecastReducer() }
        Scope(state: \.character, action: \.character) { CharacterReducer() }
        Scope(state: \.profile, action: \.profile) { ProfileReducer() }
        Scope(state: \.cityList, action: \.cityList) { CityListReducer() }

        Reduce { state, action in
            switch action {
            case .appLaunched:
                return .send(.cityList(.onAppear))

            case let .tabSelected(tab):
                state.selectedTab = tab
                return .none

            case .presentCityList:
                state.isPresentingCityList = true
                return .none

            case .dismissCityList:
                state.isPresentingCityList = false
                return .none

            case let .cityList(.delegate(.selected(city))):
                state.isPresentingCityList = false
                return .send(.today(.citySelected(city)))

            case let .cityList(.citiesLoaded(cities)):
                guard state.today.selectedCity == nil else { return .none }
                if let first = cities.first {
                    return .send(.today(.citySelected(first)))
                }
                return .send(.today(.useCurrentLocationTapped))

            case let .today(.weatherResponse(.success(snapshot))):
                state.forecast.snapshot = snapshot
                state.character.condition = snapshot.current.condition
                return .none

            case let .today(.settingsLoaded(settings)):
                state.forecast.settings = settings
                state.profile.settings = settings
                return .none

            case .today, .forecast, .character, .profile, .cityList:
                return .none
            }
        }
    }
}
