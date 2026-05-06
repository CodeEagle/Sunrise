import Foundation

public struct WeatherSnapshot: Codable, Hashable, Sendable {
    public let updatedAt: Date
    public let current: CurrentWeather
    public let hourly: [HourlyForecast]
    public let daily: [DailyForecast]

    public init(
        updatedAt: Date,
        current: CurrentWeather,
        hourly: [HourlyForecast],
        daily: [DailyForecast]
    ) {
        self.updatedAt = updatedAt
        self.current = current
        self.hourly = hourly
        self.daily = daily
    }
}

public struct CurrentWeather: Codable, Hashable, Sendable {
    public let temperature: Temperature
    public let apparentTemperature: Temperature
    public let condition: WeatherCondition
    public let humidity: Percent
    public let wind: Wind
    public let uvIndex: Int
    public let dayPeriod: DayPeriod

    public init(
        temperature: Temperature,
        apparentTemperature: Temperature,
        condition: WeatherCondition,
        humidity: Percent,
        wind: Wind,
        uvIndex: Int,
        dayPeriod: DayPeriod
    ) {
        self.temperature = temperature
        self.apparentTemperature = apparentTemperature
        self.condition = condition
        self.humidity = humidity
        self.wind = wind
        self.uvIndex = uvIndex
        self.dayPeriod = dayPeriod
    }
}

public struct HourlyForecast: Codable, Hashable, Sendable, Identifiable {
    public var id: Date { date }
    public let date: Date
    public let temperature: Temperature
    public let condition: WeatherCondition
    public let precipitationChance: Percent

    public init(date: Date, temperature: Temperature, condition: WeatherCondition, precipitationChance: Percent) {
        self.date = date
        self.temperature = temperature
        self.condition = condition
        self.precipitationChance = precipitationChance
    }
}

public struct DailyForecast: Codable, Hashable, Sendable, Identifiable {
    public var id: Date { date }
    public let date: Date
    public let highTemperature: Temperature
    public let lowTemperature: Temperature
    public let condition: WeatherCondition
    public let precipitationChance: Percent
    public let wind: Wind

    public init(
        date: Date,
        highTemperature: Temperature,
        lowTemperature: Temperature,
        condition: WeatherCondition,
        precipitationChance: Percent,
        wind: Wind
    ) {
        self.date = date
        self.highTemperature = highTemperature
        self.lowTemperature = lowTemperature
        self.condition = condition
        self.precipitationChance = precipitationChance
        self.wind = wind
    }
}
