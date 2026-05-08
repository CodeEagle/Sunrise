import Foundation
import CoreLocation
import Dependencies
import DependenciesMacros

#if canImport(WeatherKit)
import WeatherKit
#endif

@DependencyClient
public struct WeatherClient: Sendable {
    public var fetch: @Sendable (_ coordinate: CLLocationCoordinate2D) async throws -> WeatherSnapshot
}

extension WeatherClient: DependencyKey {
    public static var liveValue: WeatherClient {
        #if canImport(WeatherKit)
        let service = WeatherService.shared
        return WeatherClient(
            fetch: { coordinate in
                let location = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
                let weather = try await service.weather(for: location)
                return WeatherSnapshot(weatherKit: weather)
            }
        )
        #else
        return .unimplemented
        #endif
    }

    public static let previewValue = WeatherClient(
        fetch: { _ in .preview }
    )

    public static let testValue = WeatherClient()

    static let unimplemented = WeatherClient(
        fetch: { _ in throw WeatherClientError.unsupportedPlatform }
    )
}

public enum WeatherClientError: Error, Sendable {
    case unsupportedPlatform
}

public extension DependencyValues {
    var weatherClient: WeatherClient {
        get { self[WeatherClient.self] }
        set { self[WeatherClient.self] = newValue }
    }
}

#if canImport(WeatherKit)
private extension WeatherSnapshot {
    init(weatherKit weather: Weather) {
        let current = weather.currentWeather
        let dayPeriod: DayPeriod = current.isDaylight ? .day : .night

        self.init(
            updatedAt: current.date,
            current: CurrentWeather(
                temperature: Temperature(celsius: current.temperature.converted(to: .celsius).value),
                apparentTemperature: Temperature(celsius: current.apparentTemperature.converted(to: .celsius).value),
                condition: WeatherCondition(weatherKit: current.condition),
                humidity: Percent(value: current.humidity),
                wind: Wind(
                    speedKPH: current.wind.speed.converted(to: .kilometersPerHour).value,
                    directionDegrees: current.wind.direction.converted(to: .degrees).value
                ),
                uvIndex: current.uvIndex.value,
                dayPeriod: dayPeriod
            ),
            hourly: weather.hourlyForecast.forecast.prefix(24).map { entry in
                HourlyForecast(
                    date: entry.date,
                    temperature: Temperature(celsius: entry.temperature.converted(to: .celsius).value),
                    condition: WeatherCondition(weatherKit: entry.condition),
                    precipitationChance: Percent(value: entry.precipitationChance)
                )
            },
            daily: weather.dailyForecast.forecast.prefix(15).map { entry in
                DailyForecast(
                    date: entry.date,
                    highTemperature: Temperature(celsius: entry.highTemperature.converted(to: .celsius).value),
                    lowTemperature: Temperature(celsius: entry.lowTemperature.converted(to: .celsius).value),
                    condition: WeatherCondition(weatherKit: entry.condition),
                    precipitationChance: Percent(value: entry.precipitationChance),
                    wind: Wind(
                        speedKPH: entry.wind.speed.converted(to: .kilometersPerHour).value,
                        directionDegrees: entry.wind.direction.converted(to: .degrees).value
                    )
                )
            }
        )
    }
}

private extension WeatherCondition {
    init(weatherKit condition: WeatherKit.WeatherCondition) {
        switch condition {
        case .clear, .mostlyClear, .hot:
            self = .clear
        case .cloudy, .mostlyCloudy, .partlyCloudy, .smoky, .haze:
            self = .cloudy
        case .drizzle, .rain, .heavyRain, .freezingRain, .sunShowers:
            self = .rain
        case .thunderstorms, .strongStorms, .isolatedThunderstorms, .scatteredThunderstorms, .hurricane:
            self = .thunderstorm
        case .snow, .heavySnow, .flurries, .sleet, .wintryMix, .blizzard, .blowingSnow, .freezingDrizzle, .hail, .sunFlurries, .frigid:
            self = .snow
        case .breezy, .windy, .blowingDust, .tropicalStorm:
            self = .windy
        case .foggy:
            self = .fog
        @unknown default:
            self = .clear
        }
    }
}
#endif
