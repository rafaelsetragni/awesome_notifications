//
//  DateUtils.swift
//  awesome_notifications
//
//  Created by Rafael Setragni on 05/09/20.
//

import Foundation

class DateUtils {

    public static let localTimeZone :TimeZone = Date.localTimeZone()//Calendar.current.timeZone
    public static let utcTimeZone :TimeZone = TimeZone(secondsFromGMT: 0)!;

    public static func stringToDate(_ dateTime:String?, timeZone:String?) -> Date? {
        
        if(StringUtils.isNullOrEmpty(dateTime)){ return nil }
        
        guard let safeDateTime:String = dateTime else { return nil }
        
        let dateFormatter = DateFormatter()
        dateFormatter.timeZone = TimeZone(identifier: timeZone ?? DateUtils.localTimeZone.identifier)
        dateFormatter.dateFormat = Definitions.DATE_FORMAT

        let date = dateFormatter.date(from: safeDateTime)
        return date
    }
    
    public static func dateToString(_ dateTime:Date?, timeZone:String?) -> String? {
        
        if(dateTime == nil){ return nil }
        
        let dateFormatter = DateFormatter()
        dateFormatter.timeZone = TimeZone(identifier: timeZone ?? DateUtils.localTimeZone.identifier)
        dateFormatter.dateFormat = Definitions.DATE_FORMAT

        let date = dateFormatter.string(from: dateTime!)
        return date
    }

    public static func getUTCTextDate() -> String {
        let timeZone:String = DateUtils.utcTimeZone.identifier
        let dateUtc:Date = getUTCDateTime()
        return dateToString(dateUtc, timeZone: timeZone)!
    }
    
    public static func getLocalTextDate(fromTimeZone timeZone: String) -> String? {
        return dateToString(getLocalDateTime(fromTimeZone: timeZone), timeZone: timeZone)
    }
    
    public static func getUTCDateTime() -> Date {
        return Date()
    }
    
    public static func getLocalDateTime(fromTimeZone timeZone: String?) -> Date? {
        return Date() // there is no true timezone component into Dates in swift
    }
    
    public static func getNextValidDate(
        scheduleModel:NotificationScheduleModel,
        fixedDate:String?,
        timeZone:String = DateUtils.utcTimeZone.identifier) -> Date? {
        
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: timeZone)!
        
        let fixedDateTime:Date =
            fixedDate?.toDate(fromTimeZone: timeZone) ??
            DateUtils.getLocalDateTime(fromTimeZone: timeZone) ??
            DateUtils.getUTCDateTime()
        
        var nextValidDate:Date?
        if scheduleModel is NotificationIntervalModel {
            let scheduleInterval:NotificationIntervalModel = scheduleModel as! NotificationIntervalModel
            nextValidDate = calendar.date(byAdding: .second, value: scheduleInterval.interval!, to: fixedDateTime)
        } else
        if scheduleModel is NotificationCalendarModel {
            let scheduleCalendar:NotificationCalendarModel = scheduleModel as! NotificationCalendarModel
            nextValidDate = calendar.nextDate(after: fixedDateTime, matching: scheduleCalendar.toDateComponents(), matchingPolicy: .nextTime)
        }

        return nextValidDate
    }
    
    public static func getLastValidDate(
        scheduleModel:NotificationScheduleModel,
        fixedDate:String?,
        timeZone:String = DateUtils.localTimeZone.identifier) -> Date? {
        
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: timeZone)!
        
        let fixedDateTime:Date =
            fixedDate?.toDate(fromTimeZone: timeZone) ??
            DateUtils.getLocalDateTime(fromTimeZone: timeZone) ??
            DateUtils.getUTCDateTime()
        
        var lastValidDate:Date?
        if scheduleModel is NotificationIntervalModel {
            let scheduleInterval:NotificationIntervalModel = scheduleModel as! NotificationIntervalModel
            lastValidDate = calendar.date(byAdding: .second, value: -scheduleInterval.interval!, to: fixedDateTime)
        } else
        if scheduleModel is NotificationCalendarModel {
            let scheduleCalendar:NotificationCalendarModel = scheduleModel as! NotificationCalendarModel
            lastValidDate = calendar.nextDate(after: fixedDateTime, matching: scheduleCalendar.toDateComponents(), matchingPolicy: .previousTimePreservingSmallerComponents)
        }

        return lastValidDate
    }
}
