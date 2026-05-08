#if canImport(UIKit)
import UIKit

/// Resolves the integrated character + scene composite image for a given
/// weather condition. Files live at
/// `Sunrise/Resources/Characters/portrait_<condition>.png` and replace the
/// older split-layer (`bg_*.png` + `sunny_*.png`) approach the Character
/// tab used to draw — those layers always read as "pasted over" each
/// other, which the design feedback flagged as feeling weird.
public enum PortraitArt {
    public static func image(forConditionRawValue raw: String, in bundle: Bundle = .main) -> UIImage? {
        let name = "portrait_\(raw)"
        if let asset = UIImage(named: name, in: bundle, with: nil) {
            return asset
        }
        if let path = bundle.path(forResource: name, ofType: "png") {
            return UIImage(contentsOfFile: path)
        }
        // Fallback to the legacy split-layer character art if a composite
        // for this condition hasn't shipped yet.
        return CharacterArt.image(forConditionRawValue: raw, in: bundle)
    }
}
#endif
