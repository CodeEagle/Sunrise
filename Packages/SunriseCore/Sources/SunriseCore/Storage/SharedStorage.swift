import Foundation

/// App-Group-backed snapshot cache shared between the main app and the widget
/// extension. If the App Group entitlement isn't enabled (e.g. dev signing
/// without a paid team), it gracefully falls back to standard UserDefaults so
/// the in-app code path still works.
public enum SharedStorage {
    public static let appGroupIdentifier = "group.fun.selfstudio.sunrise"

    public static var defaults: UserDefaults {
        UserDefaults(suiteName: appGroupIdentifier) ?? .standard
    }

    private static let snapshotKey = "sunrise.shared.snapshot"
    private static let cityKey = "sunrise.shared.city"

    public static func saveSnapshot(_ snapshot: WeatherSnapshot, city: City) {
        let encoder = JSONEncoder()
        if let data = try? encoder.encode(snapshot) {
            defaults.set(data, forKey: snapshotKey)
        }
        if let data = try? encoder.encode(city) {
            defaults.set(data, forKey: cityKey)
        }
    }

    public static func loadSnapshot() -> (snapshot: WeatherSnapshot, city: City)? {
        let decoder = JSONDecoder()
        guard let snapshotData = defaults.data(forKey: snapshotKey),
              let cityData = defaults.data(forKey: cityKey),
              let snapshot = try? decoder.decode(WeatherSnapshot.self, from: snapshotData),
              let city = try? decoder.decode(City.self, from: cityData) else {
            return nil
        }
        return (snapshot, city)
    }
}
