//
//  NotificationIntervalModel.swift
//  awesome_notifications
//
//  Created by Rafael Setragni on 09/03/21.
//

import Foundation

public class NotificationIntervalModel : NotificationScheduleModel {
    
    static let TAG = "NotificationIntervalModel"
    
    var _createdDate:RealDateTime?
    var _timeZone:TimeZone?
    
    /// Initial reference date from schedule
    public var createdDate:RealDateTime? { get{
        return _createdDate
    } set(newValue){
        _createdDate = newValue
    }}
    
    /// Time zone reference date from schedule (abbreviation)
    public var timeZone:TimeZone? { get{
        return _timeZone
    } set(newValue){
        _timeZone = newValue
    }}
    
    /// Field number for get and set indicating the year.
    var interval:Int?
    /// Specify false to deliver the notification one time. Specify true to reschedule the notification request each time the notification is delivered.
    var repeats:Bool?
    
    public init(){}
    
    public func fromMap(arguments: [String : Any?]?) -> AbstractModel? {
        
        self._timeZone = MapUtils<TimeZone>.getValueOrDefault(reference: Definitions.NOTIFICATION_SCHEDULE_TIMEZONE, arguments: arguments)
        self.createdDate = MapUtils<RealDateTime>.getRealDateOrDefault(reference: Definitions.NOTIFICATION_SCHEDULE_INITIAL_DATE, arguments: arguments, defaultTimeZone: RealDateTime.utcTimeZone)
        self.interval = MapUtils<Int>.getValueOrDefault(reference: Definitions.NOTIFICATION_SCHEDULE_INTERVAL, arguments: arguments)
        self.repeats  = MapUtils<Bool>.getValueOrDefault(reference: Definitions.NOTIFICATION_SCHEDULE_REPEATS, arguments: arguments)
        
        return self
    }
    
    public func toMap() -> [String : Any?] {
        var mapData:[String: Any?] = [:]
        
        if(_timeZone != nil) {mapData[Definitions.NOTIFICATION_SCHEDULE_TIMEZONE] = TimeZoneUtils.shared.timeZoneToString(timeZone: self._timeZone)}
        if(createdDate != nil) {mapData[Definitions.NOTIFICATION_SCHEDULE_INITIAL_DATE] = self.createdDate!.description}
        if(interval != nil) {mapData[Definitions.NOTIFICATION_SCHEDULE_INTERVAL] = self.interval}
        if(repeats != nil) {mapData[Definitions.NOTIFICATION_SCHEDULE_REPEATS]  = self.repeats}
        
        return mapData
    }
    
    public func validate() throws {
        
        if(IntUtils.isNullOrEmpty(interval) || interval! <= 5){
            throw ExceptionFactory
                .shared
                .createNewAwesomeException(
                    className: NotificationIntervalModel.TAG,
                    code: ExceptionCode.CODE_INVALID_ARGUMENTS,
                    message: "Interval is required and must be greater than 5",
                    detailedCode: ExceptionCode.DETAILED_INVALID_ARGUMENTS+".notificationInterval.interval")
        }

        if((repeats ?? false) && interval! < 60){
            throw ExceptionFactory
                .shared
                .createNewAwesomeException(
                    className: NotificationIntervalModel.TAG,
                    code: ExceptionCode.CODE_INVALID_ARGUMENTS,
                    message: "time interval must be at least 60 if repeating",
                    detailedCode: ExceptionCode.DETAILED_INVALID_ARGUMENTS+".notificationInterval.interval")
        }
    }
    
    public func getUNNotificationTrigger() -> UNNotificationTrigger? {
        
        do {
            try validate();
            let trigger = UNTimeIntervalNotificationTrigger( timeInterval: Double(interval!), repeats: repeats! )
            
            return trigger
            
        } catch {
            Logger.e("NotificationIntervalModel", error.localizedDescription)
        }
        return nil
    }
    
    public func getNextValidDate() -> RealDateTime? {
        let timeZone:TimeZone = self.timeZone ?? TimeZone.current
        
        let referenceDate:RealDateTime =
            (self.repeats ?? true) ?
                RealDateTime(fromTimeZone: timeZone) :
                createdDate ?? RealDateTime(fromTimeZone: timeZone)
        
        guard let nextValidDate:Date =
            DateUtils
                .shared
                .getNextValidDate(
                    fromScheduleModel: self,
                    withReferenceDate: referenceDate)        
        else { return nil }
        
        return RealDateTime.init(
            fromDate: nextValidDate,
            inTimeZone: timeZone)
    }
    
    public func hasNextValidDate() -> Bool {
        
        let timeZone:TimeZone = self.timeZone ?? TimeZone.current
        let nowDate:RealDateTime? = RealDateTime(fromTimeZone: timeZone)
        
        let nextValidDate:RealDateTime? = getNextValidDate()
        
        return
            nil != nextValidDate &&
            nil != nowDate &&
            nextValidDate! > nowDate!
            
    }
}
