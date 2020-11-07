//
//  LifeCycleManager.swift
//  Pods
//
//  Created by Rafael Setragni on 05/11/20.
//

import Foundation

public class LifeCycleManager {
    
    static let _sharedInstance = UserDefaults(suiteName: Definitions.USER_DEFAULT_TAG)
    
    public static func getLifeCycle(referenceKey:String) -> NotificationLifeCycle {
        let rawName = _sharedInstance?.string(forKey: referenceKey)
        return rawName == nil ? NotificationLifeCycle.AppKilled : EnumUtils.fromString(rawName)
    }
    
    public static func setLifeCycle(referenceKey:String, lifeCycle:NotificationLifeCycle){
        _sharedInstance?.setValue(lifeCycle.rawValue, forKey: referenceKey)
    }
    
}
