import UIKit
import ComposableArchitecture
import ProfileFeature
import SunriseCore
import SunriseDesignSystem

/// Settings → Language. Picks the per-app language and writes it through to
/// `AppleLanguages` in user defaults. iOS reads that key on next launch to
/// pick string tables / locale formatters, so we surface a relaunch prompt.
final class LanguageSettingsViewController: UITableViewController {
    private let store: StoreOf<ProfileReducer>

    init(store: StoreOf<ProfileReducer>) {
        self.store = store
        super.init(style: .insetGrouped)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError() }

    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.title = String(localized: "settings.row.language", defaultValue: "Language")
        view.backgroundColor = Palette.canvas
        tableView.backgroundColor = .clear
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "Cell")
        observeState { [weak self] in self?.tableView.reloadData() }
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        AppLanguage.allCases.count
    }

    override func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        String(localized: "settings.language.footer",
               defaultValue: "Language changes take effect after relaunching Sunrise.")
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
        let language = AppLanguage.allCases[indexPath.row]
        var content = cell.defaultContentConfiguration()
        content.text = label(for: language)
        content.textProperties.font = Typography.body()
        cell.contentConfiguration = content
        cell.accessoryType = (language == store.settings.language) ? .checkmark : .none
        return cell
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let language = AppLanguage.allCases[indexPath.row]
        guard language != store.settings.language else { return }
        store.send(.languageChanged(language))
        applyLanguageToAppleLanguages(language)
        promptRelaunch()
    }

    /// Writes the user's language preference into the `AppleLanguages` user
    /// default so the next launch picks the right string table. iOS-13+ also
    /// honours this for the per-app Settings page; setting `nil` falls back
    /// to the system language.
    private func applyLanguageToAppleLanguages(_ language: AppLanguage) {
        let defaults = UserDefaults.standard
        switch language {
        case .system:
            defaults.removeObject(forKey: "AppleLanguages")
        case .english, .simplifiedChinese, .japanese:
            defaults.set([language.rawValue], forKey: "AppleLanguages")
        }
    }

    private func promptRelaunch() {
        let alert = UIAlertController(
            title: String(localized: "settings.language.relaunch_title",
                          defaultValue: "Relaunch required"),
            message: String(localized: "settings.language.relaunch_body",
                            defaultValue: "Quit and reopen Sunrise to apply the new language."),
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(
            title: String(localized: "common.ok", defaultValue: "OK"),
            style: .default
        ))
        present(alert, animated: true)
    }

    private func label(for language: AppLanguage) -> String {
        switch language {
        case .system: return String(localized: "settings.language.system", defaultValue: "System")
        case .english: return "English"
        case .simplifiedChinese: return "简体中文"
        case .japanese: return "日本語"
        }
    }
}
