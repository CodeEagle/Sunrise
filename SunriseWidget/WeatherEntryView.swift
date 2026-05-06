import SwiftUI
import WidgetKit
import SunriseCore
import SunriseDesignSystem

struct WeatherEntryView: View {
    let entry: WeatherEntry

    @Environment(\.widgetFamily) private var family

    var body: some View {
        switch family {
        case .systemMedium: mediumView
        default: smallView
        }
    }

    private var smallView: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(entry.cityName)
                .font(.caption)
                .foregroundStyle(Color(Palette.inkSecondary))
            Spacer(minLength: 0)
            HStack(alignment: .lastTextBaseline, spacing: 2) {
                Text(temperatureText)
                    .font(.system(size: 36, weight: .bold, design: .rounded))
                Text("°")
                    .font(.system(size: 22, weight: .regular, design: .rounded))
            }
            .foregroundStyle(Color(Palette.inkPrimary))
            HStack(spacing: 4) {
                Image(systemName: ConditionGlyph.symbolName(forConditionRawValue: entry.snapshot.current.condition.rawValue))
                    .foregroundStyle(Color(ConditionGlyph.tint(forConditionRawValue: entry.snapshot.current.condition.rawValue)))
                Text(entry.snapshot.current.condition.rawValue.capitalized)
                    .font(.caption)
                    .foregroundStyle(Color(Palette.inkSecondary))
            }
        }
    }

    private var mediumView: some View {
        HStack(alignment: .top) {
            smallView
            Spacer()
            VStack(alignment: .trailing, spacing: 6) {
                ForEach(entry.snapshot.hourly.prefix(4)) { hour in
                    HStack(spacing: 6) {
                        Text(hourFormatter.string(from: hour.date))
                            .font(.caption2)
                            .foregroundStyle(Color(Palette.inkSecondary))
                        Image(systemName: ConditionGlyph.symbolName(forConditionRawValue: hour.condition.rawValue))
                            .foregroundStyle(Color(ConditionGlyph.tint(forConditionRawValue: hour.condition.rawValue)))
                            .font(.caption)
                        Text("\(Int(hour.temperature.celsius.rounded()))°")
                            .font(.caption)
                            .foregroundStyle(Color(Palette.inkPrimary))
                    }
                }
            }
        }
    }

    private var temperatureText: String {
        "\(Int(entry.snapshot.current.temperature.celsius.rounded()))"
    }

    private let hourFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "HH"
        return f
    }()
}
