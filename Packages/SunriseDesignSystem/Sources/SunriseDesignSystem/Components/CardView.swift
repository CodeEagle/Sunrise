#if canImport(UIKit)
import UIKit

public final class CardView: UIView {
    public init(cornerRadius: CGFloat = Radius.large, fill: UIColor = Palette.cloudWhite) {
        super.init(frame: .zero)
        backgroundColor = fill
        layer.cornerRadius = cornerRadius
        layer.cornerCurve = .continuous
        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOpacity = 0.06
        layer.shadowRadius = 16
        layer.shadowOffset = CGSize(width: 0, height: 8)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError() }
}
#endif
