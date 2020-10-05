//
//  CronUtils.swift
//  awesome_notifications
//
//  Created by Rafael Setragni on 22/09/20.
//

import Foundation

public final class CronUtils {

    public static var fixedNowDate:Date?

    public static let validDateFormat:String = "yyyy-MM-dd HH:mm:ss"

    /// https://www.baeldung.com/cron-expressions
    /// <second> <minute> <hour> <day-of-month> <month> <day-of-week> <year>
    public static func getNextCalendar(
        initialDateTime:String?,
        crontabRule:String?
    ) -> Date? {

        if(StringUtils.isNullOrEmpty(initialDateTime) && StringUtils.isNullOrEmpty(crontabRule))
        { return nil }

        var calendar:Calendar = Calendar.current
        calendar.timeZone = DateUtils.utcTimeZone

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
            initialScheduleDay = DateUtils.parseDate(initialDateTime)
        }

        // if initial date is a future one, show in future. Otherwise, show now
        switch (initialScheduleDay!.compare(now).rawValue) {

            case -1: // if initial date is not a repetition and is in the past, do not show
                if(StringUtils.isNullOrEmpty(crontabRule))
                { return nil }

            case 0: // if initial date is in future, shows in future
                return initialScheduleDay
            
            case 1: // if initial date is right now, shows now
                return initialScheduleDay
            
            default:
                return initialScheduleDay
        }

        delayedNow = applyToleranceDate(now);

        if (!StringUtils.isNullOrEmpty(crontabRule)) {

            if(CronExpression.validate(cronExpression: crontabRule!)) {
                
                do {
                    let cronExpression:CronExpression = try CronExpression.init(crontabRule!)
                    let nextSchedule:Date? = cronExpression.getNextValidDate(referenceDate: now)

                    if (nextSchedule != nil && nextSchedule!.compare(delayedNow) == ComparisonResult.orderedAscending) {
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

        return now
    }

    /// Processing time tolerance
    public static func applyToleranceDate(_ initialScheduleDay: Date) -> Date {
        let delayedScheduleDay:Date = initialScheduleDay.addingTimeInterval(TimeInterval(1))
        return delayedScheduleDay
    }
}
