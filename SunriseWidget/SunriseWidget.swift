import WidgetKit
import SwiftUI
import SunriseCore
import SunriseDesignSystem

@main
struct SunriseWidgetBundle: WidgetBundle {
    var body: some Widget {
        SunriseWidget()
    }
}

struct SunriseWidget: Widget {
    let kind = "SunriseWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: WeatherTimelineProvider()) { entry in
            WeatherEntryView(entry: entry)
                .containerBackground(for: .widget) {
                    LinearGradient(
                        colors: [
                            Color(GradientPalette.clearDay.top),
                            Color(GradientPalette.clearDay.bottom)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                }
        }
        .configurationDisplayName("Sunrise")
        .description("Today's weather and Sunny's mood at a glance.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}
