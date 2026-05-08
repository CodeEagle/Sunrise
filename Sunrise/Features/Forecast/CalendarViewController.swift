import UIKit
import ComposableArchitecture
import ForecastFeature
import SunriseCore
import SunriseDesignSystem

/// Weather history — the past 14 days for the selected city, presented as
/// a list of cards with the day's condition icon + high/low. Tapping a
/// card surfaces the detail row at the top of the screen so the user can
/// scrub through days without leaving the screen.
///
/// WeatherKit only serves historical data for ~14 days. Days outside that
/// window (or entries that came back empty) simply don't appear.
final class CalendarViewController: UIViewController {
    private let store: StoreOf<CalendarReducer>
    private let tableView = UITableView(frame: .zero, style: .insetGrouped)
    private let detailCard = DetailCard()
    private let emptyLabel = UILabel()
    private let activity = UIActivityIndicatorView(style: .medium)

    private let weekdayFormatter: DateFormatter = {
        let df = DateFormatter()
        df.dateFormat = "EEEE"
        return df
    }()

    private let dateFormatter: DateFormatter = {
        let df = DateFormatter()
        df.dateStyle = .medium
        df.timeStyle = .none
        return df
    }()

    init(store: StoreOf<CalendarReducer>) {
        self.store = store
        super.init(nibName: nil, bundle: nil)
        hidesBottomBarWhenPushed = true
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError() }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = Palette.canvas
        navigationItem.title = "calendar.title".l10n("Weather History")

        configureLayout()
        observeState { [weak self] in self?.render() }
        onLanguageChange { [weak self] in
            self?.navigationItem.title = "calendar.title".l10n("Weather History")
            self?.tableView.reloadData()
            self?.render()
        }
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        // Defer the historical fetch until the push transition completes —
        // WeatherKit calls can take a beat and we don't want them blocking
        // the slide-in animation.
        store.send(.onAppear)
    }

    private func configureLayout() {
        detailCard.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(detailCard)

        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.backgroundColor = .clear
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(DayCell.self, forCellReuseIdentifier: DayCell.reuseID)
        view.addSubview(tableView)

        emptyLabel.font = Typography.body()
        emptyLabel.textColor = Palette.inkSecondary
        emptyLabel.textAlignment = .center
        emptyLabel.numberOfLines = 0
        emptyLabel.translatesAutoresizingMaskIntoConstraints = false
        emptyLabel.isHidden = true
        view.addSubview(emptyLabel)

        activity.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(activity)

        NSLayoutConstraint.activate([
            detailCard.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: Spacing.s),
            detailCard.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: Spacing.m),
            detailCard.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -Spacing.m),

            tableView.topAnchor.constraint(equalTo: detailCard.bottomAnchor, constant: Spacing.s),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            emptyLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            emptyLabel.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            emptyLabel.leadingAnchor.constraint(greaterThanOrEqualTo: view.leadingAnchor, constant: Spacing.l),
            emptyLabel.trailingAnchor.constraint(lessThanOrEqualTo: view.trailingAnchor, constant: -Spacing.l),

            activity.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            activity.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
    }

    private func render() {
        if store.isLoading {
            activity.startAnimating()
            emptyLabel.isHidden = true
        } else {
            activity.stopAnimating()
        }

        if store.dailies.isEmpty, !store.isLoading {
            emptyLabel.text = store.error
                ?? "calendar.empty".l10n("No history yet. WeatherKit serves the last 14 days only.")
            emptyLabel.isHidden = false
        } else {
            emptyLabel.isHidden = true
        }

        let selected = store.selectedDate.flatMap { date in
            store.dailies.first { Calendar.current.isDate($0.date, inSameDayAs: date) }
        } ?? store.dailies.first
        detailCard.update(daily: selected,
                          dayLabel: selected.map { weekdayFormatter.string(from: $0.date) },
                          dateLabel: selected.map { dateFormatter.string(from: $0.date) },
                          settings: store.settings)
        detailCard.isHidden = (selected == nil)

        tableView.reloadData()
    }
}

extension CalendarViewController: UITableViewDataSource, UITableViewDelegate {
    func numberOfSections(in tableView: UITableView) -> Int { 1 }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        store.dailies.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: DayCell.reuseID, for: indexPath) as! DayCell
        let day = store.dailies[indexPath.row]
        cell.configure(day: day,
                       weekday: weekdayFormatter.string(from: day.date),
                       date: dateFormatter.string(from: day.date),
                       settings: store.settings,
                       isSelected: store.selectedDate.map {
                           Calendar.current.isDate($0, inSameDayAs: day.date)
                       } ?? false)
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let day = store.dailies[indexPath.row]
        store.send(.selectDate(day.date))
    }
}

private final class DayCell: UITableViewCell {
    static let reuseID = "DayCell"

    private let dayLabel = UILabel()
    private let dateLabel = UILabel()
    private let iconView = UIImageView()
    private let highLowLabel = UILabel()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        backgroundColor = Palette.surface

        dayLabel.font = Typography.body(15)
        dayLabel.textColor = Palette.inkPrimary

        dateLabel.font = Typography.caption(12)
        dateLabel.textColor = Palette.inkSecondary

        iconView.contentMode = .scaleAspectFit
        iconView.translatesAutoresizingMaskIntoConstraints = false
        iconView.widthAnchor.constraint(equalToConstant: 32).isActive = true
        iconView.heightAnchor.constraint(equalToConstant: 32).isActive = true

        highLowLabel.font = Typography.body(15)
        highLowLabel.textColor = Palette.inkPrimary
        highLowLabel.textAlignment = .right

        let textStack = UIStackView(arrangedSubviews: [dayLabel, dateLabel])
        textStack.axis = .vertical
        textStack.spacing = 2
        textStack.alignment = .leading

        let row = UIStackView(arrangedSubviews: [textStack, UIView(), iconView, highLowLabel])
        row.axis = .horizontal
        row.alignment = .center
        row.spacing = Spacing.s
        row.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(row)

        NSLayoutConstraint.activate([
            row.topAnchor.constraint(equalTo: contentView.topAnchor, constant: Spacing.s),
            row.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -Spacing.s),
            row.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: Spacing.m),
            row.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -Spacing.m)
        ])
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError() }

    func configure(day: DailyForecast, weekday: String, date: String, settings: UserSettings, isSelected: Bool) {
        dayLabel.text = weekday
        dateLabel.text = date
        let formatter = WeatherFormatter(settings: settings)
        highLowLabel.text = "\(formatter.temperature(day.lowTemperature))° / \(formatter.temperature(day.highTemperature))°"
        if let icon = WeatherIconArt.image(forConditionRawValue: day.condition.rawValue) {
            iconView.image = icon
            iconView.tintColor = nil
        } else {
            iconView.image = UIImage(systemName: ConditionGlyph.symbolName(forConditionRawValue: day.condition.rawValue))
            iconView.tintColor = ConditionGlyph.tint(forConditionRawValue: day.condition.rawValue)
        }
        accessoryType = isSelected ? .checkmark : .none
    }
}

/// Top-of-screen detail card showing the selected day's full breakdown.
/// Lives outside the table so the user always sees the focused day even
/// while scrolling the rest of the history.
private final class DetailCard: UIView {
    private let glass = GlassPanel(style: .regular, cornerRadius: Radius.medium)
    private let dayLabel = UILabel()
    private let dateLabel = UILabel()
    private let iconView = UIImageView()
    private let highLabel = UILabel()
    private let lowLabel = UILabel()
    private let conditionLabel = UILabel()
    private let detailRowLabel = UILabel()

    init() {
        super.init(frame: .zero)
        configureLayout()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError() }

    private func configureLayout() {
        glass.translatesAutoresizingMaskIntoConstraints = false
        glass.isUserInteractionEnabled = false
        addSubview(glass)

        dayLabel.font = Typography.title(20)
        dayLabel.textColor = Palette.inkPrimary

        dateLabel.font = Typography.caption(13)
        dateLabel.textColor = Palette.inkSecondary

        iconView.contentMode = .scaleAspectFit
        iconView.translatesAutoresizingMaskIntoConstraints = false
        iconView.widthAnchor.constraint(equalToConstant: 56).isActive = true
        iconView.heightAnchor.constraint(equalToConstant: 56).isActive = true

        highLabel.font = Typography.numeric(28)
        highLabel.textColor = Palette.blossomPink

        lowLabel.font = Typography.numeric(20)
        lowLabel.textColor = Palette.skyBlue

        conditionLabel.font = Typography.body(15)
        conditionLabel.textColor = Palette.inkPrimary

        detailRowLabel.font = Typography.caption(12)
        detailRowLabel.textColor = Palette.inkSecondary
        detailRowLabel.numberOfLines = 0

        let titleStack = UIStackView(arrangedSubviews: [dayLabel, dateLabel])
        titleStack.axis = .vertical
        titleStack.spacing = 2
        titleStack.alignment = .leading

        let tempStack = UIStackView(arrangedSubviews: [highLabel, lowLabel])
        tempStack.axis = .horizontal
        tempStack.alignment = .lastBaseline
        tempStack.spacing = Spacing.s

        let topRow = UIStackView(arrangedSubviews: [titleStack, UIView(), iconView])
        topRow.axis = .horizontal
        topRow.alignment = .center
        topRow.spacing = Spacing.s

        let stack = UIStackView(arrangedSubviews: [topRow, tempStack, conditionLabel, detailRowLabel])
        stack.axis = .vertical
        stack.alignment = .leading
        stack.spacing = Spacing.xs
        stack.translatesAutoresizingMaskIntoConstraints = false
        addSubview(stack)

        NSLayoutConstraint.activate([
            glass.topAnchor.constraint(equalTo: topAnchor),
            glass.bottomAnchor.constraint(equalTo: bottomAnchor),
            glass.leadingAnchor.constraint(equalTo: leadingAnchor),
            glass.trailingAnchor.constraint(equalTo: trailingAnchor),

            stack.topAnchor.constraint(equalTo: topAnchor, constant: Spacing.m),
            stack.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -Spacing.m),
            stack.leadingAnchor.constraint(equalTo: leadingAnchor, constant: Spacing.m),
            stack.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -Spacing.m),
            topRow.widthAnchor.constraint(equalTo: stack.widthAnchor)
        ])
    }

    func update(daily: DailyForecast?, dayLabel: String?, dateLabel: String?, settings: UserSettings) {
        guard let daily else { return }
        self.dayLabel.text = dayLabel
        self.dateLabel.text = dateLabel
        let formatter = WeatherFormatter(settings: settings)
        highLabel.text = "\(formatter.temperature(daily.highTemperature))°"
        lowLabel.text = "\(formatter.temperature(daily.lowTemperature))°"
        conditionLabel.text = localizedCondition(daily.condition)
        let precip = String.localizedStringWithFormat(
            "calendar.precipitation".l10n("Precipitation %@"),
            formatter.percent(daily.precipitationChance)
        )
        let wind = String.localizedStringWithFormat(
            "today.wind_inline".l10n("Wind %@"),
            formatter.windSpeed(daily.wind)
        )
        detailRowLabel.text = [precip, wind].joined(separator: "  ·  ")
        if let icon = WeatherIconArt.image(forConditionRawValue: daily.condition.rawValue) {
            iconView.image = icon
            iconView.tintColor = nil
        } else {
            iconView.image = UIImage(systemName: ConditionGlyph.symbolName(forConditionRawValue: daily.condition.rawValue))
            iconView.tintColor = ConditionGlyph.tint(forConditionRawValue: daily.condition.rawValue)
        }
    }

    private func localizedCondition(_ condition: WeatherCondition) -> String {
        switch condition {
        case .clear: return "condition.clear".l10n("Clear")
        case .cloudy: return "condition.cloudy".l10n("Cloudy")
        case .rain: return "condition.rain".l10n("Rain")
        case .thunderstorm: return "condition.thunderstorm".l10n("Thunderstorms")
        case .snow: return "condition.snow".l10n("Snow")
        case .windy: return "condition.windy".l10n("Windy")
        case .fog: return "condition.fog".l10n("Foggy")
        }
    }
}
