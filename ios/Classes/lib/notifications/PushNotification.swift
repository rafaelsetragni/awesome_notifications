//
//  PushNotification.swift
//  awesome_notifications
//
//  Created by Rafael Setragni on 05/09/20.
//

import Foundation

public class PushNotification : AbstractModel {
        
    var content:NotificationContentModel?
    var actionButtons:[NotificationButtonModel]?
    var schedule:NotificationScheduleModel?
    
    public func fromMap(arguments: [String : Any?]?) -> AbstractModel? {
        
        self.content = extractNotificationContent(Definitions.PUSH_NOTIFICATION_CONTENT, arguments)
        
        // required
        if(self.content == nil){ return nil }
        
        self.schedule = extractNotificationSchedule(Definitions.PUSH_NOTIFICATION_SCHEDULE, arguments)
        self.actionButtons = extractNotificationButtons(Definitions.PUSH_NOTIFICATION_BUTTONS, arguments)
        
        return self
    }
    
    public func toMap() -> [String : Any?] {
        var mapData:[String: Any?] = [:]
        
        mapData["content"] = self.content!.toMap()
        if(self.schedule != nil){ mapData["schedule"] = self.schedule!.toMap() }
        if(self.actionButtons != nil){
            var listButtons:[[String:Any?]] = []
            
            for button in self.actionButtons! {
                listButtons.append(button.toMap())
            }
            
            mapData["actionButtons"] = listButtons
        }
        
        return mapData
    }
    
    func extractNotificationContent(_ reference:String, _ arguments:[String:Any?]?) -> NotificationContentModel? {
        guard let map:[String:Any?] = arguments![reference] as? [String:Any?] else { return nil }
        if(map.isEmpty){ return nil }
        return NotificationContentModel().fromMap(arguments: map) as? NotificationContentModel
    }
    
    func extractNotificationSchedule(_ reference:String, _ arguments:[String:Any?]?) -> NotificationScheduleModel? {
        guard let map:[String:Any?] = arguments![reference] as? [String:Any?] else { return nil }
        if(map.isEmpty){ return nil }
        return NotificationScheduleModel().fromMap(arguments: map) as? NotificationScheduleModel
    }
    
    func extractNotificationButtons(_ reference:String, _ arguments:[String:Any?]?) -> [NotificationButtonModel]? {
        guard let actionButtonsData:[[String:Any?]] = arguments![reference] as? [[String:Any?]] else { return nil }
        if(actionButtonsData.isEmpty){ return nil }
        
        var actionButtons:[NotificationButtonModel] = []
        
        for buttonData in actionButtonsData {
            let button:NotificationButtonModel? = NotificationButtonModel().fromMap(arguments: buttonData) as? NotificationButtonModel
            if(button == nil){ return nil }
            actionButtons.append(button!)
        }
        
        return actionButtons
    }
    
    public func validate() throws {
        try self.content?.validate()
        try self.schedule?.validate()
        
        if(self.actionButtons != nil){
            for button in self.actionButtons! {
                try button.validate()
            }
        }
    }
}
