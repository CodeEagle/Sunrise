#if canImport(UIKit)
import UIKit

/// Liquid Glass panel used as a card / pill / chip background. iOS 26 ships
/// `UIGlassEffect`; we wrap it in a `UIVisualEffectView` and round the corners
/// so callers get a drop-in alternative to the cream-tinted `cloudWhite` cards
/// the app used pre-Liquid Glass.
public final class GlassPanel: UIView {
    public enum Style {
        case regular  // standard Liquid Glass — most cards
        case clear    // see-through capsule — small chips & pills

        @available(iOS 26.0, *)
        fileprivate var glass: UIGlassEffect {
            switch self {
            case .regular:
                return UIGlassEffect()
            case .clear:
                let effect = UIGlassEffect()
                effect.isInteractive = false
                return effect
            }
        }
    }

    private let backdrop: UIView

    public init(style: Style = .regular, cornerRadius: CGFloat = Radius.medium) {
        if #available(iOS 26.0, *) {
            backdrop = UIVisualEffectView(effect: style.glass)
        } else {
            // Pre-iOS-26 fallback (won't actually run since deployment is 26+,
            // but keeps the package compilable as we transition).
            let v = UIView()
            v.backgroundColor = UIColor.systemBackground.withAlphaComponent(0.85)
            backdrop = v
        }
        super.init(frame: .zero)

        backdrop.translatesAutoresizingMaskIntoConstraints = false
        addSubview(backdrop)
        NSLayoutConstraint.activate([
            backdrop.topAnchor.constraint(equalTo: topAnchor),
            backdrop.bottomAnchor.constraint(equalTo: bottomAnchor),
            backdrop.leadingAnchor.constraint(equalTo: leadingAnchor),
            backdrop.trailingAnchor.constraint(equalTo: trailingAnchor)
        ])

        layer.cornerRadius = cornerRadius
        layer.cornerCurve = .continuous
        clipsToBounds = true
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError() }
}
#endif
