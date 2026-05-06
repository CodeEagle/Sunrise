import Foundation

public struct WeatherFormatter: Sendable {
    public let settings: UserSettings
    public let locale: Locale

    public init(settings: UserSettings, locale: Locale = .current) {
        self.settings = settings
        self.locale = locale
    }

    /// Returns the temperature value as digits only — call sites append the
    /// degree symbol so we don't double up (MeasurementFormatter already
    /// inserts one).
    public func temperature(_ value: Temperature, fractionDigits: Int = 0) -> String {
        let raw: Double
        switch settings.temperatureUnit {
        case .celsius: raw = value.celsius
        case .fahrenheit: raw = value.fahrenheit
        }
        let formatter = NumberFormatter()
        formatter.locale = locale
        formatter.maximumFractionDigits = fractionDigits
        formatter.minimumFractionDigits = 0
        return formatter.string(from: NSNumber(value: raw)) ?? "\(Int(raw.rounded()))"
    }

    public func windSpeed(_ wind: Wind) -> String {
        let measurement: Measurement<UnitSpeed>
        switch settings.windSpeedUnit {
        case .kilometersPerHour:
            measurement = Measurement(value: wind.speedKPH, unit: .kilometersPerHour)
        case .milesPerHour:
            measurement = Measurement(value: wind.speedMPH, unit: .milesPerHour)
        case .metersPerSecond:
            measurement = Measurement(value: wind.speedMPS, unit: .metersPerSecond)
        }
        let formatter = MeasurementFormatter()
        formatter.locale = locale
        formatter.unitOptions = .providedUnit
        formatter.numberFormatter.maximumFractionDigits = 1
        return formatter.string(from: measurement)
    }

    public func percent(_ value: Percent) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .percent
        formatter.locale = locale
        formatter.maximumFractionDigits = 0
        return formatter.string(from: NSNumber(value: value.value)) ?? "\(Int(value.value * 100))%"
    }
}
