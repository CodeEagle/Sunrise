import XCTest
import ComposableArchitecture
@testable import CityFeature
import SunriseCore

@MainActor
final class CityListReducerTests: XCTestCase {
    func testCityResolvedFromSearchAppendsAndSelects() async {
        let store = TestStore(initialState: CityListReducer.State()) {
            CityListReducer()
        } withDependencies: {
            $0.persistenceClient.saveCities = { @Sendable _ in }
        }

        let city = City.preview
        await store.send(.search(.delegate(.cityResolved(city)))) {
            $0.cities = [city]
            $0.isPresentingSearch = false
            $0.selectedCityID = city.id
        }

        await store.receive(\.delegate.selected) { _ in }
    }
}
