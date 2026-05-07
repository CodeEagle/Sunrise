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

    /// Mock-mode launches need richer starter state than production launches —
    /// the design board shows a non-zero sunshine score (阳光值 86), and starting
    /// from 0 makes the screenshot read as "empty" instead of representative.
    private func initialRootState() -> RootReducer.State {
        var state = RootReducer.State()
        if ProcessInfo.processInfo.arguments.contains("-mockData") {
            state.character.sunshinePoints = 86
        }
        return state
    }
}
