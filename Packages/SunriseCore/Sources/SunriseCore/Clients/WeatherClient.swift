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
        let todaySun = weather.dailyForecast.forecast.first?.sun
        let dayPeriod = Self.dayPeriod(at: current.date, sun: todaySun, isDaylight: current.isDaylight)

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
                dayPeriod: dayPeriod,
                dewPoint: Temperature(celsius: current.dewPoint.converted(to: .celsius).value),
                pressure: Pressure(hPa: current.pressure.converted(to: .hectopascals).value),
                pressureTrend: PressureTrend(weatherKit: current.pressureTrend),
                cloudCover: Percent(value: current.cloudCover),
                visibilityKilometers: current.visibility.converted(to: .kilometers).value
            ),
            hourly: weather.hourlyForecast.forecast.prefix(48).map { entry in
                HourlyForecast(
                    date: entry.date,
                    temperature: Temperature(celsius: entry.temperature.converted(to: .celsius).value),
                    condition: WeatherCondition(weatherKit: entry.condition),
                    precipitationChance: Percent(value: entry.precipitationChance),
                    precipitationAmountMillimetres: entry.precipitationAmount.converted(to: .millimeters).value
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
                    ),
                    apparentHigh: Temperature(celsius: entry.highTemperature.converted(to: .celsius).value),
                    apparentLow: Temperature(celsius: entry.lowTemperature.converted(to: .celsius).value),
                    sun: SunEvents(
                        sunrise: entry.sun.sunrise,
                        sunset: entry.sun.sunset,
                        civilDawn: entry.sun.civilDawn,
                        civilDusk: entry.sun.civilDusk,
                        solarNoon: entry.sun.solarNoon
                    ),
                    moon: MoonInfo(
                        phase: MoonPhase(weatherKit: entry.moon.phase),
                        moonrise: entry.moon.moonrise,
                        moonset: entry.moon.moonset
                    ),
                    precipitationAmountMillimetres: entry.precipitationAmount.converted(to: .millimeters).value,
                    snowfallAmountMillimetres: entry.snowfallAmount.converted(to: .millimeters).value,
                    uvIndex: entry.uvIndex.value
                )
            },
            alerts: (weather.weatherAlerts ?? []).map(WeatherAlert.init(weatherKit:)),
            minute: weather.minuteForecast?.forecast.prefix(60).map { entry in
                MinuteForecast(
                    date: entry.date,
                    precipitationChance: Percent(value: entry.precipitationChance),
                    // WeatherKit reports precipitationIntensity in
                    // `Measurement<UnitSpeed>` whose default unit is
                    // millimetres-per-hour despite UnitSpeed not exposing
                    // `.millimetersPerHour` publicly. `.value` returns
                    // the figure in that native unit, which is exactly
                    // what we want to store.
                    precipitationIntensity: entry.precipitationIntensity.value
                )
            }
        )
    }
}

private extension WeatherSnapshot {
    /// Resolve the day-period bucket for art/copy from the current
    /// timestamp + today's sun events. Without sun data we fall back to
    /// WeatherKit's `isDaylight` (day or night only).
    static func dayPeriod(
        at now: Date,
        sun: WeatherKit.SunEvents?,
        isDaylight: Bool
    ) -> DayPeriod {
        guard let sun else { return isDaylight ? .day : .night }
        if let civilDawn = sun.civilDawn,
           let sunrise = sun.sunrise,
           now >= civilDawn, now < sunrise {
            return .dawn
        }
        if let sunset = sun.sunset,
           let civilDusk = sun.civilDusk,
           now >= sunset, now < civilDusk {
            return .dusk
        }
        return isDaylight ? .day : .night
    }
}

private extension PressureTrend {
    init(weatherKit trend: WeatherKit.PressureTrend) {
        switch trend {
        case .rising: self = .rising
        case .falling: self = .falling
        case .steady: self = .steady
        @unknown default: self = .steady
        }
    }
}

private extension MoonPhase {
    init(weatherKit phase: WeatherKit.MoonPhase) {
        switch phase {
        case .new: self = .new
        case .waxingCrescent: self = .waxingCrescent
        case .firstQuarter: self = .firstQuarter
        case .waxingGibbous: self = .waxingGibbous
        case .full: self = .full
        case .waningGibbous: self = .waningGibbous
        case .lastQuarter: self = .lastQuarter
        case .waningCrescent: self = .waningCrescent
        @unknown default: self = .new
        }
    }
}

private extension WeatherAlert {
    init(weatherKit alert: WeatherKit.WeatherAlert) {
        let severity: Severity
        switch alert.severity {
        case .minor: severity = .minor
        case .moderate: severity = .moderate
        case .severe: severity = .severe
        case .extreme: severity = .extreme
        case .unknown: severity = .unknown
        @unknown default: severity = .unknown
        }
        // WeatherKit's WeatherAlert doesn't expose a stable `id` —
        // synthesise one from the metadata + summary so duplicates
        // dedup by content rather than by reference.
        let issued = alert.metadata.date.timeIntervalSince1970
        let expires = alert.metadata.expirationDate.timeIntervalSince1970
        let synthesised = "\(Int(issued))-\(Int(expires))-\(alert.summary.prefix(64))"
        self.init(
            id: synthesised,
            summary: alert.summary,
            severity: severity,
            region: alert.region,
            source: alert.source,
            detailsURL: alert.detailsURL,
            issuedAt: alert.metadata.date,
            expiresAt: alert.metadata.expirationDate
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
