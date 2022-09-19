//
//  NotificationCalendarModel.swift
//  awesome_notifications
//
//  Created by Rafael Setragni on 09/03/21.
//

import Foundation

public class NotificationCalendarModel : NotificationScheduleModel {
    
    var _createdDate:RealDateTime?
    var _timeZone:TimeZone?
    
    public init(){}
    
    /// Initial reference date from schedule
    public var createdDate:RealDateTime? { get{
        return _createdDate
    } set(newValue){
        _createdDate = newValue
    }}
    
    /// Initial reference date from schedule
    public var timeZone:TimeZone? { get{
        return _timeZone
    } set(newValue){
        _timeZone = newValue
    }}
    
    /// Field number for get and set indicating the year.
    var year:Int?
    /// Field number for get and set indicating the month.
    var month:Int?
    /// Field number for get and set indicating the day number of the month (1-31).
    var day:Int?
    /// Field number for get and set indicating the hour of the day (0-23).
    var hour:Int?
    /// Field number for get and set indicating the minute within the hour (0-59).
    var minute:Int?
    /// Field number for get and set indicating the second within the minute (0-59).
    var second:Int?
    /// Field number for get and set indicating the day of the week (1-7).
    var weekday:Int?
    /// Field number for get and set indicating the count of weeks of the month (0-53).
    var weekOfMonth:Int?
    /// Field number for get and set indicating the weeks of the year.
    var weekOfYear:Int?
    /// Specify false to deliver the notification one time. Specify true to reschedule the notification request each time the notification is delivered.
    var repeats:Bool?
    
    public func fromMap(arguments: [String : Any?]?) -> AbstractModel? {
        
        self._createdDate =
            MapUtils<RealDateTime>.getRealDateOrDefault(
                reference: Definitions.NOTIFICATION_CREATED_DATE, arguments: arguments, defaultTimeZone: RealDateTime.utcTimeZone)
        
        self._timeZone =
            MapUtils<TimeZone>.getValueOrDefault(reference: Definitions.NOTIFICATION_SCHEDULE_TIMEZONE, arguments: arguments)
        
        self.year = MapUtils<Int>.getValueOrDefault(reference: Definitions.NOTIFICATION_SCHEDULE_YEAR, arguments: arguments)
        self.month = MapUtils<Int>.getValueOrDefault(reference: Definitions.NOTIFICATION_SCHEDULE_MONTH, arguments: arguments)
        self.day = MapUtils<Int>.getValueOrDefault(reference: Definitions.NOTIFICATION_SCHEDULE_DAY, arguments: arguments)
        self.hour = MapUtils<Int>.getValueOrDefault(reference: Definitions.NOTIFICATION_SCHEDULE_HOUR, arguments: arguments)
        self.minute = MapUtils<Int>.getValueOrDefault(reference: Definitions.NOTIFICATION_SCHEDULE_MINUTE, arguments: arguments)
        self.second = MapUtils<Int>.getValueOrDefault(reference: Definitions.NOTIFICATION_SCHEDULE_SECOND, arguments: arguments)
        self.weekday = MapUtils<Int>.getValueOrDefault(reference: Definitions.NOTIFICATION_SCHEDULE_WEEKDAY, arguments: arguments)
        self.weekOfMonth = MapUtils<Int>.getValueOrDefault(reference: Definitions.NOTIFICATION_SCHEDULE_WEEKOFMONTH, arguments: arguments)
        self.weekOfYear = MapUtils<Int>.getValueOrDefault(reference: Definitions.NOTIFICATION_SCHEDULE_WEEKOFYEAR, arguments: arguments)
        
        self.repeats = MapUtils<Bool>.getValueOrDefault(reference: Definitions.NOTIFICATION_SCHEDULE_REPEATS, arguments: arguments)
        
        if (self.year ?? 0) < 0 { self.year = nil }
        if (self.month ?? 0) < 0 { self.month = nil }
        if (self.day ?? 0) < 0 { self.day = nil }
        if (self.hour ?? 0) < 0 { self.hour = nil }
        if (self.minute ?? 0) < 0 { self.minute = nil }
        if (self.second ?? 0) < 0 { self.second = nil }
        if (self.weekday ?? 0) < 0 { self.weekday = nil }
        if (self.weekOfMonth ?? 0) < 0 { self.weekOfMonth = nil }
        if (self.weekOfYear ?? 0) < 0 { self.weekOfYear = nil }
        
        // https://github.com/rafaelsetragni/awesome_notifications/issues/153#issuecomment-830732722
        if(self.weekday != nil){
            self.weekday = self.weekday == 7 ? 1 : (self.weekday! + 1)
        }

        return self
    }

    public func toMap() -> [String : Any?] {
        var mapData:[String: Any?] = [:]
        
        if(_timeZone != nil)   {mapData[Definitions.NOTIFICATION_SCHEDULE_TIMEZONE] = TimeZoneUtils.shared.timeZoneToString(timeZone: self._timeZone)}
        if(_createdDate != nil){mapData[Definitions.NOTIFICATION_CREATED_DATE] = self._createdDate!.description}

        if(year != nil)        {mapData[Definitions.NOTIFICATION_SCHEDULE_YEAR]   = self.year}
        if(month != nil)       {mapData[Definitions.NOTIFICATION_SCHEDULE_MONTH]  = self.month}
        if(day != nil)         {mapData[Definitions.NOTIFICATION_SCHEDULE_DAY]    = self.day}
        if(hour != nil)        {mapData[Definitions.NOTIFICATION_SCHEDULE_HOUR]   = self.hour}
        if(minute != nil)      {mapData[Definitions.NOTIFICATION_SCHEDULE_MINUTE] = self.minute}
        if(second != nil)      {mapData[Definitions.NOTIFICATION_SCHEDULE_SECOND] = self.second}
        if(weekday != nil)     {mapData[Definitions.NOTIFICATION_SCHEDULE_WEEKDAY]     = self.weekday == 1 ? 7 : (self.weekday! - 1)}
        if(weekOfMonth != nil) {mapData[Definitions.NOTIFICATION_SCHEDULE_WEEKOFMONTH] = self.weekOfMonth}
        if(weekOfYear != nil)  {mapData[Definitions.NOTIFICATION_SCHEDULE_WEEKOFYEAR]  = self.weekOfYear}
        if(repeats != nil)     {mapData[Definitions.NOTIFICATION_SCHEDULE_REPEATS] = self.repeats}

        return mapData
    }

    public func validate() throws {
        if(
            year == nil &&
            month == nil &&
            day == nil &&
            hour == nil &&
            minute == nil &&
            second == nil &&
            weekday == nil &&
            weekOfMonth == nil &&
            weekOfYear == nil
        ){
            throw ExceptionFactory
                .shared
                .createNewAwesomeException(
                    className: NotificationIntervalModel.TAG,
                    code: ExceptionCode.CODE_INVALID_ARGUMENTS,
                    message: "At least one time condition is required",
                    detailedCode: ExceptionCode.DETAILED_INVALID_ARGUMENTS+".notificationCalendar")
        }

        if(!(
            IntUtils.isBetween(self.year ?? 0, min: 0, max: 99999) &&
            IntUtils.isBetween(self.month ?? 1, min: 1, max: 12) &&
            IntUtils.isBetween(self.day ?? 1, min: 1, max: 31) &&
            IntUtils.isBetween(self.hour ?? 0, min: 0, max: 23) &&
            IntUtils.isBetween(self.minute ?? 0, min: 0, max: 59) &&
            IntUtils.isBetween(self.second ?? 0, min: 0, max: 59) &&
            IntUtils.isBetween(self.weekday ?? 1, min: 1, max: 7) &&
            IntUtils.isBetween(self.weekOfMonth ?? 1, min: 1, max: 6) &&
            IntUtils.isBetween(self.weekOfYear ?? 1, min: 1, max: 53)
        )){
            throw ExceptionFactory
                .shared
                .createNewAwesomeException(
                    className: NotificationIntervalModel.TAG,
                    code: ExceptionCode.CODE_INVALID_ARGUMENTS,
                    message: "The time conditions are invalid",
                    detailedCode: ExceptionCode.DETAILED_INVALID_ARGUMENTS+".notificationCalendar")
        }
    }

    public func toDateComponents() -> DateComponents {
        let dateComponents:DateComponents = DateComponents(
            timeZone: timeZone ?? TimeZone.current,
            year: year,
            month: month,
            day: day,
            hour: hour,
            minute: minute,
            second: second,
            weekday: weekday,
            weekOfMonth: weekOfMonth,
            weekOfYear: weekOfYear
        )
        return dateComponents
    }
    
    public func getNextValidDate() -> RealDateTime? {
        let timeZone:TimeZone = self.timeZone ?? TimeZone.current
        
        let referenceDate =
            (self.repeats ?? true) ?
                RealDateTime(fromTimeZone: timeZone):
                createdDate ?? RealDateTime(fromTimeZone: timeZone)
        
        guard let nextValidDate =
                    DateUtils
                        .shared
                        .getNextValidDate(
                            fromScheduleModel: self,
                            withReferenceDate: referenceDate)
        else {
            return nil
        }
        
        return RealDateTime(
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

    public func getUNNotificationTrigger() -> UNNotificationTrigger? {

        do {
            try validate();

            let trigger = UNCalendarNotificationTrigger(
                dateMatching: toDateComponents(),
                repeats: repeats!
            )
            
            return trigger
            
        } catch {
            Logger.e("NotificationCallendarModel", error.localizedDescription)
        }
        return nil
    }
}

