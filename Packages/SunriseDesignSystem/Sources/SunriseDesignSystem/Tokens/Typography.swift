#if canImport(UIKit)
import UIKit

/// Font tokens. Body 14–16pt, captions 12–13pt, hero numerals 28–34pt
/// — matches the type spec lifted from the design board.
public enum Typography {
    public static func display(_ size: CGFloat = 34) -> UIFont {
        scaled(.systemFont(ofSize: size, weight: .bold), style: .largeTitle)
    }

    public static func title(_ size: CGFloat = 22) -> UIFont {
        scaled(.systemFont(ofSize: size, weight: .semibold), style: .title2)
    }

    public static func body(_ size: CGFloat = 16) -> UIFont {
        scaled(.systemFont(ofSize: size, weight: .regular), style: .body)
    }

    public static func caption(_ size: CGFloat = 13) -> UIFont {
        scaled(.systemFont(ofSize: size, weight: .regular), style: .caption1)
    }

    public static func numeric(_ size: CGFloat = 56) -> UIFont {
        // Hero temperature reading. Rounded design feels closer to the hand-drawn aesthetic.
        let descriptor = UIFontDescriptor
            .preferredFontDescriptor(withTextStyle: .largeTitle)
            .withDesign(.rounded)?
            .withSymbolicTraits(.traitBold)
        return UIFont(descriptor: descriptor ?? UIFontDescriptor.preferredFontDescriptor(withTextStyle: .largeTitle), size: size)
    }

    private static func scaled(_ font: UIFont, style: UIFont.TextStyle) -> UIFont {
        UIFontMetrics(forTextStyle: style).scaledFont(for: font)
    }
}
#endif
