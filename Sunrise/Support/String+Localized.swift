import Foundation
import Localize_Swift

/// Live-switching localized lookup. Apple's iOS 16+ `String(localized:)`
/// API doesn't go through Localize-Swift's bundle override, so changing
/// the active language at runtime via `Localize.setCurrentLanguage(_:)`
/// has no effect on those calls. `.l10n(_:)` routes through the override
/// instead, returning the supplied fallback when no translation exists.
///
/// Use anywhere a string needs to flip live when the user picks a new
/// language in Settings; behaves identically to
/// `"key".l10n("fallback")` for cold-launch
/// reads since both end up reading the same xcstrings table.
extension String {
    func l10n(_ defaultValue: String) -> String {
        let resolved = self.localized()
        return resolved == self ? defaultValue : resolved
    }
}
