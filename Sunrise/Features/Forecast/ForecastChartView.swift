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

    private var fiveDay: [DailyForecast] { Array(snapshot.daily.prefix(5)) }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                fiveDayStrip
                section(title: String(localized: "forecast.temp_trend", defaultValue: "Temperature trend")) {
                    temperatureChart
                }
                section(title: String(localized: "forecast.precip", defaultValue: "Precipitation chance")) {
                    VStack(alignment: .leading, spacing: 8) {
                        precipitationChart
                        windRow
                    }
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
            ForEach(Array(fiveDay.enumerated()), id: \.element.id) { index, day in
                VStack(spacing: 6) {
                    Text(dayLabel(for: day, index: index))
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(Color(Palette.inkPrimary))
                    Text(dateFormatter.string(from: day.date))
                        .font(.caption2)
                        .foregroundStyle(Color(Palette.inkSecondary))
                    AnimatedWeatherIcon(conditionRawValue: day.condition.rawValue)
                        .frame(width: 44, height: 44)
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
        let unitSuffix = settings.temperatureUnit == .celsius ? "°C" : "°F"
        return Chart(fiveDay) { day in
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
            .symbol(.circle)
            .annotation(position: .top, alignment: .center, spacing: 2) {
                Text("\(Int(tempValue(day.highTemperature).rounded()))°")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(Color(Palette.blossomPink))
            }

            LineMark(
                x: .value("day", day.date),
                y: .value("low", tempValue(day.lowTemperature))
            )
            .foregroundStyle(Color(Palette.skyBlue))
            .interpolationMethod(.catmullRom)
            .symbol(.circle)
            .annotation(position: .bottom, alignment: .center, spacing: 2) {
                Text("\(Int(tempValue(day.lowTemperature).rounded()))°")
                    .font(.caption2)
                    .foregroundStyle(Color(Palette.skyBlue))
            }
        }
        .frame(height: 200)
        // X-axis: weekday tick per data point so the temperature strip and
        // the chart agree on the day labels. Y-axis: degrees with the unit
        // suffix on the leading edge so a reader can pin numbers without
        // counting from the strip above.
        .chartXAxis {
            AxisMarks(values: fiveDay.map(\.date)) { value in
                AxisGridLine()
                    .foregroundStyle(Color(Palette.inkSecondary).opacity(0.15))
                AxisValueLabel(format: .dateTime.weekday(.abbreviated))
                    .foregroundStyle(Color(Palette.inkSecondary))
            }
        }
        .chartYAxis {
            AxisMarks(position: .leading) { value in
                AxisGridLine()
                    .foregroundStyle(Color(Palette.inkSecondary).opacity(0.15))
                AxisValueLabel {
                    if let raw = value.as(Double.self) {
                        Text("\(Int(raw))\(unitSuffix)")
                            .font(.caption2)
                            .foregroundStyle(Color(Palette.inkSecondary))
                    }
                }
            }
        }
        .padding(.top, 14)
    }

    private var precipitationChart: some View {
        Chart(fiveDay) { day in
            BarMark(
                x: .value("day", day.date, unit: .day),
                y: .value("precip", day.precipitationChance.value * 100)
            )
            .foregroundStyle(Color(Palette.skyBlue))
            .cornerRadius(4)
            .annotation(position: .top, alignment: .center) {
                Text("\(Int((day.precipitationChance.value * 100).rounded()))%")
                    .font(.caption2)
                    .foregroundStyle(Color(Palette.inkSecondary))
            }
        }
        .frame(height: 140)
        .chartYAxis(.hidden)
        // Hide X axis here too — the wind row directly below carries the
        // per-day annotation, so duplicating weekday labels just adds noise.
        .chartXAxis(.hidden)
    }

    private var windRow: some View {
        HStack(spacing: 0) {
            ForEach(fiveDay) { day in
                VStack(spacing: 2) {
                    Text(windDirectionLabel(for: day.wind))
                        .font(.caption2)
                        .foregroundStyle(Color(Palette.inkSecondary))
                    Text(windLevelLabel(for: day.wind))
                        .font(.caption2)
                        .foregroundStyle(Color(Palette.inkSecondary))
                }
                .frame(maxWidth: .infinity)
            }
        }
    }

    private func windDirectionLabel(for wind: Wind) -> String {
        let bucket = Int(((wind.directionDegrees + 22.5).truncatingRemainder(dividingBy: 360)) / 45)
        switch bucket {
        case 0: return String(localized: "wind.dir.n", defaultValue: "N")
        case 1: return String(localized: "wind.dir.ne", defaultValue: "NE")
        case 2: return String(localized: "wind.dir.e", defaultValue: "E")
        case 3: return String(localized: "wind.dir.se", defaultValue: "SE")
        case 4: return String(localized: "wind.dir.s", defaultValue: "S")
        case 5: return String(localized: "wind.dir.sw", defaultValue: "SW")
        case 6: return String(localized: "wind.dir.w", defaultValue: "W")
        default: return String(localized: "wind.dir.nw", defaultValue: "NW")
        }
    }

    private func windLevelLabel(for wind: Wind) -> String {
        let level = max(0, min(12, Int((wind.speedKPH / 6).rounded())))
        return String.localizedStringWithFormat(
            String(localized: "wind.level", defaultValue: "Lv %d"),
            level
        )
    }

    private var dailyList: some View {
        VStack(alignment: .leading, spacing: 8) {
            ForEach(snapshot.daily) { day in
                HStack {
                    Text(dayFormatter.string(from: day.date))
                        .font(.body)
                        .foregroundStyle(Color(Palette.inkPrimary))
                        .frame(width: 56, alignment: .leading)
                    AnimatedWeatherIcon(conditionRawValue: day.condition.rawValue)
                        .frame(width: 32, height: 32)
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
