import Foundation
import Dependencies
import DependenciesMacros

@DependencyClient
public struct PersistenceClient: Sendable {
    public var loadCities: @Sendable () async throws -> [City]
    public var saveCities: @Sendable (_ cities: [City]) async throws -> Void
    public var loadSettings: @Sendable () async throws -> UserSettings
    public var saveSettings: @Sendable (_ settings: UserSettings) async throws -> Void
}

extension PersistenceClient: DependencyKey {
    public static var liveValue: PersistenceClient {
        let store = UserDefaultsStore()
        return PersistenceClient(
            loadCities: { store.load([City].self, key: .cities) ?? [] },
            saveCities: { store.save($0, key: .cities) },
            loadSettings: { store.load(UserSettings.self, key: .settings) ?? .default },
            saveSettings: { store.save($0, key: .settings) }
        )
    }

    public static let previewValue = PersistenceClient(
        loadCities: { [.preview] },
        saveCities: { _ in },
        loadSettings: { .default },
        saveSettings: { _ in }
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
private struct UserDefaultsStore: Sendable {
    let defaults = UserDefaults.standard
    let encoder = JSONEncoder()
    let decoder = JSONDecoder()

    func load<T: Decodable>(_ type: T.Type, key: StoreKey) -> T? {
        guard let data = defaults.data(forKey: key.rawValue) else { return nil }
        return try? decoder.decode(T.self, from: data)
    }

    func save<T: Encodable>(_ value: T, key: StoreKey) {
        guard let data = try? encoder.encode(value) else { return }
        defaults.set(data, forKey: key.rawValue)
    }
}
