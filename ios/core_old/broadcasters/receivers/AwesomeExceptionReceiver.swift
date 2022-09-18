//
//  AwesomeExceptionReceiver.swift
//  awesome_notifications
//
//  Created by CardaDev on 08/04/22.
//

import Foundation

public class AwesomeExceptionReceiver  {
    
    let TAG = "AwesomeExceptionReceiver"
    
    // ******************** SINGLETON PATTERN *****************************
    
    static var instance:AwesomeExceptionReceiver?
    public static var shared:AwesomeExceptionReceiver {
        get {
            AwesomeExceptionReceiver.instance =
                AwesomeExceptionReceiver.instance ?? AwesomeExceptionReceiver()
            return AwesomeExceptionReceiver.instance!
        }
    }
    private init(){}
    
    
    // ******************* OBSERVER PATTERN *******************************
    
    private lazy var eventListeners = [AwesomeExceptionListener]()
    
    public func subscribeOnNotificationEvents(listener:AwesomeExceptionListener) -> Self {
        eventListeners.append(listener)
        
        if AwesomeNotifications.debug {
            Logger.d(TAG, String(describing: listener) + " subscribed to receive exception events")
        }
        return self
    }
    
    public func unsubscribeOnNotificationEvents(listener:AwesomeExceptionListener) -> Self {
        if let index = eventListeners.firstIndex(where: {$0 === listener}) {
            eventListeners.remove(at: index)
            if AwesomeNotifications.debug {
                Logger.d(TAG, String(describing: listener) + " unsubscribed from exception events")
            }
        }
        return self
    }
    
    public func notifyExceptionEvent(
        fromClassName className:String,
        withAwesomeException awesomeException:AwesomeNotificationsException
    ){
        Logger.e(TAG, awesomeException.message)
        for listener in eventListeners {
            listener.onNewAwesomeException(
                fromClassName: className,
                withAwesomeException: awesomeException)
        }
    }
    
    
}
