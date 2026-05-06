#if canImport(UIKit)
import UIKit

/// Resolves bundled hand-drawn weather icons by `WeatherCondition.rawValue`.
/// Files live at `Sunrise/Resources/WeatherIcons/icon_<condition>.png` and
/// fall back to `nil` so callers can drop down to SF Symbols.
public enum WeatherIconArt {
    public static func image(forConditionRawValue raw: String, in bundle: Bundle = .main) -> UIImage? {
        let name = "icon_\(raw)"
        if let asset = UIImage(named: name, in: bundle, with: nil) {
            return asset
        }
        if let path = bundle.path(forResource: name, ofType: "png") {
            return UIImage(contentsOfFile: path)
        }
        return nil
    }
}
#endif
