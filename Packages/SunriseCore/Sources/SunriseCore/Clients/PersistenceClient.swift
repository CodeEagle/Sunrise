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
