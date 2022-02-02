//
//  NotificationActionReceiver.swift
//  awesome_notifications
//
//  Created by CardaDev on 31/01/22.
//

import Foundation

public class NotificationActionReceiver {
    
    // ************** SINGLETON PATTERN ***********************
    
    public static let shared: NotificationActionReceiver = NotificationActionReceiver()
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
        
        guard let jsonData:String = response.notification.request.content.userInfo[Definitions.NOTIFICATION_JSON] as? String
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
        
        switch actionReceived.actionType! {
            
            case .Default:
                BroadcastSender
                    .shared
                    .sendBroadcast(
                        actionReceived: actionReceived)
                break
                
            case .KeepOnTop:
                if LifeCycleManager.shared.currentLifeCycle != .AppKilled {
                    BroadcastSender
                        .shared
                        .sendBroadcast(
                            actionReceived: actionReceived)
                }
                else {
                    BroadcastSender
                        .shared
                        .enqueue(
                            silentAction: actionReceived)
                }
                break
                
            case .SilentAction:
                if LifeCycleManager.shared.currentLifeCycle != .AppKilled {
                    BroadcastSender
                        .shared
                        .sendBroadcast(
                            silentAction: actionReceived)
                }
                else {
                    BroadcastSender
                        .shared
                        .enqueue(
                            silentBackgroundAction: actionReceived)
                }
                break
                
            case .SilentBackgroundAction:
                BroadcastSender
                    .shared
                    .enqueue(
                        silentBackgroundAction: actionReceived)
                break
            
            case .DismissAction:
                BroadcastSender
                    .shared
                    .sendBroadcast(
                        notificationDismissed: actionReceived)
                break
                
            case .DisabledAction:
                break
        }
        
        completionHandler(true)
    }
    
}
