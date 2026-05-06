#if canImport(UIKit)
import UIKit

public struct GradientPalette: Equatable, Sendable {
    public let top: UIColor
    public let bottom: UIColor

    public init(top: UIColor, bottom: UIColor) {
        self.top = top
        self.bottom = bottom
    }

    public static let clearDay = GradientPalette(
        top: UIColor(red: 0.55, green: 0.78, blue: 0.93, alpha: 1.0),
        bottom: UIColor(red: 0.92, green: 0.96, blue: 0.99, alpha: 1.0)
    )
    public static let clearNight = GradientPalette(
        top: UIColor(red: 0.10, green: 0.13, blue: 0.27, alpha: 1.0),
        bottom: UIColor(red: 0.27, green: 0.32, blue: 0.50, alpha: 1.0)
    )
    public static let cloudy = GradientPalette(
        top: UIColor(red: 0.66, green: 0.74, blue: 0.84, alpha: 1.0),
        bottom: UIColor(red: 0.93, green: 0.94, blue: 0.96, alpha: 1.0)
    )
    public static let rain = GradientPalette(
        top: UIColor(red: 0.41, green: 0.50, blue: 0.62, alpha: 1.0),
        bottom: UIColor(red: 0.78, green: 0.83, blue: 0.88, alpha: 1.0)
    )
    public static let thunderstorm = GradientPalette(
        top: UIColor(red: 0.20, green: 0.23, blue: 0.34, alpha: 1.0),
        bottom: UIColor(red: 0.44, green: 0.49, blue: 0.59, alpha: 1.0)
    )
    public static let snow = GradientPalette(
        top: UIColor(red: 0.79, green: 0.86, blue: 0.95, alpha: 1.0),
        bottom: UIColor(red: 0.97, green: 0.98, blue: 1.00, alpha: 1.0)
    )
    public static let windy = GradientPalette(
        top: UIColor(red: 0.78, green: 0.84, blue: 0.78, alpha: 1.0),
        bottom: UIColor(red: 0.95, green: 0.94, blue: 0.86, alpha: 1.0)
    )
    public static let fog = GradientPalette(
        top: UIColor(red: 0.72, green: 0.74, blue: 0.76, alpha: 1.0),
        bottom: UIColor(red: 0.90, green: 0.91, blue: 0.92, alpha: 1.0)
    )
}

public final class GradientBackgroundView: UIView {
    public override class var layerClass: AnyClass { CAGradientLayer.self }

    public var palette: GradientPalette {
        didSet { applyPalette() }
    }

    public init(palette: GradientPalette = .clearDay) {
        self.palette = palette
        super.init(frame: .zero)
        applyPalette()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError() }

    private func applyPalette() {
        guard let layer = layer as? CAGradientLayer else { return }
        layer.colors = [palette.top.cgColor, palette.bottom.cgColor]
        layer.startPoint = CGPoint(x: 0.5, y: 0)
        layer.endPoint = CGPoint(x: 0.5, y: 1)
    }
}
#endif
