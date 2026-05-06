import UIKit
import Observation

/// Lightweight wrapper around `withObservationTracking` for view controllers.
/// Each invocation runs `apply` once, then re-subscribes whenever any
/// observed `@ObservableState` property changes. Stop by deallocating the VC.
extension UIViewController {
    func observeState(_ apply: @escaping () -> Void) {
        observeStateRecursive(apply)
    }

    private func observeStateRecursive(_ apply: @escaping () -> Void) {
        withObservationTracking {
            apply()
        } onChange: { [weak self] in
            DispatchQueue.main.async {
                self?.observeStateRecursive(apply)
            }
        }
    }
}
