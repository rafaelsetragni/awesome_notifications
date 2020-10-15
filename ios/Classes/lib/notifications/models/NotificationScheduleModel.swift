//
//  NotificationScheduleModel.swift
//  awesome_notifications
//
//  Created by Rafael Setragni on 05/09/20.
//

import Foundation

public class NotificationScheduleModel : AbstractModel {
    
    var _crontabSchedule: String?
    var cronHelper: CronExpression?
        
    var initialDateTime: String?
    var crontabSchedule: String? {
        get {
            return _crontabSchedule
        }
        set(value) {
            if(StringUtils.isNullOrEmpty(value)){
                cronHelper = nil
            }
            else {
                do {
                    cronHelper = try CronExpression(value!)
                }
                catch {
                    cronHelper = nil
                }
            }
        }
    }
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
        if(
            StringUtils.isNullOrEmpty(initialDateTime) &&
            StringUtils.isNullOrEmpty(crontabSchedule) &&
            ListUtils.isEmptyLists(preciseSchedules as [AnyObject]?)
        ){
            throw PushNotificationError.invalidRequiredFields(msg: "Schedule cannot have initial date time and cron rule null or empty")
        }
        
        if(initialDateTime != nil && DateUtils.parseDate(initialDateTime) == nil){
            throw PushNotificationError.invalidRequiredFields(msg: "Schedule initial date is invalid")
        }
        
        if(!(cronHelper?.isValidExpression ?? true)){
            throw PushNotificationError.invalidRequiredFields(msg: "Schedule cron expression is invalid")
        }
        
        if(preciseSchedules != nil){
            for schedule in preciseSchedules! {
                if DateUtils.parseDate(schedule) == nil {
                    throw PushNotificationError.invalidRequiredFields(msg: "Precise schedule '"+schedule+"' is invalid")
                }
            }
        }
    }
    
    
}
