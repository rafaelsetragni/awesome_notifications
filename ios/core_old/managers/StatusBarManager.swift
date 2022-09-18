//
//  StatusBarManager.swift
//  awesome_notifications
//
//  Created by Rafael Setragni on 06/12/21.
//

import Foundation

public class StatusBarManager {
    
    static let TAG = "StatusBarManager"
    
    // ************** SINGLETON PATTERN ***********************
    
    static var instance:StatusBarManager?
    public static var shared:StatusBarManager {
        get {
            StatusBarManager.instance =
                StatusBarManager.instance ?? StatusBarManager()
            return StatusBarManager.instance!
        }
    }
    private init(){}
    
    // ********************************************************
    
    public func dismissNotification(id:Int) -> Bool {
        let referenceKey:String = String(id)
            
        let center = UNUserNotificationCenter.current()
        center.removeDeliveredNotifications(withIdentifiers: [referenceKey])
        
        return true
    }
    
    public func dismissNotificationsByChannelKey(channelKey: String) -> Bool {
        let center = UNUserNotificationCenter.current()
        
        center.getDeliveredNotifications(completionHandler: { (notificationRequest) in
            for notification in notificationRequest {
                if channelKey == notification.request.content.userInfo[Definitions.NOTIFICATION_CHANNEL_KEY] as? String {
                    center.removeDeliveredNotifications(withIdentifiers: [notification.request.identifier])
                }
            }
        })
        
        return true
    }

    public func dismissNotificationsByGroupKey(groupKey: String) -> Bool {
        let center = UNUserNotificationCenter.current()
        
        center.getDeliveredNotifications(completionHandler: { (notificationRequest) in
            for notification in notificationRequest {
                if groupKey == notification.request.content.userInfo[Definitions.NOTIFICATION_GROUP_KEY] as? String {
                    center.removeDeliveredNotifications(withIdentifiers: [notification.request.identifier])
                }
            }
        })
        
        return true
    }
    
    public func dismissAllNotifications() -> Bool {
            
        let center = UNUserNotificationCenter.current()
        center.removeAllDeliveredNotifications()
        
        return true
    }
    
    
    @available(iOS 10.0, *)
    public func showNotificationOnStatusBar(
        withNotificationModel notificationModel: NotificationModel,
        whenFinished completionHandler: @escaping (Bool, Bool) -> Void
    ) {
        
        /*
        if(content.userInfo["updated"] == nil){
            
            let pushData = notificationModel.toMap()
            let updatedJsonData = JsonUtils.toJson(pushData)
            
            let content:UNMutableNotificationContent =
                UNMutableNotificationContent().copyContent(from: content)
            
            content.userInfo[Definitions.NOTIFICATION_JSON] = updatedJsonData
            content.userInfo["updated"] = true
            
            let request = UNNotificationRequest(identifier: notificationModel!.content!.id!.description, content: content, trigger: nil)
            
            UNUserNotificationCenter.current().add(request)
            {
                error in // called when message has been sent

                if error != nil {
                    Logger.e("StatusBarManager", error.debugDescription)
                }
            }
            
            completionHandler([])
            return
        }
        */
    
        let notificationReceived:NotificationReceived? = NotificationReceived(notificationModel.content)
        if(notificationReceived != nil){
            
            notificationModel.content!.displayedLifeCycle = LifeCycleManager.shared.currentLifeCycle
            
            let channel:NotificationChannelModel? =
                ChannelManager
                .shared
                .getChannelByKey(channelKey: notificationModel.content!.channelKey!)
            
            alertOnlyOnceNotification(
                channel?.onlyAlertOnce,
                notificationReceived: notificationReceived!,
                completionHandler: completionHandler
            )
        }
    }
        
    @available(iOS 10.0, *)
    private func alertOnlyOnceNotification(
        _ alertOnce:Bool?,
        notificationReceived:NotificationReceived,
        completionHandler: @escaping (Bool, Bool) -> Void
    ){
        
        if !self.shouldDisplay(notificationReceived: notificationReceived) {
            completionHandler(false, false)
            return
        }
        
        if(alertOnce ?? false){
            
            UNUserNotificationCenter.current().getDeliveredNotifications { (notifications) in
                
                for notification in notifications {
                    if notification.request.identifier == String(notificationReceived.id!) {
                        completionHandler(true, false)
                        return
                    }
                }
            }
            
        }
        
        completionHandler(true, true)
    }
    
    @available(iOS 10.0, *)
    private func shouldDisplay(notificationReceived:NotificationReceived) -> Bool {
        
        let currentLifeCycle = LifeCycleManager.shared.currentLifeCycle
        
        if currentLifeCycle == .Foreground {
            return notificationReceived.displayOnForeground ?? false
        }
        
        if currentLifeCycle == .Background {
            return notificationReceived.displayOnBackground ?? false
        }
        
        return false
    }
}
