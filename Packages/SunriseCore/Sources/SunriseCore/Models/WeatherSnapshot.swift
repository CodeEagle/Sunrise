import Foundation

public struct WeatherSnapshot: Codable, Hashable, Sendable {
    public let updatedAt: Date
    public let current: CurrentWeather
    public let hourly: [HourlyForecast]
    public let daily: [DailyForecast]
    /// Active severe-weather alerts (storm warnings, heat advisories,
    /// flash-flood watches…) issued by the regional forecaster. Empty
    /// when WeatherKit has nothing for the location.
    public let alerts: [WeatherAlert]
    /// Minute-by-minute precipitation intensity for the next ~60
    /// minutes, when WeatherKit can produce it (region-dependent).
    /// Drives the "rain starts in 12 minutes" pill on the Today tab.
    public let minute: [MinuteForecast]?

    public init(
        updatedAt: Date,
        current: CurrentWeather,
        hourly: [HourlyForecast],
        daily: [DailyForecast],
        alerts: [WeatherAlert] = [],
        minute: [MinuteForecast]? = nil
    ) {
        self.updatedAt = updatedAt
        self.current = current
        self.hourly = hourly
        self.daily = daily
        self.alerts = alerts
        self.minute = minute
    }

    private enum CodingKeys: String, CodingKey {
        case updatedAt, current, hourly, daily, alerts, minute
    }

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        self.updatedAt = try c.decode(Date.self, forKey: .updatedAt)
        self.current = try c.decode(CurrentWeather.self, forKey: .current)
        self.hourly = try c.decode([HourlyForecast].self, forKey: .hourly)
        self.daily = try c.decode([DailyForecast].self, forKey: .daily)
        self.alerts = (try? c.decodeIfPresent([WeatherAlert].self, forKey: .alerts)) ?? []
        self.minute = try? c.decodeIfPresent([MinuteForecast].self, forKey: .minute)
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
    /// Optional, populated from WeatherKit when available. Older
    /// cached snapshots (decoded from previous schema) leave these
    /// nil; UI should hide rows where everything is nil.
    public let dewPoint: Temperature?
    public let pressure: Pressure?
    public let pressureTrend: PressureTrend?
    public let cloudCover: Percent?
    public let visibilityKilometers: Double?

    public init(
        temperature: Temperature,
        apparentTemperature: Temperature,
        condition: WeatherCondition,
        humidity: Percent,
        wind: Wind,
        uvIndex: Int,
        dayPeriod: DayPeriod,
        dewPoint: Temperature? = nil,
        pressure: Pressure? = nil,
        pressureTrend: PressureTrend? = nil,
        cloudCover: Percent? = nil,
        visibilityKilometers: Double? = nil
    ) {
        self.temperature = temperature
        self.apparentTemperature = apparentTemperature
        self.condition = condition
        self.humidity = humidity
        self.wind = wind
        self.uvIndex = uvIndex
        self.dayPeriod = dayPeriod
        self.dewPoint = dewPoint
        self.pressure = pressure
        self.pressureTrend = pressureTrend
        self.cloudCover = cloudCover
        self.visibilityKilometers = visibilityKilometers
    }

    private enum CodingKeys: String, CodingKey {
        case temperature, apparentTemperature, condition, humidity, wind, uvIndex, dayPeriod
        case dewPoint, pressure, pressureTrend, cloudCover, visibilityKilometers
    }

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        self.temperature = try c.decode(Temperature.self, forKey: .temperature)
        self.apparentTemperature = try c.decode(Temperature.self, forKey: .apparentTemperature)
        self.condition = try c.decode(WeatherCondition.self, forKey: .condition)
        self.humidity = try c.decode(Percent.self, forKey: .humidity)
        self.wind = try c.decode(Wind.self, forKey: .wind)
        self.uvIndex = try c.decode(Int.self, forKey: .uvIndex)
        self.dayPeriod = try c.decode(DayPeriod.self, forKey: .dayPeriod)
        self.dewPoint = try? c.decodeIfPresent(Temperature.self, forKey: .dewPoint)
        self.pressure = try? c.decodeIfPresent(Pressure.self, forKey: .pressure)
        self.pressureTrend = try? c.decodeIfPresent(PressureTrend.self, forKey: .pressureTrend)
        self.cloudCover = try? c.decodeIfPresent(Percent.self, forKey: .cloudCover)
        self.visibilityKilometers = try? c.decodeIfPresent(Double.self, forKey: .visibilityKilometers)
    }
}

public struct HourlyForecast: Codable, Hashable, Sendable, Identifiable {
    public var id: Date { date }
    public let date: Date
    public let temperature: Temperature
    public let condition: WeatherCondition
    public let precipitationChance: Percent
    /// Cumulative precipitation expected for this hour, in millimetres.
    /// Optional so older cached entries decode cleanly.
    public let precipitationAmountMillimetres: Double?

    public init(
        date: Date,
        temperature: Temperature,
        condition: WeatherCondition,
        precipitationChance: Percent,
        precipitationAmountMillimetres: Double? = nil
    ) {
        self.date = date
        self.temperature = temperature
        self.condition = condition
        self.precipitationChance = precipitationChance
        self.precipitationAmountMillimetres = precipitationAmountMillimetres
    }

    private enum CodingKeys: String, CodingKey {
        case date, temperature, condition, precipitationChance, precipitationAmountMillimetres
    }

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        self.date = try c.decode(Date.self, forKey: .date)
        self.temperature = try c.decode(Temperature.self, forKey: .temperature)
        self.condition = try c.decode(WeatherCondition.self, forKey: .condition)
        self.precipitationChance = try c.decode(Percent.self, forKey: .precipitationChance)
        self.precipitationAmountMillimetres = try? c.decodeIfPresent(Double.self, forKey: .precipitationAmountMillimetres)
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
    public let apparentHigh: Temperature?
    public let apparentLow: Temperature?
    public let sun: SunEvents?
    public let moon: MoonInfo?
    /// Total precipitation expected over the day, in millimetres.
    public let precipitationAmountMillimetres: Double?
    /// Total snowfall expected over the day, in millimetres.
    public let snowfallAmountMillimetres: Double?
    public let uvIndex: Int?

    public init(
        date: Date,
        highTemperature: Temperature,
        lowTemperature: Temperature,
        condition: WeatherCondition,
        precipitationChance: Percent,
        wind: Wind,
        apparentHigh: Temperature? = nil,
        apparentLow: Temperature? = nil,
        sun: SunEvents? = nil,
        moon: MoonInfo? = nil,
        precipitationAmountMillimetres: Double? = nil,
        snowfallAmountMillimetres: Double? = nil,
        uvIndex: Int? = nil
    ) {
        self.date = date
        self.highTemperature = highTemperature
        self.lowTemperature = lowTemperature
        self.condition = condition
        self.precipitationChance = precipitationChance
        self.wind = wind
        self.apparentHigh = apparentHigh
        self.apparentLow = apparentLow
        self.sun = sun
        self.moon = moon
        self.precipitationAmountMillimetres = precipitationAmountMillimetres
        self.snowfallAmountMillimetres = snowfallAmountMillimetres
        self.uvIndex = uvIndex
    }

    private enum CodingKeys: String, CodingKey {
        case date, highTemperature, lowTemperature, condition, precipitationChance, wind
        case apparentHigh, apparentLow, sun, moon
        case precipitationAmountMillimetres, snowfallAmountMillimetres, uvIndex
    }

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        self.date = try c.decode(Date.self, forKey: .date)
        self.highTemperature = try c.decode(Temperature.self, forKey: .highTemperature)
        self.lowTemperature = try c.decode(Temperature.self, forKey: .lowTemperature)
        self.condition = try c.decode(WeatherCondition.self, forKey: .condition)
        self.precipitationChance = try c.decode(Percent.self, forKey: .precipitationChance)
        self.wind = try c.decode(Wind.self, forKey: .wind)
        self.apparentHigh = try? c.decodeIfPresent(Temperature.self, forKey: .apparentHigh)
        self.apparentLow = try? c.decodeIfPresent(Temperature.self, forKey: .apparentLow)
        self.sun = try? c.decodeIfPresent(SunEvents.self, forKey: .sun)
        self.moon = try? c.decodeIfPresent(MoonInfo.self, forKey: .moon)
        self.precipitationAmountMillimetres = try? c.decodeIfPresent(Double.self, forKey: .precipitationAmountMillimetres)
        self.snowfallAmountMillimetres = try? c.decodeIfPresent(Double.self, forKey: .snowfallAmountMillimetres)
        self.uvIndex = try? c.decodeIfPresent(Int.self, forKey: .uvIndex)
    }
}

/// Atmospheric pressure expressed in hPa (hectopascals / millibars —
/// 1 hPa = 1 mbar). Conversion to inHg or mmHg done at format time.
public struct Pressure: Codable, Hashable, Sendable {
    public let hPa: Double
    public init(hPa: Double) { self.hPa = hPa }
    public var inHg: Double { hPa * 0.0295299830714 }
    public var mmHg: Double { hPa * 0.7500616827042 }
}

public enum PressureTrend: String, Codable, Sendable {
    case rising, steady, falling
}

/// Sunrise / sunset / civil-dawn / civil-dusk timestamps for a single
/// day. Optional fields stay nil when the location is in polar
/// twilight (no real sunrise / sunset for that day).
public struct SunEvents: Codable, Hashable, Sendable {
    public let sunrise: Date?
    public let sunset: Date?
    public let civilDawn: Date?
    public let civilDusk: Date?
    public let solarNoon: Date?

    public init(
        sunrise: Date? = nil,
        sunset: Date? = nil,
        civilDawn: Date? = nil,
        civilDusk: Date? = nil,
        solarNoon: Date? = nil
    ) {
        self.sunrise = sunrise
        self.sunset = sunset
        self.civilDawn = civilDawn
        self.civilDusk = civilDusk
        self.solarNoon = solarNoon
    }
}

public struct MoonInfo: Codable, Hashable, Sendable {
    public let phase: MoonPhase
    public let moonrise: Date?
    public let moonset: Date?

    public init(phase: MoonPhase, moonrise: Date? = nil, moonset: Date? = nil) {
        self.phase = phase
        self.moonrise = moonrise
        self.moonset = moonset
    }
}

public enum MoonPhase: String, Codable, Sendable, CaseIterable {
    case new, waxingCrescent, firstQuarter, waxingGibbous
    case full, waningGibbous, lastQuarter, waningCrescent
}

public struct WeatherAlert: Codable, Hashable, Sendable, Identifiable {
    public let id: String
    public let summary: String
    public let severity: Severity
    public let region: String?
    public let source: String?
    public let detailsURL: URL?
    public let issuedAt: Date?
    public let expiresAt: Date?

    public enum Severity: String, Codable, Sendable {
        case minor, moderate, severe, extreme, unknown
    }

    public init(
        id: String,
        summary: String,
        severity: Severity,
        region: String? = nil,
        source: String? = nil,
        detailsURL: URL? = nil,
        issuedAt: Date? = nil,
        expiresAt: Date? = nil
    ) {
        self.id = id
        self.summary = summary
        self.severity = severity
        self.region = region
        self.source = source
        self.detailsURL = detailsURL
        self.issuedAt = issuedAt
        self.expiresAt = expiresAt
    }
}

public struct MinuteForecast: Codable, Hashable, Sendable, Identifiable {
    public var id: Date { date }
    public let date: Date
    /// 0…1 chance of any precipitation in the minute.
    public let precipitationChance: Percent
    /// Precipitation intensity in mm/h.
    public let precipitationIntensity: Double

    public init(date: Date, precipitationChance: Percent, precipitationIntensity: Double) {
        self.date = date
        self.precipitationChance = precipitationChance
        self.precipitationIntensity = precipitationIntensity
    }
}
