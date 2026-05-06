import UIKit
import ComposableArchitecture
import ProfileFeature
import SunriseDesignSystem

final class ProfileViewController: UIViewController {
    private let store: StoreOf<ProfileReducer>
    var onManageCitiesTapped: (() -> Void)?

    init(store: StoreOf<ProfileReducer>) {
        self.store = store
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError() }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = String(localized: "tab.profile", defaultValue: "Me")
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

        store.send(.onAppear)
    }
}
