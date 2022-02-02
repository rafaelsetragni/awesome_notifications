//
//  BroadcastSender.swift
//  awesome_notifications
//
//  Created by CardaDev on 02/02/22.
//

import Foundation

class BroadcastSender {
    
    private let TAG = "BroadcastSender"
    
    // ************** SINGLETON PATTERN ***********************
    
    public static let shared = BroadcastSender()
    private init(){}
    
    // ********************************************************
    
    public func sendBroadcast(notificationCreated notificationReceived: NotificationReceived){
        if LifeCycleManager.shared.currentLifeCycle == .AppKilled {
            CreatedManager.saveCreated(received: notificationReceived)
        }
        else {
            AwesomeEventsReceiver
                .shared
                .addNotificationEvent(
                    named: Definitions.CHANNEL_METHOD_NOTIFICATION_CREATED,
                    with: notificationReceived)
        }
    }
    
    public func sendBroadcast(notificationDisplayed notificationReceived: NotificationReceived){
        if LifeCycleManager.shared.currentLifeCycle == .AppKilled {
            DisplayedManager.saveDisplayed(received: notificationReceived)
        }
        else {
            AwesomeEventsReceiver
                .shared
                .addNotificationEvent(
                    named: Definitions.CHANNEL_METHOD_NOTIFICATION_DISPLAYED,
                    with: notificationReceived)
        }
    }
    
    public func sendBroadcast(notificationDismissed actionReceived: ActionReceived){
        if LifeCycleManager.shared.currentLifeCycle == .AppKilled {
            DismissedManager.saveDismissed(received: actionReceived)
        }
        else {
            AwesomeEventsReceiver
                .shared
                .addNotificationEvent(
                    named: Definitions.CHANNEL_METHOD_NOTIFICATION_DISMISSED,
                    with: actionReceived)
        }
    }
    
    public func sendBroadcast(actionReceived: ActionReceived){
        if LifeCycleManager.shared.currentLifeCycle == .AppKilled {
            ActionManager.saveAction(received: actionReceived)
        }
        else {
            AwesomeEventsReceiver
                .shared
                .addNotificationEvent(
                    named: Definitions.CHANNEL_METHOD_RECEIVED_ACTION,
                    with: actionReceived)
        }
    }
    
    public func sendBroadcast(silentAction: ActionReceived){
        AwesomeEventsReceiver
            .shared
            .addNotificationEvent(
                named: Definitions.CHANNEL_METHOD_SILENT_ACTION,
                with: silentAction)
    }
    
    public func enqueue(silentAction actionReceived: ActionReceived){
        Bac
    }
    
    public func enqueue(silentBackgroundAction actionReceived: ActionReceived){
        Bac
    }
    
}
