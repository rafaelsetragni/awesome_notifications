//
//  NotificationIntervalModel.swift
//  awesome_notifications
//
//  Created by Rafael Setragni on 09/03/21.
//

import Foundation

public class NotificationIntervalModel : NotificationScheduleModel {
    
    var _createdDate:String?
    var _timeZone:String?
    
    /// Initial reference date from schedule
    public var createdDate:String? { get{
        return _createdDate
    } set(newValue){
        _createdDate = newValue
    }}
    
    /// Time zone reference date from schedule (abbreviation)
    public var timeZone:String? { get{
        return _timeZone
    } set(newValue){
        _timeZone = newValue
    }}
    
    /// Field number for get and set indicating the year.
    var interval:Int?
    /// Specify false to deliver the notification one time. Specify true to reschedule the notification request each time the notification is delivered.
    var repeats:Bool?
    
    public func fromMap(arguments: [String : Any?]?) -> AbstractModel? {
        
        self._timeZone = MapUtils<String>.getValueOrDefault(reference: Definitions.NOTIFICATION_SCHEDULE_TIMEZONE, arguments: arguments)
        self.createdDate = MapUtils<String>.getValueOrDefault(reference: Definitions.NOTIFICATION_SCHEDULE_INITIAL_DATE, arguments: arguments)
        self.interval = MapUtils<Int>.getValueOrDefault(reference: Definitions.NOTIFICATION_SCHEDULE_INTERVAL, arguments: arguments)
        self.repeats  = MapUtils<Bool>.getValueOrDefault(reference: Definitions.NOTIFICATION_SCHEDULE_REPEATS, arguments: arguments)
        
        return self
    }
    
    public func toMap() -> [String : Any?] {
        var mapData:[String: Any?] = [:]
        
        if(_timeZone != nil) {mapData[Definitions.NOTIFICATION_SCHEDULE_TIMEZONE] = self._timeZone}
        if(createdDate != nil) {mapData[Definitions.NOTIFICATION_SCHEDULE_INITIAL_DATE] = self.createdDate}
        if(interval != nil) {mapData[Definitions.NOTIFICATION_SCHEDULE_INTERVAL] = self.interval}
        if(repeats != nil)  {mapData[Definitions.NOTIFICATION_SCHEDULE_REPEATS]  = self.repeats}
        
        return mapData
    }
    
    public func validate() throws {
        
        if(IntUtils.isNullOrEmpty(interval) || interval! <= 0){
            throw AwesomeNotificationsException.invalidRequiredFields(msg: "Interval cannot be null, empty or zero")
        }

        if((repeats ?? false) && interval! < 60){
            throw AwesomeNotificationsException.invalidRequiredFields(msg: "time interval must be at least 60 if repeating");
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
    
    public func getNextValidDate() -> Date? {
        let timeZone:String = self.timeZone ?? DateUtils.localTimeZone.identifier
        
        return DateUtils.getNextValidDate(
            scheduleModel: self,
            fixedDate: (self.repeats ?? true) ?
                DateUtils.getLocalTextDate(fromTimeZone: timeZone ) :
                createdDate,
            timeZone: timeZone
        )
    }
    
    public func hasNextValidDate() -> Bool {
        
        let timeZone:String = self.timeZone ?? DateUtils.localTimeZone.identifier
        let nowDate:Date? = DateUtils.getLocalDateTime(fromTimeZone: timeZone)
        
        let nextValidDate:Date? = getNextValidDate()
        
        return
            nil != nextValidDate &&
            nil != nowDate &&
            nextValidDate! > nowDate!
            
    }
}
