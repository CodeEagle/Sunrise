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
    /// Run `handler` on the main actor whenever Localize-Swift broadcasts
    /// a language change. The callback is delivered on the main queue, but
    /// `NotificationCenter`'s closure type is @Sendable on Swift 6 — hop
    /// through `Task { @MainActor in }` so a non-Sendable handler (which
    /// captures UIKit state) stays on the main actor without violating
    /// Sendable.
    func onLanguageChange(_ handler: @escaping @MainActor () -> Void) {
        let observer = LanguageObserver(handler: handler)
        observer.start()
        objc_setAssociatedObject(self, &LanguageObserverKey.key, observer, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
    }
}

/// Bridge object that owns the NotificationCenter token and the @MainActor
/// handler. Marked `@unchecked Sendable` because the only mutation point
/// is `start()` on init and we never expose `handler` outside the main
/// actor block.
private final class LanguageObserver: @unchecked Sendable {
    private let handler: @MainActor () -> Void
    private var token: NSObjectProtocol?

    init(handler: @escaping @MainActor () -> Void) {
        self.handler = handler
    }

    func start() {
        token = NotificationCenter.default.addObserver(
            forName: NSNotification.Name(rawValue: "LCLLanguageChangeNotification"),
            object: nil,
            queue: .main
        ) { [handler] _ in
            // The notification block is @Sendable; hop to the main actor
            // so we can invoke the @MainActor handler safely.
            Task { @MainActor in handler() }
        }
    }

    deinit {
        if let token {
            NotificationCenter.default.removeObserver(token)
        }
    }
}

/// objc_setAssociatedObject needs a stable address. The byte is never
/// mutated; `nonisolated(unsafe)` lets Swift 6 strict concurrency accept
/// the global.
private enum LanguageObserverKey {
    nonisolated(unsafe) static var key: UInt8 = 0
}
