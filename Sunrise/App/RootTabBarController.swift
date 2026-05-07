import UIKit
import ComposableArchitecture
import RootFeature
import TodayFeature
import ForecastFeature
import CharacterFeature
import ProfileFeature
import CityFeature
import SunriseDesignSystem

final class RootTabBarController: UITabBarController {
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
        // Don't set `standardAppearance` / `scrollEdgeAppearance` — assigning
        // a custom UITabBarAppearance, even with `configureWithDefaultBackground`,
        // shadows iOS 26's native Liquid Glass material with the iOS 13-era
        // UIBlurEffect default. Leaving the appearance untouched lets the
        // system render the floating Liquid Glass tab bar straight from the
        // SDK; we only override the tint colours and the yellow selection
        // chip on top.
        tabBar.tintColor = Palette.inkPrimary
        tabBar.unselectedItemTintColor = Palette.inkSecondary
        tabBar.selectionIndicatorImage = makeSelectionChip()

        let today = TodayViewController(
            store: store.scope(state: \.today, action: \.today)
        )
        today.onMenuTapped = { [weak self] in
            self?.store.send(.presentCityList)
        }
        today.tabBarItem = UITabBarItem(
            title: String(localized: "tab.today", defaultValue: "Weather"),
            image: TabIcon.image(named: "tab_weather", fallbackSF: "cloud.sun"),
            selectedImage: TabIcon.image(named: "tab_weather", fallbackSF: "cloud.sun.fill")
        )

        let forecast = ForecastViewController(
            store: store.scope(state: \.forecast, action: \.forecast)
        )
        forecast.tabBarItem = UITabBarItem(
            title: String(localized: "tab.forecast", defaultValue: "Forecast"),
            image: TabIcon.image(named: "tab_forecast", fallbackSF: "calendar"),
            selectedImage: TabIcon.image(named: "tab_forecast", fallbackSF: "calendar.circle.fill")
        )

        let character = CharacterViewController(
            store: store.scope(state: \.character, action: \.character)
        )
        character.tabBarItem = UITabBarItem(
            title: String(localized: "tab.character", defaultValue: "Sunny"),
            image: TabIcon.image(named: "tab_character", fallbackSF: "face.smiling"),
            selectedImage: TabIcon.image(named: "tab_character", fallbackSF: "face.smiling.inverse")
        )

        let profile = ProfileViewController(
            store: store.scope(state: \.profile, action: \.profile)
        )
        profile.onManageCitiesTapped = { [weak self] in
            self?.store.send(.presentCityList)
        }
        profile.tabBarItem = UITabBarItem(
            title: String(localized: "tab.profile", defaultValue: "Me"),
            image: TabIcon.image(named: "tab_profile", fallbackSF: "person"),
            selectedImage: TabIcon.image(named: "tab_profile", fallbackSF: "person.fill")
        )

        viewControllers = [today, forecast, character, profile].map {
            UINavigationController(rootViewController: $0)
        }

        observeState { [weak self] in
            guard let self else { return }
            let index = RootTab.allCases.firstIndex(of: self.store.selectedTab) ?? 0
            if self.selectedIndex != index { self.selectedIndex = index }
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

    private func makeSelectionChip() -> UIImage {
        // Slightly bigger insets so the chip outline reads as a discrete
        // "pill behind the icon" rather than a wash that fills the whole
        // item width.
        let size = CGSize(width: 60, height: 48)
        let renderer = UIGraphicsImageRenderer(size: size)
        let raw = renderer.image { _ in
            let rect = CGRect(origin: .zero, size: size).insetBy(dx: 4, dy: 6)
            let path = UIBezierPath(roundedRect: rect, cornerRadius: 14)
            // iOS 26's Liquid Glass tab bar dims selectionIndicatorImage —
            // 0.55 read as nearly invisible. 0.85 punches through the glass
            // wash without going full opaque (which would overpower the
            // icon).
            Palette.sunYellow.withAlphaComponent(0.85).setFill()
            path.fill()
        }
        return raw.resizableImage(
            withCapInsets: UIEdgeInsets(top: 18, left: 22, bottom: 18, right: 22),
            resizingMode: .stretch
        )
    }

    override func tabBar(_ tabBar: UITabBar, didSelect item: UITabBarItem) {
        guard let index = self.tabBar.items?.firstIndex(of: item),
              let tab = RootTab.allCases[safe: index] else { return }
        store.send(.tabSelected(tab))
    }
}

private extension Array {
    subscript(safe index: Int) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}
