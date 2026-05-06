#if canImport(UIKit)
import UIKit

/// Color tokens distilled from the design mock — warm parchment background,
/// soft sailor-suit blues, and accent yellows from the character's ribbon.
/// MVP uses hard-coded light-mode values; migrate to a dynamic Asset Catalog
/// when we add dark-mode art (see DesignSystem/Resources roadmap).
public enum Palette {
    public static let canvas = UIColor(red: 0.97, green: 0.94, blue: 0.86, alpha: 1.0)
    public static let inkPrimary = UIColor(red: 0.16, green: 0.20, blue: 0.30, alpha: 1.0)
    public static let inkSecondary = UIColor(red: 0.36, green: 0.42, blue: 0.52, alpha: 1.0)
    public static let skyBlue = UIColor(red: 0.42, green: 0.62, blue: 0.83, alpha: 1.0)
    public static let cloudWhite = UIColor(white: 0.98, alpha: 1.0)
    public static let sunYellow = UIColor(red: 0.98, green: 0.80, blue: 0.27, alpha: 1.0)
    public static let leafGreen = UIColor(red: 0.55, green: 0.74, blue: 0.49, alpha: 1.0)
    public static let blossomPink = UIColor(red: 0.91, green: 0.55, blue: 0.55, alpha: 1.0)
}
#endif
