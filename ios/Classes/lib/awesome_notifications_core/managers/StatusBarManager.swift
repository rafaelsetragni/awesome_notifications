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
    
    public static let shared: StatusBarManager = StatusBarManager()
    private init(){}
    
    // ********************************************************
    
    public func dismissNotification(id:Int) -> Bool {
        let referenceKey:String = String(id)
            
        let center = UNUserNotificationCenter.current()
        center.removeDeliveredNotifications(withIdentifiers: [referenceKey])
        
        return true
    }
    
    public func dismissNotificationsByChannelKey(channelKey: String) -> Bool {
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

    public func dismissNotificationsByGroupKey(groupKey: String) -> Bool {
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
    
    public func dismissAllNotifications() -> Bool {
            
        let center = UNUserNotificationCenter.current()
        center.removeAllDeliveredNotifications()
        
        return true
    }
    
    
    @available(iOS 10.0, *)
    public func showNotificationOnStatusBar(
        withNotificationModel: notificationModel NotificationModel,
        whenFinished: completionHandler @escaping (Bool, Bool) -> void
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
                    debugPrint("Error: \(error.debugDescription)")
                }
            }
            
            completionHandler([])
            return
        }
        */
    
        let notificationReceived:NotificationReceived? = NotificationReceived(notificationModel.content)
        if(notificationReceived != nil){
            
            notificationModel.content!.displayedLifeCycle = SwiftAwesomeNotificationsPlugin.appLifeCycle
                        
            let channel:NotificationChannelModel? = ChannelManager.getChannelByKey(channelKey: notificationModel.content!.channelKey!)
            
            alertOnlyOnceNotification(
                channel?.onlyAlertOnce,
                notificationReceived: notificationReceived!,
                completionHandler: completionHandler
            )
            
            if CreatedManager.getCreatedByKey(id: notificationReceived!.id!) != nil {
                SwiftAwesomeNotificationsPlugin.createEvent(notificationReceived: notificationReceived!)
            }
            
            DisplayedManager.reloadLostSchedulesDisplayed(referenceDate: Date())
            
            SwiftAwesomeNotificationsPlugin.displayEvent(notificationReceived: notificationReceived!)

            /*
            if(notificationModel.schedule != nil){
                                
                do {
                    try NotificationSenderAndScheduler().send(
                        createdSource: notificationModel.content!.createdSource!,
                        notificationModel: notificationModel,
                        completion: { sent, content, error in
                        
                        }
                    )
                } catch {
                    // Fallback on earlier versions
                }
            }
            */

            // Completion handler was called in alertOnlyOnceNotification(...) / its subcalls.
        }
    }
        
    @available(iOS 10.0, *)
    private func alertOnlyOnceNotification(_ alertOnce:Bool?, notificationReceived:NotificationReceived, completionHandler: @escaping (UNNotificationPresentationOptions) -> Void){
        
        if(alertOnce ?? false){
            
            UNUserNotificationCenter.current().getDeliveredNotifications { (notifications) in
                
                for notification in notifications {
                    if notification.request.identifier == String(notificationReceived.id!) {
                        
                        self.shouldDisplay(
                            notificationReceived: notificationReceived,
                            options: [.alert, .badge],
                            completionHandler: completionHandler
                        )
                        
                        return
                    }
                }
            }
            
        }
            
        self.shouldDisplay(
            notificationReceived: notificationReceived,
            options: [.alert, .badge, .sound],
            completionHandler: completionHandler
        )
    }
    
    @available(iOS 10.0, *)
    private func shouldDisplay(notificationReceived:NotificationReceived, options:UNNotificationPresentationOptions, completionHandler: @escaping (UNNotificationPresentationOptions) -> Void){
        
        let currentLifeCycle = SwiftAwesomeNotificationsPlugin.appLifeCycle
        if(
            (notificationReceived.displayOnForeground! && currentLifeCycle == .Foreground)
                ||
            (notificationReceived.displayOnBackground! && currentLifeCycle == .Background)
        ){
            completionHandler(options)
        }
        completionHandler([])
    }
}
