import UIKit
import ComposableArchitecture
import RootFeature
import TodayFeature
import ForecastFeature
import CharacterFeature
import ProfileFeature
import CityFeature
import SunriseDesignSystem

final class RootTabBarController: UITabBarController, UITabBarControllerDelegate {
    private let store: StoreOf<RootReducer>
    private var presentedCityList: UIViewController?

    init(store: StoreOf<RootReducer>) {
        self.store = store
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError() }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = Palette.canvas
        // iOS 26 Liquid Glass on the tab bar is gated on TWO things:
        //   1. Using the iOS 18+ `UITab` API (`tabs = [UITab(...)]`, see
        //      below). The legacy `viewControllers` + `tabBarItem` path
        //      renders the iOS 13-era UIBlurEffect material and never
        //      upgrades.
        //   2. NOT assigning a custom `UITabBarAppearance` at all. Even one
        //      built via `configureWithDefaultBackground()` silently swaps
        //      the bar back onto the legacy blur pipeline and suppresses
        //      Liquid Glass — that's the bug we shipped before. tintColor
        //      and unselectedItemTintColor work fine without a custom
        //      appearance, so we set just those and let the system handle
        //      the material, hairline, and pill geometry.
        // Ref: WWDC25 #284 "Build a UIKit app with the new design".
        tabBar.tintColor = Palette.inkPrimary
        tabBar.unselectedItemTintColor = Palette.inkSecondary
        delegate = self

        let today = TodayViewController(
            store: store.scope(state: \.today, action: \.today)
        )
        today.onMenuTapped = { [weak self] in
            self?.store.send(.presentCityList)
        }
        let todayNav = UINavigationController(rootViewController: today)

        let forecast = ForecastViewController(
            store: store.scope(state: \.forecast, action: \.forecast)
        )
        let forecastNav = UINavigationController(rootViewController: forecast)

        let character = CharacterViewController(
            store: store.scope(state: \.character, action: \.character)
        )
        let characterNav = UINavigationController(rootViewController: character)

        let profile = ProfileViewController(
            store: store.scope(state: \.profile, action: \.profile)
        )
        profile.onManageCitiesTapped = { [weak self] in
            self?.store.send(.presentCityList)
        }
        let profileNav = UINavigationController(rootViewController: profile)

        let todayTab = UITab(
            title: "tab.today".l10n("Weather"),
            image: TabIcon.image(named: "tab_weather", fallbackSF: "cloud.sun"),
            identifier: RootTab.today.rawValue,
            viewControllerProvider: { _ in todayNav }
        )
        let forecastTab = UITab(
            title: "tab.forecast".l10n("Forecast"),
            image: TabIcon.image(named: "tab_forecast", fallbackSF: "calendar"),
            identifier: RootTab.forecast.rawValue,
            viewControllerProvider: { _ in forecastNav }
        )
        let characterTab = UITab(
            title: "tab.character".l10n("Sunny"),
            image: TabIcon.image(named: "tab_character", fallbackSF: "face.smiling"),
            identifier: RootTab.character.rawValue,
            viewControllerProvider: { _ in characterNav }
        )
        let profileTab = UITab(
            title: "tab.profile".l10n("Me"),
            image: TabIcon.image(named: "tab_profile", fallbackSF: "person"),
            identifier: RootTab.profile.rawValue,
            viewControllerProvider: { _ in profileNav }
        )

        tabs = [todayTab, forecastTab, characterTab, profileTab]

        observeState { [weak self] in
            guard let self else { return }
            let id = self.store.selectedTab.rawValue
            if let target = self.tab(forIdentifier: id), self.selectedTab !== target {
                self.selectedTab = target
            }
            self.syncCityListPresentation()
            self.syncThemePreference()
        }

        store.send(.appLaunched)
    }

    /// Mirror the user's ThemePreference into the host window. Called on
    /// every observation tick — the comparison is cheap and lets the theme
    /// picker update the chrome live without a relaunch.
    private func syncThemePreference() {
        let style: UIUserInterfaceStyle
        switch store.profile.settings.theme {
        case .system: style = .unspecified
        case .light: style = .light
        case .dark: style = .dark
        }
        if view.window?.overrideUserInterfaceStyle != style {
            view.window?.overrideUserInterfaceStyle = style
        }
    }

    private func syncCityListPresentation() {
        if store.isPresentingCityList, presentedCityList == nil {
            let cityListVC = CityListViewController(
                store: store.scope(state: \.cityList, action: \.cityList)
            )
            // Override the leftBarButtonItem set inside CityListViewController
            // (the edit button) with a Done button on the modal — the user
            // can re-enter edit mode via the table swipe gestures.
            let doneButton = UIBarButtonItem(
                barButtonSystemItem: .done,
                target: self,
                action: #selector(handleCityListDone)
            )
            doneButton.tintColor = Palette.inkPrimary
            cityListVC.navigationItem.leftBarButtonItem = doneButton

            let nav = UINavigationController(rootViewController: cityListVC)
            // Propagate the host window's effective interface style to the
            // modal sheet — without this, iOS 26 sheets sometimes resolve to
            // .light regardless of the underlying window's override (the
            // "add-city button reverts to white theme" bug).
            if let window = view.window, window.overrideUserInterfaceStyle != .unspecified {
                nav.overrideUserInterfaceStyle = window.overrideUserInterfaceStyle
            }
            present(nav, animated: true)
            presentedCityList = nav
        } else if !store.isPresentingCityList, let presented = presentedCityList {
            presented.dismiss(animated: true)
            presentedCityList = nil
        }
    }

    @objc private func handleCityListDone() {
        store.send(.dismissCityList)
    }

    // The optional protocol method's parameter type is `UIViewController`, not
    // `UITab` — declaring it with `UITab` "nearly matches" but Swift treats it
    // as a separate overload that UIKit never dispatches to. Use the legacy
    // signature and resolve the active `UITab` via `selectedTab`.
    func tabBarController(_ tabBarController: UITabBarController, didSelect viewController: UIViewController) {
        guard let tab = tabBarController.selectedTab,
              let rootTab = RootTab(rawValue: tab.identifier) else { return }
        store.send(.tabSelected(rootTab))
    }
}
