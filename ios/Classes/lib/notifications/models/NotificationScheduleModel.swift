//
//  NotificationScheduleModel.swift
//  awesome_notifications
//
//  Created by Rafael Setragni on 05/09/20.
//

import Foundation

public class NotificationScheduleModel : AbstractModel {
        
    var initialDateTime: String?
    var crontabSchedule: String?
    var allowWhileIdle: Bool?
    var preciseSchedules: [String]?
    
    public func fromMap(arguments: [String : Any?]?) -> AbstractModel? {
        self.initialDateTime = MapUtils<String>.getValueOrDefault(reference: "initialDateTime", arguments: arguments)
        self.crontabSchedule = MapUtils<String>.getValueOrDefault(reference: "crontabSchedule", arguments: arguments)
        self.allowWhileIdle  = MapUtils<Bool>.getValueOrDefault(reference: "allowWhileIdle", arguments: arguments)
        
        if(arguments?["preciseSchedules"] != nil){
            do {
                preciseSchedules = arguments!["preciseSchedules"] as? [String]
            } catch {
                
            }
        }
        
        return self
    }
    
    public func toMap() -> [String : Any?] {
        var mapData:[String: Any?] = [:]
        
        if(initialDateTime != nil) {mapData["initialDateTime"]  = self.initialDateTime}
        if(crontabSchedule != nil) {mapData["crontabSchedule"]  = self.crontabSchedule}
        if(allowWhileIdle != nil)  {mapData["allowWhileIdle"]   = self.allowWhileIdle}
        if(preciseSchedules != nil){mapData["preciseSchedules"] = self.preciseSchedules}
        
        return mapData
    }
    
    public func validate() throws {
        if(StringUtils.isNullOrEmpty(initialDateTime) && StringUtils.isNullOrEmpty(crontabSchedule)){
            throw PushNotificationError.invalidRequiredFields(msg: "Schedule cannot have initial date time and cron rule null or empty")
        }
        
        if(initialDateTime != nil && DateUtils.parseDate(initialDateTime) == nil){
            throw PushNotificationError.invalidRequiredFields(msg: "Schedule cannot have initial date time and cron rule null or empty")
        }
        
        // TODO missing cron validation
    }
    
    
}
