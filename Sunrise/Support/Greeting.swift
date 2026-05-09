import Foundation
import SunriseCore

/// Composes the speech-bubble line for a city + weather + time
/// context. Pulls together day-period (dawn / morning / noon / dusk /
/// night), condition, and active alerts so the line feels alive instead
/// of a fixed-per-condition string.
///
/// Strings flow through `.l10n(_:)` so they flip live with the
/// language picker; templates use `%@` placeholders so each locale's
/// translation can reorder city / time / temperature naturally.
enum Greeting {
    struct Context {
        let condition: WeatherCondition
        let dayPeriod: DayPeriod
        let cityName: String?
        let temperature: Temperature?
        let now: Date
        let sunrise: Date?
        let sunset: Date?
        let alerts: [WeatherAlert]
    }

    static func line(for context: Context, locale: Locale = .current) -> String {
        // Severe weather always wins the bubble.
        if let alert = mostSevereAlert(context.alerts) {
            return String.localizedStringWithFormat(
                "bubble.alert.template".l10n("⚠️ %@ — stay safe and check official sources."),
                alert.summary
            )
        }

        switch tone(for: context) {
        case .dawn:
            if let sunrise = context.sunrise {
                let time = formatTime(sunrise, locale: locale, timeZone: nil)
                if let city = displayName(context.cityName) {
                    return String.localizedStringWithFormat(
                        "bubble.dawn.city".l10n("🌅 Sunrise at %@ in %@ — Sunny is up early."),
                        time, city
                    )
                }
                return String.localizedStringWithFormat(
                    "bubble.dawn".l10n("🌅 Sunrise at %@ — Sunny is up early."),
                    time
                )
            }
        case .morning:
            if let temperature = context.temperature, let city = displayName(context.cityName) {
                return String.localizedStringWithFormat(
                    "bubble.morning.full".l10n("Good morning, %@! It's %@° outside."),
                    city,
                    formatTemperature(temperature)
                )
            }
            if let city = displayName(context.cityName) {
                return String.localizedStringWithFormat(
                    "bubble.morning.city".l10n("Good morning, %@!"),
                    city
                )
            }
        case .noon:
            return "bubble.noon".l10n("Bright noon — drink water, stay cool.")
        case .afternoon:
            if let city = displayName(context.cityName) {
                return String.localizedStringWithFormat(
                    "bubble.afternoon.city".l10n("Afternoon in %@ — Sunny is enjoying the breeze."),
                    city
                )
            }
        case .dusk:
            if let sunset = context.sunset {
                return String.localizedStringWithFormat(
                    "bubble.dusk".l10n("🌇 Sunset at %@ — chase the colours."),
                    formatTime(sunset, locale: locale, timeZone: nil)
                )
            }
        case .night:
            if let city = displayName(context.cityName) {
                return String.localizedStringWithFormat(
                    "bubble.night.city".l10n("Quiet night in %@."),
                    city
                )
            }
            return "bubble.night".l10n("Quiet night — Sunny is curled up with a book.")
        }

        // Fallback: condition-keyed line (the original set).
        return conditionLine(context.condition)
    }

    // MARK: - Tone selection

    private enum Tone { case dawn, morning, noon, afternoon, dusk, night }

    private static func tone(for context: Context) -> Tone {
        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: context.now)
        // Sun-relative when both sunrise & sunset known.
        if let sunrise = context.sunrise, let sunset = context.sunset {
            if context.now < sunrise.addingTimeInterval(-15 * 60) {
                return .night
            }
            if context.now < sunrise.addingTimeInterval(15 * 60) {
                return .dawn
            }
            if context.now < sunset.addingTimeInterval(-90 * 60) {
                if hour >= 11, hour < 14 { return .noon }
                return hour < 12 ? .morning : .afternoon
            }
            if context.now < sunset.addingTimeInterval(15 * 60) {
                return .dusk
            }
            return .night
        }
        // Sun events missing (polar regions or mock data) — fall back to clock hour.
        switch hour {
        case 5..<9: return .dawn
        case 9..<11: return .morning
        case 11..<14: return .noon
        case 14..<17: return .afternoon
        case 17..<20: return .dusk
        default: return .night
        }
    }

    private static func mostSevereAlert(_ alerts: [WeatherAlert]) -> WeatherAlert? {
        alerts.max { lhs, rhs in
            severityRank(lhs.severity) < severityRank(rhs.severity)
        }
    }

    private static func severityRank(_ severity: WeatherAlert.Severity) -> Int {
        switch severity {
        case .extreme: return 4
        case .severe: return 3
        case .moderate: return 2
        case .minor: return 1
        case .unknown: return 0
        }
    }

    // MARK: - Condition fallback

    private static func conditionLine(_ condition: WeatherCondition) -> String {
        switch condition {
        case .clear: return "bubble.clear".l10n("Beautiful day — let's go outside!")
        case .cloudy: return "bubble.cloudy".l10n("Clouds drifting by — what shape will they make next?")
        case .rain: return "bubble.rain".l10n("Don't forget your umbrella!")
        case .thunderstorm: return "bubble.thunderstorm".l10n("Storms incoming — stay safe indoors.")
        case .snow: return "bubble.snow".l10n("Snowflakes! Let's build a snowman.")
        case .windy: return "bubble.windy".l10n("Hold onto your hat — it's blustery out there!")
        case .fog: return "bubble.fog".l10n("Misty morning — drive carefully.")
        }
    }

    // MARK: - Formatting helpers

    private static func formatTime(_ date: Date, locale: Locale, timeZone: TimeZone?) -> String {
        let df = DateFormatter()
        df.locale = locale
        df.dateStyle = .none
        df.timeStyle = .short
        if let timeZone {
            df.timeZone = timeZone
        }
        return df.string(from: date)
    }

    private static func formatTemperature(_ temperature: Temperature) -> String {
        String(format: "%.0f", temperature.celsius)
    }

    /// "Current Location" sentinel resolves to a localised label so the
    /// bubble doesn't read "Good morning, Current Location!"
    private static func displayName(_ name: String?) -> String? {
        guard let name, !name.isEmpty else { return nil }
        if name == "Current Location" {
            return "today.current_location".l10n("Current Location")
        }
        return name
    }
}
