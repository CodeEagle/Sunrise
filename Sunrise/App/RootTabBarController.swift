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
            title: String(localized: "tab.today", defaultValue: "Weather"),
            image: TabIcon.image(named: "tab_weather", fallbackSF: "cloud.sun"),
            identifier: RootTab.today.rawValue,
            viewControllerProvider: { _ in todayNav }
        )
        let forecastTab = UITab(
            title: String(localized: "tab.forecast", defaultValue: "Forecast"),
            image: TabIcon.image(named: "tab_forecast", fallbackSF: "calendar"),
            identifier: RootTab.forecast.rawValue,
            viewControllerProvider: { _ in forecastNav }
        )
        let characterTab = UITab(
            title: String(localized: "tab.character", defaultValue: "Sunny"),
            image: TabIcon.image(named: "tab_character", fallbackSF: "face.smiling"),
            identifier: RootTab.character.rawValue,
            viewControllerProvider: { _ in characterNav }
        )
        let profileTab = UITab(
            title: String(localized: "tab.profile", defaultValue: "Me"),
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
        }

        store.send(.appLaunched)
    }

    private func syncCityListPresentation() {
        if store.isPresentingCityList, presentedCityList == nil {
            let cityListVC = CityListViewController(
                store: store.scope(state: \.cityList, action: \.cityList)
            )
            cityListVC.navigationItem.leftBarButtonItem = UIBarButtonItem(
                barButtonSystemItem: .done,
                target: self,
                action: #selector(handleCityListDone)
            )
            let nav = UINavigationController(rootViewController: cityListVC)
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
