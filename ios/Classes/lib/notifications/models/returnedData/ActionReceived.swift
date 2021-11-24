//
//  ActionReceived.swift
//  awesome_notifications
//
//  Created by Rafael Setragni on 05/09/20.
//

import Foundation

public class ActionReceived : NotificationReceived {
    
    var buttonKeyPressed: String?
    var buttonKeyInput: String?

    var actionLifeCycle: NotificationLifeCycle?
    var dismissedLifeCycle: NotificationLifeCycle?
    var actionDate: String?
    var dismissedDate: String?
    
    override init(_ contentModel:NotificationContentModel?){
        super.init(contentModel)
        
        if(contentModel == nil){ return }
    }
    
    override public func fromMap(arguments: [String : Any?]?) -> AbstractModel {
        _ = super.fromMap(arguments: arguments)
        
        self.buttonKeyPressed       = MapUtils<String>.getValueOrDefault(reference: "buttonKeyPressed", arguments: arguments)
        self.buttonKeyInput     = MapUtils<String>.getValueOrDefault(reference: "buttonKeyInput", arguments: arguments)
        
        self.actionDate      = MapUtils<String>.getValueOrDefault(reference: "actionDate", arguments: arguments)
        self.dismissedDate   = MapUtils<String>.getValueOrDefault(reference: "dismissedDate", arguments: arguments)
        
        self.actionLifeCycle = EnumUtils<NotificationLifeCycle>.getEnumOrDefault(reference: "actionLifeCycle", arguments: arguments)
        self.dismissedLifeCycle = EnumUtils<NotificationLifeCycle>.getEnumOrDefault(reference: "dismissedLifeCycle", arguments: arguments)
        
        return self
    }
    
    override public func toMap() -> [String : Any?] {
        var dataMap:[String : Any?] = super.toMap()
                
        if(buttonKeyPressed != nil) {dataMap["buttonKeyPressed"] = self.buttonKeyPressed}
        if(buttonKeyInput != nil) {dataMap["buttonKeyInput"] = self.buttonKeyInput}
        
        if(actionLifeCycle != nil) {dataMap["actionLifeCycle"] = self.actionLifeCycle?.rawValue}
        if(dismissedLifeCycle != nil) {dataMap["dismissedLifeCycle"] = self.dismissedLifeCycle?.rawValue}
        if(actionDate != nil) {dataMap["actionDate"] = self.actionDate}
        if(dismissedDate != nil) {dataMap["dismissedDate"] = self.dismissedDate}
        
        return dataMap
    }
    
    override public func validate() throws {
        
    }
    
}
