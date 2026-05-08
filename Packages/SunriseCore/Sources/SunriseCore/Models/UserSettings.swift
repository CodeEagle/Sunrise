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

/// Light / dark / follow-system preference. Surfaced in Settings and applied
/// to the host UIWindow as `overrideUserInterfaceStyle`.
public enum ThemePreference: String, Codable, Sendable, CaseIterable {
    case system
    case light
    case dark
}

/// In-app language override. Applied via the per-app `AppleLanguages`
/// UserDefaults key — iOS reads it on launch to pick string tables and
/// numeric / date formats. Switching at runtime requires an app relaunch
/// (we surface that to the user in Settings).
public enum AppLanguage: String, Codable, Sendable, CaseIterable {
    case system
    case english = "en"
    case simplifiedChinese = "zh-Hans"
    case japanese = "ja"
}

public struct UserSettings: Codable, Hashable, Sendable {
    public var temperatureUnit: TemperatureUnit
    public var windSpeedUnit: WindSpeedUnit
    public var distanceUnit: DistanceUnit
    public var notificationsEnabled: Bool
    public var theme: ThemePreference
    public var language: AppLanguage

    public init(
        temperatureUnit: TemperatureUnit = .celsius,
        windSpeedUnit: WindSpeedUnit = .metersPerSecond,
        distanceUnit: DistanceUnit = .kilometers,
        notificationsEnabled: Bool = true,
        theme: ThemePreference = .system,
        language: AppLanguage = .system
    ) {
        self.temperatureUnit = temperatureUnit
        self.windSpeedUnit = windSpeedUnit
        self.distanceUnit = distanceUnit
        self.notificationsEnabled = notificationsEnabled
        self.theme = theme
        self.language = language
    }

    public static let `default` = UserSettings()

    private enum CodingKeys: String, CodingKey {
        case temperatureUnit, windSpeedUnit, distanceUnit, notificationsEnabled, theme, language
    }

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        self.temperatureUnit = try c.decodeIfPresent(TemperatureUnit.self, forKey: .temperatureUnit) ?? .celsius
        self.windSpeedUnit = try c.decodeIfPresent(WindSpeedUnit.self, forKey: .windSpeedUnit) ?? .metersPerSecond
        self.distanceUnit = try c.decodeIfPresent(DistanceUnit.self, forKey: .distanceUnit) ?? .kilometers
        self.notificationsEnabled = try c.decodeIfPresent(Bool.self, forKey: .notificationsEnabled) ?? true
        self.theme = try c.decodeIfPresent(ThemePreference.self, forKey: .theme) ?? .system
        self.language = try c.decodeIfPresent(AppLanguage.self, forKey: .language) ?? .system
    }
}
