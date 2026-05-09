import Foundation
import Dependencies
import DependenciesMacros

@DependencyClient
public struct PersistenceClient: Sendable {
    public var loadCities: @Sendable () async throws -> [City]
    public var saveCities: @Sendable (_ cities: [City]) async throws -> Void
    public var loadSettings: @Sendable () async throws -> UserSettings
    public var saveSettings: @Sendable (_ settings: UserSettings) async throws -> Void
    /// Records "today's" daily forecast for a city into a local rolling
    /// history. Called every time the Today tab gets a fresh snapshot —
    /// the snapshot's `daily.first` entry is the closest thing to a
    /// historical observation we can produce locally without the
    /// WeatherKit historical query (which 400s in our setup). The cache
    /// keeps up to ~30 days per city; older entries are pruned.
    public var recordHistoricalDay: @Sendable (_ cityID: City.ID, _ entry: DailyForecast) async -> Void
    /// Loads the rolling history for a city in the requested date range,
    /// inclusive on both ends. Returns an empty array when no entries
    /// have accumulated yet.
    public var loadHistoricalRange: @Sendable (_ cityID: City.ID, _ start: Date, _ end: Date) async -> [DailyForecast]
}

extension PersistenceClient: DependencyKey {
    public static var liveValue: PersistenceClient {
        let store = UserDefaultsStore()
        return PersistenceClient(
            loadCities: { store.load([City].self, key: .cities) ?? [] },
            saveCities: { store.save($0, key: .cities) },
            loadSettings: { store.load(UserSettings.self, key: .settings) ?? .default },
            saveSettings: { store.save($0, key: .settings) },
            recordHistoricalDay: { cityID, entry in
                store.recordHistoricalDay(cityID: cityID, entry: entry)
            },
            loadHistoricalRange: { cityID, start, end in
                store.loadHistoricalRange(cityID: cityID, start: start, end: end)
            }
        )
    }

    public static let previewValue = PersistenceClient(
        loadCities: { [.preview] },
        saveCities: { _ in },
        loadSettings: { .default },
        saveSettings: { _ in },
        recordHistoricalDay: { _, _ in },
        loadHistoricalRange: { _, _, _ in [] }
    )

    public static let testValue = PersistenceClient()
}

public extension DependencyValues {
    var persistenceClient: PersistenceClient {
        get { self[PersistenceClient.self] }
        set { self[PersistenceClient.self] = newValue }
    }
}

private enum StoreKey: String {
    case cities = "sunrise.cities"
    case settings = "sunrise.settings"
}

/// MVP storage: UserDefaults + Codable. Swap for GRDB once we add hourly history / aggregates.
/// Stateless on purpose — `UserDefaults`, `JSONEncoder` and `JSONDecoder`
/// are flagged non-Sendable under Swift 6 strict concurrency, so holding
/// them as stored properties would force the whole struct off `Sendable`.
/// Constructing fresh ones per call is cheap relative to a settings save.
private struct UserDefaultsStore: Sendable {
    func load<T: Decodable>(_ type: T.Type, key: StoreKey) -> T? {
        guard let data = UserDefaults.standard.data(forKey: key.rawValue) else { return nil }
        return try? JSONDecoder().decode(T.self, from: data)
    }

    func save<T: Encodable>(_ value: T, key: StoreKey) {
        guard let data = try? JSONEncoder().encode(value) else { return }
        UserDefaults.standard.set(data, forKey: key.rawValue)
    }

    /// Per-city history is keyed by `sunrise.history.<uuid>` and stores an
    /// array of DailyForecast entries deduped by start-of-day timestamp.
    func recordHistoricalDay(cityID: City.ID, entry: DailyForecast) {
        let key = historyKey(cityID)
        var existing = (load([DailyForecast].self, rawKey: key) ?? [])
        let dayStart = startOfUTCDay(entry.date)
        existing.removeAll { startOfUTCDay($0.date) == dayStart }
        existing.append(entry)
        // Keep at most 35 days (extra slack beyond the calendar's 14-day
        // window so prior weeks remain available if we ever extend the UI).
        let cutoff = Calendar.utc.date(byAdding: .day, value: -35, to: dayStart) ?? dayStart
        existing.removeAll { $0.date < cutoff }
        existing.sort { $0.date < $1.date }
        save(existing, rawKey: key)
    }

    func loadHistoricalRange(cityID: City.ID, start: Date, end: Date) -> [DailyForecast] {
        let key = historyKey(cityID)
        let entries = load([DailyForecast].self, rawKey: key) ?? []
        return entries.filter { entry in
            let day = startOfUTCDay(entry.date)
            return day >= start && day < end
        }
    }

    private func historyKey(_ cityID: City.ID) -> String {
        "sunrise.history.\(cityID.uuidString)"
    }

    private func startOfUTCDay(_ date: Date) -> Date {
        Calendar.utc.startOfDay(for: date)
    }

    private func load<T: Decodable>(_ type: T.Type, rawKey: String) -> T? {
        guard let data = UserDefaults.standard.data(forKey: rawKey) else { return nil }
        return try? JSONDecoder().decode(T.self, from: data)
    }

    private func save<T: Encodable>(_ value: T, rawKey: String) {
        guard let data = try? JSONEncoder().encode(value) else { return }
        UserDefaults.standard.set(data, forKey: rawKey)
    }
}

private extension Calendar {
    /// Shared Gregorian-UTC calendar for normalising history-cache
    /// timestamps. Local time-zone day boundaries would split the same
    /// real day differently per traveller, breaking dedup across trips.
    static let utc: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "UTC") ?? .gmt
        return calendar
    }()
}
