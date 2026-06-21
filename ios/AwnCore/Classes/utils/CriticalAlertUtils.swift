//
//  CriticalAlertUtils.swift
//  awesome_notifications
//

import Foundation
import UserNotifications

@available(iOS 10.0, *)
public class CriticalAlertUtils {

    private static let TAG = "CriticalAlertUtils"
    private static var cachedCanDeliver: Bool?

    public static func updateCache(from settings: UNNotificationSettings) {
        if #available(iOS 12.0, *) {
            cachedCanDeliver = settings.criticalAlertSetting == .enabled
        } else {
            cachedCanDeliver = false
        }
    }

    public static func clearCache() {
        cachedCanDeliver = nil
    }

    public static func canDeliverCriticalAlerts() -> Bool {
        if let cachedCanDeliver = cachedCanDeliver {
            return cachedCanDeliver
        }

        var canDeliver = false
        let semaphore = DispatchSemaphore(value: 0)

        UNUserNotificationCenter.current().getNotificationSettings { settings in
            if #available(iOS 12.0, *) {
                canDeliver = settings.criticalAlertSetting == .enabled
            }
            cachedCanDeliver = canDeliver
            semaphore.signal()
        }

        _ = semaphore.wait(timeout: .now() + 2)
        return canDeliver
    }

    public static func isCriticalAlertRequested(
        channel: NotificationChannelModel,
        notificationModel: NotificationModel
    ) -> Bool {
        return (channel.criticalAlerts ?? false) ||
            (notificationModel.content?.criticalAlert ?? false)
    }
}
