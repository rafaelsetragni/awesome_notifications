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
    
    public static let shared = DismissedNotificationReceiver()
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
            
        guard let actionReceived:ActionReceived =
                NotificationBuilder
                    .newInstance()
                    .buildNotificationActionFromJson(
                        jsonData: jsonData,
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
                notificationDismissed: actionReceived)
        
        completionHandler(true)
    }
}
