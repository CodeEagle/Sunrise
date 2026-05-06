#if canImport(UIKit)
import UIKit

public enum TabIcon {
    /// Loads a custom tab icon (rendered with original colours so it doesn't
    /// pick up the tab bar tint) or falls back to an SF Symbol so the bar
    /// always renders even before assets are bundled.
    public static func image(named name: String, fallbackSF: String) -> UIImage? {
        if let path = Bundle.main.path(forResource: name, ofType: "png"),
           let image = UIImage(contentsOfFile: path) {
            return image.withRenderingMode(.alwaysOriginal)
        }
        if let asset = UIImage(named: name) {
            return asset.withRenderingMode(.alwaysOriginal)
        }
        return UIImage(systemName: fallbackSF)
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
