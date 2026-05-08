import UIKit
import ComposableArchitecture
import CharacterFeature
import SunriseCore
import SunriseDesignSystem

/// Character tab — Sunny's standing portrait layered over the live weather
/// scene. The mood / outfit / voice chips are gone; this screen now reads as
/// a character poster with a small speech bubble. Will host a Seedance 2.0
/// generated video loop in a follow-up — for now the static portrait sits in
/// for the video player.
final class CharacterViewController: UIViewController {
    private let store: StoreOf<CharacterReducer>

    private let backdrop = SceneBackgroundView()
    private let portrait = UIImageView()
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
        navigationItem.title = String(localized: "character.nav_title", defaultValue: "Sunny")
        view.backgroundColor = Palette.canvas

        configureLayout()
        observeState { [weak self] in self?.render() }
    }

    private func configureLayout() {
        backdrop.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(backdrop)

        portrait.contentMode = .scaleAspectFit
        portrait.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(portrait)

        // Floating glass pill that names the current weather condition —
        // pinned top-center so the user reads "what is Sunny standing in".
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

        // Speech bubble — sits below the portrait, above the bottom safe area.
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
            backdrop.topAnchor.constraint(equalTo: view.topAnchor),
            backdrop.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            backdrop.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            backdrop.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            conditionGlass.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: Spacing.s),
            conditionGlass.centerXAnchor.constraint(equalTo: view.centerXAnchor),

            // Portrait fills most of the screen; full-body character anchored
            // bottom-aligned so feet sit just above the speech bubble. Width
            // capped so very tall devices don't blow up the figure.
            portrait.topAnchor.constraint(equalTo: conditionGlass.bottomAnchor, constant: Spacing.s),
            portrait.bottomAnchor.constraint(equalTo: bubble.topAnchor, constant: -Spacing.m),
            portrait.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            portrait.widthAnchor.constraint(lessThanOrEqualTo: view.widthAnchor, multiplier: 0.92),

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

        // Backdrop: weather scene (bg_<condition>.png). The painted scene gives
        // Sunny a setting that matches the weather she's reacting to.
        backdrop.update(
            conditionRawValue: condition.rawValue,
            palette: palette(for: condition),
            preferredAsset: "bg_\(condition.rawValue)",
            animated: true
        )

        // Foreground portrait: full-body Sunny in the matching outfit.
        portrait.image = CharacterArt.image(forConditionRawValue: condition.rawValue)
            ?? UIImage(systemName: "person.fill")

        conditionPill.text = localizedCondition(condition)
        bubble.text = encouragement(for: condition)
    }

    private func palette(for condition: WeatherCondition) -> GradientPalette {
        switch condition {
        case .clear: return .clearDay
        case .cloudy: return .cloudy
        case .rain: return .rain
        case .thunderstorm: return .thunderstorm
        case .snow: return .snow
        case .windy: return .windy
        case .fog: return .fog
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
