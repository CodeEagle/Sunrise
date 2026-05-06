import UIKit
import ComposableArchitecture
import TodayFeature
import SunriseCore
import SunriseDesignSystem

final class TodayViewController: UIViewController {
    private let store: StoreOf<TodayReducer>

    private let scrollView = UIScrollView()
    private let stack = UIStackView()
    private let cityLabel = UILabel()
    private let conditionLabel = UILabel()
    private let temperatureLabel = UILabel()
    private let detailsLabel = UILabel()
    private let bubbleLabel = UILabel()
    private let refreshControl = UIRefreshControl()
    private let card = CardView()

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
        configureLayout()

        observeState { [weak self] in
            self?.render()
        }

        store.send(.onAppear)
    }

    private func configureLayout() {
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.refreshControl = refreshControl
        refreshControl.addTarget(self, action: #selector(handleRefresh), for: .valueChanged)
        view.addSubview(scrollView)

        card.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(card)

        stack.axis = .vertical
        stack.spacing = Spacing.s
        stack.translatesAutoresizingMaskIntoConstraints = false
        card.addSubview(stack)

        cityLabel.font = Typography.title(20)
        cityLabel.textColor = Palette.inkPrimary

        temperatureLabel.font = Typography.numeric(72)
        temperatureLabel.textColor = Palette.inkPrimary

        conditionLabel.font = Typography.body()
        conditionLabel.textColor = Palette.inkSecondary

        detailsLabel.font = Typography.caption()
        detailsLabel.textColor = Palette.inkSecondary
        detailsLabel.numberOfLines = 0

        bubbleLabel.font = Typography.body(15)
        bubbleLabel.textColor = Palette.inkPrimary
        bubbleLabel.numberOfLines = 0
        bubbleLabel.backgroundColor = Palette.cloudWhite.withAlphaComponent(0.85)
        bubbleLabel.layer.cornerRadius = Radius.medium
        bubbleLabel.layer.cornerCurve = .continuous
        bubbleLabel.layer.masksToBounds = true
        bubbleLabel.textAlignment = .center

        [cityLabel, temperatureLabel, conditionLabel, detailsLabel, bubbleLabel]
            .forEach(stack.addArrangedSubview)

        let frame = view.frameLayoutGuide
        let content = scrollView.contentLayoutGuide
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            card.topAnchor.constraint(equalTo: content.topAnchor, constant: Spacing.m),
            card.leadingAnchor.constraint(equalTo: frame.leadingAnchor, constant: Spacing.m),
            card.trailingAnchor.constraint(equalTo: frame.trailingAnchor, constant: -Spacing.m),
            card.bottomAnchor.constraint(equalTo: content.bottomAnchor, constant: -Spacing.m),

            stack.topAnchor.constraint(equalTo: card.topAnchor, constant: Spacing.l),
            stack.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: Spacing.l),
            stack.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -Spacing.l),
            stack.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -Spacing.l),

            bubbleLabel.heightAnchor.constraint(greaterThanOrEqualToConstant: 56)
        ])
    }

    private func render() {
        cityLabel.text = store.selectedCity?.name ?? String(localized: "today.locating", defaultValue: "Locating…")

        if let snapshot = store.snapshot {
            let formatter = WeatherFormatter(settings: store.settings)
            temperatureLabel.text = formatter.temperature(snapshot.current.temperature) + "°"
            conditionLabel.text = localizedCondition(snapshot.current.condition)
            let feels = String.localizedStringWithFormat(
                String(localized: "today.feels_like", defaultValue: "Feels like %@°"),
                formatter.temperature(snapshot.current.apparentTemperature)
            )
            let humidity = String.localizedStringWithFormat(
                String(localized: "today.humidity", defaultValue: "Humidity %@"),
                formatter.percent(snapshot.current.humidity)
            )
            let wind = String.localizedStringWithFormat(
                String(localized: "today.wind", defaultValue: "Wind %@"),
                formatter.windSpeed(snapshot.current.wind)
            )
            detailsLabel.text = [feels, humidity, wind].joined(separator: "  ·  ")
            bubbleLabel.text = encouragement(for: snapshot.current.condition)
        } else if store.isLoading {
            temperatureLabel.text = "–"
            conditionLabel.text = String(localized: "today.loading", defaultValue: "Fetching the latest forecast…")
            detailsLabel.text = nil
            bubbleLabel.text = nil
        } else if let error = store.error {
            temperatureLabel.text = "–"
            conditionLabel.text = String(localized: "today.error", defaultValue: "Couldn't fetch weather")
            detailsLabel.text = error
            bubbleLabel.text = nil
        }

        if !store.isLoading {
            refreshControl.endRefreshing()
        }
    }

    @objc private func handleRefresh() {
        store.send(.refreshTapped)
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
