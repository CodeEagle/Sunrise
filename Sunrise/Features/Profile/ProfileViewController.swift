import UIKit
import ComposableArchitecture
import ProfileFeature
import SunriseCore
import SunriseDesignSystem

/// Settings tab — was "Me" (改为 settings per design feedback). Single
/// inset-grouped table grouped into:
/// - Appearance (Theme, Language)
/// - Data (Cities, Units, Notifications)
/// - About
///
/// Theme + Language now push their own sub-page (`ThemeSettingsViewController`,
/// `LanguageSettingsViewController`); Units stays as a quick action sheet to
/// keep the existing UX.
final class ProfileViewController: UIViewController {
    private let store: StoreOf<ProfileReducer>
    private let tableView = UITableView(frame: .zero, style: .insetGrouped)

    var onManageCitiesTapped: (() -> Void)?

    init(store: StoreOf<ProfileReducer>) {
        self.store = store
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError() }

    private enum Section: Int, CaseIterable {
        case appearance, data, about

        var rows: [Row] {
            switch self {
            case .appearance: return [.theme, .language]
            case .data: return [.cities, .units, .notifications]
            case .about: return [.about]
            }
        }

        var title: String {
            switch self {
            case .appearance: return "settings.section.appearance".l10n("Appearance")
            case .data: return "settings.section.data".l10n("Data")
            case .about: return "settings.section.about".l10n("About")
            }
        }
    }

    private enum Row {
        case theme, language, cities, units, notifications, about

        var symbol: String {
            switch self {
            case .theme: return "circle.righthalf.filled"
            case .language: return "globe"
            case .cities: return "mappin.and.ellipse"
            case .units: return "ruler"
            case .notifications: return "app.badge"
            case .about: return "info.circle"
            }
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.title = "settings.title".l10n("Settings")
        view.backgroundColor = Palette.canvas

        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.backgroundColor = .clear
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "Cell")
        view.addSubview(tableView)
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])

        observeState { [weak self] in self?.tableView.reloadData() }
        onLanguageChange { [weak self] in
            self?.navigationItem.title = "settings.title".l10n("Settings")
            self?.tableView.reloadData()
        }
        store.send(.onAppear)
    }
}

extension ProfileViewController: UITableViewDataSource, UITableViewDelegate {
    func numberOfSections(in tableView: UITableView) -> Int { Section.allCases.count }

    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        Section(rawValue: section)?.title
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        Section(rawValue: section)?.rows.count ?? 0
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
        cell.accessoryView = nil
        cell.accessoryType = .disclosureIndicator

        var content = cell.defaultContentConfiguration()
        content.textProperties.font = Typography.body()
        content.secondaryTextProperties.font = Typography.caption()
        content.secondaryTextProperties.color = Palette.inkSecondary
        content.imageProperties.tintColor = Palette.sunYellow

        let row = Section(rawValue: indexPath.section)!.rows[indexPath.row]
        content.image = UIImage(systemName: row.symbol)

        switch row {
        case .theme:
            content.text = "settings.row.theme".l10n("Theme")
            content.secondaryText = themeSummary(store.settings.theme)
        case .language:
            content.text = "settings.row.language".l10n("Language")
            content.secondaryText = languageSummary(store.settings.language)
        case .cities:
            content.text = "profile.row.cities".l10n("City management")
            content.secondaryText = String.localizedStringWithFormat(
                "profile.row.cities_value".l10n("%d cities"),
                store.managedCities.count
            )
        case .units:
            content.text = "profile.row.units".l10n("Unit settings")
            content.secondaryText = unitsSummary()
        case .notifications:
            content.text = "profile.row.notifications".l10n("Notifications")
            content.secondaryText = nil
            cell.accessoryType = .none
            let toggle = UISwitch()
            toggle.isOn = store.settings.notificationsEnabled
            toggle.addTarget(self, action: #selector(handleNotifToggle(_:)), for: .valueChanged)
            cell.accessoryView = toggle
        case .about:
            content.text = "profile.row.about".l10n("About Sunny weather")
            let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "0.1.0"
            content.secondaryText = String.localizedStringWithFormat(
                "profile.version_value".l10n("Version %@"),
                version
            )
        }

        cell.contentConfiguration = content
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let row = Section(rawValue: indexPath.section)!.rows[indexPath.row]
        switch row {
        case .theme:
            let vc = ThemeSettingsViewController(store: store)
            navigationController?.pushViewController(vc, animated: true)
        case .language:
            let vc = LanguageSettingsViewController(store: store)
            navigationController?.pushViewController(vc, animated: true)
        case .cities:
            onManageCitiesTapped?()
        case .units:
            presentUnitsPicker()
        case .notifications, .about:
            break
        }
    }

    @objc private func handleNotifToggle(_ sender: UISwitch) {
        let title = "notif.title".l10n("Good morning")
        let body = "notif.body".l10n("Sunny is checking the weather for you. Have a great day!")
        store.send(.notificationsToggled(sender.isOn, dailyTitle: title, dailyBody: body))
    }

    private func unitsSummary() -> String {
        let temp = store.settings.temperatureUnit == .celsius ? "°C" : "°F"
        let wind: String
        switch store.settings.windSpeedUnit {
        case .kilometersPerHour: wind = "km/h"
        case .milesPerHour: wind = "mph"
        case .metersPerSecond: wind = "m/s"
        }
        return "\(temp) · \(wind)"
    }

    private func themeSummary(_ pref: ThemePreference) -> String {
        switch pref {
        case .system: return "settings.theme.system".l10n("System")
        case .light: return "settings.theme.light".l10n("Light")
        case .dark: return "settings.theme.dark".l10n("Dark")
        }
    }

    private func languageSummary(_ language: AppLanguage) -> String {
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

    private func presentUnitsPicker() {
        let alert = UIAlertController(
            title: "profile.row.units".l10n("Unit settings"),
            message: nil,
            preferredStyle: .actionSheet
        )
        for unit in TemperatureUnit.allCases {
            let title = unit == .celsius ? "°C" : "°F"
            alert.addAction(UIAlertAction(title: title, style: .default) { [weak self] _ in
                self?.store.send(.temperatureUnitChanged(unit))
            })
        }
        for unit in WindSpeedUnit.allCases {
            let title: String
            switch unit {
            case .kilometersPerHour: title = "km/h"
            case .milesPerHour: title = "mph"
            case .metersPerSecond: title = "m/s"
            }
            alert.addAction(UIAlertAction(title: title, style: .default) { [weak self] _ in
                self?.store.send(.windUnitChanged(unit))
            })
        }
        alert.addAction(UIAlertAction(
            title: "common.cancel".l10n("Cancel"),
            style: .cancel
        ))
        present(alert, animated: true)
    }
}
