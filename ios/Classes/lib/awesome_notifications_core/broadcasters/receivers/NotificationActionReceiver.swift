//
//  NotificationActionReceiver.swift
//  awesome_notifications
//
//  Created by CardaDev on 31/01/22.
//

import Foundation

public class NotificationActionReceiver {
    
    let TAG = "NotificationActionReceiver"
    
    // ************** SINGLETON PATTERN ***********************
    
    static var instance:NotificationActionReceiver?
    public static var shared:NotificationActionReceiver {
        get {
            NotificationActionReceiver.instance =
                NotificationActionReceiver.instance ?? NotificationActionReceiver()
            return NotificationActionReceiver.instance!
        }
    }
    private init(){}
    
    // ********************************************************
    
    public func addNewActionEvent(
        fromResponse response: UNNotificationResponse,
        whenFinished completionHandler: @escaping (Bool) -> Void
    ){
     
        var userText:String?
        if let textResponse = response as? UNTextInputNotificationResponse {
            userText =  textResponse.userText
        }
        
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
                        buttonKeyPressed: response.actionIdentifier,
                        userText: userText)
        else {
            completionHandler(false)
            return
        }
        
        if actionReceived.actionType == .DismissAction {
            actionReceived.registerDismissedEvent(
                withLifeCycle:
                    LifeCycleManager
                        .shared
                        .currentLifeCycle)
        }
        else {
            actionReceived.registerActionEvent(
                withLifeCycle:
                    LifeCycleManager
                        .shared
                        .currentLifeCycle)
        }
        
        if #available(iOS 15.0, *), !actionReceived.autoDismissible! {
            if let notificationModel:NotificationModel =
                    NotificationBuilder
                        .newInstance()
                        .buildNotificationFromJson(
                            jsonData: jsonData)
            {
                let isOutOfFocus =
                        LifeCycleManager
                            .shared
                            .isOutOfFocus
                
                DispatchQueue
                    .global(qos: .background)
                    .asyncAfter(deadline: .now() +
                                (isOutOfFocus ? 1.5 : 0)) {
                        do {
                            try NotificationSenderAndScheduler
                                    .mimicPersistentNotification(
                                        notificationModel: notificationModel)
                        } catch {
                            Log.e(self.TAG, "\(error)")
                        }
                    }
            }
        }
        
        switch actionReceived.actionType! {
            
            case .Default:
                BroadcastSender
                    .shared
                    .sendBroadcast(
                        actionReceived: actionReceived,
                        whenFinished: completionHandler)
                break
                
            case .KeepOnTop:
                if LifeCycleManager.shared.currentLifeCycle != .AppKilled {
                    BroadcastSender
                        .shared
                        .sendBroadcast(
                            actionReceived: actionReceived,
                            whenFinished: completionHandler)
                }
                else {
                    BroadcastSender
                        .shared
                        .enqueue(
                            silentAction: actionReceived,
                            whenFinished: completionHandler)
                }
                break
                
            case .SilentAction:
                if LifeCycleManager.shared.currentLifeCycle != .AppKilled {
                    BroadcastSender
                        .shared
                        .sendBroadcast(
                            silentAction: actionReceived,
                            whenFinished: completionHandler)
                }
                else {
                    BroadcastSender
                        .shared
                        .enqueue(
                            silentBackgroundAction: actionReceived,
                            whenFinished: completionHandler)
                }
                break
                
            case .SilentBackgroundAction:
                BroadcastSender
                    .shared
                    .enqueue(
                        silentBackgroundAction: actionReceived,
                        whenFinished: completionHandler)
                break
            
            case .DismissAction:
                BroadcastSender
                    .shared
                    .sendBroadcast(
                        notificationDismissed: actionReceived,
                        whenFinished: completionHandler)
                break
                
            case .DisabledAction:
                completionHandler(true)
                break
        }
    }
    
}
