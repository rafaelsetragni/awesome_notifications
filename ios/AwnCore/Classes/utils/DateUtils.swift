//
//  DateUtils.swift
//  awesome_notifications
//
//  Created by Rafael Setragni on 05/09/20.
//

import Foundation

public class DateUtils {
    
    let TAG = "DateUtils"
    
    // ************** SINGLETON PATTERN ***********************
    
    static var instance:DateUtils?
    public static var shared:DateUtils {
        get {
            DateUtils.instance =
                DateUtils.instance ?? DateUtils()
            return DateUtils.instance!
        }
    }
    private init(){}
    
    // ********************************************************

    public let localTimeZone :TimeZone = Date.localTimeZone()//Calendar.current.timeZone
    public let utcTimeZone :TimeZone = TimeZone(secondsFromGMT: 0)!;

    public func stringToDate(_ dateTime:String?, timeZone:String?) -> Date? {
        
        if(StringUtils.shared.isNullOrEmpty(dateTime)){ return nil }
        
        guard let safeDateTime:String = dateTime else { return nil }
        
        let dateFormatter = DateFormatter()
        dateFormatter.timeZone = TimeZone(identifier: timeZone ?? localTimeZone.identifier)
        dateFormatter.dateFormat = Definitions.DATE_FORMAT

        let date = dateFormatter.date(from: safeDateTime)
        return date
    }
    
    public func dateToString(_ dateTime:Date?, timeZone:String?) -> String? {
        
        if(dateTime == nil){ return nil }
        
        let dateFormatter = DateFormatter()
        dateFormatter.timeZone = TimeZone(identifier: timeZone ?? localTimeZone.identifier)
        dateFormatter.dateFormat = Definitions.DATE_FORMAT

        let date = dateFormatter.string(from: dateTime!)
        return date
    }

    public func getUTCTextDate() -> String {
        let timeZone:String = utcTimeZone.identifier
        let dateUtc:Date = getUTCDateTime()
        return dateToString(dateUtc, timeZone: timeZone)!
    }
    
    public func getLocalTextDate(fromTimeZone timeZone: String) -> String? {
        return dateToString(getLocalDateTime(fromTimeZone: timeZone), timeZone: timeZone)
    }
    
    public func getUTCDateTime() -> Date {
        return Date()
    }
    
    public func getLocalDateTime(fromTimeZone timeZone: String?) -> Date? {
        return Date() // there is no true timezone component into Dates in swift
    }
    
    public func getNextValidDate(
        fromScheduleModel scheduleModel:NotificationScheduleModel,
        withReferenceDate fixedDateTime:RealDateTime
    ) -> Date? {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = fixedDateTime.timeZone
                
        var nextValidDate:Date?
        if scheduleModel is NotificationIntervalModel {
            let scheduleInterval:NotificationIntervalModel = scheduleModel as! NotificationIntervalModel
            nextValidDate = calendar.date(byAdding: .second, value: scheduleInterval.interval!, to: fixedDateTime.date)
        } else
        if scheduleModel is NotificationCalendarModel {
            let scheduleCalendar:NotificationCalendarModel = scheduleModel as! NotificationCalendarModel
            nextValidDate = calendar.nextDate(after: fixedDateTime.date, matching: scheduleCalendar.toDateComponents(), matchingPolicy: .nextTime)
        }

        return nextValidDate
    }
    
    public func getLastValidDate(
        scheduleModel:NotificationScheduleModel,
        fixedDateTime:RealDateTime
    ) -> RealDateTime? {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = scheduleModel.timeZone ?? RealDateTime.utcTimeZone
        
        var lastValidDate:Date?
        if scheduleModel is NotificationIntervalModel {
            let scheduleInterval:NotificationIntervalModel = scheduleModel as! NotificationIntervalModel
            lastValidDate = calendar.date(byAdding: .second, value: -scheduleInterval.interval!, to: fixedDateTime.date)
        } else
        if scheduleModel is NotificationCalendarModel {
            let scheduleCalendar:NotificationCalendarModel = scheduleModel as! NotificationCalendarModel
            let shiftedFixedDate = fixedDateTime.shiftTimeZone(toTimeZone: scheduleCalendar.timeZone!)
            lastValidDate = calendar.nextDate(
                after: shiftedFixedDate.date,
                matching: scheduleCalendar.toDateComponents(),
                matchingPolicy: .previousTimePreservingSmallerComponents,
                repeatedTimePolicy: .first,
                direction: .backward)
        }

        if lastValidDate == nil {
            return nil
        }
        return RealDateTime.init(fromDate: lastValidDate!, inTimeZone: fixedDateTime.timeZone)
    }
}
