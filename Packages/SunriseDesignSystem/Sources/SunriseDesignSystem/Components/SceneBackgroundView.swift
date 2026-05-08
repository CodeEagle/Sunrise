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
        // Clip ourselves so the Ken-Burns scale/translate on imageView never
        // bleeds past the view's bounds when the background is animated.
        clipsToBounds = true
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
    /// `animated` opts the scene image into a slow Ken-Burns + parallax loop —
    /// gpt-image-2 sequential frames drift too much to play back as
    /// per-frame animation, so we instead lift a single static painting
    /// with subtle Core Animation transforms.
    public func update(
        conditionRawValue: String,
        palette: GradientPalette,
        preferredAsset: String? = nil,
        animated: Bool = false
    ) {
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

        if animated, image != nil {
            startAmbientAnimation()
        } else {
            stopAmbientAnimation()
        }
    }

    // MARK: - Ambient animation

    private func startAmbientAnimation() {
        // Coprime durations + autoreverse means the scale and pan phases
        // realign every LCM(9,13)=117s — long enough that the eye never
        // catches a visible loop.
        let scale = CABasicAnimation(keyPath: "transform.scale")
        scale.fromValue = 1.0
        scale.toValue = 1.04
        scale.duration = 9
        scale.autoreverses = true
        scale.repeatCount = .infinity
        scale.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)

        let pan = CABasicAnimation(keyPath: "transform.translation.x")
        pan.fromValue = -8
        pan.toValue = 8
        pan.duration = 13
        pan.autoreverses = true
        pan.repeatCount = .infinity
        pan.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)

        imageView.layer.removeAllAnimations()
        imageView.layer.add(scale, forKey: "ambient.scale")
        imageView.layer.add(pan, forKey: "ambient.pan")
    }

    private func stopAmbientAnimation() {
        imageView.layer.removeAllAnimations()
    }
}
#endif
