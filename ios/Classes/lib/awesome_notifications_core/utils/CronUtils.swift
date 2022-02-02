//
//  CronUtils.swift
//  awesome_notifications
//
//  Created by Rafael Setragni on 22/09/20.
//

import Foundation

public final class CronUtils {

    public var fixedNowDate:Date?

    public let validDateFormat:String = Definitions.DATE_FORMAT

    public func getInitialCalendar() -> Calendar {
        var calendar:Calendar = Calendar.current
        calendar.timeZone = DateUtils.utcTimeZone
        return calendar
    }
    
    /// https://www.baeldung.com/cron-expressions
    /// <second> <minute> <hour> <day-of-month> <month> <day-of-week> <year>
    public func getNextCalendar(
        initialDateTime:String?,
        crontabRule:String?
    ) -> Date? {

        if(StringUtils.isNullOrEmpty(initialDateTime) && StringUtils.isNullOrEmpty(crontabRule))
        { return nil }

        var now:Date, delayedNow:Date
        if(fixedNowDate == nil){
            now = DateUtils.getUTCDateTime()
        } else {
            now = fixedNowDate!
        }

        var initialScheduleDay:Date?
        if (initialDateTime == nil) {
            initialScheduleDay = now
        }
        else {
            initialScheduleDay = DateUtils.stringToDate(initialDateTime, timeZone: DateUtils.localTimeZone.identifier)
        }

        // if initial date is a future one, show in future. Otherwise, show now
        switch (now.compare(initialScheduleDay!)) {

            case .orderedDescending: // if initial date is not a repetition and is in the past, do not show
                if(StringUtils.isNullOrEmpty(crontabRule))
                { return nil }
                break

            case .orderedSame: // if initial date is right now, shows now
                break
            
            case .orderedAscending: // if initial date is in future, shows in future
                if(StringUtils.isNullOrEmpty(crontabRule))
                { return initialScheduleDay }
                break
            
            default:
                break
        }

        delayedNow = applyToleranceDate(now);

        if (!StringUtils.isNullOrEmpty(crontabRule)) {

            if(CronExpression.validate(cronExpression: crontabRule!)) {
                
                do {
                    let cronExpression:CronExpression = try CronExpression.init(crontabRule!)
                    let nextSchedule:Date? = cronExpression.getNextValidDate(referenceDate: now)

                    if (nextSchedule != nil && delayedNow.compare(nextSchedule!) == ComparisonResult.orderedAscending) {
                        return nextSchedule
                    } else {
                        // if there is no more valid dates, remove the repetitions
                        return nil
                    }

                } catch {
                    
                }
            }

            return nil
        }

        return delayedNow
    }

    /// Processing time tolerance
    public func applyToleranceDate(_ initialScheduleDay: Date) -> Date {
        let delayedScheduleDay:Date = initialScheduleDay.addingTimeInterval(TimeInterval(1))
        return delayedScheduleDay
    }
}
