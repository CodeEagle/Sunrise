import UIKit
import ComposableArchitecture
import ProfileFeature
import SunriseCore
import SunriseDesignSystem

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

    /// Single-section list of six rows mirroring the design board
    /// (城市管理 / 天气提醒 / 角色与语音 / 单位设置 / 通知设置 / 关于).
    private enum Row: Int, CaseIterable {
        case cities, briefing, voice, units, notifications, about

        var symbol: String {
            switch self {
            case .cities: return "mappin.and.ellipse"
            case .briefing: return "bell.badge"
            case .voice: return "person.wave.2"
            case .units: return "gearshape"
            case .notifications: return "app.badge"
            case .about: return "info.circle"
            }
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        // Design board has no page-level title — the avatar card stands in
        // for it. Skip setting `navigationItem.title` so the nav bar reads
        // empty above the table.
        view.backgroundColor = Palette.canvas

        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.backgroundColor = .clear
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "Cell")
        tableView.tableHeaderView = makeHeader(width: view.bounds.width)
        view.addSubview(tableView)
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])

        observeState { [weak self] in self?.tableView.reloadData() }
        store.send(.onAppear)
    }

    private func makeHeader(width: CGFloat) -> UIView {
        // Avatar lives in its own rounded card above the settings list, so
        // we wrap it in a card view inset from the table edges.
        let outer = UIView(frame: CGRect(x: 0, y: 0, width: width, height: 116))
        outer.backgroundColor = .clear

        let card = UIView()
        card.backgroundColor = Palette.surface
        card.layer.cornerRadius = Radius.medium
        card.layer.cornerCurve = .continuous
        card.translatesAutoresizingMaskIntoConstraints = false

        let avatar = UIImageView()
        avatar.contentMode = .scaleAspectFill
        // Mood portraits are bust crops — they sit cleanly in a circle, unlike
        // the full-body character scenes which get awkwardly squashed.
        avatar.image = MoodArt.image(forMoodRawValue: "happy")
            ?? CharacterArt.image(forConditionRawValue: "clear")
        avatar.layer.cornerRadius = 30
        avatar.clipsToBounds = true
        avatar.backgroundColor = Palette.sunYellow.withAlphaComponent(0.25)
        avatar.translatesAutoresizingMaskIntoConstraints = false

        let name = UILabel()
        name.text = String(localized: "profile.friend_name", defaultValue: "Sunny's friend")
        name.font = Typography.title(18)
        name.textColor = Palette.inkPrimary

        let id = UILabel()
        id.text = "ID: 20240520"
        id.font = Typography.caption(12)
        id.textColor = Palette.inkSecondary

        let textStack = UIStackView(arrangedSubviews: [name, id])
        textStack.axis = .vertical
        textStack.spacing = 2
        textStack.translatesAutoresizingMaskIntoConstraints = false

        let chevron = UIImageView(image: UIImage(systemName: "chevron.right"))
        chevron.tintColor = Palette.inkSecondary
        chevron.contentMode = .scaleAspectFit
        chevron.translatesAutoresizingMaskIntoConstraints = false

        outer.addSubview(card)
        card.addSubview(avatar)
        card.addSubview(textStack)
        card.addSubview(chevron)

        // .defaultHigh so this yields (instead of cascading 5 broken
        // constraints) during UITableView's 0-width tableHeaderView sizing pass.
        let cardTrailing = card.trailingAnchor.constraint(equalTo: outer.trailingAnchor, constant: -Spacing.m)
        cardTrailing.priority = .defaultHigh

        NSLayoutConstraint.activate([
            card.topAnchor.constraint(equalTo: outer.topAnchor, constant: Spacing.s),
            card.bottomAnchor.constraint(equalTo: outer.bottomAnchor, constant: -Spacing.s),
            card.leadingAnchor.constraint(equalTo: outer.leadingAnchor, constant: Spacing.m),
            cardTrailing,

            avatar.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: Spacing.m),
            avatar.centerYAnchor.constraint(equalTo: card.centerYAnchor),
            avatar.widthAnchor.constraint(equalToConstant: 60),
            avatar.heightAnchor.constraint(equalToConstant: 60),

            textStack.leadingAnchor.constraint(equalTo: avatar.trailingAnchor, constant: Spacing.m),
            textStack.trailingAnchor.constraint(lessThanOrEqualTo: chevron.leadingAnchor, constant: -Spacing.s),
            textStack.centerYAnchor.constraint(equalTo: card.centerYAnchor),

            chevron.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -Spacing.m),
            chevron.centerYAnchor.constraint(equalTo: card.centerYAnchor),
            chevron.widthAnchor.constraint(equalToConstant: 12),
            chevron.heightAnchor.constraint(equalToConstant: 16)
        ])
        return outer
    }
}

extension ProfileViewController: UITableViewDataSource, UITableViewDelegate {
    func numberOfSections(in tableView: UITableView) -> Int { 1 }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        Row.allCases.count
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

        let row = Row(rawValue: indexPath.row)!
        content.image = UIImage(systemName: row.symbol)
        switch row {
        case .cities:
            content.text = String(localized: "profile.row.cities", defaultValue: "City management")
            content.secondaryText = String.localizedStringWithFormat(
                String(localized: "profile.row.cities_value", defaultValue: "%d cities"),
                store.managedCities.count
            )
        case .briefing:
            content.text = String(localized: "profile.row.briefing", defaultValue: "Weather briefing")
            content.secondaryText = store.settings.notificationsEnabled
                ? String(localized: "profile.row.briefing_value_on", defaultValue: "Daily at 08:00")
                : String(localized: "profile.row.briefing_value_off", defaultValue: "Off")
        case .voice:
            content.text = String(localized: "profile.row.voice", defaultValue: "Character & voice")
            content.secondaryText = String(localized: "profile.row.voice_value", defaultValue: "Sunny · default voice")
        case .units:
            content.text = String(localized: "profile.row.units", defaultValue: "Unit settings")
            content.secondaryText = unitsSummary()
        case .notifications:
            content.text = String(localized: "profile.row.notifications", defaultValue: "Notifications")
            content.secondaryText = nil
            cell.accessoryType = .none
            let toggle = UISwitch()
            toggle.isOn = store.settings.notificationsEnabled
            toggle.addTarget(self, action: #selector(handleNotifToggle(_:)), for: .valueChanged)
            cell.accessoryView = toggle
        case .about:
            content.text = String(localized: "profile.row.about", defaultValue: "About Sunny weather")
            let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "0.1.0"
            content.secondaryText = String.localizedStringWithFormat(
                String(localized: "profile.version_value", defaultValue: "Version %@"),
                version
            )
        }

        cell.contentConfiguration = content
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        switch Row(rawValue: indexPath.row)! {
        case .cities: onManageCitiesTapped?()
        case .units: presentUnitsPicker()
        case .briefing, .voice, .about, .notifications: break
        }
    }

    @objc private func handleNotifToggle(_ sender: UISwitch) {
        let title = String(localized: "notif.title", defaultValue: "Good morning")
        let body = String(localized: "notif.body", defaultValue: "Sunny is checking the weather for you. Have a great day!")
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

    private func presentUnitsPicker() {
        let alert = UIAlertController(
            title: String(localized: "profile.row.units", defaultValue: "Unit settings"),
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
            title: String(localized: "common.cancel", defaultValue: "Cancel"),
            style: .cancel
        ))
        present(alert, animated: true)
    }
}
