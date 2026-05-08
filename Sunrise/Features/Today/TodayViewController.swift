import UIKit
import ComposableArchitecture
import TodayFeature
import SunriseCore
import SunriseDesignSystem

/// Horizontal pager of city pages — matches the system Weather app: each
/// city is a full-screen page, swipe left/right to switch, dot indicator at
/// the bottom shows position, "manage cities" pill on the trailing side.
///
/// Each visible / adjacent page is its own `TodayPageViewController` backed by
/// a scoped `StoreOf<TodayPageReducer>`, so a fetch on the active page can
/// continue while the user swipes ahead to the next city.
final class TodayViewController: UIViewController {
    private let store: StoreOf<TodayReducer>
    private let pageVC: UIPageViewController
    private let pageControl = UIPageControl()
    private let manageButton = UIButton(type: .system)
    private let emptyLabel = UILabel()

    private var pageCache: [City.ID: TodayPageViewController] = [:]
    /// Snapshot of the most recent ordered city ids the pager rendered. Lets
    /// us detect whether `pages` mutated and rebuild the cache without
    /// re-syncing on every observation.
    private var orderedIDs: [City.ID] = []
    /// Tracks whether the page-vc has any controller mounted at all — guard
    /// against the first `setViewControllers` racing with a still-empty store
    /// (the initial render before `citiesUpdated` arrives).
    private var hasMountedInitialPage = false
    /// True between `willTransitionTo` and `didFinishAnimating`. While set,
    /// `render()` won't call `setViewControllers` — that interrupts the
    /// gesture and leaves the scrollview parked mid-page (the "switching
    /// incomplete, slow drift" symptom).
    private var isTransitioning = false
    /// If render() wants to change pages while a swipe is mid-flight, defer
    /// the update to didFinishAnimating so the gesture can complete clean.
    private var pendingTargetID: City.ID?
    /// Fixed reserved height for the bottom page-control glass; mirrored
    /// into each child page's `additionalSafeAreaInsets.bottom` so the page
    /// content (bubble, retry button) doesn't tuck under the capsule.
    private static let bottomBarReservedHeight: CGFloat = 60

    var onMenuTapped: (() -> Void)?

    init(store: StoreOf<TodayReducer>) {
        self.store = store
        self.pageVC = UIPageViewController(
            transitionStyle: .scroll,
            navigationOrientation: .horizontal
        )
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError() }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = Palette.canvas

        // Hide the nav bar on the pager — each page now carries its own
        // city header inside the body, and the manage button + dots live
        // in the bottom overlay so the painted scene reads full-bleed.
        navigationController?.setNavigationBarHidden(true, animated: false)

        configureChildPager()
        configureBottomBar()
        configureEmptyState()

        observeState { [weak self] in self?.render() }
        onLanguageChange { [weak self] in self?.render() }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: animated)
        // Today is the root of its nav stack — the interactive pop gesture
        // has nothing to fall back to and would only fight the page swipe
        // (the "switch incomplete, drifts slowly" symptom often traces to
        // this conflicting recogniser on the leading screen edge).
        navigationController?.interactivePopGestureRecognizer?.isEnabled = false
    }

    private func configureChildPager() {
        addChild(pageVC)
        pageVC.view.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(pageVC.view)
        NSLayoutConstraint.activate([
            pageVC.view.topAnchor.constraint(equalTo: view.topAnchor),
            pageVC.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            pageVC.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            pageVC.view.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        pageVC.didMove(toParent: self)
        pageVC.dataSource = self
        pageVC.delegate = self
    }

    private func configureBottomBar() {
        let glass = GlassPanel(style: .clear, cornerRadius: Radius.large)
        glass.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(glass)

        pageControl.translatesAutoresizingMaskIntoConstraints = false
        pageControl.hidesForSinglePage = true
        pageControl.pageIndicatorTintColor = Palette.inkPrimary.withAlphaComponent(0.3)
        pageControl.currentPageIndicatorTintColor = Palette.inkPrimary
        pageControl.addTarget(self, action: #selector(handlePageControlTap), for: .valueChanged)
        view.addSubview(pageControl)

        var manageConfig = UIButton.Configuration.plain()
        manageConfig.image = UIImage(systemName: "list.bullet")
        manageConfig.baseForegroundColor = Palette.inkPrimary
        manageConfig.contentInsets = NSDirectionalEdgeInsets(top: 8, leading: 12, bottom: 8, trailing: 12)
        manageButton.configuration = manageConfig
        manageButton.translatesAutoresizingMaskIntoConstraints = false
        manageButton.addTarget(self, action: #selector(handleManageTap), for: .touchUpInside)
        view.addSubview(manageButton)

        NSLayoutConstraint.activate([
            glass.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -Spacing.xs),
            glass.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: Spacing.l),
            glass.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -Spacing.l),
            glass.heightAnchor.constraint(equalToConstant: 44),

            pageControl.centerYAnchor.constraint(equalTo: glass.centerYAnchor),
            pageControl.centerXAnchor.constraint(equalTo: glass.centerXAnchor),

            manageButton.centerYAnchor.constraint(equalTo: glass.centerYAnchor),
            manageButton.trailingAnchor.constraint(equalTo: glass.trailingAnchor, constant: -Spacing.xs)
        ])
    }

    private func configureEmptyState() {
        emptyLabel.text = "today.locating".l10n("Locating…")
        emptyLabel.font = Typography.body()
        emptyLabel.textColor = Palette.inkSecondary
        emptyLabel.textAlignment = .center
        emptyLabel.numberOfLines = 0
        emptyLabel.translatesAutoresizingMaskIntoConstraints = false
        emptyLabel.isHidden = true
        view.addSubview(emptyLabel)
        NSLayoutConstraint.activate([
            emptyLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            emptyLabel.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            emptyLabel.leadingAnchor.constraint(greaterThanOrEqualTo: view.leadingAnchor, constant: Spacing.l),
            emptyLabel.trailingAnchor.constraint(lessThanOrEqualTo: view.trailingAnchor, constant: -Spacing.l)
        ])
    }

    private func render() {
        let ids = Array(store.pages.ids)
        if ids != orderedIDs {
            orderedIDs = ids
            pruneOrphans()
        }

        pageControl.numberOfPages = ids.count

        guard !ids.isEmpty else {
            emptyLabel.text = store.isResolvingLocation
                ? "today.locating".l10n("Locating…")
                : "today.empty".l10n("Add a city to see the weather.")
            emptyLabel.isHidden = false
            if hasMountedInitialPage {
                pageVC.setViewControllers([], direction: .forward, animated: false)
                hasMountedInitialPage = false
            }
            return
        }
        emptyLabel.isHidden = true

        let targetID = store.selectedCityID ?? ids.first!
        let targetIndex = ids.firstIndex(of: targetID) ?? 0
        pageControl.currentPage = targetIndex

        guard let target = childController(for: targetID) else { return }
        let visibleID = currentlyVisibleID()
        guard !hasMountedInitialPage || visibleID != targetID else { return }

        // Mid-swipe: queue the update; didFinishAnimating will flush it.
        // setViewControllers during the transition stalls the scroll view
        // halfway and leaves the user with a sliver of the next page
        // visible — the exact "switch incomplete" bug reported.
        if isTransitioning {
            pendingTargetID = targetID
            return
        }

        applyPage(target: target, targetID: targetID, visibleID: visibleID, ids: ids)
    }

    private func applyPage(
        target: TodayPageViewController,
        targetID: City.ID,
        visibleID: City.ID?,
        ids: [City.ID]
    ) {
        let direction: UIPageViewController.NavigationDirection
        if let visibleID,
           let from = ids.firstIndex(of: visibleID),
           let to = ids.firstIndex(of: targetID),
           from < to {
            direction = .forward
        } else {
            direction = .reverse
        }
        pageVC.setViewControllers([target], direction: direction, animated: hasMountedInitialPage)
        hasMountedInitialPage = true
    }

    private func currentlyVisibleID() -> City.ID? {
        guard let visible = pageVC.viewControllers?.first as? TodayPageViewController else { return nil }
        return visible.cityID
    }

    private func childController(for id: City.ID) -> TodayPageViewController? {
        if let existing = pageCache[id] { return existing }
        guard let pageStore = store.scope(state: \.pages[id: id], action: \.page[id: id]) else {
            return nil
        }
        let vc = TodayPageViewController(store: pageStore)
        vc.cityID = id
        // Tell the page how much bottom space the pager's footer reserves so
        // the page's safeAreaLayoutGuide already excludes the glass capsule.
        vc.additionalSafeAreaInsets = UIEdgeInsets(
            top: 0, left: 0, bottom: Self.bottomBarReservedHeight, right: 0
        )
        pageCache[id] = vc
        return vc
    }

    private func pruneOrphans() {
        let live = Set(orderedIDs)
        pageCache = pageCache.filter { live.contains($0.key) }
    }

    @objc private func handleManageTap() {
        onMenuTapped?()
    }

    @objc private func handlePageControlTap() {
        let idx = pageControl.currentPage
        guard idx < orderedIDs.count else { return }
        store.send(.selectCity(orderedIDs[idx]))
    }
}

extension TodayViewController: UIPageViewControllerDataSource, UIPageViewControllerDelegate {
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerBefore viewController: UIViewController) -> UIViewController? {
        guard let page = viewController as? TodayPageViewController,
              let id = page.cityID,
              let index = orderedIDs.firstIndex(of: id),
              index > 0 else { return nil }
        return childController(for: orderedIDs[index - 1]) as UIViewController?
    }

    func pageViewController(_ pageViewController: UIPageViewController, viewControllerAfter viewController: UIViewController) -> UIViewController? {
        guard let page = viewController as? TodayPageViewController,
              let id = page.cityID,
              let index = orderedIDs.firstIndex(of: id),
              index < orderedIDs.count - 1 else { return nil }
        return childController(for: orderedIDs[index + 1]) as UIViewController?
    }

    func pageViewController(_ pageViewController: UIPageViewController, willTransitionTo pendingViewControllers: [UIViewController]) {
        isTransitioning = true
    }

    func pageViewController(_ pageViewController: UIPageViewController, didFinishAnimating finished: Bool, previousViewControllers: [UIViewController], transitionCompleted completed: Bool) {
        isTransitioning = false
        if completed,
           let visible = pageViewController.viewControllers?.first as? TodayPageViewController,
           let id = visible.cityID,
           id != store.selectedCityID {
            store.send(.selectCity(id))
        }

        // Flush a queued page change requested while a swipe was mid-flight.
        if let pendingID = pendingTargetID, let target = childController(for: pendingID) {
            pendingTargetID = nil
            let visibleID = currentlyVisibleID()
            applyPage(target: target, targetID: pendingID, visibleID: visibleID, ids: orderedIDs)
        }
    }
}

/// objc_*Association needs a stable address — the value is never read,
/// only its pointer is used as the key. `nonisolated(unsafe)` lets Swift 6
/// strict concurrency accept the global; the byte is never mutated.
private enum CityIDAssociation {
    nonisolated(unsafe) static var key: UInt8 = 0
}

extension TodayPageViewController {
    /// Stash the page's city id on the view controller so the data-source
    /// callbacks can recover it without scoping the store again. UIPageVC
    /// hands us back UIViewController in its delegate, and we need a way
    /// from that VC instance back to its position in the ordered list.
    var cityID: City.ID? {
        get { objc_getAssociatedObject(self, &CityIDAssociation.key) as? City.ID }
        set { objc_setAssociatedObject(self, &CityIDAssociation.key, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC) }
    }
}
