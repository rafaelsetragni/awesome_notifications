//
//  NotificationIntervalModel.swift
//  awesome_notifications
//
//  Created by Rafael Setragni on 09/03/21.
//

import Foundation

public class NotificationIntervalModel : NotificationScheduleModel {
    
    var interval: Int?
    var repeats: Bool?
    
    public func fromMap(arguments: [String : Any?]?) -> AbstractModel? {
        
        self.interval = MapUtils<Int>.getValueOrDefault(reference: "interval", arguments: arguments)
        self.repeats = MapUtils<Bool>.getValueOrDefault(reference: "repeats", arguments: arguments)
        
        return self
    }
    
    public func toMap() -> [String : Any?] {
        var mapData:[String: Any?] = [:]
        
        if(interval != nil) {mapData["interval"]  = self.interval}
        if(repeats != nil) {mapData["repeats"]  = self.repeats}
        
        return mapData
    }
    
    public func validate() throws {
        
        if(IntUtils.isNullOrEmpty(interval) || interval! <= 0){
            throw AwesomeNotificationsException.invalidRequiredFields(msg: "Interval cannot be null, empty or zero")
        }
    }
    
    public func getUNNotificationTrigger() -> UNNotificationTrigger? {
        
        do {
            try validate();
            
            let trigger = UNTimeIntervalNotificationTrigger( timeInterval: Double(interval!), repeats: repeats! )
            
            return trigger
            
        } catch {
            debugPrint("\(error)")
        }
        return nil
    }
}
