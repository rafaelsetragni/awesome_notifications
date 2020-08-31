//
//  NotificationScheduleModel.swift
//  awesome_notifications
//
//  Created by Rafael Setragni on 29/08/20.
//

import Foundation

public class NotificationScheduleModel : AbstractModel {
        
    var initialDateTime: String?
    var crontabSchedule: String?
    var allowWhileIdle: Bool?
    
    func fromMap(arguments: [String : Any?]?) -> AbstractModel {
        self.initialDateTime = MapUtils<String>.getValueOrDefault(reference: "initialDateTime", arguments: arguments)
        self.crontabSchedule = MapUtils<String>.getValueOrDefault(reference: "crontabSchedule", arguments: arguments)
        self.allowWhileIdle  = MapUtils<Bool>.getValueOrDefault(reference: "allowWhileIdle", arguments: arguments)
        
        return self
    }
    
    func toMap() -> [String : Any?] {
        var mapData:[String: Any?] = [:]
        
        if(initialDateTime != nil) {mapData["initialDateTime"] = self.initialDateTime}
        if(crontabSchedule != nil) {mapData["crontabSchedule"] = self.crontabSchedule}
        if(allowWhileIdle != nil)  {mapData["allowWhileIdle"]  = self.allowWhileIdle}
        
        return mapData
    }
    
    func validate() throws {
        if(StringUtils.isNullOrEmpty(initialDateTime) && StringUtils.isNullOrEmpty(crontabSchedule)){
            throw PushNotificationError.invalidRequiredFields(msg: "Schedule cannot have initial date time and cron rule null or empty")
        }
        
        if(initialDateTime != nil && DateUtils.parseDate(initialDateTime) == nil){
            throw PushNotificationError.invalidRequiredFields(msg: "Schedule cannot have initial date time and cron rule null or empty")
        }
        
        // TODO missing cron validation
    }
    
    
}
