import UIKit

/// Helpers for view controllers that need to refresh their visible strings
/// when the user picks a new language in Settings. Localize-Swift posts
/// `LCLLanguageChangeNotification` on `Localize.setCurrentLanguage(_:)` —
/// observe it here and call back to whatever the VC's render path is.
///
/// The observer token is retained on the host VC via an associated object,
/// so callers don't have to manage lifetime — when the VC deallocs, the
/// token goes with it and `NotificationCenter` quietly drops the entry.
extension UIViewController {
    func onLanguageChange(_ handler: @escaping () -> Void) {
        let token = NotificationCenter.default.addObserver(
            forName: NSNotification.Name(rawValue: "LCLLanguageChangeNotification"),
            object: nil,
            queue: .main
        ) { _ in handler() }
        objc_setAssociatedObject(self, &LanguageObserverKey.key, token, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
    }
}

/// objc_setAssociatedObject needs a stable address. The byte is never
/// mutated; `nonisolated(unsafe)` lets Swift 6 strict concurrency accept
/// the global.
private enum LanguageObserverKey {
    nonisolated(unsafe) static var key: UInt8 = 0
}
