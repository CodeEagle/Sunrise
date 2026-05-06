import Foundation

public struct WeatherFormatter: Sendable {
    public let settings: UserSettings
    public let locale: Locale

    public init(settings: UserSettings, locale: Locale = .current) {
        self.settings = settings
        self.locale = locale
    }

    public func temperature(_ value: Temperature, fractionDigits: Int = 0) -> String {
        let measurement: Measurement<UnitTemperature>
        switch settings.temperatureUnit {
        case .celsius:
            measurement = Measurement(value: value.celsius, unit: .celsius)
        case .fahrenheit:
            measurement = Measurement(value: value.fahrenheit, unit: .fahrenheit)
        }
        let formatter = MeasurementFormatter()
        formatter.locale = locale
        formatter.unitOptions = .temperatureWithoutUnit
        formatter.numberFormatter.maximumFractionDigits = fractionDigits
        return formatter.string(from: measurement)
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
