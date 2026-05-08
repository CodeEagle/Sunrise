#if canImport(UIKit)
import UIKit

public final class CardView: UIView {
    public init(cornerRadius: CGFloat = Radius.large, fill: UIColor = Palette.surface) {
        super.init(frame: .zero)
        backgroundColor = fill
        layer.cornerRadius = cornerRadius
        layer.cornerCurve = .continuous
        layer.shadowOpacity = Elevation.cardOpacity
        layer.shadowRadius = Elevation.cardRadius
        layer.shadowOffset = Elevation.cardOffset
        bindAdaptiveColors { [weak self] traits in
            self?.layer.shadowColor = Palette.shadow.resolvedColor(with: traits).cgColor
        }
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError() }
}
#endif
