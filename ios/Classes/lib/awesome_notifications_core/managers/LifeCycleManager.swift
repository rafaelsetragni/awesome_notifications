//
//  LifeCycleManager.swift
//  Pods
//
//  Created by Rafael Setragni on 05/11/20.
//

import Foundation

public class LifeCycleManager {
    
    private let TAG = "LifeCycleManager"
    
    static let _userDefaults = UserDefaults(suiteName: Definitions.USER_DEFAULT_TAG)
    private let referenceKey: String = "currentlifeCycle"
    
    // ************** SINGLETON PATTERN ***********************
    
    public static let shared: LifeCycleManager = LifeCycleManager()
    private init(){}
    
    
    // ************** OBSERVER PATTERN ************************
    
    private lazy var listeners = [AwesomeLifeCycleEventListener]()
    
    public func subscribe(listener:AwesomeLifeCycleEventListener) -> Self {
        listeners.append(listener)
        return self
    }
    
    public func unsubscribe(listener:AwesomeLifeCycleEventListener) {
        if let index = listeners.firstIndex(where: {$0 === listener}) {
            listeners.remove(at: index)
        }
    }
    
    public func notify(lifeCycle: NotificationLifeCycle){
        for listener in listeners {
            listener.onNewLifeCycleEvent(lifeCycle: lifeCycle)
        }
    }
    
    // ********************************************************
    
    private var _currentLifeCycle:NotificationLifeCycle?
    public var currentLifeCycle: NotificationLifeCycle {
        get {
            if _currentLifeCycle == nil {
                if let rawName =
                        LifeCycleManager
                            ._userDefaults?
                            .string(forKey: referenceKey)
                {
                    _currentLifeCycle = EnumUtils.fromString(rawName)
                }
                else {
                    _currentLifeCycle = NotificationLifeCycle.AppKilled
                }
                
            }
            return _currentLifeCycle ?? NotificationLifeCycle.AppKilled
        }
        set {
            _currentLifeCycle = newValue
            notify(lifeCycle: newValue)
            
            LifeCycleManager
                ._userDefaults?
                .setValue(newValue.rawValue, forKey: referenceKey)
        }
    }
    
    // ******************************  IOS LIFECYCLE EVENTS  ***********************************
    
    
    public func applicationDidBecomeActive(_ application: UIApplication) {
        notify(lifeCycle: NotificationLifeCycle.Foreground)
        
        if AwesomeNotifications.debug {
            Log.d(
                TAG,
                "Notification lifeCycle: (DidBecomeActive) "
                + currentLifeCycle.rawValue )
        }
    }
    
    public func applicationWillResignActive(_ application: UIApplication) {
        // applicationWillTerminate is not always get called, so the Background state is not correct defined in this cases
        // notify(lifeCycle: NotificationLifeCycle.Foreground)
        notify(lifeCycle: NotificationLifeCycle.Background)
        
        if(AwesomeNotifications.debug){
            Log.d(
                SwiftAwesomeNotificationsPlugin.TAG,
                "Notification lifeCycle: (WillResignActive) "
                    + currentLifeCycle.rawValue)
        }
    }
    
    public func applicationDidEnterBackground(_ application: UIApplication) {
        // applicationWillTerminate is not always get called, so the AppKilled state is not correct defined in this cases
        // notify(lifeCycle: NotificationLifeCycle.Background)
        notify(lifeCycle: NotificationLifeCycle.AppKilled)
        
        if(AwesomeNotifications.debug){
            Log.d(
                SwiftAwesomeNotificationsPlugin.TAG,
                "Notification lifeCycle: (DidEnterBackground) "
                    + currentLifeCycle.rawValue)
        }
    }
    
    public func applicationWillEnterForeground(_ application: UIApplication) {
        notify(lifeCycle: NotificationLifeCycle.Background)
        
        if(AwesomeNotifications.debug){
            Log.d(
                SwiftAwesomeNotificationsPlugin.TAG,
                "Notification lifeCycle: (WillEnterForeground) "
                    + currentLifeCycle.rawValue)
        }
    }
    
    public func applicationWillTerminate(_ application: UIApplication) {
        notify(lifeCycle: NotificationLifeCycle.AppKilled)
        
        if(AwesomeNotifications.debug){
            Log.d(
                SwiftAwesomeNotificationsPlugin.TAG,
                "Notification lifeCycle: (WillTerminate) "
                    + currentLifeCycle.rawValue)
        }
    }
    
}
