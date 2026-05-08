import XCTest
import ComposableArchitecture
@testable import TodayFeature
import SunriseCore

@MainActor
final class TodayPageReducerTests: XCTestCase {
    func testWeatherResponseSuccess() async {
        let store = TestStore(initialState: TodayPageReducer.State(city: .preview)) {
            TodayPageReducer()
        }

        await store.send(.weatherResponse(.success(.preview))) {
            $0.snapshot = .preview
            $0.isLoading = false
            $0.error = nil
        }
    }

    func testOnAppearTriggersFetchWhenSnapshotMissing() async {
        let snapshot = WeatherSnapshot.preview

        let store = TestStore(initialState: TodayPageReducer.State(city: .preview)) {
            TodayPageReducer()
        } withDependencies: {
            $0.weatherClient.fetch = { @Sendable _ in snapshot }
        }

        await store.send(.onAppear) {
            $0.isLoading = true
            $0.error = nil
        }

        await store.receive(\.weatherResponse.success) {
            $0.isLoading = false
            $0.snapshot = snapshot
        }
    }
}

@MainActor
final class TodayReducerTests: XCTestCase {
    func testCitiesUpdatedPopulatesPagesAndFetches() async {
        let snapshot = WeatherSnapshot.preview
        let city = City.preview

        let store = TestStore(initialState: TodayReducer.State()) {
            TodayReducer()
        } withDependencies: {
            $0.weatherClient.fetch = { @Sendable _ in snapshot }
        }

        await store.send(.citiesUpdated(cities: [city], selectedID: city.id)) {
            $0.pages = [TodayPageReducer.State(city: city, settings: .default)]
            $0.selectedCityID = city.id
        }

        // citiesUpdated re-emits selectCity so the parent reducer can mirror
        // the cached snapshot into forecast / character.
        await store.receive(\.selectCity)

        // The selectCity then forwards .onAppear to the page, kicking the
        // weather fetch effect.
        await store.receive(\.page) {
            $0.pages[id: city.id]?.isLoading = true
        }
        await store.receive(\.page) {
            $0.pages[id: city.id]?.isLoading = false
            $0.pages[id: city.id]?.snapshot = snapshot
        }
    }

    func testSelectCityWithoutSnapshotTriggersFetch() async {
        let snapshot = WeatherSnapshot.preview
        let cityA = City.preview
        let cityB = City(
            name: "Tokyo",
            region: nil,
            country: "JP",
            latitude: 35.68,
            longitude: 139.76
        )

        let initialPages: IdentifiedArrayOf<TodayPageReducer.State> = [
            .init(city: cityA, snapshot: snapshot, settings: .default),
            .init(city: cityB, settings: .default)
        ]

        let store = TestStore(
            initialState: TodayReducer.State(
                pages: initialPages,
                selectedCityID: cityA.id
            )
        ) {
            TodayReducer()
        } withDependencies: {
            $0.weatherClient.fetch = { @Sendable _ in snapshot }
        }

        await store.send(.selectCity(cityB.id)) {
            $0.selectedCityID = cityB.id
        }

        await store.receive(\.page) {
            $0.pages[id: cityB.id]?.isLoading = true
        }
        await store.receive(\.page) {
            $0.pages[id: cityB.id]?.isLoading = false
            $0.pages[id: cityB.id]?.snapshot = snapshot
        }
    }
}
