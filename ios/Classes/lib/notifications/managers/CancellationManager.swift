//
//  CancellationManager.swift
//  awesome_notifications
//
//  Created by Rafael Setragni on 06/12/21.
//

import Foundation

public class CancellationManager {
    
    public static let TAG: String = "CancellationManager"
        
    public static func dismissNotification(id:Int) -> Bool {
        return StatusBarManager.dismissNotification(id: id)
    }
    
    public static func dismissNotificationsByChannelKey(channelKey: String) -> Bool {
        return StatusBarManager.dismissNotificationsByChannelKey(channelKey: channelKey)
    }
    
    public static func dismissNotificationsByGroupKey(groupKey: String) -> Bool {
        return StatusBarManager.dismissNotificationsByGroupKey(groupKey: groupKey)
    }
    
    public static func dismissAllNotifications() -> Bool {
        return StatusBarManager.dismissAllNotifications()
    }
    
    public static func cancelSchedule(id:Int) -> Bool {
        return
            ScheduleManager.cancelScheduled(id: id) &&
            _cancelNativeScheduledNotification(id: id)
    }
    
    public static func cancelSchedulesByChannelKey(channelKey: String) -> Bool {
        return
            _cancelNativeSchedulesByChannelKey(channelKey: channelKey)
    }
    
    public static func cancelSchedulesByGroupKey(groupKey: String) -> Bool {
        return
            _cancelNativeSchedulesByGroupKey(groupKey: groupKey)
    }
    
    public static func cancelAllSchedules() -> Bool {
        return
            ScheduleManager.cancelAllSchedules() &&
            _cancellAllNativeScheduledNotifications()
    }
    
    public static func cancelNotification(id:Int) -> Bool {
        return
            dismissNotification(id: id) &&
            cancelSchedule(id: id)
    }
    
    public static func cancelNotificationsByChannelKey(channelKey: String) -> Bool {
        return
            dismissNotificationsByChannelKey(channelKey: channelKey) &&
            cancelSchedulesByChannelKey(channelKey: channelKey)
    }
    
    public static func cancelNotificationsByGroupKey(groupKey: String) -> Bool {
        return
            dismissNotificationsByGroupKey(groupKey: groupKey) &&
            cancelSchedulesByGroupKey(groupKey: groupKey)
    }

    public static func cancelAllNotifications() -> Bool {
        return
            dismissAllNotifications() &&
            cancelAllSchedules()
    }
        
    private static func _cancelNativeSchedulesByChannelKey(channelKey: String) -> Bool {
        
        let center = UNUserNotificationCenter.current()
        center.getPendingNotificationRequests(completionHandler: { (notificationRequest) in
            for notification in notificationRequest {
                if channelKey == notification.content.userInfo[Definitions.NOTIFICATION_CHANNEL_KEY] as? String {
                    if notification.content.userInfo[Definitions.NOTIFICATION_ID] != nil {
                        
                        if let id:String = notification.content.userInfo[Definitions.NOTIFICATION_ID] as? String {
                            center.removePendingNotificationRequests(withIdentifiers: [id])
                        }
                        else {
                            if let id:Int64 = notification.content.userInfo[Definitions.NOTIFICATION_ID] as? Int64 {
                                center.removePendingNotificationRequests(withIdentifiers: [String(id)])
                            }
                        }
                    }
                }
            }
        })
        
        return true
    }
    
    private static func _cancelNativeSchedulesByGroupKey(groupKey: String) -> Bool {

        let center = UNUserNotificationCenter.current()
        center.getPendingNotificationRequests(completionHandler: { (notificationRequest) in
            for notification in notificationRequest {
                if groupKey == notification.content.userInfo[Definitions.NOTIFICATION_GROUP_KEY] as? String {
                    if notification.content.userInfo[Definitions.NOTIFICATION_ID] != nil {
                        
                        if let id:String = notification.content.userInfo[Definitions.NOTIFICATION_ID] as? String {
                            center.removePendingNotificationRequests(withIdentifiers: [id])
                        }
                        else {
                            if let id:Int64 = notification.content.userInfo[Definitions.NOTIFICATION_ID] as? Int64 {
                                center.removePendingNotificationRequests(withIdentifiers: [String(id)])
                            }
                        }
                    }
                }
            }
        })
        
        return true
    }
    
    private static func _cancelNativeScheduledNotification(id:Int) -> Bool {
        let referenceKey:String = String(id)
            
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: [referenceKey])
        
        return true
    }
    
    private static func _cancelNativeNotification(id:Int) -> Bool {
        let referenceKey:String = String(id)
            
        let center = UNUserNotificationCenter.current()
        center.removeDeliveredNotifications(withIdentifiers: [referenceKey])
        center.removePendingNotificationRequests(withIdentifiers: [referenceKey])
        
        return true
    }
    
    private static func _cancellAllNativeScheduledNotifications() -> Bool {
            
        let center = UNUserNotificationCenter.current()
        center.removeAllPendingNotificationRequests()
        
        return true
    }
    
    public static func _cancellAllNativeNotifications() -> Bool {
            
        let center = UNUserNotificationCenter.current()
        center.removeAllDeliveredNotifications()
        center.removeAllPendingNotificationRequests()
        
        return true
    }
    
}
