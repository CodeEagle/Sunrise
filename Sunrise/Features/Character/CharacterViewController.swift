import UIKit
import ComposableArchitecture
import CharacterFeature
import SunriseCore
import SunriseDesignSystem
import SunriseAnimation

final class CharacterViewController: UIViewController {
    private let store: StoreOf<CharacterReducer>

    private let gradient = GradientBackgroundView(palette: .clearDay)
    private let scrollView = UIScrollView()
    private let stack = UIStackView()
    private let portraitFallback = UIImageView()
    private lazy var characterView = LottieCharacterView(fallbackView: portraitFallback)
    private let bubble = UILabel()
    private let sunshineLabel = UILabel()
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
        gradient.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(gradient)
        NSLayoutConstraint.activate([
            gradient.topAnchor.constraint(equalTo: view.topAnchor),
            gradient.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            gradient.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            gradient.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])

        scrollView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(scrollView)
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])

        stack.axis = .vertical
        stack.spacing = Spacing.l
        stack.alignment = .fill
        stack.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(stack)
        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor, constant: Spacing.m),
            stack.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor, constant: -Spacing.l),
            stack.leadingAnchor.constraint(equalTo: scrollView.frameLayoutGuide.leadingAnchor, constant: Spacing.m),
            stack.trailingAnchor.constraint(equalTo: scrollView.frameLayoutGuide.trailingAnchor, constant: -Spacing.m)
        ])

        sunshineLabel.font = Typography.title(18)
        sunshineLabel.textColor = Palette.inkPrimary
        sunshineLabel.textAlignment = .center

        portraitFallback.contentMode = .scaleAspectFit
        characterView.translatesAutoresizingMaskIntoConstraints = false
        characterView.heightAnchor.constraint(equalToConstant: 240).isActive = true

        bubble.font = Typography.body(15)
        bubble.textColor = Palette.inkPrimary
        bubble.numberOfLines = 0
        bubble.textAlignment = .center
        bubble.backgroundColor = Palette.cloudWhite.withAlphaComponent(0.85)
        bubble.layer.cornerRadius = Radius.medium
        bubble.layer.cornerCurve = .continuous
        bubble.layer.masksToBounds = true
        bubble.heightAnchor.constraint(greaterThanOrEqualToConstant: 56).isActive = true

        moodTitle.text = String(localized: "character.mood_title", defaultValue: "How does Sunny feel today?")
        moodTitle.font = Typography.body(15)
        moodTitle.textColor = Palette.inkSecondary
        moodTitle.textAlignment = .center

        moodStack.axis = .vertical
        moodStack.spacing = Spacing.xs
        let allMoods = CharacterMood.allCases
        for chunk in stride(from: 0, to: allMoods.count, by: 3) {
            let row = UIStackView()
            row.axis = .horizontal
            row.distribution = .fillEqually
            row.spacing = Spacing.xs
            for mood in allMoods[chunk..<min(chunk + 3, allMoods.count)] {
                row.addArrangedSubview(makeMoodButton(mood))
            }
            moodStack.addArrangedSubview(row)
        }

        [sunshineLabel, characterView, bubble, moodTitle, moodStack].forEach(stack.addArrangedSubview)
    }

    private func makeMoodButton(_ mood: CharacterMood) -> UIButton {
        var config = UIButton.Configuration.tinted()
        config.baseBackgroundColor = Palette.cloudWhite.withAlphaComponent(0.6)
        config.baseForegroundColor = Palette.inkPrimary
        config.cornerStyle = .medium
        config.title = localizedMood(mood)
        let button = UIButton(configuration: config)
        button.tag = CharacterMood.allCases.firstIndex(of: mood) ?? 0
        button.addTarget(self, action: #selector(handleMoodTap(_:)), for: .touchUpInside)
        return button
    }

    @objc private func handleMoodTap(_ sender: UIButton) {
        let mood = CharacterMood.allCases[sender.tag]
        store.send(.moodSelected(mood))
        store.send(.awardSunshine(2))
    }

    private func render() {
        gradient.palette = palette(for: store.condition)

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
        sunshineLabel.text = String.localizedStringWithFormat(
            String(localized: "character.sunshine", defaultValue: "Sunshine points: %d"),
            store.sunshinePoints
        )

        for row in moodStack.arrangedSubviews {
            guard let row = row as? UIStackView else { continue }
            for case let button as UIButton in row.arrangedSubviews {
                let mood = CharacterMood.allCases[button.tag]
                var config = button.configuration
                if mood == store.mood {
                    config?.baseBackgroundColor = Palette.sunYellow
                    config?.baseForegroundColor = Palette.inkPrimary
                } else {
                    config?.baseBackgroundColor = Palette.cloudWhite.withAlphaComponent(0.6)
                    config?.baseForegroundColor = Palette.inkSecondary
                }
                button.configuration = config
            }
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
