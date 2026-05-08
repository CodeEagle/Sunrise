import UIKit
import ComposableArchitecture
import ProfileFeature
import SunriseCore
import SunriseDesignSystem
import Localize_Swift

/// Settings → Language. Dispatches the new selection through Localize-Swift
/// (`Localize.setCurrentLanguage(_:)`) so every `String(localized:)` lookup
/// flips live via the package's bundle swizzle — no relaunch needed. The
/// preference is also persisted into UserSettings so it survives a cold
/// launch.
final class LanguageSettingsViewController: UITableViewController {
    private let store: StoreOf<ProfileReducer>

    init(store: StoreOf<ProfileReducer>) {
        self.store = store
        super.init(style: .insetGrouped)
        hidesBottomBarWhenPushed = true
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError() }

    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.title = "settings.row.language".l10n("Language")
        view.backgroundColor = Palette.canvas
        tableView.backgroundColor = .clear
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "Cell")
        observeState { [weak self] in
            self?.tableView.reloadData()
            self?.navigationItem.title = "settings.row.language".l10n("Language")
        }
        onLanguageChange { [weak self] in
            self?.tableView.reloadData()
            self?.navigationItem.title = "settings.row.language".l10n("Language")
        }
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        AppLanguage.allCases.count
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
        applyLanguage(language)
    }

    /// Hands the picked language to Localize-Swift so all currently-mounted
    /// views can observe `LCLLanguageChangeNotification` and re-render with
    /// the new strings. Also writes through to AppleLanguages so the next
    /// cold launch starts in the right language even before this VC mounts.
    private func applyLanguage(_ language: AppLanguage) {
        let defaults = UserDefaults.standard
        switch language {
        case .system:
            defaults.removeObject(forKey: "AppleLanguages")
            // Localize-Swift falls back to the system language when the
            // override matches the device locale; setting to the device
            // language explicitly is the closest API call we have.
            if let device = Locale.preferredLanguages.first?.split(separator: "-").first.map(String.init) {
                Localize.setCurrentLanguage(device)
            }
        case .english, .simplifiedChinese, .japanese,
             .traditionalChinese, .korean, .french, .german, .spanish,
             .italian, .portuguese, .russian, .arabic, .vietnamese,
             .thai, .indonesian, .turkish, .polish, .dutch, .swedish,
             .danish, .norwegian, .finnish, .hindi, .malay, .czech,
             .hungarian, .romanian, .greek, .hebrew, .ukrainian, .catalan,
             .croatian, .slovak:
            defaults.set([language.rawValue], forKey: "AppleLanguages")
            Localize.setCurrentLanguage(language.rawValue)
        }
    }

    private func label(for language: AppLanguage) -> String {
        switch language {
        case .system: return "settings.language.system".l10n("System")
        case .english: return "English"
        case .simplifiedChinese: return "简体中文"
        case .traditionalChinese: return "繁體中文"
        case .japanese: return "日本語"
        case .korean: return "한국어"
        case .french: return "Français"
        case .german: return "Deutsch"
        case .spanish: return "Español"
        case .italian: return "Italiano"
        case .portuguese: return "Português"
        case .russian: return "Русский"
        case .arabic: return "العربية"
        case .vietnamese: return "Tiếng Việt"
        case .thai: return "ไทย"
        case .indonesian: return "Bahasa Indonesia"
        case .turkish: return "Türkçe"
        case .polish: return "Polski"
        case .dutch: return "Nederlands"
        case .swedish: return "Svenska"
        case .danish: return "Dansk"
        case .norwegian: return "Norsk"
        case .finnish: return "Suomi"
        case .hindi: return "हिन्दी"
        case .malay: return "Bahasa Melayu"
        case .czech: return "Čeština"
        case .hungarian: return "Magyar"
        case .romanian: return "Română"
        case .greek: return "Ελληνικά"
        case .hebrew: return "עברית"
        case .ukrainian: return "Українська"
        case .catalan: return "Català"
        case .croatian: return "Hrvatski"
        case .slovak: return "Slovenčina"
        }
    }
}
