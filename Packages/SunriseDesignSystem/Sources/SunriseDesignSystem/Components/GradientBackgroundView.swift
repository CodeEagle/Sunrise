#if canImport(UIKit)
import UIKit

public struct GradientPalette: Equatable, Sendable {
    public let top: UIColor
    public let bottom: UIColor

    public init(top: UIColor, bottom: UIColor) {
        self.top = top
        self.bottom = bottom
    }

    /// Builds a palette whose `top` and `bottom` resolve to different RGB
    /// values in light vs. dark mode. Pair with a view that re-applies its
    /// CAGradientLayer colours via `bindAdaptiveColors` so the layer tracks
    /// the system theme (CGColor doesn't auto-resolve dynamic UIColors).
    private static func dynamic(
        light: (top: UIColor, bottom: UIColor),
        dark: (top: UIColor, bottom: UIColor)
    ) -> GradientPalette {
        GradientPalette(
            top: UIColor { traits in
                traits.userInterfaceStyle == .dark ? dark.top : light.top
            },
            bottom: UIColor { traits in
                traits.userInterfaceStyle == .dark ? dark.bottom : light.bottom
            }
        )
    }

    public static let clearDay = dynamic(
        light: (UIColor(red: 0.55, green: 0.78, blue: 0.93, alpha: 1.0),
                UIColor(red: 0.92, green: 0.96, blue: 0.99, alpha: 1.0)),
        dark: (UIColor(red: 0.16, green: 0.22, blue: 0.36, alpha: 1.0),
               UIColor(red: 0.30, green: 0.36, blue: 0.50, alpha: 1.0))
    )
    public static let clearNight = dynamic(
        light: (UIColor(red: 0.10, green: 0.13, blue: 0.27, alpha: 1.0),
                UIColor(red: 0.27, green: 0.32, blue: 0.50, alpha: 1.0)),
        dark: (UIColor(red: 0.05, green: 0.07, blue: 0.15, alpha: 1.0),
               UIColor(red: 0.16, green: 0.20, blue: 0.34, alpha: 1.0))
    )
    public static let cloudy = dynamic(
        light: (UIColor(red: 0.66, green: 0.74, blue: 0.84, alpha: 1.0),
                UIColor(red: 0.93, green: 0.94, blue: 0.96, alpha: 1.0)),
        dark: (UIColor(red: 0.20, green: 0.23, blue: 0.30, alpha: 1.0),
               UIColor(red: 0.32, green: 0.36, blue: 0.42, alpha: 1.0))
    )
    public static let rain = dynamic(
        light: (UIColor(red: 0.41, green: 0.50, blue: 0.62, alpha: 1.0),
                UIColor(red: 0.78, green: 0.83, blue: 0.88, alpha: 1.0)),
        dark: (UIColor(red: 0.14, green: 0.18, blue: 0.26, alpha: 1.0),
               UIColor(red: 0.28, green: 0.32, blue: 0.40, alpha: 1.0))
    )
    public static let thunderstorm = dynamic(
        light: (UIColor(red: 0.20, green: 0.23, blue: 0.34, alpha: 1.0),
                UIColor(red: 0.44, green: 0.49, blue: 0.59, alpha: 1.0)),
        dark: (UIColor(red: 0.08, green: 0.10, blue: 0.18, alpha: 1.0),
               UIColor(red: 0.22, green: 0.26, blue: 0.34, alpha: 1.0))
    )
    public static let snow = dynamic(
        light: (UIColor(red: 0.79, green: 0.86, blue: 0.95, alpha: 1.0),
                UIColor(red: 0.97, green: 0.98, blue: 1.00, alpha: 1.0)),
        dark: (UIColor(red: 0.22, green: 0.27, blue: 0.36, alpha: 1.0),
               UIColor(red: 0.38, green: 0.44, blue: 0.54, alpha: 1.0))
    )
    public static let windy = dynamic(
        light: (UIColor(red: 0.78, green: 0.84, blue: 0.78, alpha: 1.0),
                UIColor(red: 0.95, green: 0.94, blue: 0.86, alpha: 1.0)),
        dark: (UIColor(red: 0.18, green: 0.22, blue: 0.20, alpha: 1.0),
               UIColor(red: 0.30, green: 0.32, blue: 0.28, alpha: 1.0))
    )
    public static let fog = dynamic(
        light: (UIColor(red: 0.72, green: 0.74, blue: 0.76, alpha: 1.0),
                UIColor(red: 0.90, green: 0.91, blue: 0.92, alpha: 1.0)),
        dark: (UIColor(red: 0.18, green: 0.19, blue: 0.21, alpha: 1.0),
               UIColor(red: 0.30, green: 0.31, blue: 0.33, alpha: 1.0))
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
        // CAGradientLayer.colors holds resolved CGColors and won't react to
        // UITrait flips on its own — re-apply on every appearance change.
        bindAdaptiveColors { [weak self] _ in
            self?.applyPalette()
        }
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError() }

    private func applyPalette() {
        guard let layer = layer as? CAGradientLayer else { return }
        layer.colors = [
            palette.top.resolvedColor(with: traitCollection).cgColor,
            palette.bottom.resolvedColor(with: traitCollection).cgColor
        ]
        layer.startPoint = CGPoint(x: 0.5, y: 0)
        layer.endPoint = CGPoint(x: 0.5, y: 1)
    }
}
#endif
