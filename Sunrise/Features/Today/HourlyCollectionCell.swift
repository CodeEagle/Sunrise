import UIKit
import SunriseCore
import SunriseDesignSystem

final class HourlyCollectionCell: UICollectionViewCell {
    static let reuseID = "HourlyCollectionCell"

    private let timeLabel = UILabel()
    private let iconView = UIImageView()
    private let tempLabel = UILabel()

    override init(frame: CGRect) {
        super.init(frame: frame)
        configure()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError() }

    func configure(with hourly: HourlyForecast, formatter: WeatherFormatter, calendar: Calendar) {
        let df = DateFormatter()
        df.locale = formatter.locale
        df.dateFormat = "HH"
        timeLabel.text = df.string(from: hourly.date)

        if let watercolor = WeatherIconArt.image(forConditionRawValue: hourly.condition.rawValue) {
            iconView.image = watercolor
            iconView.tintColor = nil
        } else {
            let symbolName = ConditionGlyph.symbolName(forConditionRawValue: hourly.condition.rawValue)
            let config = UIImage.SymbolConfiguration(pointSize: 22, weight: .medium)
            iconView.image = UIImage(systemName: symbolName, withConfiguration: config)
            iconView.tintColor = ConditionGlyph.tint(forConditionRawValue: hourly.condition.rawValue)
        }
        tempLabel.text = formatter.temperature(hourly.temperature) + "°"
    }

    private func configure() {
        contentView.backgroundColor = Palette.cloudWhite.withAlphaComponent(0.7)
        contentView.layer.cornerRadius = Radius.medium
        contentView.layer.cornerCurve = .continuous

        timeLabel.font = Typography.caption(12)
        timeLabel.textColor = Palette.inkSecondary
        timeLabel.textAlignment = .center

        iconView.contentMode = .scaleAspectFit

        tempLabel.font = Typography.body(15)
        tempLabel.textColor = Palette.inkPrimary
        tempLabel.textAlignment = .center

        let stack = UIStackView(arrangedSubviews: [timeLabel, iconView, tempLabel])
        stack.axis = .vertical
        stack.spacing = Spacing.xs
        stack.alignment = .center
        stack.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(stack)
        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: contentView.topAnchor, constant: Spacing.s),
            stack.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -Spacing.s),
            stack.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: Spacing.xs),
            stack.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -Spacing.xs),
            iconView.heightAnchor.constraint(equalToConstant: 26)
        ])
    }
}
