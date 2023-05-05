//
//  DefaultsManager.swift
//  awesome_notifications
//
//  Created by CardaDev on 31/01/22.
//

import Foundation

public class DefaultsManager {
    
    let TAG = "DefaultsManager"
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
    
    public func setDefaultGroupTest() {
        userDefaults.setValue("pass", forKey: Definitions.TEST_APP_GROUP)
    }
    
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
            
            guard let dateText:String = dateText else {
                return RealDateTime.init(fromTimeZone: RealDateTime.utcTimeZone)
            }
            
            Logger.d(TAG, "Awesome Notifications - last displayed date : \(dateText)")
            
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
    
    public func checkIfAppGroupConnected() {
        let valueRestored:String? = userDefaults.object(forKey: Definitions.TEST_APP_GROUP) as? String
        if valueRestored?.isEmpty ?? true {
            Logger.e(TAG, "App Groups are not successfully connected. Please, use '\(Definitions.USER_DEFAULT_TAG)' group name in your App Groups Capabilities.")
        }
    }
}
