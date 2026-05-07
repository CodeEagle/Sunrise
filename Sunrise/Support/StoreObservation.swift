import UIKit
import Observation

/// Lightweight wrapper around `withObservationTracking` for view controllers.
/// Each invocation runs `apply` once, then re-subscribes whenever any
/// observed `@ObservableState` property changes. Stop by deallocating the VC.
extension UIViewController {
    // `apply` is annotated `@MainActor` so it satisfies the Sendable
    // requirement of `withObservationTracking`'s `onChange` closure when the
    // body re-captures it for the recursive resubscribe. UIViewController is
    // already `@MainActor`-isolated, so call sites pass plain closures
    // unchanged.
    func observeState(_ apply: @escaping @MainActor () -> Void) {
        observeStateRecursive(apply)
    }

    private func observeStateRecursive(_ apply: @escaping @MainActor () -> Void) {
        withObservationTracking {
            apply()
        } onChange: { [weak self] in
            Task { @MainActor [weak self] in
                self?.observeStateRecursive(apply)
            }
        }
    }
}
