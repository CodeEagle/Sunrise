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
    /// WeatherKit historical query (which doesn't exist).
    /// Entries are kept forever; users scroll back through their full
    /// personal history.
    public var recordHistoricalDay: @Sendable (_ cityID: City.ID, _ entry: DailyForecast) async -> Void = { _, _ in }
    /// Loads the rolling history for a city in the requested date range,
    /// inclusive on both ends. Returns an empty array when no entries
    /// have accumulated yet.
    public var loadHistoricalRange: @Sendable (_ cityID: City.ID, _ start: Date, _ end: Date) async -> [DailyForecast] = { _, _, _ in [] }
    /// Loads every cached daily-forecast entry for a city, sorted
    /// ascending by date.
    public var loadAllHistorical: @Sendable (_ cityID: City.ID) async -> [DailyForecast] = { _ in [] }
    /// Records hourly forecast entries for a city. Called on every
    /// Today snapshot. Entries are deduped per (city, hour) so
    /// repeated fetches in the same hour overwrite rather than
    /// duplicate.
    public var recordHistoricalHours: @Sendable (_ cityID: City.ID, _ entries: [HourlyForecast]) async -> Void = { _, _ in }
    /// Loads every cached hourly entry for a specific UTC day on a
    /// city. Returns the 0–24 entries we have for that day, sorted
    /// ascending.
    public var loadHistoricalHours: @Sendable (_ cityID: City.ID, _ day: Date) async -> [HourlyForecast] = { _, _ in [] }
}

extension PersistenceClient: DependencyKey {
    public static var liveValue: PersistenceClient {
        let store = UserDefaultsStore()
        let history = FileSystemHistoryStore()
        return PersistenceClient(
            loadCities: { store.load([City].self, key: .cities) ?? [] },
            saveCities: { store.save($0, key: .cities) },
            loadSettings: { store.load(UserSettings.self, key: .settings) ?? .default },
            saveSettings: { store.save($0, key: .settings) },
            recordHistoricalDay: { cityID, entry in
                history.recordDaily(cityID: cityID, entry: entry)
            },
            loadHistoricalRange: { cityID, start, end in
                history.loadDailyRange(cityID: cityID, start: start, end: end)
            },
            loadAllHistorical: { cityID in
                history.loadAllDaily(cityID: cityID)
            },
            recordHistoricalHours: { cityID, entries in
                history.recordHours(cityID: cityID, entries: entries)
            },
            loadHistoricalHours: { cityID, day in
                history.loadHours(cityID: cityID, day: day)
            }
        )
    }

    public static let previewValue = PersistenceClient(
        loadCities: { [.preview] },
        saveCities: { _ in },
        loadSettings: { .default },
        saveSettings: { _ in },
        recordHistoricalDay: { _, _ in },
        loadHistoricalRange: { _, _, _ in [] },
        loadAllHistorical: { _ in [] },
        recordHistoricalHours: { _, _ in },
        loadHistoricalHours: { _, _ in [] }
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

/// MVP storage for cities + settings: UserDefaults + Codable. Swap for
/// GRDB once we add hourly aggregates over many years of history.
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
}

/// Per-city / per-date JSON files under
/// `Documents/sunrise/history/<cityUUID>/{daily,hourly}/<yyyy-MM-dd>.json`.
///
/// Reasons for the per-date layout (vs. one big UserDefaults blob):
/// - Each day is a small (<1 KB daily, <16 KB hourly) standalone file —
///   easy to inspect, back up, ship to debug logs.
/// - UserDefaults is meant for preferences; a multi-year weather log
///   bloats the plist and slows every preference read.
/// - Atomic per-day writes mean a crash mid-write at most loses the
///   single day in flight, never the whole history.
private struct FileSystemHistoryStore: Sendable {
    func recordDaily(cityID: City.ID, entry: DailyForecast) {
        let url = dailyURL(cityID: cityID, date: entry.date)
        guard let directory = url?.deletingLastPathComponent() else { return }
        ensureDirectory(at: directory)
        guard let url, let data = try? JSONEncoder().encode(entry) else { return }
        try? data.write(to: url, options: .atomic)
    }

    func loadAllDaily(cityID: City.ID) -> [DailyForecast] {
        guard let directory = dailyDirectory(cityID: cityID) else { return [] }
        return loadAllJSON(in: directory, as: DailyForecast.self)
            .sorted { $0.date < $1.date }
    }

    func loadDailyRange(cityID: City.ID, start: Date, end: Date) -> [DailyForecast] {
        loadAllDaily(cityID: cityID).filter { entry in
            let day = startOfUTCDay(entry.date)
            return day >= start && day < end
        }
    }

    func recordHours(cityID: City.ID, entries: [HourlyForecast]) {
        guard !entries.isEmpty else { return }
        // Group incoming entries by UTC day. Each day's file holds the
        // merged hour set so re-fetching keeps the existing hours
        // and overwrites duplicates by hour-of-day.
        let grouped = Dictionary(grouping: entries) { startOfUTCDay($0.date) }
        for (day, dayEntries) in grouped {
            guard let url = hourlyURL(cityID: cityID, date: day) else { continue }
            ensureDirectory(at: url.deletingLastPathComponent())
            var existing: [HourlyForecast] = (try? Data(contentsOf: url))
                .flatMap { try? JSONDecoder().decode([HourlyForecast].self, from: $0) } ?? []
            var byHour: [Date: HourlyForecast] = [:]
            for entry in existing {
                byHour[startOfUTCHour(entry.date)] = entry
            }
            for entry in dayEntries {
                byHour[startOfUTCHour(entry.date)] = entry
            }
            existing = byHour.values.sorted { $0.date < $1.date }
            if let data = try? JSONEncoder().encode(existing) {
                try? data.write(to: url, options: .atomic)
            }
        }
    }

    func loadHours(cityID: City.ID, day: Date) -> [HourlyForecast] {
        guard let url = hourlyURL(cityID: cityID, date: day) else { return [] }
        guard let data = try? Data(contentsOf: url),
              let decoded = try? JSONDecoder().decode([HourlyForecast].self, from: data) else {
            return []
        }
        return decoded.sorted { $0.date < $1.date }
    }

    // MARK: - Paths

    private func dailyDirectory(cityID: City.ID) -> URL? {
        historyRoot(cityID: cityID)?.appending(path: "daily", directoryHint: .isDirectory)
    }

    private func hourlyDirectory(cityID: City.ID) -> URL? {
        historyRoot(cityID: cityID)?.appending(path: "hourly", directoryHint: .isDirectory)
    }

    private func dailyURL(cityID: City.ID, date: Date) -> URL? {
        dailyDirectory(cityID: cityID)?.appending(path: "\(filenameStamp(date)).json")
    }

    private func hourlyURL(cityID: City.ID, date: Date) -> URL? {
        hourlyDirectory(cityID: cityID)?.appending(path: "\(filenameStamp(date)).json")
    }

    private func historyRoot(cityID: City.ID) -> URL? {
        guard let documents = FileManager.default.urls(
            for: .documentDirectory,
            in: .userDomainMask
        ).first else { return nil }
        return documents
            .appending(path: "sunrise", directoryHint: .isDirectory)
            .appending(path: "history", directoryHint: .isDirectory)
            .appending(path: cityID.uuidString, directoryHint: .isDirectory)
    }

    private func ensureDirectory(at url: URL) {
        try? FileManager.default.createDirectory(
            at: url,
            withIntermediateDirectories: true
        )
    }

    private func loadAllJSON<T: Decodable>(in directory: URL, as type: T.Type) -> [T] {
        guard let names = try? FileManager.default.contentsOfDirectory(atPath: directory.path) else {
            return []
        }
        let decoder = JSONDecoder()
        return names.compactMap { name -> T? in
            guard name.hasSuffix(".json") else { return nil }
            let url = directory.appending(path: name)
            guard let data = try? Data(contentsOf: url) else { return nil }
            return try? decoder.decode(T.self, from: data)
        }
    }

    // MARK: - Date helpers

    /// Filename stamp keyed by UTC day so the same calendar day always
    /// resolves to the same file regardless of where the device is.
    private func filenameStamp(_ date: Date) -> String {
        Self.stampFormatter.string(from: date)
    }

    private static let stampFormatter: DateFormatter = {
        let df = DateFormatter()
        df.calendar = Calendar(identifier: .gregorian)
        df.timeZone = TimeZone(identifier: "UTC") ?? .gmt
        df.locale = Locale(identifier: "en_US_POSIX")
        df.dateFormat = "yyyy-MM-dd"
        return df
    }()

    private func startOfUTCDay(_ date: Date) -> Date {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "UTC") ?? .gmt
        return calendar.startOfDay(for: date)
    }

    private func startOfUTCHour(_ date: Date) -> Date {
        let interval = floor(date.timeIntervalSince1970 / 3600) * 3600
        return Date(timeIntervalSince1970: interval)
    }
}
