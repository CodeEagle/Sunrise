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

    private let titleLabel = UILabel()
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
        title = String(localized: "tab.character", defaultValue: "Sunny")
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
        gradient.colors = [
            Palette.canvas.withAlphaComponent(0.6).cgColor,
            UIColor.clear.cgColor,
            Palette.canvas.withAlphaComponent(0.7).cgColor
        ]
        gradient.locations = [0.0, 0.5, 1.0]
        scrim.layer.addSublayer(gradient)
        scrimGradient = gradient
        view.addSubview(scrim)

        // Top header: title + sunshine pill
        titleLabel.text = String(localized: "character.today_mood", defaultValue: "Sunny's mood today")
        titleLabel.font = Typography.title(18)
        titleLabel.textColor = Palette.inkPrimary

        sunshineLabel.font = Typography.body(14)
        sunshineLabel.textColor = Palette.inkPrimary
        sunshineLabel.backgroundColor = Palette.cloudWhite.withAlphaComponent(0.85)
        sunshineLabel.layer.cornerRadius = 14
        sunshineLabel.layer.cornerCurve = .continuous
        sunshineLabel.layer.masksToBounds = true
        sunshineLabel.textAlignment = .center
        sunshineLabel.heightAnchor.constraint(equalToConstant: 28).isActive = true

        let header = UIStackView(arrangedSubviews: [titleLabel, UIView(), sunshineLabel])
        header.axis = .horizontal
        header.alignment = .center
        header.spacing = Spacing.s
        header.translatesAutoresizingMaskIntoConstraints = false

        // Character portrait
        portraitFallback.contentMode = .scaleAspectFit
        characterView.translatesAutoresizingMaskIntoConstraints = false

        // Right-side action buttons (换装 / 语音 / 动作 / 日记)
        actionStack.axis = .vertical
        actionStack.spacing = Spacing.xs
        actionStack.alignment = .trailing
        actionStack.translatesAutoresizingMaskIntoConstraints = false
        for action in CharacterAction.allCases {
            actionStack.addArrangedSubview(makeActionButton(action))
        }

        // Bubble
        bubble.font = Typography.body(15)
        bubble.textColor = Palette.inkPrimary
        bubble.numberOfLines = 0
        bubble.textAlignment = .center
        bubble.backgroundColor = Palette.cloudWhite.withAlphaComponent(0.92)
        bubble.layer.cornerRadius = Radius.medium
        bubble.layer.cornerCurve = .continuous
        bubble.layer.masksToBounds = true
        bubble.translatesAutoresizingMaskIntoConstraints = false

        // Mood section
        moodTitle.text = String(localized: "character.mood_state", defaultValue: "Mood state")
        moodTitle.font = Typography.body(15)
        moodTitle.textColor = Palette.inkSecondary
        moodTitle.translatesAutoresizingMaskIntoConstraints = false

        moodStack.axis = .horizontal
        moodStack.spacing = Spacing.xs
        moodStack.distribution = .fillEqually
        moodStack.translatesAutoresizingMaskIntoConstraints = false
        for mood in CharacterMood.allCases {
            moodStack.addArrangedSubview(makeMoodButton(mood))
        }

        view.addSubview(header)
        view.addSubview(characterView)
        view.addSubview(actionStack)
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

            header.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: Spacing.s),
            header.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: Spacing.l),
            header.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -Spacing.l),

            characterView.topAnchor.constraint(equalTo: header.bottomAnchor, constant: Spacing.m),
            characterView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: Spacing.m),
            characterView.trailingAnchor.constraint(equalTo: actionStack.leadingAnchor, constant: -Spacing.s),
            characterView.heightAnchor.constraint(equalToConstant: 320),

            actionStack.centerYAnchor.constraint(equalTo: characterView.centerYAnchor),
            actionStack.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -Spacing.m),
            actionStack.widthAnchor.constraint(equalToConstant: 64),

            bubble.topAnchor.constraint(equalTo: characterView.bottomAnchor, constant: Spacing.s),
            bubble.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: Spacing.l),
            bubble.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -Spacing.l),
            bubble.heightAnchor.constraint(greaterThanOrEqualToConstant: 56),

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
        var config = UIButton.Configuration.plain()
        config.title = localizedAction(action)
        config.image = UIImage(systemName: action.symbol)
        config.imagePadding = 4
        config.imagePlacement = .top
        config.contentInsets = NSDirectionalEdgeInsets(top: 8, leading: 4, bottom: 8, trailing: 4)
        config.background.backgroundColor = Palette.cloudWhite.withAlphaComponent(0.85)
        config.background.cornerRadius = Radius.small
        config.baseForegroundColor = Palette.inkPrimary
        let button = UIButton(configuration: config)
        button.titleLabel?.font = Typography.caption(12)
        button.heightAnchor.constraint(greaterThanOrEqualToConstant: 56).isActive = true
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
        backdrop.update(
            conditionRawValue: store.condition.rawValue,
            palette: palette(for: store.condition),
            preferredAsset: "bg_room"
        )

        if let art = CharacterArt.image(forConditionRawValue: store.condition.rawValue) {
            portraitFallback.image = art
            portraitFallback.tintColor = nil
        } else {
            let symbolName = symbolName(for: store.mood)
            let config = UIImage.SymbolConfiguration(pointSize: 160, weight: .regular)
            portraitFallback.image = UIImage(systemName: symbolName, withConfiguration: config)
            portraitFallback.tintColor = ConditionGlyph.tint(forConditionRawValue: store.condition.rawValue)
        }

        let animated = AnimatedCondition(rawValue: store.condition.rawValue) ?? .clear
        characterView.update(condition: animated, dayPeriod: .day)

        bubble.text = encouragement(for: store.condition, mood: store.mood)
        sunshineLabel.text = "  " + String.localizedStringWithFormat(
            String(localized: "character.sunshine_score", defaultValue: "♥ Sunshine %d"),
            store.sunshinePoints
        ) + "  "

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
        case .shy: return "leaf.fill"
        }
    }

    private func localizedMood(_ mood: CharacterMood) -> String {
        switch mood {
        case .happy: return String(localized: "mood.happy", defaultValue: "Happy")
        case .calm: return String(localized: "mood.calm", defaultValue: "Calm")
        case .tender: return String(localized: "mood.tender", defaultValue: "Tender")
        case .worried: return String(localized: "mood.worried", defaultValue: "Worried")
        case .excited: return String(localized: "mood.excited", defaultValue: "Excited")
        case .shy: return String(localized: "mood.shy", defaultValue: "Shy")
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
        case (.shy, _): return String(localized: "character.shy", defaultValue: "Sunny is hiding behind a cloud, peeking shyly.")
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
