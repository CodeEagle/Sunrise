import Foundation

/// Coarse-grained weather buckets used to drive character art, copy, and UI state.
/// Mapped from `WeatherKit.WeatherCondition` in the live client.
public enum WeatherCondition: String, Codable, Hashable, Sendable, CaseIterable {
    case clear
    case cloudy
    case rain
    case thunderstorm
    case snow
    case windy
    case fog
}

public enum DayPeriod: String, Codable, Hashable, Sendable {
    case dawn, day, dusk, night
}
