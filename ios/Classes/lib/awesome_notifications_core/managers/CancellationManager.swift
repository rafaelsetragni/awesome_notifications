//
//  CancellationManager.swift
//  awesome_notifications
//
//  Created by Rafael Setragni on 06/12/21.
//

import Foundation

public class CancellationManager {
    
    public static let TAG: String = "CancellationManager"
    
    // ************** SINGLETON PATTERN ***********************
    
    public static let shared: CancellationManager = CancellationManager()
    private init(){}
    
    // ********************************************************
        
    public func dismissNotification(byId id:Int) -> Bool {
        return StatusBarManager.dismissNotification(id: id)
    }
    
    public func dismissNotifications(byChannelKey channelKey: String) -> Bool {
        return StatusBarManager.dismissNotificationsByChannelKey(channelKey: channelKey)
    }
    
    public func dismissNotifications(byGroupKey groupKey: String) -> Bool {
        return StatusBarManager.dismissNotificationsByGroupKey(groupKey: groupKey)
    }
    
    public func dismissAllNotifications() -> Bool {
        return StatusBarManager.dismissAllNotifications()
    }
    
    public func cancelSchedule(byId id:Int) -> Bool {
        return
            ScheduleManager.cancelScheduled(id: id) &&
            _cancelNativeScheduledNotification(id: id)
    }
    
    public func cancelSchedules(byChannelKey channelKey: String) -> Bool {
        return
            _cancelNativeSchedulesByChannelKey(channelKey: channelKey)
    }
    
    public func cancelSchedules(byGroupKey groupKey: String) -> Bool {
        return
            _cancelNativeSchedulesByGroupKey(groupKey: groupKey)
    }
    
    public func cancelAllSchedules() -> Bool {
        return
            ScheduleManager.cancelAllSchedules() &&
            _cancellAllNativeScheduledNotifications()
    }
    
    public func cancelNotification(byId id:Int) -> Bool {
        return
            dismissNotification(id: id) &&
            cancelSchedule(id: id)
    }
    
    public func cancelNotifications(byChannelKey channelKey: String) -> Bool {
        return
            dismissNotificationsByChannelKey(channelKey: channelKey) &&
            cancelSchedulesByChannelKey(channelKey: channelKey)
    }
    
    public func cancelNotifications(byGroupKey groupKey: String) -> Bool {
        return
            dismissNotificationsByGroupKey(groupKey: groupKey) &&
            cancelSchedulesByGroupKey(groupKey: groupKey)
    }

    public func cancelAllNotifications() -> Bool {
        return
            dismissAllNotifications() &&
            cancelAllSchedules()
    }
        
    private func _cancelNativeSchedulesByChannelKey(channelKey: String) -> Bool {
        
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
    
    private func _cancelNativeSchedulesByGroupKey(groupKey: String) -> Bool {

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
    
    private func _cancelNativeScheduledNotification(id:Int) -> Bool {
        let referenceKey:String = String(id)
            
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: [referenceKey])
        
        return true
    }
    
    private func _cancelNativeNotification(id:Int) -> Bool {
        let referenceKey:String = String(id)
            
        let center = UNUserNotificationCenter.current()
        center.removeDeliveredNotifications(withIdentifiers: [referenceKey])
        center.removePendingNotificationRequests(withIdentifiers: [referenceKey])
        
        return true
    }
    
    private func _cancellAllNativeScheduledNotifications() -> Bool {
            
        let center = UNUserNotificationCenter.current()
        center.removeAllPendingNotificationRequests()
        
        return true
    }
    
    public func _cancellAllNativeNotifications() -> Bool {
            
        let center = UNUserNotificationCenter.current()
        center.removeAllDeliveredNotifications()
        center.removeAllPendingNotificationRequests()
        
        return true
    }
    
}
