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
        whenFinished completionHandler: @escaping (Bool, Error?) -> Void
    ) throws {
        guard let jsonData:String =
                response
                    .notification
                    .request
                    .content
                    .userInfo[Definitions.NOTIFICATION_JSON] as? String
        else {
            throw ExceptionFactory
                .shared
                .createNewAwesomeException(
                    className: TAG,
                    code: ExceptionCode.CODE_INVALID_ARGUMENTS,
                    message: "The dismiss content doesn't contain any awesome information",
                    detailedCode: ExceptionCode.DETAILED_INVALID_ARGUMENTS + ".addNewDismissEvent.jsonData")
        }
            
        guard
            let notificationModel:NotificationModel =
                NotificationBuilder
                    .newInstance()
                    .buildNotificationFromJson(
                        jsonData: jsonData),
            let dismissedReceived:ActionReceived =
                NotificationBuilder
                    .newInstance()
                    .buildNotificationActionFromModel(
                        notificationModel: notificationModel,
                        buttonKeyPressed: nil,
                        userText: nil)
        else {
            throw ExceptionFactory
                .shared
                .createNewAwesomeException(
                    className: TAG,
                    code: ExceptionCode.CODE_INVALID_ARGUMENTS,
                    message: "The dismiss content doesn't contain any valid awesome content",
                    detailedCode: ExceptionCode.DETAILED_INVALID_ARGUMENTS + ".addNewDismissEvent.dismissedReceived")
        }
        
        dismissedReceived.registerDismissedEvent(
            withLifeCycle:
                LifeCycleManager
                    .shared
                    .currentLifeCycle)
        
        BroadcastSender
            .shared
            .sendBroadcast(
                notificationDismissed: dismissedReceived,
                whenFinished: completionHandler)
    }
}
