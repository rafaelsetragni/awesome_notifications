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
    
    public static let shared = AwesomeEventsReceiver()
    private init(){}
    
    
    // **************************** OBSERVER PATTERN **************************************
    
    private lazy var listeners = [AwesomeEventListener]()
    
    public func subscribeOnNotificationEvents(listener:AwesomeEventListener) {
        listeners.append(listener)
    }
    
    public func unsubscribeOnNotificationEvents(listener:AwesomeEventListener) {
        if let index = listeners.firstIndex(where: {$0 === listener}) {
            listeners.remove(at: index)
        }
    }
    
    public func addNotificationEvent(
        named eventName: String,
        with notificationReceived: NotificationReceived
    ){
        for listener in listeners {
            listener.onNewAwesomeEvent(
                eventType: eventName,
                content: notificationReceived.toMap())
        }
    }
    
}
