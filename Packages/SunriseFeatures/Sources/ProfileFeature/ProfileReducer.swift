import Foundation
import ComposableArchitecture
import SunriseCore

@Reducer
public struct ProfileReducer: Sendable {
    @ObservableState
    public struct State: Equatable, Sendable {
        public var settings: UserSettings = .default
        public var managedCities: [City] = []
        public init(settings: UserSettings = .default, managedCities: [City] = []) {
            self.settings = settings
            self.managedCities = managedCities
        }
    }

    public enum Action: Sendable {
        case onAppear
        case settingsLoaded(UserSettings)
        case citiesLoaded([City])
        case temperatureUnitChanged(TemperatureUnit)
        case windUnitChanged(WindSpeedUnit)
        case notificationsToggled(Bool, dailyTitle: String, dailyBody: String)
    }

    @Dependency(\.persistenceClient) var persistence
    @Dependency(\.notificationsClient) var notifications

    public init() {}

    public var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .onAppear:
                return .run { send in
                    let settings = (try? await persistence.loadSettings()) ?? .default
                    let cities = (try? await persistence.loadCities()) ?? []
                    await send(.settingsLoaded(settings))
                    await send(.citiesLoaded(cities))
                }

            case let .settingsLoaded(settings):
                state.settings = settings
                return .none

            case let .citiesLoaded(cities):
                state.managedCities = cities
                return .none

            case let .temperatureUnitChanged(unit):
                state.settings.temperatureUnit = unit
                return persist(state.settings)

            case let .windUnitChanged(unit):
                state.settings.windSpeedUnit = unit
                return persist(state.settings)

            case let .notificationsToggled(enabled, title, body):
                state.settings.notificationsEnabled = enabled
                let scheduling: Effect<Action> = .run { _ in
                    if enabled {
                        _ = try? await notifications.requestAuthorization()
                        try? await notifications.scheduleDailyBriefing(hour: 8, minute: 0, title: title, body: body)
                    } else {
                        await notifications.cancelDailyBriefing()
                    }
                }
                return .merge(persist(state.settings), scheduling)
            }
        }
    }

    private func persist(_ settings: UserSettings) -> Effect<Action> {
        .run { _ in try? await persistence.saveSettings(settings: settings) }
    }
}
