import UIKit
import ComposableArchitecture
import CityFeature
import SunriseCore
import SunriseDesignSystem

final class CityListViewController: UIViewController {
    private let store: StoreOf<CityListReducer>
    private let tableView = UITableView(frame: .zero, style: .insetGrouped)
    private let emptyLabel = UILabel()

    init(store: StoreOf<CityListReducer>) {
        self.store = store
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError() }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = String(localized: "cities.title", defaultValue: "Cities")
        view.backgroundColor = Palette.canvas

        // Bar buttons need their tint pinned to Palette.inkPrimary — without
        // it the system picks the parent nav bar's tint which can drift back
        // to systemBlue when the modal is re-presented (we'd see a white-ish
        // "+" against the cream sheet, which is the bug a user flagged).
        let addButton = UIBarButtonItem(
            barButtonSystemItem: .add,
            target: self,
            action: #selector(handleAdd)
        )
        addButton.tintColor = Palette.inkPrimary
        navigationItem.rightBarButtonItem = addButton

        let editItem = editButtonItem
        editItem.tintColor = Palette.inkPrimary
        navigationItem.leftBarButtonItem = editItem

        // Apply the same tint to the surrounding nav bar so the title chrome
        // stays in inkPrimary even after Liquid Glass swaps materials.
        navigationController?.navigationBar.tintColor = Palette.inkPrimary

        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.backgroundColor = .clear
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "CityCell")
        view.addSubview(tableView)

        emptyLabel.text = String(localized: "cities.empty", defaultValue: "Tap + to add your first city")
        emptyLabel.font = Typography.body()
        emptyLabel.textColor = Palette.inkSecondary
        emptyLabel.textAlignment = .center
        emptyLabel.numberOfLines = 0
        emptyLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(emptyLabel)

        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            emptyLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            emptyLabel.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            emptyLabel.leadingAnchor.constraint(greaterThanOrEqualTo: view.leadingAnchor, constant: Spacing.l),
            emptyLabel.trailingAnchor.constraint(lessThanOrEqualTo: view.trailingAnchor, constant: -Spacing.l)
        ])

        observeState { [weak self] in self?.render() }
        store.send(.onAppear)
    }

    override func setEditing(_ editing: Bool, animated: Bool) {
        super.setEditing(editing, animated: animated)
        tableView.setEditing(editing, animated: animated)
    }

    private func render() {
        emptyLabel.isHidden = !store.cities.isEmpty
        tableView.reloadData()

        if store.isPresentingSearch, presentedViewController == nil {
            let searchVC = CitySearchViewController(
                store: store.scope(state: \.search, action: \.search)
            )
            let nav = UINavigationController(rootViewController: searchVC)
            present(nav, animated: true)
        } else if !store.isPresentingSearch, presentedViewController != nil {
            dismiss(animated: true)
        }
    }

    @objc private func handleAdd() {
        store.send(.addCityTapped)
    }
}

extension CityListViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        store.cities.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "CityCell", for: indexPath)
        let city = store.cities[indexPath.row]
        var content = cell.defaultContentConfiguration()
        content.text = city.name
        content.secondaryText = [city.region, city.country].compactMap { $0 }.joined(separator: ", ")
        content.textProperties.font = Typography.body()
        content.secondaryTextProperties.font = Typography.caption()
        cell.contentConfiguration = content
        cell.accessoryType = (city.id == store.selectedCityID) ? .checkmark : .none
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let city = store.cities[indexPath.row]
        store.send(.selectCity(city.id))
        tableView.deselectRow(at: indexPath, animated: true)
    }

    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        guard editingStyle == .delete else { return }
        let city = store.cities[indexPath.row]
        store.send(.deleteCity(city.id))
    }

    func tableView(_ tableView: UITableView, moveRowAt sourceIndexPath: IndexPath, to destinationIndexPath: IndexPath) {
        store.send(.moveCity(IndexSet(integer: sourceIndexPath.row), destinationIndexPath.row))
    }

    func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool { true }
}
