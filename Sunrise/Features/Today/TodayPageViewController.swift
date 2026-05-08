import UIKit
import ComposableArchitecture
import TodayFeature
import SunriseCore
import SunriseDesignSystem

/// One city's page within the Today pager. Renders a full-bleed scene with
/// the city header pinned near the top of the safe area (moved out of the
/// nav title view, per design feedback) and the temperature / condition /
/// detail row anchored to the bottom-left.
final class TodayPageViewController: UIViewController {
    private let store: StoreOf<TodayPageReducer>

    private let backdrop = SceneBackgroundView()
    private let scrim = GradientView()

    // City header (lives in the body now, not the nav title)
    private let cityPin = UIImageView(image: UIImage(systemName: "location.fill"))
    private let cityLabel = UILabel()
    private let updatedLabel = UILabel()

    private let temperatureLabel = UILabel()
    private let apparentLabel = UILabel()
    private let conditionLabel = UILabel()
    private let detailRowLabel = UILabel()

    private let bubble = BubbleView()
    private let retryButton = UIButton(type: .system)

    init(store: StoreOf<TodayPageReducer>) {
        self.store = store
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError() }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = Palette.canvas
        configureLayout()
        observeState { [weak self] in self?.render() }
        onLanguageChange { [weak self] in self?.render() }
        store.send(.onAppear)
    }

    private func configureLayout() {
        backdrop.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(backdrop)

        scrim.translatesAutoresizingMaskIntoConstraints = false
        scrim.colors = [
            UIColor.clear,
            Palette.canvas.withAlphaComponent(0.0),
            Palette.canvas.withAlphaComponent(Opacity.glassStrong)
        ]
        scrim.locations = [0.0, 0.55, 1.0]
        scrim.isUserInteractionEnabled = false
        view.addSubview(scrim)

        // City header — pin glyph + name + caret + updated time, stacked.
        // Lives at the TOP of the bottom info stack (not as a separate top
        // banner) so the painted scene's character / sky stay fully visible
        // and we don't double up two text columns at top + bottom.
        cityPin.tintColor = Palette.sunYellow
        cityPin.contentMode = .scaleAspectFit
        cityPin.translatesAutoresizingMaskIntoConstraints = false
        cityPin.widthAnchor.constraint(equalToConstant: 14).isActive = true
        cityPin.heightAnchor.constraint(equalToConstant: 14).isActive = true

        cityLabel.font = Typography.title(20)
        cityLabel.textColor = Palette.inkPrimary
        cityLabel.shadow()

        let cityRow = UIStackView(arrangedSubviews: [cityPin, cityLabel])
        cityRow.axis = .horizontal
        cityRow.alignment = .center
        cityRow.spacing = 4

        updatedLabel.font = Typography.caption(11)
        updatedLabel.textColor = Palette.inkPrimary.withAlphaComponent(0.7)
        updatedLabel.shadow(opacity: 0.4, radius: 2)

        temperatureLabel.font = Typography.numeric(96)
        temperatureLabel.textColor = Palette.inkPrimary
        temperatureLabel.shadow(opacity: 0.25, radius: 4)

        apparentLabel.font = Typography.body(14)
        apparentLabel.textColor = Palette.inkSecondary
        apparentLabel.shadow()

        let tempRow = UIStackView(arrangedSubviews: [temperatureLabel, apparentLabel])
        tempRow.axis = .horizontal
        tempRow.alignment = .lastBaseline
        tempRow.spacing = Spacing.s

        conditionLabel.font = Typography.title(24)
        conditionLabel.textColor = Palette.inkPrimary
        conditionLabel.shadow()

        detailRowLabel.font = Typography.body(13)
        detailRowLabel.textColor = Palette.inkSecondary
        detailRowLabel.numberOfLines = 0
        detailRowLabel.shadow()

        var retryConfig = UIButton.Configuration.tinted()
        retryConfig.cornerStyle = .capsule
        retryConfig.title = "today.retry".l10n("Retry")
        retryConfig.image = UIImage(systemName: "arrow.clockwise")
        retryConfig.imagePadding = 6
        retryConfig.baseBackgroundColor = Palette.canvas
        retryConfig.baseForegroundColor = Palette.inkPrimary
        retryButton.configuration = retryConfig
        retryButton.addTarget(self, action: #selector(handleRetryTap), for: .touchUpInside)
        retryButton.isHidden = true

        let infoStack = UIStackView(arrangedSubviews: [
            cityRow, updatedLabel, tempRow, conditionLabel, detailRowLabel, retryButton, bubble
        ])
        infoStack.axis = .vertical
        infoStack.alignment = .leading
        infoStack.spacing = Spacing.xs
        infoStack.setCustomSpacing(Spacing.s, after: updatedLabel)
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
            // safeAreaLayoutGuide.bottom already has the pager's footer
            // reserved (see TodayViewController setting additionalSafeAreaInsets
            // on each child), so a small extra m gap here just clears the
            // glass capsule visually.
            infoStack.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -Spacing.s),

            bubble.widthAnchor.constraint(equalTo: infoStack.widthAnchor)
        ])
    }

    private func render() {
        let snapshot = store.snapshot
        let formatter = WeatherFormatter(settings: store.settings)

        cityLabel.text = displayName(for: store.city)

        if let snapshot {
            backdrop.update(
                conditionRawValue: snapshot.current.condition.rawValue,
                palette: palette(for: snapshot.current.condition, period: snapshot.current.dayPeriod),
                preferredAsset: "today_\(snapshot.current.condition.rawValue)",
                animated: true
            )

            temperatureLabel.text = formatter.temperature(snapshot.current.temperature) + "°"

            apparentLabel.text = String.localizedStringWithFormat(
                "today.feels_like".l10n("Feels like %@°"),
                formatter.temperature(snapshot.current.apparentTemperature)
            )

            conditionLabel.text = localizedCondition(snapshot.current.condition)

            let wind = String.localizedStringWithFormat(
                "today.wind_inline".l10n("Wind %@"),
                formatter.windSpeed(snapshot.current.wind)
            )
            let humidity = String.localizedStringWithFormat(
                "today.humidity_inline".l10n("Humidity %@"),
                formatter.percent(snapshot.current.humidity)
            )
            let uv = String.localizedStringWithFormat(
                "today.uv_inline".l10n("UV %d"),
                snapshot.current.uvIndex
            )
            detailRowLabel.text = [wind, humidity, uv].joined(separator: "  ·  ")

            let updatedFormatter = DateFormatter()
            updatedFormatter.locale = formatter.locale
            updatedFormatter.dateStyle = .none
            updatedFormatter.timeStyle = .short
            updatedLabel.text = String.localizedStringWithFormat(
                "today.updated_at".l10n("Updated %@"),
                updatedFormatter.string(from: snapshot.updatedAt)
            )

            bubble.text = encouragement(for: snapshot.current.condition)
            bubble.isHidden = false
        } else if store.isLoading {
            temperatureLabel.text = "–"
            apparentLabel.text = nil
            conditionLabel.text = "today.loading".l10n("Fetching the latest forecast…")
            detailRowLabel.text = nil
            updatedLabel.text = nil
            bubble.isHidden = true
        } else if let error = store.error {
            temperatureLabel.text = "–"
            apparentLabel.text = nil
            conditionLabel.text = "today.error".l10n("Couldn't fetch weather")
            detailRowLabel.text = error
            updatedLabel.text = nil
            bubble.isHidden = true
        }

        retryButton.isHidden = (store.error == nil)
    }

    @objc private func handleRetryTap() {
        store.send(.retryTapped)
    }

    /// Localised display name for a city. The synthesised "current location"
    /// city carries a fixed English `name` (City has no kind enum so the
    /// pager and persistence stay simple) — translate it on the fly so the
    /// label flips with the active language.
    private func displayName(for city: City) -> String {
        if city.name == "Current Location" {
            return "today.current_location".l10n("Current Location")
        }
        return city.name
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
        case .clear: return "condition.clear".l10n("Clear")
        case .cloudy: return "condition.cloudy".l10n("Cloudy")
        case .rain: return "condition.rain".l10n("Rain")
        case .thunderstorm: return "condition.thunderstorm".l10n("Thunderstorms")
        case .snow: return "condition.snow".l10n("Snow")
        case .windy: return "condition.windy".l10n("Windy")
        case .fog: return "condition.fog".l10n("Foggy")
        }
    }

    private func encouragement(for condition: WeatherCondition) -> String {
        switch condition {
        case .clear: return "bubble.clear".l10n("Beautiful day — let's go outside!")
        case .cloudy: return "bubble.cloudy".l10n("Clouds drifting by — what shape will they make next?")
        case .rain: return "bubble.rain".l10n("Don't forget your umbrella!")
        case .thunderstorm: return "bubble.thunderstorm".l10n("Storms incoming — stay safe indoors.")
        case .snow: return "bubble.snow".l10n("Snowflakes! Let's build a snowman.")
        case .windy: return "bubble.windy".l10n("Hold onto your hat — it's blustery out there!")
        case .fog: return "bubble.fog".l10n("Misty morning — drive carefully.")
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
        backgroundColor = .clear

        let glass = GlassPanel(style: .regular, cornerRadius: Radius.medium)
        glass.translatesAutoresizingMaskIntoConstraints = false
        glass.isUserInteractionEnabled = false
        addSubview(glass)
        NSLayoutConstraint.activate([
            glass.topAnchor.constraint(equalTo: topAnchor),
            glass.bottomAnchor.constraint(equalTo: bottomAnchor),
            glass.leadingAnchor.constraint(equalTo: leadingAnchor),
            glass.trailingAnchor.constraint(equalTo: trailingAnchor)
        ])

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

    override init(frame: CGRect) {
        super.init(frame: frame)
        bindAdaptiveColors { [weak self] _ in
            self?.sync()
        }
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError() }

    private func sync() {
        guard let layer = layer as? CAGradientLayer else { return }
        layer.colors = colors.map { $0.resolvedColor(with: traitCollection).cgColor }
        layer.locations = locations
        layer.startPoint = CGPoint(x: 0.5, y: 0)
        layer.endPoint = CGPoint(x: 0.5, y: 1)
    }
}

private extension UILabel {
    func shadow(opacity: Float = Float(Opacity.halo), radius: CGFloat = 4) {
        layer.shadowOpacity = opacity
        layer.shadowRadius = radius
        layer.shadowOffset = .zero
        layer.masksToBounds = false
        bindAdaptiveColors { [weak self] traits in
            self?.layer.shadowColor = Palette.textHalo.resolvedColor(with: traits).cgColor
        }
    }
}
