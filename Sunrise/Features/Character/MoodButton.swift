import UIKit
import CharacterFeature
import SunriseDesignSystem

/// Selectable mood pill — Liquid Glass background, circular portrait on top, label below.
final class MoodButton: UIControl {
    let mood: CharacterMood
    private let glass = GlassPanel(style: .clear, cornerRadius: Radius.medium)
    private let imageView = UIImageView()
    private let label = UILabel()

    override var isSelected: Bool {
        didSet { applySelectionStyling() }
    }

    init(mood: CharacterMood, title: String, image: UIImage?) {
        self.mood = mood
        super.init(frame: .zero)

        backgroundColor = .clear

        glass.translatesAutoresizingMaskIntoConstraints = false
        glass.isUserInteractionEnabled = false
        addSubview(glass)

        imageView.contentMode = .scaleAspectFill
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.layer.cornerRadius = 28
        imageView.clipsToBounds = true
        imageView.backgroundColor = Palette.cloudWhite.withAlphaComponent(0.4)
        imageView.image = image ?? UIImage(systemName: "face.smiling")
        imageView.tintColor = Palette.inkSecondary

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

        addSubview(imageView)
        addSubview(label)

        NSLayoutConstraint.activate([
            glass.topAnchor.constraint(equalTo: topAnchor),
            glass.bottomAnchor.constraint(equalTo: bottomAnchor),
            glass.leadingAnchor.constraint(equalTo: leadingAnchor),
            glass.trailingAnchor.constraint(equalTo: trailingAnchor),

            imageView.topAnchor.constraint(equalTo: topAnchor, constant: Spacing.xs),
            imageView.centerXAnchor.constraint(equalTo: centerXAnchor),
            imageView.widthAnchor.constraint(equalToConstant: 56),
            imageView.heightAnchor.constraint(equalToConstant: 56),

            label.topAnchor.constraint(equalTo: imageView.bottomAnchor, constant: 4),
            label.leadingAnchor.constraint(equalTo: leadingAnchor, constant: Spacing.xxs),
            label.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -Spacing.xxs),
            label.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -Spacing.xs),

            heightAnchor.constraint(greaterThanOrEqualToConstant: 96)
        ])

        applySelectionStyling()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError() }

    private func applySelectionStyling() {
        // Selected mood gets a sunshine tint behind the Liquid Glass; the
        // glass picks the colour up and renders a warm yellow chip.
        if isSelected {
            backgroundColor = Palette.sunYellow.withAlphaComponent(0.7)
            label.textColor = Palette.inkPrimary
        } else {
            backgroundColor = .clear
            label.textColor = Palette.inkSecondary
        }
    }
}
