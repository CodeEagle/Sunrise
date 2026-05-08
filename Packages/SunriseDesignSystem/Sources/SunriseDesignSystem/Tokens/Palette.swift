#if canImport(UIKit)
import UIKit

/// Color tokens distilled from the design mock — warm parchment background,
/// soft sailor-suit blues, and accent yellows from the character's ribbon.
/// Every token is a `UIColor(dynamicProvider:)` so a single named reference
/// adapts automatically when the system flips between light and dark mode.
/// Light-mode values match the original watercolour mock; dark-mode values
/// invert canvas/ink while keeping accent colours roughly hue-stable so the
/// brand still reads at night.
public enum Palette {
    public static let canvas = dynamic(
        light: UIColor(red: 0.97, green: 0.94, blue: 0.86, alpha: 1.0),
        dark: UIColor(red: 0.10, green: 0.11, blue: 0.15, alpha: 1.0)
    )

    public static let inkPrimary = dynamic(
        light: UIColor(red: 0.16, green: 0.20, blue: 0.30, alpha: 1.0),
        dark: UIColor(red: 0.95, green: 0.94, blue: 0.88, alpha: 1.0)
    )

    public static let inkSecondary = dynamic(
        light: UIColor(red: 0.36, green: 0.42, blue: 0.52, alpha: 1.0),
        dark: UIColor(red: 0.66, green: 0.68, blue: 0.74, alpha: 1.0)
    )

    public static let skyBlue = dynamic(
        light: UIColor(red: 0.42, green: 0.62, blue: 0.83, alpha: 1.0),
        dark: UIColor(red: 0.55, green: 0.72, blue: 0.92, alpha: 1.0)
    )

    public static let cloudWhite = dynamic(
        light: UIColor(white: 0.98, alpha: 1.0),
        dark: UIColor(red: 0.18, green: 0.19, blue: 0.23, alpha: 1.0)
    )

    public static let sunYellow = dynamic(
        light: UIColor(red: 0.98, green: 0.80, blue: 0.27, alpha: 1.0),
        dark: UIColor(red: 0.96, green: 0.78, blue: 0.34, alpha: 1.0)
    )

    public static let leafGreen = dynamic(
        light: UIColor(red: 0.55, green: 0.74, blue: 0.49, alpha: 1.0),
        dark: UIColor(red: 0.60, green: 0.80, blue: 0.55, alpha: 1.0)
    )

    public static let blossomPink = dynamic(
        light: UIColor(red: 0.91, green: 0.55, blue: 0.55, alpha: 1.0),
        dark: UIColor(red: 0.95, green: 0.62, blue: 0.62, alpha: 1.0)
    )

    /// Card / pill / chip surface fill. Cream paper in light mode, deep
    /// slate in dark — used by Liquid Glass fallbacks and any non-glass
    /// rounded-rect that needs a unified theme-aware background.
    public static let surface = dynamic(
        light: UIColor(white: 1.00, alpha: 1.0),
        dark: UIColor(red: 0.16, green: 0.17, blue: 0.21, alpha: 1.0)
    )

    /// Drop-shadow tint for elevated cards. Light mode picks black; dark
    /// mode picks a near-black with a cool cast so the shadow still reads
    /// against the midnight canvas instead of disappearing.
    public static let shadow = dynamic(
        light: UIColor(white: 0.0, alpha: 1.0),
        dark: UIColor(red: 0.0, green: 0.02, blue: 0.05, alpha: 1.0)
    )

    /// Text-halo glow for labels overlaid on painted scenes. White wash in
    /// light mode keeps dark ink legible; dark wash in dark mode keeps the
    /// off-cream text legible against bright watercolour highlights.
    public static let textHalo = dynamic(
        light: UIColor(white: 1.00, alpha: 1.0),
        dark: UIColor(red: 0.05, green: 0.06, blue: 0.10, alpha: 1.0)
    )

    /// Snow / overcast neutral tint used by ConditionIcon. Slightly brighter
    /// in dark mode so the snowflake still reads on a dim sky.
    public static let snowTint = dynamic(
        light: UIColor(white: 0.78, alpha: 1.0),
        dark: UIColor(white: 0.86, alpha: 1.0)
    )

    private static func dynamic(light: UIColor, dark: UIColor) -> UIColor {
        UIColor { traits in
            traits.userInterfaceStyle == .dark ? dark : light
        }
    }
}
#endif
