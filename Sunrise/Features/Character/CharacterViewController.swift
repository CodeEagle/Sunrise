import UIKit
import ComposableArchitecture
import CharacterFeature
import SunriseCore
import SunriseDesignSystem

/// Sunny tab — a single composite watercolor of the character + scene
/// (`portrait_<condition>.png`). No separate layered character on top of
/// the backdrop — that "pasted-over" reading was what the design
/// feedback flagged. The pose has Sunny looking at the camera, waving,
/// like she's greeting the viewer through the screen. Future iteration:
/// drop in a Seedance 2.0 generated video loop on top of (or in place
/// of) the static composite.
final class CharacterViewController: UIViewController {
    private let store: StoreOf<CharacterReducer>

    private let portrait = UIImageView()
    private let scrim = GradientView()
    private let conditionPill = UILabel()
    private let bubble = PaddedLabel()

    init(store: StoreOf<CharacterReducer>) {
        self.store = store
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError() }

    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.title = "character.nav_title".l10n("Sunny")
        view.backgroundColor = Palette.canvas

        configureLayout()
        observeState { [weak self] in self?.render() }
        onLanguageChange { [weak self] in
            self?.navigationItem.title = "character.nav_title".l10n("Sunny")
            self?.render()
        }
    }

    private func configureLayout() {
        // The composite is the full visual — fill the entire view and let
        // the painted scene reach into the safe-area edges.
        portrait.contentMode = .scaleAspectFill
        portrait.clipsToBounds = true
        portrait.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(portrait)

        // Subtle bottom scrim so the speech bubble has cream contrast even
        // when the painted ground is busy.
        scrim.translatesAutoresizingMaskIntoConstraints = false
        scrim.colors = [
            UIColor.clear,
            Palette.canvas.withAlphaComponent(0.0),
            Palette.canvas.withAlphaComponent(Opacity.glassStrong)
        ]
        scrim.locations = [0.0, 0.55, 1.0]
        scrim.isUserInteractionEnabled = false
        view.addSubview(scrim)

        // Condition pill — top-center.
        let conditionGlass = GlassPanel(style: .clear, cornerRadius: 18)
        conditionGlass.translatesAutoresizingMaskIntoConstraints = false
        conditionGlass.isUserInteractionEnabled = false
        conditionGlass.heightAnchor.constraint(equalToConstant: 36).isActive = true
        conditionGlass.addSubview(conditionPill)

        conditionPill.font = Typography.body(14)
        conditionPill.textColor = Palette.inkPrimary
        conditionPill.textAlignment = .center
        conditionPill.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            conditionPill.topAnchor.constraint(equalTo: conditionGlass.topAnchor),
            conditionPill.bottomAnchor.constraint(equalTo: conditionGlass.bottomAnchor),
            conditionPill.leadingAnchor.constraint(equalTo: conditionGlass.leadingAnchor, constant: Spacing.m),
            conditionPill.trailingAnchor.constraint(equalTo: conditionGlass.trailingAnchor, constant: -Spacing.m)
        ])
        view.addSubview(conditionGlass)

        // Speech bubble — bottom.
        bubble.font = Typography.body(15)
        bubble.textColor = Palette.inkPrimary
        bubble.numberOfLines = 0
        bubble.textAlignment = .center
        bubble.backgroundColor = .clear
        bubble.translatesAutoresizingMaskIntoConstraints = false

        let bubbleGlass = GlassPanel(style: .regular, cornerRadius: Radius.medium)
        bubbleGlass.translatesAutoresizingMaskIntoConstraints = false
        bubbleGlass.isUserInteractionEnabled = false
        view.addSubview(bubbleGlass)
        view.addSubview(bubble)

        NSLayoutConstraint.activate([
            portrait.topAnchor.constraint(equalTo: view.topAnchor),
            portrait.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            portrait.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            portrait.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            scrim.topAnchor.constraint(equalTo: view.topAnchor),
            scrim.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrim.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrim.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            conditionGlass.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: Spacing.s),
            conditionGlass.centerXAnchor.constraint(equalTo: view.centerXAnchor),

            bubble.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: Spacing.l),
            bubble.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -Spacing.l),
            bubble.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -Spacing.m),
            bubble.heightAnchor.constraint(greaterThanOrEqualToConstant: 56),

            bubbleGlass.topAnchor.constraint(equalTo: bubble.topAnchor),
            bubbleGlass.bottomAnchor.constraint(equalTo: bubble.bottomAnchor),
            bubbleGlass.leadingAnchor.constraint(equalTo: bubble.leadingAnchor),
            bubbleGlass.trailingAnchor.constraint(equalTo: bubble.trailingAnchor)
        ])
    }

    private func render() {
        let condition = store.condition
        portrait.image = PortraitArt.image(
            forConditionRawValue: condition.rawValue,
            periodRawValue: store.dayPeriod.rawValue
        ) ?? UIImage(systemName: "person.fill")
        conditionPill.text = localizedCondition(condition)
        let context = Greeting.Context(
            condition: condition,
            dayPeriod: store.dayPeriod,
            cityName: store.cityName,
            temperature: store.temperature,
            now: Date(),
            sunrise: store.sunrise,
            sunset: store.sunset,
            alerts: store.alerts
        )
        bubble.text = Greeting.line(for: context)
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

/// CAGradientLayer-backed view used by the bottom scrim. Adapts to the
/// system theme via `bindAdaptiveColors`.
private final class GradientView: UIView {
    var colors: [UIColor] = [] { didSet { sync() } }
    var locations: [NSNumber] = [] { didSet { sync() } }

    override class var layerClass: AnyClass { CAGradientLayer.self }

    override init(frame: CGRect) {
        super.init(frame: frame)
        bindAdaptiveColors { [weak self] _ in self?.sync() }
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
