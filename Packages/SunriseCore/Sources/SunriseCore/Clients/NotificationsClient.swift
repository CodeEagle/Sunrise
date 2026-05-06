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
        let center = UNUserNotificationCenter.current()
        return NotificationsClient(
            requestAuthorization: {
                try await center.requestAuthorization(options: [.alert, .sound, .badge])
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
                center.removePendingNotificationRequests(withIdentifiers: [identifier])
                try await center.add(request)
            },
            cancelDailyBriefing: {
                center.removePendingNotificationRequests(withIdentifiers: [identifier])
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
