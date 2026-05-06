import Foundation

public enum TemperatureUnit: String, Codable, Sendable, CaseIterable {
    case celsius
    case fahrenheit
}

public enum WindSpeedUnit: String, Codable, Sendable, CaseIterable {
    case kilometersPerHour
    case milesPerHour
    case metersPerSecond
}

public enum DistanceUnit: String, Codable, Sendable, CaseIterable {
    case kilometers
    case miles
}

public struct UserSettings: Codable, Hashable, Sendable {
    public var temperatureUnit: TemperatureUnit
    public var windSpeedUnit: WindSpeedUnit
    public var distanceUnit: DistanceUnit
    public var notificationsEnabled: Bool

    public init(
        temperatureUnit: TemperatureUnit = .celsius,
        windSpeedUnit: WindSpeedUnit = .metersPerSecond,
        distanceUnit: DistanceUnit = .kilometers,
        notificationsEnabled: Bool = true
    ) {
        self.temperatureUnit = temperatureUnit
        self.windSpeedUnit = windSpeedUnit
        self.distanceUnit = distanceUnit
        self.notificationsEnabled = notificationsEnabled
    }

    public static let `default` = UserSettings()
}
