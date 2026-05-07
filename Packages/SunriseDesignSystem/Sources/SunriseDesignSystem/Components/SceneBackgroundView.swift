#if canImport(UIKit)
import UIKit

/// Full-screen background that prefers the bundled watercolor scene
/// (`bg_<condition>.png`) and falls back to a gradient palette when the
/// scene art is missing.
public final class SceneBackgroundView: UIView {
    private let gradient = GradientBackgroundView(palette: .clearDay)
    private let imageView = UIImageView()

    public init() {
        super.init(frame: .zero)
        gradient.translatesAutoresizingMaskIntoConstraints = false
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        addSubview(gradient)
        addSubview(imageView)

        NSLayoutConstraint.activate([
            gradient.topAnchor.constraint(equalTo: topAnchor),
            gradient.bottomAnchor.constraint(equalTo: bottomAnchor),
            gradient.leadingAnchor.constraint(equalTo: leadingAnchor),
            gradient.trailingAnchor.constraint(equalTo: trailingAnchor),

            imageView.topAnchor.constraint(equalTo: topAnchor),
            imageView.bottomAnchor.constraint(equalTo: bottomAnchor),
            imageView.leadingAnchor.constraint(equalTo: leadingAnchor),
            imageView.trailingAnchor.constraint(equalTo: trailingAnchor)
        ])
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError() }

    /// `preferredAsset` lets pages override the default `bg_<condition>.png`
    /// lookup with their own scene art (e.g. Today uses `today_<condition>.png`
    /// composites that include the character; Character uses `bg_room.png`).
    public func update(conditionRawValue: String, palette: GradientPalette, preferredAsset: String? = nil) {
        gradient.palette = palette
        let candidates = [preferredAsset, "bg_\(conditionRawValue)"].compactMap { $0 }
        let image = candidates.lazy.compactMap { name -> UIImage? in
            if let asset = UIImage(named: name) { return asset }
            if let path = Bundle.main.path(forResource: name, ofType: "png") {
                return UIImage(contentsOfFile: path)
            }
            return nil
        }.first
        imageView.image = image
        imageView.alpha = image == nil ? 0 : 1
    }
}
#endif
