//
//  LifeCycleManager.swift
//  Pods
//
//  Created by Rafael Setragni on 05/11/20.
//

import Foundation

public class LifeCycleManager:
    NSObject,
    UIApplicationDelegate {
    
    private let TAG = "LifeCycleManager"
    
    static let _userDefaults = UserDefaults(suiteName: Definitions.USER_DEFAULT_TAG)
    private let referenceKey: String = "currentlifeCycle"
    
    // ************** SINGLETON PATTERN ***********************
    
    static var instance:LifeCycleManager?
    public static var shared:LifeCycleManager {
        get {
            LifeCycleManager.instance =
                LifeCycleManager.instance ?? LifeCycleManager()
            return LifeCycleManager.instance!
        }
    }
    private override init(){
        super.init()
    }
    
    // ************** IOS EVENTS LISTENERS ************************
    
    var _listening = false
    public func startListeners(){
        if _listening {
            return
        }

        _listening = true
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(self.applicationDidBecomeActive),
            name: UIApplication.didBecomeActiveNotification, object: nil)
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(self.applicationWillResignActive),
            name: UIApplication.willResignActiveNotification, object: nil)
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(self.applicationDidEnterBackground),
            name: UIApplication.didEnterBackgroundNotification, object: nil)
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(self.applicationWillTerminate),
            name: UIApplication.willTerminateNotification, object: nil)
        
        if !SwiftUtils.isRunningOnExtension() {
            currentLifeCycle = .AppKilled
        }
    }
    
    deinit {
        if _listening {
            NotificationCenter.default.removeObserver(self)
        }
    }
    
    // ************** OBSERVER PATTERN ************************
    
    private lazy var listeners = [AwesomeLifeCycleEventListener]()
    
    public func subscribe(listener:AwesomeLifeCycleEventListener) -> Self {
        listeners.append(listener)
        if(AwesomeNotifications.debug){
            Logger.d(TAG, "LiceCycleManager listener successfully attached to iOS")
        }
        return self
    }
    
    public func unsubscribe(listener:AwesomeLifeCycleEventListener) {
        if let index = listeners.firstIndex(where: {$0 === listener}) {
            listeners.remove(at: index)
            if(AwesomeNotifications.debug){
                Logger.d(TAG, "LiceCycleManager listener successfully removed from iOS")
            }
        }
    }
    
    private func notify(lifeCycle: NotificationLifeCycle){
        for listener in listeners {
            listener.onNewLifeCycleEvent(lifeCycle: lifeCycle)
        }
    }
    
    // ********************************************************
    
    private var _oldLifeCycle:NotificationLifeCycle?
    private var _currentLifeCycle:NotificationLifeCycle?
    
    public var currentLifeCycle: NotificationLifeCycle {
        get {
            if SwiftUtils.isRunningOnExtension() {
                if let rawName =
                        LifeCycleManager
                            ._userDefaults?
                            .string(forKey: referenceKey)
                {
                    _currentLifeCycle = EnumUtils.fromString(rawName)
                }
            }
            return _currentLifeCycle ?? NotificationLifeCycle.AppKilled
        }
        set {
            _currentLifeCycle = newValue
            
            LifeCycleManager
                ._userDefaults?
                .setValue(newValue.rawValue, forKey: referenceKey)
            
            if _currentLifeCycle == .Foreground {
                _hasGoneForeground = true
            }
            
            if _currentLifeCycle != _oldLifeCycle {
                _oldLifeCycle = _currentLifeCycle
                notify(lifeCycle: newValue)
                if AwesomeNotifications.debug {
                    Logger.d(TAG, "App is now "+newValue.rawValue)
                }
            }
        }
    }
    
    var _isOutOfFocus = false
    public var isOutOfFocus:Bool {
        get {
            return _isOutOfFocus
        }
    }
    
    var _hasGoneForeground = false
    public var hasGoneForeground:Bool {
        get {
            return _hasGoneForeground
        }
    }
    
    // ******************************  IOS LIFECYCLE EVENTS  ***********************************
    
    public func applicationDidBecomeActive(_ application: UIApplication) {
        currentLifeCycle = .Foreground
        _isOutOfFocus = false
    }
    
    public func applicationWillResignActive(_ application: UIApplication) {
        _isOutOfFocus = true
    }
    
    public func applicationDidEnterBackground(_ application: UIApplication) {
        currentLifeCycle = hasGoneForeground ? .Background : .AppKilled
    }
    
    public func applicationWillTerminate(_ application: UIApplication) {
        currentLifeCycle = .AppKilled
    }
    
}
