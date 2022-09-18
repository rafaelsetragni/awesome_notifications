//
//  NotificationModel.swift
//  awesome_notifications
//
//  Created by Rafael Setragni on 05/09/20.
//

import Foundation

public class NotificationModel : AbstractModel {
    
    private static let TAG = "NotificationModel"
    
    public var content:NotificationContentModel?
    public var actionButtons:[NotificationButtonModel]?
    public var schedule:NotificationScheduleModel?
    public var importance:NotificationImportance?
    
    public var nextValidDate:RealDateTime?
    
    public init(){}
    
    public func fromMap(arguments: [String : Any?]?) -> AbstractModel? {
        
        do {
            self.content = extractNotificationContent(Definitions.NOTIFICATION_MODEL_CONTENT, arguments)
            
            if(self.content == nil){ return nil }
            
            self.schedule = try extractNotificationSchedule(Definitions.NOTIFICATION_MODEL_SCHEDULE, arguments)
            self.actionButtons = extractNotificationButtons(Definitions.NOTIFICATION_MODEL_BUTTONS, arguments)
            
            return self
        
        }
        catch {
            Logger.e("NotificationModel", error.localizedDescription)
        }
            
        return nil
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
        guard let map:[String:Any?] = arguments?[reference] as? [String:Any?] else { return nil }
        if(map.isEmpty){ return nil }
        return NotificationContentModel().fromMap(arguments: map) as? NotificationContentModel
    }
    
    func extractNotificationSchedule(_ reference:String, _ arguments:[String:Any?]?) throws -> NotificationScheduleModel? {
        guard let map:[String:Any?] = arguments?[reference] as? [String:Any?] else { return nil }
        if(map.isEmpty){ return nil }
        
        if(
            map[Definitions.NOTIFICATION_CRONTAB_EXPRESSION] != nil ||
            map[Definitions.NOTIFICATION_PRECISE_SCHEDULES] != nil ||
            map[Definitions.NOTIFICATION_INITIAL_DATE_TIME] != nil ||
            map[Definitions.NOTIFICATION_EXPIRATION_DATE_TIME] != nil
        ){
            throw ExceptionFactory
                    .shared
                    .createNewAwesomeException(
                        className: NotificationModel.TAG,
                        code: ExceptionCode.CODE_INVALID_ARGUMENTS,
                        message: "Crontab schedules are not available for iOS",
                        detailedCode: ExceptionCode.DETAILED_INVALID_ARGUMENTS+".crontab.ios")
        }
        
        if map["interval"] != nil {
            return NotificationIntervalModel().fromMap(arguments: map) as? NotificationScheduleModel
        }
        else {
            return NotificationCalendarModel().fromMap(arguments: map) as? NotificationScheduleModel
        }
    }
    
    func extractNotificationButtons(_ reference:String, _ arguments:[String:Any?]?) -> [NotificationButtonModel]? {
        guard let actionButtonsData:[[String:Any?]] = arguments?[reference] as? [[String:Any?]] else { return nil }
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
