import UIKit
import ComposableArchitecture
import Dependencies
import RootFeature
import SunriseCore

final class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    var window: UIWindow?

    func scene(
        _ scene: UIScene,
        willConnectTo session: UISceneSession,
        options connectionOptions: UIScene.ConnectionOptions
    ) {
        guard let windowScene = scene as? UIWindowScene else { return }

        applyLaunchArgumentOverrides()

        let store = Store(initialState: initialRootState()) {
            RootReducer()
                ._printChanges()
        }

        let window = UIWindow(windowScene: windowScene)
        // Apply the persisted theme *before* setting the root so the very
        // first frame matches the saved preference (no flash of light mode
        // when the user has chosen dark, or vice-versa).
        window.overrideUserInterfaceStyle = uiKitStyle(for: persistedTheme())
        window.rootViewController = RootTabBarController(store: store)
        self.window = window
        window.makeKeyAndVisible()
    }

    /// Honour `-mockData YES` (and friends) when launched from CI / screenshot
    /// runs so the UI populates with deterministic preview data instead of
    /// hitting WeatherKit / CoreLocation, which would fail without signing.
    private func applyLaunchArgumentOverrides() {
        let args = ProcessInfo.processInfo.arguments
        guard args.contains("-mockData") else { return }

        prepareDependencies {
            $0.weatherClient = .previewValue
            $0.locationClient = .previewValue
            $0.searchClient = .previewValue
            $0.persistenceClient = .previewValue
            $0.notificationsClient = .previewValue
        }
    }

    private func initialRootState() -> RootReducer.State {
        RootReducer.State()
    }

    /// Reads the persisted theme directly from UserDefaults (the same keys
    /// `PersistenceClient` writes to). Done synchronously here so we can paint
    /// the first frame without a hop through the actor-isolated client.
    private func persistedTheme() -> ThemePreference {
        guard let data = UserDefaults.standard.data(forKey: "sunrise.settings"),
              let settings = try? JSONDecoder().decode(UserSettings.self, from: data) else {
            return .system
        }
        return settings.theme
    }

    private func uiKitStyle(for theme: ThemePreference) -> UIUserInterfaceStyle {
        switch theme {
        case .system: return .unspecified
        case .light: return .light
        case .dark: return .dark
        }
    }
}
