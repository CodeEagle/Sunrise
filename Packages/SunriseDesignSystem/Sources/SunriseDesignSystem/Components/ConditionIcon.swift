#if canImport(UIKit)
import UIKit

/// Map of WeatherCondition raw values → SF Symbol names + tints. App layer
/// handles UIImage construction so this stays free of SunriseCore dependency.
public enum ConditionGlyph {
    public static func symbolName(forConditionRawValue raw: String) -> String {
        switch raw {
        case "clear": return "sun.max.fill"
        case "cloudy": return "cloud.fill"
        case "rain": return "cloud.rain.fill"
        case "thunderstorm": return "cloud.bolt.rain.fill"
        case "snow": return "cloud.snow.fill"
        case "windy": return "wind"
        case "fog": return "cloud.fog.fill"
        default: return "questionmark"
        }
    }

    public static func tint(forConditionRawValue raw: String) -> UIColor {
        switch raw {
        case "clear": return Palette.sunYellow
        case "cloudy", "fog": return Palette.inkSecondary
        case "rain", "thunderstorm": return Palette.skyBlue
        case "snow": return UIColor(white: 0.78, alpha: 1)
        case "windy": return Palette.leafGreen
        default: return Palette.inkSecondary
        }
    }
}
#endif
