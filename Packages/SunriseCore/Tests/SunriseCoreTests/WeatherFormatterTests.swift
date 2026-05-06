import XCTest
@testable import SunriseCore

final class WeatherFormatterTests: XCTestCase {
    func testCelsiusFormatting() {
        let formatter = WeatherFormatter(
            settings: UserSettings(temperatureUnit: .celsius),
            locale: Locale(identifier: "en_US_POSIX")
        )
        let result = formatter.temperature(Temperature(celsius: 28))
        XCTAssertTrue(result.contains("28"))
    }

    func testFahrenheitFormatting() {
        let formatter = WeatherFormatter(
            settings: UserSettings(temperatureUnit: .fahrenheit),
            locale: Locale(identifier: "en_US_POSIX")
        )
        let result = formatter.temperature(Temperature(celsius: 0))
        XCTAssertTrue(result.contains("32"))
    }

    func testPercentFormatting() {
        let formatter = WeatherFormatter(
            settings: .default,
            locale: Locale(identifier: "en_US_POSIX")
        )
        XCTAssertEqual(formatter.percent(Percent(value: 0.45)), "45%")
    }
}
