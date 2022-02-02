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
    
    // ********************************************************
    
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
    
    public func notify(lifeCycle:NotificationLifeCycle){
        for listener in listeners {
            listener.onNewLifeCycleEvent(lifeCycle: lifeCycle)
        }
    }
    
    // ********************************************************
    
    private var _currentLifeCycle:NotificationLifeCycle?
    var currentLifeCycle: NotificationLifeCycle {
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
            notify(_currentLifeCycle)
            
            LifeCycleManager
                ._userDefaults?
                .setValue(_currentLifeCycle.rawValue, forKey: referenceKey)
        }
    }
    
}
