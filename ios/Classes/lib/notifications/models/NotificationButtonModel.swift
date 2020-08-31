//
//  NotificationButtonModel.swift
//  awesome_notifications
//
//  Created by Rafael Setragni on 28/08/20.
//

import Foundation

class NotificationButtonModel : AbstractModel {
    
    var key:String?
    var icon:String?
    var label:String?
    var enabled:Bool?
    var autoCancel:Bool?
    var buttonType:ActionButtonType?
    
    func fromMap(arguments: [String : Any?]?) -> AbstractModel {
        if(arguments == nil){ return self }
        
        self.key        = MapUtils<String>.getValueOrDefault(reference: "key", arguments: arguments)
        self.icon       = MapUtils<String>.getValueOrDefault(reference: "icon", arguments: arguments)
        self.label      = MapUtils<String>.getValueOrDefault(reference: "label", arguments: arguments)
        self.enabled    = MapUtils<Bool>.getValueOrDefault(reference: "enabled", arguments: arguments)
        self.autoCancel = MapUtils<Bool>.getValueOrDefault(reference: "autoCancel", arguments: arguments)
        
        self.buttonType = MapUtils<ActionButtonType>.getEnumOrDefault(reference: "buttonType", arguments: arguments)
        
        return self
    }
    
    func toMap() -> [String : Any?] {
        var mapData:[String: Any?] = [:]
        
        if(key != nil) {mapData["key"] = self.key}
        if(key != nil) {mapData["icon"] = self.icon}
        if(key != nil) {mapData["label"] = self.label}
        if(key != nil) {mapData["enabled"] = self.enabled}
        if(key != nil) {mapData["autoCancel"] = self.autoCancel}
        
        if(key != nil) {mapData["buttonType"] = self.buttonType}
        
        return mapData
    }
    
    func validate() throws {
        
        if(StringUtils.isNullOrEmpty(key)){
            throw PushNotificationError.invalidRequiredFields(
                msg: "Button action key cannot be null or empty")
        }

        if(StringUtils.isNullOrEmpty(label)){
            throw PushNotificationError.invalidRequiredFields(
                msg: "Button label cannot be null or empty")
        }
    }
}
