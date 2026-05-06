#if canImport(UIKit)
import UIKit
import Lottie

/// View that renders the character with a Lottie animation if available in the
/// host bundle, otherwise leaves the contained `fallbackView` visible. The
/// host app is responsible for supplying `bundle` (defaults to `.main`).
public final class LottieCharacterView: UIView, CharacterAnimator {
    private let bundle: Bundle
    private let fallbackView: UIView
    private var lottieView: LottieAnimationView?

    public init(fallbackView: UIView, bundle: Bundle = .main) {
        self.bundle = bundle
        self.fallbackView = fallbackView
        super.init(frame: .zero)

        fallbackView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(fallbackView)
        NSLayoutConstraint.activate([
            fallbackView.topAnchor.constraint(equalTo: topAnchor),
            fallbackView.bottomAnchor.constraint(equalTo: bottomAnchor),
            fallbackView.leadingAnchor.constraint(equalTo: leadingAnchor),
            fallbackView.trailingAnchor.constraint(equalTo: trailingAnchor)
        ])
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError() }

    public func update(condition: AnimatedCondition, dayPeriod: AnimatedDayPeriod) {
        let name = CharacterAnimationCatalog.filename(for: condition)
        guard bundle.url(forResource: name, withExtension: "json") != nil else {
            // No Lottie file for this condition yet — keep showing the fallback.
            tearDownLottie()
            fallbackView.isHidden = false
            return
        }
        let view = lottieView ?? makeLottieView()
        view.animation = LottieAnimation.named(name, bundle: bundle)
        view.loopMode = .loop
        view.contentMode = .scaleAspectFit
        view.play()
        fallbackView.isHidden = true
    }

    private func makeLottieView() -> LottieAnimationView {
        let view = LottieAnimationView()
        view.translatesAutoresizingMaskIntoConstraints = false
        addSubview(view)
        NSLayoutConstraint.activate([
            view.topAnchor.constraint(equalTo: topAnchor),
            view.bottomAnchor.constraint(equalTo: bottomAnchor),
            view.leadingAnchor.constraint(equalTo: leadingAnchor),
            view.trailingAnchor.constraint(equalTo: trailingAnchor)
        ])
        lottieView = view
        return view
    }

    private func tearDownLottie() {
        lottieView?.stop()
        lottieView?.removeFromSuperview()
        lottieView = nil
    }
}
#endif
