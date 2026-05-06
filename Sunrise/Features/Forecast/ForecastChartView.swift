import SwiftUI
import Charts
import SunriseCore
import SunriseDesignSystem

struct ForecastChartView: View {
    let snapshot: WeatherSnapshot
    let settings: UserSettings

    private var formatter: WeatherFormatter { WeatherFormatter(settings: settings) }
    private var calendar: Calendar { .current }

    private let dayFormatter: DateFormatter = {
        let df = DateFormatter()
        df.dateFormat = "EEE"
        return df
    }()

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                temperatureChart
                precipitationChart
                dailyList
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 24)
        }
        .background(Color(Palette.canvas))
    }

    private var temperatureChart: some View {
        Section {
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
                AxisMarks(values: .stride(by: .day, count: 2)) { value in
                    AxisGridLine()
                    AxisValueLabel(format: .dateTime.weekday(.abbreviated))
                }
            }
        } header: {
            Text(String(localized: "forecast.temp_trend", defaultValue: "Temperature trend"))
                .font(.headline)
                .foregroundStyle(Color(Palette.inkPrimary))
        }
    }

    private var precipitationChart: some View {
        Section {
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
                AxisMarks(values: [0, 50, 100]) {
                    AxisGridLine()
                    AxisValueLabel(format: .percent.scale(0.01))
                }
            }
            .chartXAxis {
                AxisMarks(values: .stride(by: .day, count: 2)) { _ in
                    AxisGridLine()
                    AxisValueLabel(format: .dateTime.weekday(.abbreviated))
                }
            }
        } header: {
            Text(String(localized: "forecast.precip", defaultValue: "Precipitation chance"))
                .font(.headline)
                .foregroundStyle(Color(Palette.inkPrimary))
        }
    }

    private var dailyList: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(String(localized: "forecast.daily", defaultValue: "Daily details"))
                .font(.headline)
                .foregroundStyle(Color(Palette.inkPrimary))
            ForEach(snapshot.daily) { day in
                HStack {
                    Text(dayFormatter.string(from: day.date))
                        .font(.body)
                        .foregroundStyle(Color(Palette.inkPrimary))
                        .frame(width: 56, alignment: .leading)
                    Image(systemName: ConditionGlyph.symbolName(forConditionRawValue: day.condition.rawValue))
                        .foregroundStyle(Color(ConditionGlyph.tint(forConditionRawValue: day.condition.rawValue)))
                        .frame(width: 28)
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
                .background(Color(Palette.cloudWhite).opacity(0.8))
                .clipShape(RoundedRectangle(cornerRadius: 12))
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
