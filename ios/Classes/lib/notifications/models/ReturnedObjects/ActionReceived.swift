//
//  ActionReceived.swift
//  awesome_notifications
//
//  Created by Rafael Setragni on 05/09/20.
//

import Foundation

public class ActionReceived : NotificationReceived {
    
    var actionKey: String?
    var actionInput: String?

    var actionLifeCycle: NotificationLifeCycle?
    var actionDate: String?
    
    override init(_ contentModel:NotificationContentModel?){
        super.init(contentModel)
        
        if(contentModel == nil){ return }
        
        self.actionDate = DateUtils.getUTCDate()
    }
    
    override public func fromMap(arguments: [String : Any?]?) -> AbstractModel {
        _ = super.fromMap(arguments: arguments)
        
        self.actionKey       = MapUtils<String>.getValueOrDefault(reference: "actionKey", arguments: arguments)
        self.actionInput     = MapUtils<String>.getValueOrDefault(reference: "actionInput", arguments: arguments)
        self.actionLifeCycle = EnumUtils<NotificationLifeCycle>.getEnumOrDefault(reference: "actionLifeCycle", arguments: arguments)
        
        return self
    }
    
    override public func toMap() -> [String : Any?] {
        var dataMap:[String : Any?] = super.toMap()
                
        if(actionKey != nil) {dataMap["actionKey"] = self.actionKey}
        if(actionInput != nil) {dataMap["actionInput"] = self.actionInput}
        if(actionLifeCycle != nil) {dataMap["actionLifeCycle"] = self.actionLifeCycle?.rawValue}
        if(actionDate != nil) {dataMap["actionDate"] = self.actionDate}
        
        return dataMap
    }
    
    override public func validate() throws {
        
    }
    
}
