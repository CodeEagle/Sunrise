import Foundation

public extension City {
    static let preview = City(
        name: "Shanghai",
        region: "Shanghai",
        country: "China",
        latitude: 31.2304,
        longitude: 121.4737,
        timeZoneIdentifier: "Asia/Shanghai"
    )
}

public extension WeatherSnapshot {
    static let preview: WeatherSnapshot = {
        let now = Date()
        let calendar = Calendar(identifier: .gregorian)
        let hourly: [HourlyForecast] = (0..<24).map { offset in
            HourlyForecast(
                date: calendar.date(byAdding: .hour, value: offset, to: now) ?? now,
                temperature: Temperature(celsius: 28 - Double(offset % 6)),
                condition: offset.isMultiple(of: 5) ? .cloudy : .clear,
                precipitationChance: Percent(value: Double(offset % 4) / 10)
            )
        }
        // Smooth-ish 15-day mock so the trend chart reads as a clean curve
        // instead of a saw-tooth. First 5 days sit close to the reference
        // values shown in the design board (今天/明天/周三/周四/周五).
        let highCs: [Double] = [30, 28, 26, 23, 25, 26, 27, 28, 27, 26, 24, 23, 22, 24, 25]
        let lowCs:  [Double] = [24, 23, 21, 20, 20, 19, 19, 20, 20, 19, 18, 17, 17, 18, 19]
        let precips: [Double] = [0.10, 0.20, 0.60, 0.30, 0.10, 0.15, 0.20, 0.25, 0.20, 0.15, 0.05, 0.05, 0.10, 0.15, 0.20]
        let conditions: [WeatherCondition] = [
            .clear, .cloudy, .rain, .thunderstorm, .clear,
            .clear, .cloudy, .cloudy, .rain, .clear,
            .clear, .clear, .cloudy, .windy, .clear
        ]
        let windDirections: [Int] = [135, 90, 45, 0, 135, 135, 90, 45, 0, 135, 135, 90, 45, 0, 135]
        let windLevels:     [Double] = [2, 2, 3, 2, 2, 2, 2, 3, 2, 2, 2, 2, 3, 4, 2]
        let daily: [DailyForecast] = (0..<15).map { offset in
            let date = calendar.date(byAdding: .day, value: offset, to: now) ?? now
            return DailyForecast(
                date: date,
                highTemperature: Temperature(celsius: highCs[offset]),
                lowTemperature: Temperature(celsius: lowCs[offset]),
                condition: conditions[offset],
                precipitationChance: Percent(value: precips[offset]),
                wind: Wind(speedKPH: windLevels[offset] * 6, directionDegrees: Double(windDirections[offset]))
            )
        }
        return WeatherSnapshot(
            updatedAt: now,
            current: CurrentWeather(
                temperature: Temperature(celsius: 28),
                apparentTemperature: Temperature(celsius: 30),
                condition: .clear,
                humidity: Percent(value: 0.45),
                wind: Wind(speedKPH: 8, directionDegrees: 135),
                uvIndex: 5,
                dayPeriod: .day
            ),
            hourly: hourly,
            daily: daily
        )
    }()
}
