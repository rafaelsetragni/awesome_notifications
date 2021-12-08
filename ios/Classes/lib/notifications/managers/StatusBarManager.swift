//
//  StatusBarManager.swift
//  awesome_notifications
//
//  Created by Rafael Setragni on 06/12/21.
//

import Foundation

public class StatusBarManager {
    
    public static func dismissNotification(id:Int) -> Bool {
        let referenceKey:String = String(id)
            
        let center = UNUserNotificationCenter.current()
        center.removeDeliveredNotifications(withIdentifiers: [referenceKey])
        
        return true
    }
    
    public static func dismissNotificationsByChannelKey(channelKey: String) -> Bool {
        var removed:Bool = false
        let center = UNUserNotificationCenter.current()
        center.getDeliveredNotifications(completionHandler: { (notificationRequest) in
            for notification in notificationRequest {
                if channelKey == notification.request.content.userInfo[Definitions.NOTIFICATION_CHANNEL_KEY] as? String {
                    center.removeDeliveredNotifications(withIdentifiers: [notification.request.identifier])
                    removed = true
                }
            }
        })
        
        return removed
    }

    public static func dismissNotificationsByGroupKey(groupKey: String) -> Bool {
        var removed:Bool = false

        let center = UNUserNotificationCenter.current()
        center.getDeliveredNotifications(completionHandler: { (notificationRequest) in
            for notification in notificationRequest {
                if groupKey == notification.request.content.userInfo[Definitions.NOTIFICATION_GROUP_KEY] as? String {
                    center.removeDeliveredNotifications(withIdentifiers: [notification.request.identifier])
                    removed = true
                }
            }
        })
        
        return removed
    }
    
    public static func dismissAllNotifications() -> Bool {
            
        let center = UNUserNotificationCenter.current()
        center.removeAllDeliveredNotifications()
        
        return true
    }
    
}
