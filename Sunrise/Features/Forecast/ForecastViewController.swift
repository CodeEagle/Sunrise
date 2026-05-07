import UIKit
import SwiftUI
import ComposableArchitecture
import ForecastFeature
import SunriseCore
import SunriseDesignSystem

final class ForecastViewController: UIViewController {
    private let store: StoreOf<ForecastReducer>
    private var hostingController: UIHostingController<AnyView>?
    private let emptyLabel = UILabel()

    init(store: StoreOf<ForecastReducer>) {
        self.store = store
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError() }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = Palette.canvas

        title = String(localized: "forecast.nav_title", defaultValue: "15-day trend")

        emptyLabel.text = String(localized: "forecast.empty", defaultValue: "Pick a city on the Weather tab to see the 15-day outlook.")
        emptyLabel.font = Typography.body()
        emptyLabel.textColor = Palette.inkSecondary
        emptyLabel.textAlignment = .center
        emptyLabel.numberOfLines = 0
        emptyLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(emptyLabel)
        NSLayoutConstraint.activate([
            emptyLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            emptyLabel.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            emptyLabel.leadingAnchor.constraint(greaterThanOrEqualTo: view.leadingAnchor, constant: Spacing.l),
            emptyLabel.trailingAnchor.constraint(lessThanOrEqualTo: view.trailingAnchor, constant: -Spacing.l)
        ])

        observeState { [weak self] in self?.render() }
    }

    private func render() {
        guard let snapshot = store.snapshot else {
            emptyLabel.isHidden = false
            removeHostingController()
            return
        }
        emptyLabel.isHidden = true
        installOrUpdateHosting(snapshot: snapshot, settings: store.settings)
    }

    private func installOrUpdateHosting(snapshot: WeatherSnapshot, settings: UserSettings) {
        let chart = ForecastChartView(snapshot: snapshot, settings: settings)
        let view = AnyView(chart)
        if let host = hostingController {
            host.rootView = view
            return
        }
        let host = UIHostingController(rootView: view)
        addChild(host)
        host.view.translatesAutoresizingMaskIntoConstraints = false
        host.view.backgroundColor = .clear
        self.view.addSubview(host.view)
        NSLayoutConstraint.activate([
            host.view.topAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.topAnchor),
            host.view.leadingAnchor.constraint(equalTo: self.view.leadingAnchor),
            host.view.trailingAnchor.constraint(equalTo: self.view.trailingAnchor),
            host.view.bottomAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.bottomAnchor)
        ])
        host.didMove(toParent: self)
        hostingController = host
    }

    private func removeHostingController() {
        guard let host = hostingController else { return }
        host.willMove(toParent: nil)
        host.view.removeFromSuperview()
        host.removeFromParent()
        hostingController = nil
    }
}
