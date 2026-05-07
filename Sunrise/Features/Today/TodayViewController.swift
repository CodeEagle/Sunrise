import UIKit
import ComposableArchitecture
import TodayFeature
import SunriseCore
import SunriseDesignSystem

/// Single-screen Today layout that matches the design board 1:1: a full-bleed
/// scene illustration with the city name + temperature + condition + wind /
/// humidity / UV row + speech bubble all anchored to the bottom-left, layered
/// over the scene with light shadows for legibility.
final class TodayViewController: UIViewController {
    private let store: StoreOf<TodayReducer>

    private let backdrop = SceneBackgroundView()

    private let cityLabel = UILabel()
    private let cityCaret = UIImageView(image: UIImage(systemName: "chevron.down"))
    private let updatedLabel = UILabel()

    private let temperatureLabel = UILabel()
    private let highLowLabel = UILabel()
    private let conditionLabel = UILabel()
    private let detailRowLabel = UILabel()

    private let bubble = BubbleView()
    private let scrim = GradientView()

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

        configureNavigationBar()
        configureLayout()

        observeState { [weak self] in self?.render() }
        store.send(.onAppear)
    }

    private func configureNavigationBar() {
        navigationController?.navigationBar.isTranslucent = true
        navigationController?.navigationBar.setBackgroundImage(UIImage(), for: .default)
        navigationController?.navigationBar.shadowImage = UIImage()

        cityLabel.font = Typography.title(20)
        cityLabel.textColor = Palette.inkPrimary
        cityCaret.tintColor = Palette.inkPrimary
        cityCaret.contentMode = .scaleAspectFit
        cityCaret.translatesAutoresizingMaskIntoConstraints = false
        cityCaret.widthAnchor.constraint(equalToConstant: 12).isActive = true

        let cityRow = UIStackView(arrangedSubviews: [cityLabel, cityCaret])
        cityRow.axis = .horizontal
        cityRow.alignment = .center
        cityRow.spacing = 4
        navigationItem.titleView = cityRow

        navigationItem.rightBarButtonItem = UIBarButtonItem(
            image: UIImage(systemName: "line.3.horizontal"),
            style: .plain,
            target: self,
            action: #selector(handleMenuTap)
        )
        navigationItem.rightBarButtonItem?.tintColor = Palette.inkPrimary
    }

    private func configureLayout() {
        backdrop.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(backdrop)

        scrim.translatesAutoresizingMaskIntoConstraints = false
        // Cream wash from ~55% downward so dark text stays legible over the
        // busy painted scene (the character & rooftops live in that area).
        scrim.colors = [
            UIColor.clear,
            Palette.canvas.withAlphaComponent(0.0),
            Palette.canvas.withAlphaComponent(0.85)
        ]
        scrim.locations = [0.0, 0.55, 1.0]
        scrim.isUserInteractionEnabled = false
        view.addSubview(scrim)

        updatedLabel.font = Typography.caption(12)
        updatedLabel.textColor = Palette.inkSecondary
        updatedLabel.shadow()

        temperatureLabel.font = Typography.numeric(96)
        temperatureLabel.textColor = Palette.inkPrimary
        temperatureLabel.shadow(opacity: 0.25, radius: 4)

        highLowLabel.font = Typography.title(18)
        highLowLabel.textColor = Palette.inkSecondary
        highLowLabel.shadow()

        let tempRow = UIStackView(arrangedSubviews: [temperatureLabel, highLowLabel])
        tempRow.axis = .horizontal
        tempRow.alignment = .lastBaseline
        tempRow.spacing = Spacing.s

        conditionLabel.font = Typography.title(18)
        conditionLabel.textColor = Palette.inkPrimary
        conditionLabel.shadow()

        detailRowLabel.font = Typography.body(14)
        detailRowLabel.textColor = Palette.inkSecondary
        detailRowLabel.numberOfLines = 0
        detailRowLabel.shadow()

        let infoStack = UIStackView(arrangedSubviews: [updatedLabel, tempRow, conditionLabel, detailRowLabel, bubble])
        infoStack.axis = .vertical
        infoStack.alignment = .leading
        infoStack.spacing = Spacing.s
        infoStack.setCustomSpacing(Spacing.m, after: detailRowLabel)
        infoStack.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(infoStack)

        NSLayoutConstraint.activate([
            backdrop.topAnchor.constraint(equalTo: view.topAnchor),
            backdrop.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            backdrop.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            backdrop.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            scrim.topAnchor.constraint(equalTo: view.topAnchor),
            scrim.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrim.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrim.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            infoStack.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: Spacing.l),
            infoStack.trailingAnchor.constraint(lessThanOrEqualTo: view.trailingAnchor, constant: -Spacing.l),
            infoStack.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -Spacing.m),

            bubble.widthAnchor.constraint(equalTo: infoStack.widthAnchor)
        ])
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

            if let high = snapshot.daily.first?.highTemperature {
                highLowLabel.text = String.localizedStringWithFormat(
                    String(localized: "today.high_pill", defaultValue: "%@ %@°"),
                    localizedCondition(snapshot.current.condition),
                    formatter.temperature(high)
                )
            } else {
                highLowLabel.text = localizedCondition(snapshot.current.condition)
            }

            conditionLabel.text = String.localizedStringWithFormat(
                String(localized: "today.feels_like", defaultValue: "Feels like %@°"),
                formatter.temperature(snapshot.current.apparentTemperature)
            )

            let wind = String.localizedStringWithFormat(
                String(localized: "today.wind_inline", defaultValue: "Wind %@"),
                formatter.windSpeed(snapshot.current.wind)
            )
            let humidity = String.localizedStringWithFormat(
                String(localized: "today.humidity_inline", defaultValue: "Humidity %@"),
                formatter.percent(snapshot.current.humidity)
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

            bubble.text = encouragement(for: snapshot.current.condition)
            bubble.isHidden = false
        } else if store.isLoading {
            temperatureLabel.text = "–"
            highLowLabel.text = nil
            conditionLabel.text = String(localized: "today.loading", defaultValue: "Fetching the latest forecast…")
            detailRowLabel.text = nil
            updatedLabel.text = nil
            bubble.isHidden = true
        } else if let error = store.error {
            temperatureLabel.text = "–"
            highLowLabel.text = nil
            conditionLabel.text = String(localized: "today.error", defaultValue: "Couldn't fetch weather")
            detailRowLabel.text = error
            updatedLabel.text = nil
            bubble.isHidden = true
        }
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

private final class BubbleView: UIView {
    private let label = UILabel()
    private let speakerIcon = UIImageView(image: UIImage(systemName: "speaker.wave.2.fill"))

    var text: String? {
        get { label.text }
        set { label.text = newValue }
    }

    init() {
        super.init(frame: .zero)
        backgroundColor = Palette.cloudWhite.withAlphaComponent(0.9)
        layer.cornerRadius = Radius.medium
        layer.cornerCurve = .continuous

        label.font = Typography.body(14)
        label.textColor = Palette.inkPrimary
        label.numberOfLines = 0
        label.translatesAutoresizingMaskIntoConstraints = false

        speakerIcon.tintColor = Palette.inkSecondary
        speakerIcon.contentMode = .scaleAspectFit
        speakerIcon.translatesAutoresizingMaskIntoConstraints = false

        addSubview(label)
        addSubview(speakerIcon)

        NSLayoutConstraint.activate([
            label.topAnchor.constraint(equalTo: topAnchor, constant: 12),
            label.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -12),
            label.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            label.trailingAnchor.constraint(equalTo: speakerIcon.leadingAnchor, constant: -8),

            speakerIcon.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
            speakerIcon.centerYAnchor.constraint(equalTo: centerYAnchor),
            speakerIcon.widthAnchor.constraint(equalToConstant: 18),
            speakerIcon.heightAnchor.constraint(equalToConstant: 18)
        ])
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError() }
}

private final class GradientView: UIView {
    var colors: [UIColor] = [] { didSet { sync() } }
    var locations: [NSNumber] = [] { didSet { sync() } }

    override class var layerClass: AnyClass { CAGradientLayer.self }

    private func sync() {
        guard let layer = layer as? CAGradientLayer else { return }
        layer.colors = colors.map { $0.cgColor }
        layer.locations = locations
        layer.startPoint = CGPoint(x: 0.5, y: 0)
        layer.endPoint = CGPoint(x: 0.5, y: 1)
    }
}

private extension UILabel {
    /// Soft white halo around dark text, so labels stay legible over the
    /// busy painted scenes behind them.
    func shadow(opacity: Float = 0.85, radius: CGFloat = 4) {
        layer.shadowColor = UIColor.white.cgColor
        layer.shadowOpacity = opacity
        layer.shadowRadius = radius
        layer.shadowOffset = .zero
        layer.masksToBounds = false
    }
}
