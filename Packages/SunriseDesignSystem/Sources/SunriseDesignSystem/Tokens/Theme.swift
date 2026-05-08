#if canImport(UIKit)
import UIKit

/// Centralised opacity scale. Cards / pills / scrims previously sprinkled
/// raw 0.4 / 0.55 / 0.7 / 0.85 / 0.95 alphas across the codebase — these
/// named tokens make the layering intent explicit and keep light/dark mode
/// surfaces consistent.
public enum Opacity {
    public static let glassFaint: CGFloat = 0.4
    public static let highlight: CGFloat = 0.55
    public static let glass: CGFloat = 0.7
    public static let glassStrong: CGFloat = 0.85
    public static let scrimSoft: CGFloat = 0.6
    public static let scrimMid: CGFloat = 0.75
    public static let scrimHeavy: CGFloat = 0.95
    public static let muted: CGFloat = 0.7
    public static let halo: CGFloat = 0.85
}

/// Shared elevation token so every floating card / panel reaches for the
/// same shadow recipe — keeps the cream-paper aesthetic coherent.
public enum Elevation {
    public static let cardOpacity: Float = 0.06
    public static let cardRadius: CGFloat = 16
    public static let cardOffset = CGSize(width: 0, height: 8)
}

public extension UIView {
    /// Re-runs `apply` whenever the view's user-interface style changes
    /// (light ↔ dark). Calls `apply` once immediately so the initial state
    /// is correct, then registers a trait-change handler for subsequent
    /// flips. Use this anywhere a CALayer-resident colour (shadow,
    /// gradient stops, border) needs to track the system theme — UIView /
    /// UILabel `backgroundColor` and `tintColor` already adapt for free
    /// when assigned a dynamic UIColor.
    func bindAdaptiveColors(_ apply: @escaping (UITraitCollection) -> Void) {
        apply(traitCollection)
        registerForTraitChanges([UITraitUserInterfaceStyle.self]) { (view: UIView, _: UITraitCollection) in
            apply(view.traitCollection)
        }
    }
}
#endif
