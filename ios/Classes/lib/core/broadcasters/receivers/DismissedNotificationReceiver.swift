//
//  DismissedNotificationReceiver.swift
//  awesome_notifications
//
//  Created by CardaDev on 02/02/22.
//

import Foundation

class DismissedNotificationReceiver {
    
    private let TAG = "DismissedNotificationReceiver"
    
    
    // **************************** SINGLETON PATTERN *************************************
    
    static var instance:DismissedNotificationReceiver?
    public static var shared:DismissedNotificationReceiver {
        get {
            DismissedNotificationReceiver.instance =
                DismissedNotificationReceiver.instance ?? DismissedNotificationReceiver()
            return DismissedNotificationReceiver.instance!
        }
    }
    private init(){}
    
    
    // **************************** OBSERVER PATTERN **************************************
    
    public func addNewDismissEvent(
        fromResponse response: UNNotificationResponse,
        whenFinished completionHandler: @escaping (Bool) -> Void
    ){
        guard let jsonData:String =
                response
                    .notification
                    .request
                    .content
                    .userInfo[Definitions.NOTIFICATION_JSON] as? String
        else {
            completionHandler(false)
            return
        }
            
        guard
            let notificationModel:NotificationModel =
                NotificationBuilder
                    .newInstance()
                    .buildNotificationFromJson(
                        jsonData: jsonData),
            let actionReceived:ActionReceived =
                NotificationBuilder
                    .newInstance()
                    .buildNotificationActionFromModel(
                        notificationModel: notificationModel,
                        buttonKeyPressed: nil,
                        userText: nil)
        else {
            completionHandler(false)
            return
        }
        
        actionReceived.registerDismissedEvent(
            withLifeCycle:
                LifeCycleManager
                    .shared
                    .currentLifeCycle)
        
        BroadcastSender
            .shared
            .sendBroadcast(
                notificationDismissed: actionReceived,
                whenFinished: completionHandler)
    }
}
