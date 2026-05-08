import UIKit
import CharacterFeature
import SunriseDesignSystem

/// Selectable mood pill — circular bust portrait on top, label below.
/// The design board has the moods sit as plain circle-plus-label items
/// (no surrounding card), with the active one wearing a soft yellow ring
/// behind the portrait. Match that here instead of wrapping each item in
/// a Liquid Glass rounded rect, which read as "card per mood" rather than
/// "row of portraits".
final class MoodButton: UIControl {
    let mood: CharacterMood
    private let portraitContainer = UIView()
    private let imageView = UIImageView()
    private let label = UILabel()

    private static let portraitSize: CGFloat = 56

    override var isSelected: Bool {
        didSet { applySelectionStyling() }
    }

    init(mood: CharacterMood, title: String, image: UIImage?) {
        self.mood = mood
        super.init(frame: .zero)

        backgroundColor = .clear

        // Container holds the round bust; the selected state colours its
        // background to draw a soft yellow halo behind the portrait.
        portraitContainer.translatesAutoresizingMaskIntoConstraints = false
        portraitContainer.layer.cornerRadius = Self.portraitSize / 2 + 4
        portraitContainer.layer.cornerCurve = .continuous
        portraitContainer.isUserInteractionEnabled = false
        addSubview(portraitContainer)

        imageView.contentMode = .scaleAspectFill
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.layer.cornerRadius = Self.portraitSize / 2
        imageView.clipsToBounds = true
        imageView.backgroundColor = Palette.surface.withAlphaComponent(Opacity.glassFaint)
        imageView.image = image ?? UIImage(systemName: "face.smiling")
        imageView.tintColor = Palette.inkSecondary
        portraitContainer.addSubview(imageView)

        label.text = title
        label.font = Typography.caption(12)
        label.textColor = Palette.inkPrimary
        label.textAlignment = .center
        label.numberOfLines = 1
        label.lineBreakMode = .byTruncatingTail
        label.adjustsFontSizeToFitWidth = true
        label.minimumScaleFactor = 0.6
        label.allowsDefaultTighteningForTruncation = true
        label.translatesAutoresizingMaskIntoConstraints = false
        addSubview(label)

        NSLayoutConstraint.activate([
            portraitContainer.topAnchor.constraint(equalTo: topAnchor),
            portraitContainer.centerXAnchor.constraint(equalTo: centerXAnchor),
            portraitContainer.widthAnchor.constraint(equalToConstant: Self.portraitSize + 8),
            portraitContainer.heightAnchor.constraint(equalToConstant: Self.portraitSize + 8),

            imageView.centerXAnchor.constraint(equalTo: portraitContainer.centerXAnchor),
            imageView.centerYAnchor.constraint(equalTo: portraitContainer.centerYAnchor),
            imageView.widthAnchor.constraint(equalToConstant: Self.portraitSize),
            imageView.heightAnchor.constraint(equalToConstant: Self.portraitSize),

            label.topAnchor.constraint(equalTo: portraitContainer.bottomAnchor, constant: 4),
            label.leadingAnchor.constraint(equalTo: leadingAnchor, constant: Spacing.xxs),
            label.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -Spacing.xxs),
            label.bottomAnchor.constraint(equalTo: bottomAnchor),

            heightAnchor.constraint(greaterThanOrEqualToConstant: 92)
        ])

        applySelectionStyling()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError() }

    private func applySelectionStyling() {
        if isSelected {
            portraitContainer.backgroundColor = Palette.sunYellow.withAlphaComponent(Opacity.highlight)
            label.textColor = Palette.inkPrimary
        } else {
            portraitContainer.backgroundColor = .clear
            label.textColor = Palette.inkSecondary
        }
    }
}
