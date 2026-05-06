import WidgetKit
import Foundation
import SunriseCore

struct WeatherEntry: TimelineEntry {
    let date: Date
    let snapshot: WeatherSnapshot
    let cityName: String
}

struct WeatherTimelineProvider: TimelineProvider {
    func placeholder(in context: Context) -> WeatherEntry {
        WeatherEntry(date: .now, snapshot: .preview, cityName: "Shanghai")
    }

    func getSnapshot(in context: Context, completion: @escaping (WeatherEntry) -> Void) {
        if let cached = SharedStorage.loadSnapshot() {
            completion(WeatherEntry(date: .now, snapshot: cached.snapshot, cityName: cached.city.name))
        } else {
            completion(placeholder(in: context))
        }
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<WeatherEntry>) -> Void) {
        let nextRefresh = Calendar.current.date(byAdding: .minute, value: 30, to: .now) ?? .now

        if let cached = SharedStorage.loadSnapshot() {
            let entry = WeatherEntry(date: .now, snapshot: cached.snapshot, cityName: cached.city.name)
            completion(Timeline(entries: [entry], policy: .after(nextRefresh)))
            return
        }

        let entry = placeholder(in: context)
        completion(Timeline(entries: [entry], policy: .after(nextRefresh)))
    }
}
