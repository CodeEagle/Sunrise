import UIKit
import ComposableArchitecture
import CharacterFeature
import SunriseCore
import SunriseDesignSystem
import SunriseAnimation

final class CharacterViewController: UIViewController {
    private let store: StoreOf<CharacterReducer>

    private let backdrop = SceneBackgroundView()
    private let scrim = UIView()
    private var scrimGradient: CAGradientLayer?

    private let sunshineLabel = UILabel()
    private let portraitFallback = UIImageView()
    private lazy var characterView = LottieCharacterView(fallbackView: portraitFallback)
    private let bubble = PaddedLabel()
    private let actionStack = UIStackView()
    private let moodTitle = UILabel()
    private let moodStack = UIStackView()

    init(store: StoreOf<CharacterReducer>) {
        self.store = store
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError() }

    override func viewDidLoad() {
        super.viewDidLoad()
        // Nav title carries the page label so the body can lead straight with
        // the centered sunshine pill, matching the design board. Set
        // navigationItem.title directly so the explicit tabBarItem.title
        // ("Sunny" / "小晴") wired up in RootTabBarController is untouched.
        navigationItem.title = String(localized: "character.today_mood", defaultValue: "Sunny's mood today")
        view.backgroundColor = Palette.canvas
        configureLayout()
        observeState { [weak self] in self?.render() }
    }

    private func configureLayout() {
        backdrop.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(backdrop)

        scrim.translatesAutoresizingMaskIntoConstraints = false
        scrim.isUserInteractionEnabled = false
        let gradient = CAGradientLayer()
        // Four-stop wash so the bubble and mood rows sit on near-solid cream
        // — earlier the bottom 30% only reached 0.7 alpha and the painted
        // bedroom floor bled through, eating "Mood state" and the labels.
        gradient.locations = [0.0, 0.35, 0.62, 1.0]
        scrim.layer.addSublayer(gradient)
        scrimGradient = gradient
        view.addSubview(scrim)
        // CGColors don't auto-resolve dynamic UIColors when the system flips
        // light↔dark — re-bake the four-stop wash whenever the trait changes
        // so the scrim follows Palette.canvas into dark mode instead of
        // staying glued to the light-mode cream.
        scrim.bindAdaptiveColors { [weak self] traits in
            self?.scrimGradient?.colors = [
                Palette.canvas.resolvedColor(with: traits).withAlphaComponent(Opacity.scrimSoft).cgColor,
                UIColor.clear.cgColor,
                Palette.canvas.resolvedColor(with: traits).withAlphaComponent(Opacity.scrimMid).cgColor,
                Palette.canvas.resolvedColor(with: traits).withAlphaComponent(Opacity.scrimHeavy).cgColor
            ]
        }

        // Centered sunshine pill — the page title is carried by the nav bar
        // (set in viewDidLoad), so the body can lead with this floating pill.
        sunshineLabel.font = Typography.body(14)
        sunshineLabel.textColor = Palette.inkPrimary
        sunshineLabel.backgroundColor = .clear
        sunshineLabel.textAlignment = .center

        let sunshineGlass = GlassPanel(style: .clear, cornerRadius: 16)
        sunshineGlass.translatesAutoresizingMaskIntoConstraints = false
        sunshineGlass.isUserInteractionEnabled = false
        sunshineGlass.heightAnchor.constraint(equalToConstant: 32).isActive = true
        sunshineGlass.addSubview(sunshineLabel)
        sunshineLabel.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            sunshineLabel.topAnchor.constraint(equalTo: sunshineGlass.topAnchor),
            sunshineLabel.bottomAnchor.constraint(equalTo: sunshineGlass.bottomAnchor),
            sunshineLabel.leadingAnchor.constraint(equalTo: sunshineGlass.leadingAnchor, constant: Spacing.m),
            sunshineLabel.trailingAnchor.constraint(equalTo: sunshineGlass.trailingAnchor, constant: -Spacing.m)
        ])

        // Character portrait
        portraitFallback.contentMode = .scaleAspectFit
        characterView.translatesAutoresizingMaskIntoConstraints = false

        // Right-side action chips (换装 / 语音 / 动作 / 日记) — separate tall
        // pills, each its own floating glass button per the design board.
        actionStack.axis = .vertical
        actionStack.spacing = Spacing.s
        actionStack.alignment = .fill
        actionStack.distribution = .fillEqually
        actionStack.translatesAutoresizingMaskIntoConstraints = false
        for action in CharacterAction.allCases {
            actionStack.addArrangedSubview(makeActionButton(action))
        }

        // Bubble — Liquid Glass background
        bubble.font = Typography.body(15)
        bubble.textColor = Palette.inkPrimary
        bubble.numberOfLines = 0
        bubble.textAlignment = .center
        bubble.backgroundColor = .clear
        bubble.translatesAutoresizingMaskIntoConstraints = false

        let bubbleGlass = GlassPanel(style: .regular, cornerRadius: Radius.medium)
        bubbleGlass.translatesAutoresizingMaskIntoConstraints = false
        bubbleGlass.isUserInteractionEnabled = false

        // Mood section — design board uses inkPrimary (full weight) for the
        // "心情状态" label, not the secondary tone we had. Bumping the colour
        // also rescues legibility against the painted bedroom backdrop.
        moodTitle.text = String(localized: "character.mood_state", defaultValue: "Mood state")
        moodTitle.font = Typography.body(15)
        moodTitle.textColor = Palette.inkPrimary
        moodTitle.translatesAutoresizingMaskIntoConstraints = false

        moodStack.axis = .horizontal
        moodStack.spacing = Spacing.xs
        moodStack.distribution = .fillEqually
        moodStack.translatesAutoresizingMaskIntoConstraints = false
        for mood in CharacterMood.allCases {
            moodStack.addArrangedSubview(makeMoodButton(mood))
        }

        view.addSubview(sunshineGlass)
        view.addSubview(characterView)
        view.addSubview(actionStack)
        view.addSubview(bubbleGlass)
        view.addSubview(bubble)
        view.addSubview(moodTitle)
        view.addSubview(moodStack)

        NSLayoutConstraint.activate([
            backdrop.topAnchor.constraint(equalTo: view.topAnchor),
            backdrop.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            backdrop.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            backdrop.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            scrim.topAnchor.constraint(equalTo: view.topAnchor),
            scrim.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrim.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrim.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            sunshineGlass.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: Spacing.s),
            sunshineGlass.centerXAnchor.constraint(equalTo: view.centerXAnchor),

            characterView.topAnchor.constraint(equalTo: sunshineGlass.bottomAnchor, constant: Spacing.s),
            characterView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: Spacing.m),
            characterView.trailingAnchor.constraint(equalTo: actionStack.leadingAnchor, constant: -Spacing.s),
            characterView.heightAnchor.constraint(equalToConstant: 320),

            actionStack.centerYAnchor.constraint(equalTo: characterView.centerYAnchor),
            // Use Spacing.l (24) instead of m (16) — the design board has
            // visibly more breathing room between the chip column and the
            // screen edge.
            actionStack.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -Spacing.l),
            actionStack.widthAnchor.constraint(equalToConstant: 68),

            bubble.topAnchor.constraint(equalTo: characterView.bottomAnchor, constant: Spacing.s),
            bubble.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: Spacing.l),
            bubble.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -Spacing.l),
            bubble.heightAnchor.constraint(greaterThanOrEqualToConstant: 56),

            bubbleGlass.topAnchor.constraint(equalTo: bubble.topAnchor),
            bubbleGlass.bottomAnchor.constraint(equalTo: bubble.bottomAnchor),
            bubbleGlass.leadingAnchor.constraint(equalTo: bubble.leadingAnchor),
            bubbleGlass.trailingAnchor.constraint(equalTo: bubble.trailingAnchor),

            moodTitle.topAnchor.constraint(equalTo: bubble.bottomAnchor, constant: Spacing.m),
            moodTitle.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: Spacing.l),

            moodStack.topAnchor.constraint(equalTo: moodTitle.bottomAnchor, constant: Spacing.s),
            moodStack.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: Spacing.l),
            moodStack.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -Spacing.l),
            moodStack.bottomAnchor.constraint(lessThanOrEqualTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -Spacing.m),
            moodStack.heightAnchor.constraint(equalToConstant: 96)
        ])
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        scrimGradient?.frame = scrim.bounds
    }

    private func makeActionButton(_ action: CharacterAction) -> UIButton {
        // iOS 26's `.glass()` configuration adopts Liquid Glass for the button
        // chrome — gives the watercolor scene behind it room to read through.
        var config: UIButton.Configuration
        if #available(iOS 26.0, *) {
            config = .glass()
        } else {
            config = .plain()
            config.background.backgroundColor = Palette.surface.withAlphaComponent(Opacity.glassStrong)
            config.background.cornerRadius = Radius.medium
        }
        config.title = localizedAction(action)
        config.image = UIImage(systemName: action.symbol)
        config.imagePadding = 6
        config.imagePlacement = .top
        config.contentInsets = NSDirectionalEdgeInsets(top: 12, leading: 4, bottom: 12, trailing: 4)
        config.baseForegroundColor = Palette.inkPrimary
        let button = UIButton(configuration: config)
        button.titleLabel?.font = Typography.caption(12)
        button.heightAnchor.constraint(greaterThanOrEqualToConstant: 64).isActive = true
        return button
    }

    private func makeMoodButton(_ mood: CharacterMood) -> UIControl {
        let button = MoodButton(
            mood: mood,
            title: localizedMood(mood),
            image: MoodArt.image(forMoodRawValue: mood.rawValue)
        )
        button.tag = CharacterMood.allCases.firstIndex(of: mood) ?? 0
        button.addTarget(self, action: #selector(handleMoodTap(_:)), for: .touchUpInside)
        return button
    }

    @objc private func handleMoodTap(_ sender: UIControl) {
        let mood = CharacterMood.allCases[sender.tag]
        store.send(.moodSelected(mood))
        store.send(.awardSunshine(2))
    }

    private func render() {
        // Backdrop is the cozy-room scene with the character already painted in;
        // hide the standalone portrait overlay so we don't double-stack the figure.
        backdrop.update(
            conditionRawValue: store.condition.rawValue,
            palette: palette(for: store.condition),
            preferredAsset: "bg_character_room"
        )
        characterView.isHidden = true

        bubble.text = encouragement(for: store.condition, mood: store.mood)
        sunshineLabel.text = String.localizedStringWithFormat(
            String(localized: "character.sunshine_score", defaultValue: "♥ Sunshine %d"),
            store.sunshinePoints
        )

        for case let button as MoodButton in moodStack.arrangedSubviews {
            button.isSelected = (button.mood == store.mood)
        }
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

    private func symbolName(for mood: CharacterMood) -> String {
        switch mood {
        case .happy: return "face.smiling.inverse"
        case .calm: return "moon.stars.fill"
        case .tender: return "heart.fill"
        case .worried: return "cloud.drizzle.fill"
        case .excited: return "sparkles"
        case .flustered: return "wind.snow"
        }
    }

    private func localizedMood(_ mood: CharacterMood) -> String {
        switch mood {
        case .happy: return String(localized: "mood.happy", defaultValue: "Happy")
        case .calm: return String(localized: "mood.calm", defaultValue: "Calm")
        case .tender: return String(localized: "mood.tender", defaultValue: "Tender")
        case .worried: return String(localized: "mood.worried", defaultValue: "Worried")
        case .excited: return String(localized: "mood.excited", defaultValue: "Excited")
        case .flustered: return String(localized: "mood.flustered", defaultValue: "Flustered")
        }
    }

    private func localizedAction(_ action: CharacterAction) -> String {
        switch action {
        case .outfit: return String(localized: "character.action.outfit", defaultValue: "Outfit")
        case .voice: return String(localized: "character.action.voice", defaultValue: "Voice")
        case .gesture: return String(localized: "character.action.gesture", defaultValue: "Action")
        case .diary: return String(localized: "character.action.diary", defaultValue: "Diary")
        }
    }

    private func encouragement(for condition: WeatherCondition, mood: CharacterMood) -> String {
        switch (mood, condition) {
        case (.happy, _): return String(localized: "bubble.clear", defaultValue: "Beautiful day — let's go outside!")
        case (.calm, _): return String(localized: "character.calm", defaultValue: "Take a deep breath. The world will wait.")
        case (.tender, _): return String(localized: "character.tender", defaultValue: "Sunny is sending you warm wishes today.")
        case (.worried, _): return String(localized: "character.worried", defaultValue: "Sunny is a little nervous. Stay close, okay?")
        case (.excited, _): return String(localized: "character.excited", defaultValue: "Sunny found something fun! Want to play?")
        case (.flustered, _): return String(localized: "character.flustered", defaultValue: "Sunny is a little flustered today — go gently!")
        }
    }
}

private enum CharacterAction: CaseIterable {
    case outfit, voice, gesture, diary

    var symbol: String {
        switch self {
        case .outfit: return "tshirt.fill"
        case .voice: return "speaker.wave.2.fill"
        case .gesture: return "hand.wave.fill"
        case .diary: return "book.closed.fill"
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
