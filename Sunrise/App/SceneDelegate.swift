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

        let store = Store(initialState: RootReducer.State()) {
            RootReducer()
                ._printChanges()
        }

        let window = UIWindow(windowScene: windowScene)
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
}
