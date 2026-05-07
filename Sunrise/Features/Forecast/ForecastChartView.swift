import SwiftUI
import Charts
import SunriseCore
import SunriseDesignSystem

struct ForecastChartView: View {
    let snapshot: WeatherSnapshot
    let settings: UserSettings

    private var formatter: WeatherFormatter { WeatherFormatter(settings: settings) }

    private let dayFormatter: DateFormatter = {
        let df = DateFormatter()
        df.dateFormat = "EEE"
        return df
    }()

    private let dateFormatter: DateFormatter = {
        let df = DateFormatter()
        df.dateFormat = "MM/dd"
        return df
    }()

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                fiveDayStrip
                section(title: String(localized: "forecast.temp_trend", defaultValue: "Temperature trend")) {
                    temperatureChart
                }
                section(title: String(localized: "forecast.precip", defaultValue: "Precipitation chance")) {
                    precipitationChart
                }
                section(title: String(localized: "forecast.daily", defaultValue: "Daily details")) {
                    dailyList
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 24)
        }
        .background(Color(Palette.canvas))
    }

    private var fiveDayStrip: some View {
        HStack(alignment: .top, spacing: 4) {
            ForEach(Array(snapshot.daily.prefix(5).enumerated()), id: \.element.id) { index, day in
                VStack(spacing: 6) {
                    Text(dayLabel(for: day, index: index))
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(Color(Palette.inkPrimary))
                    Text(dateFormatter.string(from: day.date))
                        .font(.caption2)
                        .foregroundStyle(Color(Palette.inkSecondary))
                    Group {
                        if let watercolor = WeatherIconArt.image(forConditionRawValue: day.condition.rawValue) {
                            Image(uiImage: watercolor).resizable().scaledToFit()
                        } else {
                            Image(systemName: ConditionGlyph.symbolName(forConditionRawValue: day.condition.rawValue))
                                .resizable()
                                .scaledToFit()
                                .foregroundStyle(Color(ConditionGlyph.tint(forConditionRawValue: day.condition.rawValue)))
                        }
                    }
                    .frame(height: 36)
                    Text(formatter.temperature(day.highTemperature) + "°")
                        .font(.body.weight(.semibold))
                        .foregroundStyle(Color(Palette.blossomPink))
                    Text(formatter.temperature(day.lowTemperature) + "°")
                        .font(.body)
                        .foregroundStyle(Color(Palette.skyBlue))
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 14))
            }
        }
    }

    private func dayLabel(for day: DailyForecast, index: Int) -> String {
        switch index {
        case 0: return String(localized: "forecast.day.today", defaultValue: "Today")
        case 1: return String(localized: "forecast.day.tomorrow", defaultValue: "Tomorrow")
        default: return dayFormatter.string(from: day.date)
        }
    }

    @ViewBuilder
    private func section<Content: View>(title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.headline)
                .foregroundStyle(Color(Palette.inkPrimary))
            content()
        }
    }

    private var temperatureChart: some View {
        Chart(snapshot.daily) { day in
            AreaMark(
                x: .value("day", day.date),
                yStart: .value("low", tempValue(day.lowTemperature)),
                yEnd: .value("high", tempValue(day.highTemperature))
            )
            .foregroundStyle(
                LinearGradient(
                    colors: [Color(Palette.sunYellow).opacity(0.6), Color(Palette.skyBlue).opacity(0.4)],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .interpolationMethod(.catmullRom)

            LineMark(
                x: .value("day", day.date),
                y: .value("high", tempValue(day.highTemperature))
            )
            .foregroundStyle(Color(Palette.blossomPink))
            .interpolationMethod(.catmullRom)

            LineMark(
                x: .value("day", day.date),
                y: .value("low", tempValue(day.lowTemperature))
            )
            .foregroundStyle(Color(Palette.skyBlue))
            .interpolationMethod(.catmullRom)
        }
        .frame(height: 200)
        .chartXAxis {
            AxisMarks(values: .stride(by: .day, count: 2)) { _ in
                AxisGridLine()
                AxisValueLabel(format: .dateTime.weekday(.abbreviated))
            }
        }
    }

    private var precipitationChart: some View {
        Chart(snapshot.daily) { day in
            BarMark(
                x: .value("day", day.date, unit: .day),
                y: .value("precip", day.precipitationChance.value * 100)
            )
            .foregroundStyle(Color(Palette.skyBlue))
            .cornerRadius(4)
        }
        .frame(height: 140)
        .chartYAxis {
            AxisMarks(values: [0, 50, 100]) { value in
                AxisGridLine()
                AxisValueLabel {
                    if let v = value.as(Int.self) {
                        Text("\(v)%")
                    }
                }
            }
        }
        .chartXAxis {
            AxisMarks(values: .stride(by: .day, count: 2)) { _ in
                AxisGridLine()
                AxisValueLabel(format: .dateTime.weekday(.abbreviated))
            }
        }
    }

    private var dailyList: some View {
        VStack(alignment: .leading, spacing: 8) {
            ForEach(snapshot.daily) { day in
                HStack {
                    Text(dayFormatter.string(from: day.date))
                        .font(.body)
                        .foregroundStyle(Color(Palette.inkPrimary))
                        .frame(width: 56, alignment: .leading)
                    Group {
                        if let watercolor = WeatherIconArt.image(forConditionRawValue: day.condition.rawValue) {
                            Image(uiImage: watercolor).resizable().scaledToFit()
                        } else {
                            Image(systemName: ConditionGlyph.symbolName(forConditionRawValue: day.condition.rawValue))
                                .foregroundStyle(Color(ConditionGlyph.tint(forConditionRawValue: day.condition.rawValue)))
                        }
                    }
                    .frame(width: 28, height: 28)
                    Text(formatter.percent(day.precipitationChance))
                        .font(.caption)
                        .foregroundStyle(Color(Palette.skyBlue))
                        .frame(width: 44, alignment: .leading)
                    Spacer()
                    Text(formatter.temperature(day.lowTemperature) + "° / " + formatter.temperature(day.highTemperature) + "°")
                        .font(.body)
                        .foregroundStyle(Color(Palette.inkPrimary))
                }
                .padding(.vertical, 6)
                .padding(.horizontal, 12)
                .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 12))
            }
        }
    }

    private func tempValue(_ temperature: Temperature) -> Double {
        switch settings.temperatureUnit {
        case .celsius: return temperature.celsius
        case .fahrenheit: return temperature.fahrenheit
        }
    }
}
