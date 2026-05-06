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
        let daily: [DailyForecast] = (0..<15).map { offset in
            DailyForecast(
                date: calendar.date(byAdding: .day, value: offset, to: now) ?? now,
                highTemperature: Temperature(celsius: 30 - Double(offset % 7)),
                lowTemperature: Temperature(celsius: 22 - Double(offset % 5)),
                condition: [.clear, .cloudy, .rain, .thunderstorm, .snow, .windy][offset % 6],
                precipitationChance: Percent(value: Double(offset % 5) / 10),
                wind: Wind(speedKPH: 8 + Double(offset % 5), directionDegrees: 135)
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
