//
//  DefaultsManager.swift
//  awesome_notifications
//
//  Created by CardaDev on 31/01/22.
//

import Foundation

class DefaultsManager {
    
    // ************** SINGLETON PATTERN ***********************
    
    static let shared: DefaultsManager = DefaultsManager()
    private init(){}
    
    // ********************************************************
    
    public var actionCallback:Int64? {
        get {}
        set {}
    }
    
    public var backgroundCallback:Int64? {
        get {}
        set {}
    }
    
    public func setActionCallback(actionHandle:Int64) {
        
    }
    
    public func setDefaultIcon(defaultIconPath:String?) {
        
    }
    
    public func setDartBgCallback(dartBgHandle:Int64) {
        
    }
    
}
