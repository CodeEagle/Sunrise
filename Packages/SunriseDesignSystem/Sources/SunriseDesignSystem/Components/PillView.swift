#if canImport(UIKit)
import UIKit

public final class PillView: UIView {
    private let titleLabel = UILabel()
    private let valueLabel = UILabel()

    public init() {
        super.init(frame: .zero)
        configure()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError() }

    public func setContent(title: String, value: String) {
        titleLabel.text = title
        valueLabel.text = value
    }

    private func configure() {
        backgroundColor = Palette.surface.withAlphaComponent(Opacity.glass)
        layer.cornerRadius = Radius.small
        layer.cornerCurve = .continuous

        titleLabel.font = Typography.caption(12)
        titleLabel.textColor = Palette.inkSecondary

        valueLabel.font = Typography.body(15)
        valueLabel.textColor = Palette.inkPrimary

        let stack = UIStackView(arrangedSubviews: [titleLabel, valueLabel])
        stack.axis = .vertical
        stack.spacing = 2
        stack.translatesAutoresizingMaskIntoConstraints = false
        addSubview(stack)
        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: topAnchor, constant: Spacing.xs),
            stack.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -Spacing.xs),
            stack.leadingAnchor.constraint(equalTo: leadingAnchor, constant: Spacing.s),
            stack.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -Spacing.s)
        ])
    }
}
#endif
