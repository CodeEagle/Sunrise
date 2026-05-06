import XCTest
import ComposableArchitecture
@testable import TodayFeature
import SunriseCore

@MainActor
final class TodayReducerTests: XCTestCase {
    func testWeatherResponseSuccess() async {
        let store = TestStore(initialState: TodayReducer.State()) {
            TodayReducer()
        }

        await store.send(.weatherResponse(.success(.preview))) {
            $0.snapshot = .preview
            $0.isLoading = false
            $0.error = nil
        }
    }

    func testCitySelectionTriggersFetch() async {
        let snapshot = WeatherSnapshot.preview
        let city = City.preview

        let store = TestStore(initialState: TodayReducer.State()) {
            TodayReducer()
        } withDependencies: {
            $0.weatherClient.fetch = { @Sendable _ in snapshot }
        }

        await store.send(.citySelected(city)) {
            $0.selectedCity = city
        }

        await store.receive(\.weatherResponse.success) {
            $0.snapshot = snapshot
        }
    }
}
