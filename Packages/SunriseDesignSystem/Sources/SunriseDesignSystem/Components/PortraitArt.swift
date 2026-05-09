#if canImport(UIKit)
import UIKit

/// Resolves the integrated character + scene composite image for a
/// given weather condition + optional time-of-day period.
///
/// Lookup order (first hit wins):
/// 1. `portrait_<condition>_<period>.png` — codex-generated variant
///    for a specific tuple, e.g. `portrait_clear_dusk.png` for
///    golden-hour clear days.
/// 2. `portrait_<condition>.png` — the canonical day-time variant.
/// 3. Legacy split-layer `sunny_<condition>.png` from `CharacterArt`.
///
/// Caller passes the day-period as a raw string (e.g. `"dawn"`,
/// `"day"`, `"dusk"`, `"night"`) so this resolver stays free of any
/// `SunriseCore` dependency. Period variants are optional — drop
/// them into `Sunrise/Resources/Characters/` whenever a new codex
/// run lands and the resolver picks them up automatically.
public enum PortraitArt {
    public static func image(
        forConditionRawValue raw: String,
        periodRawValue: String? = nil,
        in bundle: Bundle = .main
    ) -> UIImage? {
        var candidates: [String] = []
        if let periodRawValue {
            candidates.append("portrait_\(raw)_\(periodRawValue)")
        }
        candidates.append("portrait_\(raw)")
        for name in candidates {
            if let asset = UIImage(named: name, in: bundle, with: nil) {
                return asset
            }
            if let path = bundle.path(forResource: name, ofType: "png"),
               let image = UIImage(contentsOfFile: path) {
                return image
            }
        }
        // Final fallback to the legacy split-layer character art if no
        // composite exists for this condition yet.
        return CharacterArt.image(forConditionRawValue: raw, in: bundle)
    }
}
#endif
