import UIKit
import ComposableArchitecture
import TodayFeature
import SunriseCore
import SunriseDesignSystem

final class TodayViewController: UIViewController {
    private let store: StoreOf<TodayReducer>

    private let backdrop = SceneBackgroundView()
    private let scrollView = UIScrollView()
    private let contentStack = UIStackView()
    private let scrim = UIView()

    private let cityLabel = UILabel()
    private let updatedLabel = UILabel()
    private let temperatureLabel = UILabel()
    private let conditionLabel = UILabel()
    private let detailRowLabel = UILabel()

    private let hourlyCollection: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        layout.itemSize = CGSize(width: 56, height: 88)
        layout.minimumInteritemSpacing = Spacing.xs
        layout.sectionInset = UIEdgeInsets(top: 0, left: Spacing.m, bottom: 0, right: Spacing.m)
        let cv = UICollectionView(frame: .zero, collectionViewLayout: layout)
        cv.backgroundColor = .clear
        cv.showsHorizontalScrollIndicator = false
        cv.alwaysBounceHorizontal = true
        return cv
    }()

    private let bubbleLabel = PaddedLabel()
    private let refreshControl = UIRefreshControl()

    var onMenuTapped: (() -> Void)?

    init(store: StoreOf<TodayReducer>) {
        self.store = store
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError() }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = Palette.canvas

        // Title becomes the scene's city pill, so hide the system nav title.
        navigationItem.titleView = UIView()
        navigationController?.navigationBar.isTranslucent = true
        navigationController?.navigationBar.setBackgroundImage(UIImage(), for: .default)
        navigationController?.navigationBar.shadowImage = UIImage()

        navigationItem.rightBarButtonItem = UIBarButtonItem(
            image: UIImage(systemName: "line.3.horizontal"),
            style: .plain,
            target: self,
            action: #selector(handleMenuTap)
        )
        navigationItem.rightBarButtonItem?.tintColor = Palette.inkPrimary

        configureLayout()

        observeState { [weak self] in
            self?.render()
        }

        store.send(.onAppear)
    }

    private func configureLayout() {
        backdrop.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(backdrop)

        // Soft cream-tinted scrim across the bottom 55% so overlay text and
        // the hourly strip stay readable over busy scene art.
        scrim.translatesAutoresizingMaskIntoConstraints = false
        scrim.isUserInteractionEnabled = false
        scrim.backgroundColor = .clear
        let gradient = CAGradientLayer()
        gradient.colors = [
            UIColor.clear.cgColor,
            Palette.canvas.withAlphaComponent(0.4).cgColor,
            Palette.canvas.withAlphaComponent(0.85).cgColor
        ]
        gradient.locations = [0.0, 0.4, 1.0]
        scrim.layer.addSublayer(gradient)
        scrimGradient = gradient
        view.addSubview(scrim)

        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.refreshControl = refreshControl
        scrollView.alwaysBounceVertical = true
        scrollView.backgroundColor = .clear
        refreshControl.addTarget(self, action: #selector(handleRefresh), for: .valueChanged)
        view.addSubview(scrollView)

        contentStack.axis = .vertical
        contentStack.spacing = Spacing.m
        contentStack.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(contentStack)

        NSLayoutConstraint.activate([
            backdrop.topAnchor.constraint(equalTo: view.topAnchor),
            backdrop.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            backdrop.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            backdrop.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            scrim.topAnchor.constraint(equalTo: view.topAnchor),
            scrim.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrim.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrim.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            contentStack.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor, constant: Spacing.m),
            contentStack.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor, constant: -Spacing.l),
            contentStack.leadingAnchor.constraint(equalTo: scrollView.frameLayoutGuide.leadingAnchor, constant: Spacing.l),
            contentStack.trailingAnchor.constraint(equalTo: scrollView.frameLayoutGuide.trailingAnchor, constant: -Spacing.l)
        ])

        contentStack.addArrangedSubview(buildHeader())
        contentStack.addArrangedSubview(spacer(height: 220))   // breathing room over the scene
        contentStack.addArrangedSubview(buildReadout())
        contentStack.addArrangedSubview(buildHourly())
        contentStack.addArrangedSubview(buildBubble())
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        scrimGradient?.frame = scrim.bounds
    }

    private var scrimGradient: CAGradientLayer?

    private func buildHeader() -> UIView {
        cityLabel.font = Typography.title(22)
        cityLabel.textColor = Palette.inkPrimary
        cityLabel.shadow(opacity: 0.2)

        updatedLabel.font = Typography.caption(12)
        updatedLabel.textColor = Palette.inkPrimary.withAlphaComponent(0.75)
        updatedLabel.shadow(opacity: 0.15)

        let stack = UIStackView(arrangedSubviews: [cityLabel, updatedLabel])
        stack.axis = .vertical
        stack.spacing = 2
        stack.alignment = .leading
        return stack
    }

    private func buildReadout() -> UIView {
        temperatureLabel.font = Typography.numeric(96)
        temperatureLabel.textColor = Palette.inkPrimary
        temperatureLabel.shadow(opacity: 0.25, radius: 4)

        conditionLabel.font = Typography.title(20)
        conditionLabel.textColor = Palette.inkPrimary
        conditionLabel.shadow(opacity: 0.2)

        detailRowLabel.font = Typography.body(14)
        detailRowLabel.textColor = Palette.inkSecondary
        detailRowLabel.numberOfLines = 0
        detailRowLabel.shadow(opacity: 0.15)

        let stack = UIStackView(arrangedSubviews: [temperatureLabel, conditionLabel, detailRowLabel])
        stack.axis = .vertical
        stack.spacing = Spacing.xs
        stack.alignment = .leading
        return stack
    }

    private func buildHourly() -> UIView {
        hourlyCollection.register(HourlyCollectionCell.self, forCellWithReuseIdentifier: HourlyCollectionCell.reuseID)
        hourlyCollection.dataSource = self
        hourlyCollection.translatesAutoresizingMaskIntoConstraints = false

        let container = UIView()
        container.backgroundColor = Palette.cloudWhite.withAlphaComponent(0.7)
        container.layer.cornerRadius = Radius.medium
        container.layer.cornerCurve = .continuous
        hourlyCollection.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(hourlyCollection)
        NSLayoutConstraint.activate([
            hourlyCollection.topAnchor.constraint(equalTo: container.topAnchor, constant: Spacing.s),
            hourlyCollection.bottomAnchor.constraint(equalTo: container.bottomAnchor, constant: -Spacing.s),
            hourlyCollection.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            hourlyCollection.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            container.heightAnchor.constraint(equalToConstant: 110)
        ])
        return container
    }

    private func buildBubble() -> UIView {
        bubbleLabel.font = Typography.body(15)
        bubbleLabel.textColor = Palette.inkPrimary
        bubbleLabel.numberOfLines = 0
        bubbleLabel.backgroundColor = Palette.cloudWhite.withAlphaComponent(0.9)
        bubbleLabel.layer.cornerRadius = Radius.medium
        bubbleLabel.layer.cornerCurve = .continuous
        bubbleLabel.layer.masksToBounds = true
        bubbleLabel.textAlignment = .left
        bubbleLabel.heightAnchor.constraint(greaterThanOrEqualToConstant: 56).isActive = true
        return bubbleLabel
    }

    private func spacer(height: CGFloat) -> UIView {
        let v = UIView()
        v.heightAnchor.constraint(equalToConstant: height).isActive = true
        v.backgroundColor = .clear
        return v
    }

    private func render() {
        let snapshot = store.snapshot
        let formatter = WeatherFormatter(settings: store.settings)

        cityLabel.text = store.selectedCity?.name
            ?? String(localized: "today.locating", defaultValue: "Locating…")

        if let snapshot {
            backdrop.update(
                conditionRawValue: snapshot.current.condition.rawValue,
                palette: palette(for: snapshot.current.condition, period: snapshot.current.dayPeriod),
                preferredAsset: "today_\(snapshot.current.condition.rawValue)"
            )
            temperatureLabel.text = formatter.temperature(snapshot.current.temperature) + "°"
            conditionLabel.text = String.localizedStringWithFormat(
                "%@ · %@",
                localizedCondition(snapshot.current.condition),
                String.localizedStringWithFormat(
                    String(localized: "today.feels_like", defaultValue: "Feels like %@°"),
                    formatter.temperature(snapshot.current.apparentTemperature)
                )
            )

            let humidity = String.localizedStringWithFormat(
                String(localized: "today.humidity_inline", defaultValue: "Humidity %@"),
                formatter.percent(snapshot.current.humidity)
            )
            let wind = String.localizedStringWithFormat(
                String(localized: "today.wind_inline", defaultValue: "Wind %@"),
                formatter.windSpeed(snapshot.current.wind)
            )
            let uv = String.localizedStringWithFormat(
                String(localized: "today.uv_inline", defaultValue: "UV %d"),
                snapshot.current.uvIndex
            )
            detailRowLabel.text = [wind, humidity, uv].joined(separator: "  ·  ")

            let updatedFormatter = DateFormatter()
            updatedFormatter.locale = formatter.locale
            updatedFormatter.dateStyle = .none
            updatedFormatter.timeStyle = .short
            updatedLabel.text = String.localizedStringWithFormat(
                String(localized: "today.updated_at", defaultValue: "Updated %@"),
                updatedFormatter.string(from: snapshot.updatedAt)
            )

            bubbleLabel.text = encouragement(for: snapshot.current.condition)
            hourlyCollection.reloadData()
        } else if store.isLoading {
            temperatureLabel.text = "–"
            conditionLabel.text = String(localized: "today.loading", defaultValue: "Fetching the latest forecast…")
            detailRowLabel.text = nil
            updatedLabel.text = nil
            bubbleLabel.text = nil
        } else if let error = store.error {
            temperatureLabel.text = "–"
            conditionLabel.text = String(localized: "today.error", defaultValue: "Couldn't fetch weather")
            detailRowLabel.text = error
            updatedLabel.text = nil
            bubbleLabel.text = nil
        }

        if !store.isLoading {
            refreshControl.endRefreshing()
        }
    }

    @objc private func handleRefresh() {
        store.send(.refreshTapped)
    }

    @objc private func handleMenuTap() {
        onMenuTapped?()
    }

    private func palette(for condition: WeatherCondition, period: DayPeriod) -> GradientPalette {
        switch (condition, period) {
        case (.clear, .night), (.clear, .dusk): return .clearNight
        case (.clear, _): return .clearDay
        case (.cloudy, _): return .cloudy
        case (.rain, _): return .rain
        case (.thunderstorm, _): return .thunderstorm
        case (.snow, _): return .snow
        case (.windy, _): return .windy
        case (.fog, _): return .fog
        }
    }

    private func localizedCondition(_ condition: WeatherCondition) -> String {
        switch condition {
        case .clear: return String(localized: "condition.clear", defaultValue: "Clear")
        case .cloudy: return String(localized: "condition.cloudy", defaultValue: "Cloudy")
        case .rain: return String(localized: "condition.rain", defaultValue: "Rain")
        case .thunderstorm: return String(localized: "condition.thunderstorm", defaultValue: "Thunderstorms")
        case .snow: return String(localized: "condition.snow", defaultValue: "Snow")
        case .windy: return String(localized: "condition.windy", defaultValue: "Windy")
        case .fog: return String(localized: "condition.fog", defaultValue: "Foggy")
        }
    }

    private func encouragement(for condition: WeatherCondition) -> String {
        switch condition {
        case .clear: return String(localized: "bubble.clear", defaultValue: "Beautiful day — let's go outside!")
        case .cloudy: return String(localized: "bubble.cloudy", defaultValue: "Clouds drifting by — what shape will they make next?")
        case .rain: return String(localized: "bubble.rain", defaultValue: "Don't forget your umbrella!")
        case .thunderstorm: return String(localized: "bubble.thunderstorm", defaultValue: "Storms incoming — stay safe indoors.")
        case .snow: return String(localized: "bubble.snow", defaultValue: "Snowflakes! Let's build a snowman.")
        case .windy: return String(localized: "bubble.windy", defaultValue: "Hold onto your hat — it's blustery out there!")
        case .fog: return String(localized: "bubble.fog", defaultValue: "Misty morning — drive carefully.")
        }
    }
}

extension TodayViewController: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        store.snapshot?.hourly.count ?? 0
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: HourlyCollectionCell.reuseID, for: indexPath) as! HourlyCollectionCell
        if let hour = store.snapshot?.hourly[indexPath.item] {
            cell.configure(
                with: hour,
                formatter: WeatherFormatter(settings: store.settings),
                calendar: .current
            )
        }
        return cell
    }
}

private final class PaddedLabel: UILabel {
    var insets = UIEdgeInsets(top: 12, left: 16, bottom: 12, right: 16)

    override func drawText(in rect: CGRect) {
        super.drawText(in: rect.inset(by: insets))
    }

    override var intrinsicContentSize: CGSize {
        let size = super.intrinsicContentSize
        return CGSize(width: size.width + insets.left + insets.right,
                      height: size.height + insets.top + insets.bottom)
    }
}

private extension UILabel {
    func shadow(opacity: Float, radius: CGFloat = 2) {
        layer.shadowColor = UIColor.white.cgColor
        layer.shadowOpacity = opacity
        layer.shadowRadius = radius
        layer.shadowOffset = .zero
        layer.masksToBounds = false
    }
}
