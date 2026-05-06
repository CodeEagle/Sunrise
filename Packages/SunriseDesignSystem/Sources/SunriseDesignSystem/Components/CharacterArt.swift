#if canImport(UIKit)
import UIKit

/// Resolves bundled character art by weather-condition raw value.
/// Files live at `Sunrise/Resources/Characters/sunny_<condition>.png` and
/// are flattened into the app bundle by XcodeGen, so a top-level lookup
/// in `Bundle.main` finds them.
public enum CharacterArt {
    public static func image(forConditionRawValue raw: String, in bundle: Bundle = .main) -> UIImage? {
        let name = "sunny_\(raw)"
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
