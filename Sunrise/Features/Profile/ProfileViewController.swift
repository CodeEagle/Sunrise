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

    private enum Section: Int, CaseIterable {
        case units
        case notifications
        case cities
        case about
    }

    private enum UnitsRow: Int, CaseIterable { case temperature, wind }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = String(localized: "tab.profile", defaultValue: "Me")
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
        store.send(.onAppear)
    }
}

extension ProfileViewController: UITableViewDataSource, UITableViewDelegate {
    func numberOfSections(in tableView: UITableView) -> Int { Section.allCases.count }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch Section(rawValue: section)! {
        case .units: return UnitsRow.allCases.count
        case .notifications: return 1
        case .cities: return 1
        case .about: return 1
        }
    }

    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        switch Section(rawValue: section)! {
        case .units: return String(localized: "profile.units", defaultValue: "Units")
        case .notifications: return String(localized: "profile.notifications", defaultValue: "Notifications")
        case .cities: return String(localized: "profile.cities", defaultValue: "Cities")
        case .about: return String(localized: "profile.about", defaultValue: "About")
        }
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
        cell.accessoryView = nil
        cell.accessoryType = .none

        var content = cell.defaultContentConfiguration()
        content.textProperties.font = Typography.body()
        content.secondaryTextProperties.font = Typography.caption()

        switch Section(rawValue: indexPath.section)! {
        case .units:
            switch UnitsRow(rawValue: indexPath.row)! {
            case .temperature:
                content.text = String(localized: "profile.temp_unit", defaultValue: "Temperature")
                content.secondaryText = temperatureUnitTitle(store.settings.temperatureUnit)
                cell.accessoryType = .disclosureIndicator
            case .wind:
                content.text = String(localized: "profile.wind_unit", defaultValue: "Wind speed")
                content.secondaryText = windUnitTitle(store.settings.windSpeedUnit)
                cell.accessoryType = .disclosureIndicator
            }
        case .notifications:
            content.text = String(localized: "profile.daily_brief", defaultValue: "Daily morning briefing")
            let toggle = UISwitch()
            toggle.isOn = store.settings.notificationsEnabled
            toggle.addTarget(self, action: #selector(handleNotifToggle(_:)), for: .valueChanged)
            cell.accessoryView = toggle
        case .cities:
            content.text = String(localized: "profile.manage_cities", defaultValue: "Manage cities")
            content.secondaryText = String.localizedStringWithFormat(
                String(localized: "profile.city_count", defaultValue: "%d saved"),
                store.managedCities.count
            )
            cell.accessoryType = .disclosureIndicator
        case .about:
            content.text = String(localized: "profile.version", defaultValue: "Version")
            let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "0.1.0"
            content.secondaryText = version
        }

        cell.contentConfiguration = content
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        switch Section(rawValue: indexPath.section)! {
        case .units:
            switch UnitsRow(rawValue: indexPath.row)! {
            case .temperature: presentTemperaturePicker()
            case .wind: presentWindPicker()
            }
        case .cities:
            onManageCitiesTapped?()
        case .notifications, .about:
            break
        }
    }

    @objc private func handleNotifToggle(_ sender: UISwitch) {
        store.send(.notificationsToggled(sender.isOn))
    }

    private func presentTemperaturePicker() {
        let alert = UIAlertController(
            title: String(localized: "profile.temp_unit", defaultValue: "Temperature"),
            message: nil,
            preferredStyle: .actionSheet
        )
        for unit in TemperatureUnit.allCases {
            alert.addAction(UIAlertAction(title: temperatureUnitTitle(unit), style: .default) { [weak self] _ in
                self?.store.send(.temperatureUnitChanged(unit))
            })
        }
        alert.addAction(UIAlertAction(title: String(localized: "common.cancel", defaultValue: "Cancel"), style: .cancel))
        present(alert, animated: true)
    }

    private func presentWindPicker() {
        let alert = UIAlertController(
            title: String(localized: "profile.wind_unit", defaultValue: "Wind speed"),
            message: nil,
            preferredStyle: .actionSheet
        )
        for unit in WindSpeedUnit.allCases {
            alert.addAction(UIAlertAction(title: windUnitTitle(unit), style: .default) { [weak self] _ in
                self?.store.send(.windUnitChanged(unit))
            })
        }
        alert.addAction(UIAlertAction(title: String(localized: "common.cancel", defaultValue: "Cancel"), style: .cancel))
        present(alert, animated: true)
    }

    private func temperatureUnitTitle(_ unit: TemperatureUnit) -> String {
        switch unit {
        case .celsius: return "°C"
        case .fahrenheit: return "°F"
        }
    }

    private func windUnitTitle(_ unit: WindSpeedUnit) -> String {
        switch unit {
        case .kilometersPerHour: return "km/h"
        case .milesPerHour: return "mph"
        case .metersPerSecond: return "m/s"
        }
    }
}
