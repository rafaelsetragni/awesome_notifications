//
//  AwesomeEventsReceiver.swift
//  awesome_notifications
//
//  Created by CardaDev on 02/02/22.
//

import Foundation

class AwesomeEventsReceiver {
    
    private let TAG = "AwesomeEventsReceiver"
    
    
    // **************************** SINGLETON PATTERN *************************************
    
    static var instance:AwesomeEventsReceiver?
    public static var shared:AwesomeEventsReceiver {
        get {
            AwesomeEventsReceiver.instance =
                AwesomeEventsReceiver.instance ?? AwesomeEventsReceiver()
            return AwesomeEventsReceiver.instance!
        }
    }
    private init(){}
    
    
    // **************************** OBSERVER PATTERN **************************************
    
    private lazy var notificationEventListeners = [AwesomeNotificationEventListener]()
    
    public func subscribeOnNotificationEvents(listener:AwesomeNotificationEventListener) -> Self {
        notificationEventListeners.append(listener)
        return self
    }
    
    public func unsubscribeOnNotificationEvents(listener:AwesomeNotificationEventListener) -> Self {
        if let index = notificationEventListeners.firstIndex(where: {$0 === listener}) {
            notificationEventListeners.remove(at: index)
        }
        return self
    }
    
    private func notifyNotificationEvent(
        named eventName: String,
        with notificationReceived: NotificationReceived
    ){
        for listener in notificationEventListeners {
            listener.onNewNotificationReceived(
                eventName: eventName,
                notificationReceived: notificationReceived)
        }
    }
    
    
    // **************************** OBSERVER PATTERN **************************************
    
    private lazy var actionEventListeners = [AwesomeActionEventListener]()
    
    public func subscribeOnActionEvents(listener:AwesomeActionEventListener) {
        actionEventListeners.append(listener)
    }
    
    public func unsubscribeOnActionEvents(listener:AwesomeActionEventListener) {
        if let index = actionEventListeners.firstIndex(where: {$0 === listener}) {
            actionEventListeners.remove(at: index)
        }
    }
    
    private func notifyActionEvent(
        named eventName: String,
        with actionReceived: ActionReceived
    ){
        for listener in actionEventListeners {
            listener.onNewActionReceived(
                fromEventNamed: eventName,
                withActionReceived: actionReceived)
        }
    }
    
    // **************************** OBSERVER PATTERN **************************************
    
    
    public func addNotificationEvent(
        named eventName: String,
        with notificationReceived: NotificationReceived
    ){
        
        if notificationEventListeners.isEmpty {
            return
        }
        
        do {
            switch eventName {
                
                case Definitions.BROADCAST_CREATED_NOTIFICATION:
                    try onBroadcast(notificationCreated: notificationReceived)
                    return
                    
                case Definitions.BROADCAST_DISPLAYED_NOTIFICATION:
                    try onBroadcast(notificationDisplayed: notificationReceived)
                    return
                    
                default:
                    if AwesomeNotifications.debug {
                        Log.d(TAG, "Received unknown notification event: '\(eventName)'")
                    }
            }
        } catch {
            Log.d(TAG, "\(error).")
        }
    }
    
    public func addActionEvent(
        named eventName: String,
        with actionReceived: ActionReceived
    ){
        do {
            switch eventName {
                
                case Definitions.BROADCAST_DEFAULT_ACTION:
                    try onBroadcast(defaultAction: actionReceived)
                    return
                    
                case Definitions.BROADCAST_DISMISSED_NOTIFICATION:
                    try onBroadcast(dismissAction: actionReceived)
                    return
                    
                case Definitions.BROADCAST_SILENT_ACTION:
                    try onBroadcast(silentAction: actionReceived)
                    return
                    
                case Definitions.BROADCAST_BACKGROUND_ACTION:
                    try onBroadcast(backgroundAction: actionReceived)
                    return
                    
                default:
                    if AwesomeNotifications.debug {
                        Log.d(TAG, "Received unknown notification event: '\(eventName)'")
                    }
            }
        }
        catch {
            Log.d(TAG, "\(error).")
        }
    }
    
    private func onBroadcast(notificationCreated notificationReceived: NotificationReceived) throws {
        try notificationReceived.validate()
        
        if AwesomeNotifications.debug {
            Log.d(TAG, "Notification created")
        }
        
        notifyNotificationEvent(
            named: Definitions.EVENT_NOTIFICATION_CREATED,
            with: notificationReceived)
    }
    
    private func onBroadcast(notificationDisplayed notificationReceived: NotificationReceived) throws {
        try notificationReceived.validate()
        
        if AwesomeNotifications.debug {
            Log.d(TAG, "Notification displayed")
        }
        
        notifyNotificationEvent(
            named: Definitions.EVENT_NOTIFICATION_DISPLAYED,
            with: notificationReceived)
    }
    
    private func onBroadcast(defaultAction actionReceived: ActionReceived) throws {
        try actionReceived.validate()
        
        if AwesomeNotifications.debug {
            Log.d(TAG, "Notification action received")
        }
        
        notifyActionEvent(
            named: Definitions.EVENT_DEFAULT_ACTION,
            with: actionReceived)
    }
    
    private func onBroadcast(dismissAction actionReceived: ActionReceived) throws {
        try actionReceived.validate()
        
        if AwesomeNotifications.debug {
            Log.d(TAG, "Notification dismissed")
        }
        
        notifyActionEvent(
            named: Definitions.EVENT_NOTIFICATION_DISMISSED,
            with: actionReceived)
    }
    
    private func onBroadcast(silentAction actionReceived: ActionReceived) throws {
        try actionReceived.validate()
        
        if AwesomeNotifications.debug {
            Log.d(TAG, "Silent action received")
        }
        
        notifyActionEvent(
            named: Definitions.EVENT_SILENT_ACTION,
            with: actionReceived)
    }
    
    private func onBroadcast(backgroundAction actionReceived: ActionReceived) throws {
        try actionReceived.validate()
        
        if AwesomeNotifications.debug {
            Log.d(TAG, "Background silent action received")
        }
        
        notifyActionEvent(
            named: Definitions.EVENT_SILENT_ACTION,
            with: actionReceived)
    }
}
