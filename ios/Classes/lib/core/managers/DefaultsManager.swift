//
//  DefaultsManager.swift
//  awesome_notifications
//
//  Created by CardaDev on 31/01/22.
//

import Foundation

class DefaultsManager {
    
    static let TAG = "DefaultsManager"
    let userDefaults:UserDefaults = UserDefaults(suiteName: Definitions.USER_DEFAULT_TAG)!
    
    // ************** SINGLETON PATTERN ***********************
    
    static var instance:DefaultsManager?
    public static var shared:DefaultsManager {
        get {
            DefaultsManager.instance =
                DefaultsManager.instance ?? DefaultsManager()
            return DefaultsManager.instance!
        }
    }
    private init(){}
    
    // ********************************************************
    
    public var debug:Bool {
        get { return Bool(userDefaults.object(forKey: Definitions.INITIALIZE_DEBUG_MODE) as? Bool ?? false) }
        set { userDefaults.setValue(newValue, forKey: Definitions.INITIALIZE_DEBUG_MODE) }
    }
    
    public var actionCallback:Int64 {
        get { return Int64(userDefaults.object(forKey: Definitions.ACTION_HANDLE) as? Int64 ?? 0) }
        set { userDefaults.setValue(newValue, forKey: Definitions.ACTION_HANDLE) }
    }
    
    public var backgroundCallback:Int64 {
        get { return Int64(userDefaults.object(forKey: Definitions.BACKGROUND_HANDLE) as? Int64 ?? 0) }
        set { userDefaults.setValue(newValue, forKey: Definitions.BACKGROUND_HANDLE) }
    }
    
    public var defaultIcon:String? {
        get { return userDefaults.object(forKey: Definitions.DEFAULT_ICON) as? String }
        set { userDefaults.setValue(newValue, forKey: Definitions.DEFAULT_ICON) }
    }
    
    public var extensionClassName:String? {
        get { return userDefaults.object(forKey: Definitions.AWESOME_EXTENSION_CLASS_NAME) as? String }
        set { userDefaults.setValue(newValue, forKey: Definitions.AWESOME_EXTENSION_CLASS_NAME) }
    }
    
    public var lastDisplayedDate:RealDateTime {
        get {
            let dateText:String? = userDefaults.object(forKey: Definitions.AWESOME_LAST_DISPLAYED_DATE) as? String
            
            Logger.d(DefaultsManager.TAG, "Awesome Notifications - UTC timezone : \(RealDateTime.utcTimeZone)")
            Logger.d(DefaultsManager.TAG, "Awesome Notifications - Local timezone : \(DateUtils.shared.localTimeZone)")
            
            guard let dateText:String = dateText else {
                return RealDateTime.init(fromTimeZone: RealDateTime.utcTimeZone)
            }
            
            Logger.d(DefaultsManager.TAG, "Awesome Notifications - last displayed date : \(dateText)")
            
            guard let lastDate:RealDateTime =
                                    RealDateTime.init(
                                        fromDateText: dateText,
                                        defaultTimeZone: RealDateTime.utcTimeZone)
            else {
                return RealDateTime.init(fromTimeZone: RealDateTime.utcTimeZone)
            }
            
            return lastDate
        }
        set { userDefaults.setValue(newValue.description, forKey: Definitions.AWESOME_LAST_DISPLAYED_DATE) }
    }
    
    
    public func registerLastDisplayedDate(){
        self.lastDisplayedDate = RealDateTime.init(fromTimeZone: RealDateTime.utcTimeZone)
    }
}
