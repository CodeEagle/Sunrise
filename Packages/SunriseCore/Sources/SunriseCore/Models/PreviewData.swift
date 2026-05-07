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
        // Hand-pulled out of the .map closure — Swift 6's type checker can't
        // resolve the inline literal cases for `condition` plus all the
        // numeric coercions in time, so we lift each component to its own
        // local first.
        let conditions: [WeatherCondition] = [.clear, .cloudy, .rain, .thunderstorm, .snow, .windy]
        let daily: [DailyForecast] = (0..<15).map { offset in
            let date = calendar.date(byAdding: .day, value: offset, to: now) ?? now
            let highC: Double = 30 - Double(offset % 7)
            let lowC: Double = 22 - Double(offset % 5)
            let condition = conditions[offset % conditions.count]
            let precip = Percent(value: Double(offset % 5) / 10)
            let wind = Wind(speedKPH: 8 + Double(offset % 5), directionDegrees: 135)
            return DailyForecast(
                date: date,
                highTemperature: Temperature(celsius: highC),
                lowTemperature: Temperature(celsius: lowC),
                condition: condition,
                precipitationChance: precip,
                wind: wind
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
