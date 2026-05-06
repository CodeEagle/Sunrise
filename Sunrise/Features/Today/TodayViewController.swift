import UIKit
import ComposableArchitecture
import TodayFeature
import SunriseCore
import SunriseDesignSystem

final class TodayViewController: UIViewController {
    private let store: StoreOf<TodayReducer>

    private let scrollView = UIScrollView()
    private let contentStack = UIStackView()
    private let backdrop = SceneBackgroundView()

    private let cityLabel = UILabel()
    private let updatedLabel = UILabel()
    private let temperatureLabel = UILabel()
    private let conditionLabel = UILabel()
    private let feelsLabel = UILabel()
    private let heroCharacterImage = UIImageView()

    private let hourlyCollection: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        layout.itemSize = CGSize(width: 64, height: 96)
        layout.minimumInteritemSpacing = Spacing.xs
        layout.sectionInset = UIEdgeInsets(top: 0, left: Spacing.m, bottom: 0, right: Spacing.m)
        let cv = UICollectionView(frame: .zero, collectionViewLayout: layout)
        cv.backgroundColor = .clear
        cv.showsHorizontalScrollIndicator = false
        cv.alwaysBounceHorizontal = true
        return cv
    }()

    private let detailsRow = UIStackView()
    private let humidityPill = PillView()
    private let windPill = PillView()
    private let uvPill = PillView()

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
        title = String(localized: "tab.today", defaultValue: "Weather")
        view.backgroundColor = Palette.canvas

        navigationItem.rightBarButtonItem = UIBarButtonItem(
            image: UIImage(systemName: "list.bullet"),
            style: .plain,
            target: self,
            action: #selector(handleMenuTap)
        )

        configureLayout()

        observeState { [weak self] in
            self?.render()
        }

        store.send(.onAppear)
    }

    private func configureLayout() {
        backdrop.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(backdrop)
        NSLayoutConstraint.activate([
            backdrop.topAnchor.constraint(equalTo: view.topAnchor),
            backdrop.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            backdrop.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            backdrop.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])

        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.refreshControl = refreshControl
        scrollView.alwaysBounceVertical = true
        refreshControl.addTarget(self, action: #selector(handleRefresh), for: .valueChanged)
        view.addSubview(scrollView)
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])

        contentStack.axis = .vertical
        contentStack.spacing = Spacing.l
        contentStack.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(contentStack)
        NSLayoutConstraint.activate([
            contentStack.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor, constant: Spacing.m),
            contentStack.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor, constant: -Spacing.l),
            contentStack.leadingAnchor.constraint(equalTo: scrollView.frameLayoutGuide.leadingAnchor, constant: Spacing.m),
            contentStack.trailingAnchor.constraint(equalTo: scrollView.frameLayoutGuide.trailingAnchor, constant: -Spacing.m)
        ])

        contentStack.addArrangedSubview(buildHeroCard())
        contentStack.addArrangedSubview(buildHourlyCard())
        contentStack.addArrangedSubview(buildDetailsCard())
        contentStack.addArrangedSubview(buildBubble())
    }

    private func buildHeroCard() -> UIView {
        let card = CardView()
        card.translatesAutoresizingMaskIntoConstraints = false

        cityLabel.font = Typography.title(20)
        cityLabel.textColor = Palette.inkPrimary

        updatedLabel.font = Typography.caption(12)
        updatedLabel.textColor = Palette.inkSecondary

        temperatureLabel.font = Typography.numeric(80)
        temperatureLabel.textColor = Palette.inkPrimary

        conditionLabel.font = Typography.body(16)
        conditionLabel.textColor = Palette.inkSecondary

        feelsLabel.font = Typography.caption(13)
        feelsLabel.textColor = Palette.inkSecondary

        let titleStack = UIStackView(arrangedSubviews: [cityLabel, updatedLabel])
        titleStack.axis = .vertical
        titleStack.spacing = 2

        let textColumn = UIStackView(arrangedSubviews: [titleStack, temperatureLabel, conditionLabel, feelsLabel])
        textColumn.axis = .vertical
        textColumn.spacing = Spacing.xs
        textColumn.alignment = .leading
        textColumn.translatesAutoresizingMaskIntoConstraints = false
        card.addSubview(textColumn)

        heroCharacterImage.contentMode = .scaleAspectFit
        heroCharacterImage.translatesAutoresizingMaskIntoConstraints = false
        // 1024×1024 PNG would otherwise drag the card to 1000pt+; force a 1:1
        // box at 45% of the card width and let the card size to text height.
        heroCharacterImage.setContentHuggingPriority(.defaultLow, for: .vertical)
        heroCharacterImage.setContentCompressionResistancePriority(.defaultLow, for: .vertical)
        card.addSubview(heroCharacterImage)

        NSLayoutConstraint.activate([
            textColumn.topAnchor.constraint(equalTo: card.topAnchor, constant: Spacing.l),
            textColumn.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: Spacing.l),
            textColumn.trailingAnchor.constraint(lessThanOrEqualTo: heroCharacterImage.leadingAnchor, constant: -Spacing.xs),

            heroCharacterImage.topAnchor.constraint(equalTo: card.topAnchor, constant: Spacing.s),
            heroCharacterImage.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -Spacing.s),
            heroCharacterImage.widthAnchor.constraint(equalTo: card.widthAnchor, multiplier: 0.45),
            heroCharacterImage.heightAnchor.constraint(equalTo: heroCharacterImage.widthAnchor),

            card.bottomAnchor.constraint(greaterThanOrEqualTo: textColumn.bottomAnchor, constant: Spacing.l),
            card.bottomAnchor.constraint(greaterThanOrEqualTo: heroCharacterImage.bottomAnchor, constant: Spacing.s)
        ])

        return card
    }

    private func buildHourlyCard() -> UIView {
        hourlyCollection.register(HourlyCollectionCell.self, forCellWithReuseIdentifier: HourlyCollectionCell.reuseID)
        hourlyCollection.dataSource = self
        hourlyCollection.translatesAutoresizingMaskIntoConstraints = false
        hourlyCollection.heightAnchor.constraint(equalToConstant: 110).isActive = true
        return hourlyCollection
    }

    private func buildDetailsCard() -> UIView {
        detailsRow.axis = .horizontal
        detailsRow.distribution = .fillEqually
        detailsRow.spacing = Spacing.s
        [humidityPill, windPill, uvPill].forEach(detailsRow.addArrangedSubview)
        detailsRow.heightAnchor.constraint(equalToConstant: 72).isActive = true
        return detailsRow
    }

    private func buildBubble() -> UIView {
        bubbleLabel.font = Typography.body(15)
        bubbleLabel.textColor = Palette.inkPrimary
        bubbleLabel.numberOfLines = 0
        bubbleLabel.backgroundColor = Palette.cloudWhite.withAlphaComponent(0.85)
        bubbleLabel.layer.cornerRadius = Radius.medium
        bubbleLabel.layer.cornerCurve = .continuous
        bubbleLabel.layer.masksToBounds = true
        bubbleLabel.textAlignment = .center
        bubbleLabel.heightAnchor.constraint(greaterThanOrEqualToConstant: 56).isActive = true
        return bubbleLabel
    }

    private func render() {
        let snapshot = store.snapshot
        let formatter = WeatherFormatter(settings: store.settings)

        cityLabel.text = store.selectedCity?.name
            ?? String(localized: "today.locating", defaultValue: "Locating…")

        if let snapshot {
            backdrop.update(
                conditionRawValue: snapshot.current.condition.rawValue,
                palette: palette(for: snapshot.current.condition, period: snapshot.current.dayPeriod)
            )
            heroCharacterImage.image = CharacterArt.image(forConditionRawValue: snapshot.current.condition.rawValue)
            temperatureLabel.text = formatter.temperature(snapshot.current.temperature) + "°"
            conditionLabel.text = localizedCondition(snapshot.current.condition)
            feelsLabel.text = String.localizedStringWithFormat(
                String(localized: "today.feels_like", defaultValue: "Feels like %@°"),
                formatter.temperature(snapshot.current.apparentTemperature)
            )

            let updatedFormatter = DateFormatter()
            updatedFormatter.locale = formatter.locale
            updatedFormatter.dateStyle = .none
            updatedFormatter.timeStyle = .short
            updatedLabel.text = String.localizedStringWithFormat(
                String(localized: "today.updated_at", defaultValue: "Updated %@"),
                updatedFormatter.string(from: snapshot.updatedAt)
            )

            humidityPill.setContent(
                title: String(localized: "today.humidity_title", defaultValue: "Humidity"),
                value: formatter.percent(snapshot.current.humidity)
            )
            windPill.setContent(
                title: String(localized: "today.wind_title", defaultValue: "Wind"),
                value: formatter.windSpeed(snapshot.current.wind)
            )
            uvPill.setContent(
                title: String(localized: "today.uv_title", defaultValue: "UV Index"),
                value: "\(snapshot.current.uvIndex)"
            )

            bubbleLabel.text = encouragement(for: snapshot.current.condition)
            hourlyCollection.reloadData()
        } else if store.isLoading {
            temperatureLabel.text = "–"
            conditionLabel.text = String(localized: "today.loading", defaultValue: "Fetching the latest forecast…")
            feelsLabel.text = nil
            updatedLabel.text = nil
            bubbleLabel.text = nil
        } else if let error = store.error {
            temperatureLabel.text = "–"
            conditionLabel.text = String(localized: "today.error", defaultValue: "Couldn't fetch weather")
            feelsLabel.text = error
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
