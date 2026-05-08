import UIKit
import ComposableArchitecture
import ProfileFeature
import SunriseCore
import SunriseDesignSystem

/// Settings → Theme. Three rows (System / Light / Dark), checkmark on the
/// active one. Picking a row dispatches `.themeChanged(...)` and the host
/// window updates its `overrideUserInterfaceStyle` immediately (wired in
/// `SceneDelegate.applyTheme`).
final class ThemeSettingsViewController: UITableViewController {
    private let store: StoreOf<ProfileReducer>

    init(store: StoreOf<ProfileReducer>) {
        self.store = store
        super.init(style: .insetGrouped)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError() }

    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.title = String(localized: "settings.row.theme", defaultValue: "Theme")
        view.backgroundColor = Palette.canvas
        tableView.backgroundColor = .clear
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "Cell")
        observeState { [weak self] in self?.tableView.reloadData() }
        onLanguageChange { [weak self] in
            self?.navigationItem.title = String(localized: "settings.row.theme", defaultValue: "Theme")
            self?.tableView.reloadData()
        }
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        ThemePreference.allCases.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
        let preference = ThemePreference.allCases[indexPath.row]
        var content = cell.defaultContentConfiguration()
        content.text = label(for: preference)
        content.textProperties.font = Typography.body()
        cell.contentConfiguration = content
        cell.accessoryType = (preference == store.settings.theme) ? .checkmark : .none
        return cell
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let preference = ThemePreference.allCases[indexPath.row]
        store.send(.themeChanged(preference))
    }

    private func label(for preference: ThemePreference) -> String {
        switch preference {
        case .system: return String(localized: "settings.theme.system", defaultValue: "System")
        case .light: return String(localized: "settings.theme.light", defaultValue: "Light")
        case .dark: return String(localized: "settings.theme.dark", defaultValue: "Dark")
        }
    }
}
