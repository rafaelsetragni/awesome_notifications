//
//  ActionReceived.swift
//  awesome_notifications
//
//  Created by Rafael Setragni on 29/08/20.
//

import Foundation

public class ActionReceived : NotificationReceived {
    
    var actionKey: String?
    var buttonInput: String?

    var actionLifeCycle: NotificationLifeCycle?
    var actionDate: String?
    
    override init(_ contentModel:NotificationContentModel?){
        
        if(contentModel == nil){ return }
        super.init(contentModel)
        
        self.actionDate = DateUtils.getUTCDate()
    }
    
    override func fromMap(arguments: [String : Any?]?) -> AbstractModel {
        super.fromMap(arguments: arguments)
        
        self.actionKey       = MapUtils.getValueOrDefault(type: String.self, reference: "actionKey", arguments: arguments)
        self.buttonInput     = MapUtils.getValueOrDefault(type: String.self, reference: "buttonInput", arguments: arguments)
        self.actionLifeCycle = MapUtils.getEnumOrDefault(type: NotificationLifeCycle.self, reference: "actionLifeCycle", arguments: arguments)
        
        return self
    }
    
    override func toMap() -> [String : Any?] {
        var dataMap:[String : Any?] = super.toMap()
                
        if(actionKey != nil) {dataMap["actionKey"] = self.actionKey}
        if(buttonInput != nil) {dataMap["buttonInput"] = self.buttonInput}
        if(actionLifeCycle != nil) {dataMap["actionLifeCycle"] = self.actionLifeCycle}
        if(actionDate != nil) {dataMap["actionDate"] = self.actionDate}
        
        return dataMap
    }
    
    override func validate() throws {
        
    }
    
}
