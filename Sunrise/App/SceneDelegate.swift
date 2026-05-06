import UIKit
import ComposableArchitecture
import RootFeature

final class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    var window: UIWindow?

    func scene(
        _ scene: UIScene,
        willConnectTo session: UISceneSession,
        options connectionOptions: UIScene.ConnectionOptions
    ) {
        guard let windowScene = scene as? UIWindowScene else { return }

        let store = Store(initialState: RootReducer.State()) {
            RootReducer()
                ._printChanges()
        }

        let window = UIWindow(windowScene: windowScene)
        window.rootViewController = RootTabBarController(store: store)
        self.window = window
        window.makeKeyAndVisible()
    }
}
