import UIKit
import ComposableArchitecture
import CityFeature
import SunriseCore
import SunriseDesignSystem

final class CitySearchViewController: UIViewController {
    private let store: StoreOf<CitySearchReducer>
    private let searchBar = UISearchBar()
    private let tableView = UITableView()
    private let activityIndicator = UIActivityIndicatorView(style: .medium)
    private let errorLabel = UILabel()

    init(store: StoreOf<CitySearchReducer>) {
        self.store = store
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError() }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = String(localized: "search.title", defaultValue: "Add City")
        view.backgroundColor = Palette.canvas
        navigationItem.leftBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .cancel,
            target: self,
            action: #selector(handleCancel)
        )

        searchBar.placeholder = String(localized: "search.placeholder", defaultValue: "Search city")
        searchBar.delegate = self
        searchBar.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(searchBar)

        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.dataSource = self
        tableView.delegate = self
        tableView.keyboardDismissMode = .onDrag
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "ResultCell")
        view.addSubview(tableView)

        errorLabel.font = Typography.caption()
        errorLabel.textColor = Palette.blossomPink
        errorLabel.numberOfLines = 0
        errorLabel.textAlignment = .center
        errorLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(errorLabel)

        activityIndicator.hidesWhenStopped = true
        activityIndicator.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(activityIndicator)

        NSLayoutConstraint.activate([
            searchBar.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            searchBar.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            searchBar.trailingAnchor.constraint(equalTo: view.trailingAnchor),

            tableView.topAnchor.constraint(equalTo: searchBar.bottomAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            errorLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            errorLabel.centerYAnchor.constraint(equalTo: view.centerYAnchor),

            activityIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            activityIndicator.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])

        observeState { [weak self] in self?.render() }
        searchBar.becomeFirstResponder()
    }

    private func render() {
        if store.isResolving {
            activityIndicator.startAnimating()
        } else {
            activityIndicator.stopAnimating()
        }
        errorLabel.text = store.error
        errorLabel.isHidden = store.error == nil || !store.results.isEmpty
        tableView.reloadData()
    }

    @objc private func handleCancel() {
        dismiss(animated: true)
    }
}

extension CitySearchViewController: UISearchBarDelegate {
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        store.send(.queryChanged(searchText))
    }
}

extension CitySearchViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        store.results.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "ResultCell", for: indexPath)
        let result = store.results[indexPath.row]
        var content = cell.defaultContentConfiguration()
        content.text = result.title
        content.secondaryText = result.subtitle
        cell.contentConfiguration = content
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let result = store.results[indexPath.row]
        store.send(.selectResult(result))
        tableView.deselectRow(at: indexPath, animated: true)
    }
}
