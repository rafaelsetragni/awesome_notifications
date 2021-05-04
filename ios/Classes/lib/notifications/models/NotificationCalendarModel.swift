//
//  NotificationCalendarModel.swift
//  awesome_notifications
//
//  Created by Rafael Setragni on 09/03/21.
//

import Foundation

public class NotificationCalendarModel : NotificationScheduleModel {
    
    /// Field number for get and set indicating the era, e.g., AD or BC in the Julian calendar
    var era:Int?
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
    /// Field number for get and set indicating the millisecond within the second (0-999).
    var millisecond:Int?
    /// Field number for get and set indicating the day of the week (1-7).
    var weekday:Int?
    /// Field number for get and set indicating the count of weeks of the month (0-53).
    var weekOfMonth:Int?
    /// Field number for get and set indicating the weeks of the year.
    var weekOfYear:Int?
    /// Specify false to deliver the notification one time. Specify true to reschedule the notification request each time the notification is delivered.
    var repeats:Bool?
    
    public func fromMap(arguments: [String : Any?]?) -> AbstractModel? {
        
        self.era = MapUtils<Int>.getValueOrDefault(reference: "era", arguments: arguments)
        self.year = MapUtils<Int>.getValueOrDefault(reference: "year", arguments: arguments)
        self.month = MapUtils<Int>.getValueOrDefault(reference: "month", arguments: arguments)
        self.day = MapUtils<Int>.getValueOrDefault(reference: "day", arguments: arguments)
        self.hour = MapUtils<Int>.getValueOrDefault(reference: "hour", arguments: arguments)
        self.minute = MapUtils<Int>.getValueOrDefault(reference: "minute", arguments: arguments)
        self.second = MapUtils<Int>.getValueOrDefault(reference: "second", arguments: arguments)
        self.millisecond = MapUtils<Int>.getValueOrDefault(reference: "millisecond", arguments: arguments)
        self.weekday = MapUtils<Int>.getValueOrDefault(reference: "weekday", arguments: arguments)
        self.weekOfMonth = MapUtils<Int>.getValueOrDefault(reference: "weekOfMonth", arguments: arguments)
        self.weekOfYear = MapUtils<Int>.getValueOrDefault(reference: "weekOfYear", arguments: arguments)
        
        self.repeats = MapUtils<Bool>.getValueOrDefault(reference: "repeats", arguments: arguments)
        
        if (self.era ?? 0) < 0 { self.era = nil }
        if (self.year ?? 0) < 0 { self.year = nil }
        if (self.month ?? 0) < 0 { self.month = nil }
        if (self.day ?? 0) < 0 { self.day = nil }
        if (self.hour ?? 0) < 0 { self.hour = nil }
        if (self.minute ?? 0) < 0 { self.minute = nil }
        if (self.second ?? 0) < 0 { self.second = nil }
        if (self.millisecond ?? 0) < 0 { self.millisecond = nil }
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

        if(era != nil) {mapData["era"]  = self.era}
        if(year != nil) {mapData["year"]  = self.year}
        if(month != nil) {mapData["month"]  = self.month}
        if(day != nil) {mapData["day"]  = self.day}
        if(hour != nil) {mapData["hour"]  = self.hour}
        if(minute != nil) {mapData["minute"]  = self.minute}
        if(second != nil) {mapData["second"]  = self.second}
        if(millisecond != nil) {mapData["millisecond"]  = self.millisecond}
        if(weekday != nil) {mapData["weekday"]  = self.weekday == 1 ? 7 : (self.weekday! - 1)}
        if(weekOfMonth != nil) {mapData["weekOfMonth"]  = self.weekOfMonth}
        if(weekOfYear != nil) {mapData["weekOfYear"]  = self.weekOfYear}
        if(repeats != nil) {mapData["repeats"]  = self.repeats}

        return mapData
    }

    public func validate() throws {
        if(
            era == nil &&
            year == nil &&
            month == nil &&
            day == nil &&
            hour == nil &&
            minute == nil &&
            second == nil &&
            millisecond == nil &&
            weekday == nil &&
            weekOfMonth == nil &&
            weekOfYear == nil
        ){
            throw AwesomeNotificationsException.invalidRequiredFields(msg: "At least one parameter is required")
        }

        if(!(
            IntUtils.isBetween(self.era ?? 0, min: 0, max: 99999) &&
            IntUtils.isBetween(self.year ?? 0, min: 0, max: 99999) &&
            IntUtils.isBetween(self.month ?? 1, min: 1, max: 12) &&
            IntUtils.isBetween(self.day ?? 1, min: 1, max: 31) &&
            IntUtils.isBetween(self.hour ?? 0, min: 0, max: 23) &&
            IntUtils.isBetween(self.minute ?? 0, min: 0, max: 59) &&
            IntUtils.isBetween(self.second ?? 0, min: 0, max: 59) &&
            IntUtils.isBetween(self.millisecond ?? 0, min: 0, max: 999) &&
            IntUtils.isBetween(self.weekday ?? 1, min: 1, max: 7) &&
            IntUtils.isBetween(self.weekOfMonth ?? 1, min: 1, max: 6) &&
            IntUtils.isBetween(self.weekOfYear ?? 1, min: 1, max: 53)
        )){
            throw AwesomeNotificationsException.invalidRequiredFields(msg: "Calendar values are invalid")
        }
    }

    public func toDateComponents() -> DateComponents {
        return DateComponents(
            era: era,
            year: year,
            month: month,
            day: day,
            hour: hour,
            minute: minute,
            second: second,
            nanosecond: millisecond == nil ? nil : millisecond! * 1000,
            weekday: weekday,
            weekOfMonth: weekOfMonth,
            weekOfYear: weekOfYear
        );
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
            debugPrint("\(error)")
        }
        return nil
    }
}

