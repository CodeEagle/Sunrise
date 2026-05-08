import Foundation
import Dependencies
import DependenciesMacros

#if canImport(UserNotifications)
import UserNotifications
#endif

@DependencyClient
public struct NotificationsClient: Sendable {
    public var requestAuthorization: @Sendable () async throws -> Bool = { false }
    public var scheduleDailyBriefing: @Sendable (_ hour: Int, _ minute: Int, _ title: String, _ body: String) async throws -> Void
    public var cancelDailyBriefing: @Sendable () async -> Void
}

public enum NotificationsClientError: Error, Sendable {
    case unsupportedPlatform
}

extension NotificationsClient: DependencyKey {
    public static var liveValue: NotificationsClient {
        #if canImport(UserNotifications)
        let identifier = "sunrise.daily-briefing"
        // We can't capture UNUserNotificationCenter in `@Sendable` closures
        // (Swift 6 sees the singleton as non-Sendable), so each closure calls
        // `.current()` itself. It's the same singleton on every call, so this
        // is purely a compile-time fix — no runtime behaviour change.
        return NotificationsClient(
            requestAuthorization: {
                try await UNUserNotificationCenter.current()
                    .requestAuthorization(options: [.alert, .sound, .badge])
            },
            scheduleDailyBriefing: { hour, minute, title, body in
                let content = UNMutableNotificationContent()
                content.title = title
                content.body = body
                content.sound = .default

                var dateComponents = DateComponents()
                dateComponents.hour = hour
                dateComponents.minute = minute
                let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)

                let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
                let center = UNUserNotificationCenter.current()
                center.removePendingNotificationRequests(withIdentifiers: [identifier])
                try await center.add(request)
            },
            cancelDailyBriefing: {
                UNUserNotificationCenter.current()
                    .removePendingNotificationRequests(withIdentifiers: [identifier])
            }
        )
        #else
        return NotificationsClient(
            requestAuthorization: { false },
            scheduleDailyBriefing: { _, _, _, _ in throw NotificationsClientError.unsupportedPlatform },
            cancelDailyBriefing: { }
        )
        #endif
    }

    public static let previewValue = NotificationsClient(
        requestAuthorization: { true },
        scheduleDailyBriefing: { _, _, _, _ in },
        cancelDailyBriefing: { }
    )

    public static let testValue = NotificationsClient()
}

public extension DependencyValues {
    var notificationsClient: NotificationsClient {
        get { self[NotificationsClient.self] }
        set { self[NotificationsClient.self] = newValue }
    }
}
