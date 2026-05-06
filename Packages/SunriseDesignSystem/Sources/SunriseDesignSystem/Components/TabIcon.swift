#if canImport(UIKit)
import UIKit

public enum TabIcon {
    /// Tab bar icons render at ~28pt regardless of source resolution. Custom
    /// PNGs come in at 256x256, so we redraw them into a 28pt-square renderer
    /// before handing to UITabBarItem (otherwise iOS treats the raw pixel
    /// size as point size and the icons swallow the screen).
    private static let renderSize = CGSize(width: 28, height: 28)

    /// Loads a custom tab icon rendered with original colours (not template
    /// tinted by the tab bar) and resized for the tab bar. Falls back to an
    /// SF Symbol if the bundled PNG is missing.
    public static func image(named name: String, fallbackSF: String) -> UIImage? {
        if let raw = bundledPNG(named: name) ?? UIImage(named: name) {
            return resized(raw).withRenderingMode(.alwaysOriginal)
        }
        return UIImage(systemName: fallbackSF)
    }

    private static func bundledPNG(named name: String) -> UIImage? {
        guard let path = Bundle.main.path(forResource: name, ofType: "png") else { return nil }
        return UIImage(contentsOfFile: path)
    }

    private static func resized(_ image: UIImage) -> UIImage {
        let format = UIGraphicsImageRendererFormat.default()
        format.opaque = false
        let renderer = UIGraphicsImageRenderer(size: renderSize, format: format)
        return renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: renderSize))
        }
    }
}

public enum MoodArt {
    public static func image(forMoodRawValue raw: String) -> UIImage? {
        let name = "mood_\(raw)"
        if let asset = UIImage(named: name) { return asset }
        if let path = Bundle.main.path(forResource: name, ofType: "png") {
            return UIImage(contentsOfFile: path)
        }
        return nil
    }
}
#endif
