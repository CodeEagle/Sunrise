import UIKit
import ComposableArchitecture
import CharacterFeature
import SunriseDesignSystem

final class CharacterViewController: UIViewController {
    private let store: StoreOf<CharacterReducer>

    init(store: StoreOf<CharacterReducer>) {
        self.store = store
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError() }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = String(localized: "tab.character", defaultValue: "Sunny")
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
