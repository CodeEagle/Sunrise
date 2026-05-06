import UIKit
import SunriseDesignSystem

/// Used for tabs we haven't built yet (Forecast, Character, Profile).
/// Replaced as each Feature lands its own view controller.
final class PlaceholderViewController: UIViewController {
    init(title: String) {
        super.init(nibName: nil, bundle: nil)
        self.title = title
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError() }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = Palette.canvas

        let label = UILabel()
        label.text = String(localized: "placeholder.coming_soon", defaultValue: "Coming soon")
        label.font = Typography.title()
        label.textColor = Palette.inkSecondary
        label.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(label)
        NSLayoutConstraint.activate([
            label.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            label.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
    }
}
