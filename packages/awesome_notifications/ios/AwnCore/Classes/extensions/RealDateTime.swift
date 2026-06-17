//
//  RealDateTime.swift
//  awesome_notifications
//
//  Created by CardaDev on 13/02/22.
//

import Foundation

public class RealDateTime: Equatable, Comparable {
    
    static let units: Set<Calendar.Component> =
        Set(arrayLiteral: .year, .month, .day, .hour, .minute, .second, .timeZone)
    
    var currentDateComponents:DateComponents
    public var dateComponents:DateComponents {
        get { return currentDateComponents }
    }
    
    public static var utcTimeZone = TimeZone(secondsFromGMT: 0)!
    
    public var timeZone:TimeZone! {
        get {
            return dateComponents.timeZone!
        }
    }
    
    public init(fromDateComponents dateComponents: DateComponents){
        self.currentDateComponents = dateComponents
    }
    
    public init(fromTimeZone timeZone: TimeZone?){
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = timeZone ?? TimeZone.current
        currentDateComponents = calendar.dateComponents(RealDateTime.units, from: Date())
    }
    
    public convenience init() {
        self.init(fromTimeZone: RealDateTime.utcTimeZone)
    }
    
    public convenience init(fromDate date: Date, inTimeZone timeZone: TimeZone) {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = timeZone
        let dateComponents = calendar.dateComponents(RealDateTime.units, from: date)
        self.init(fromDateComponents: dateComponents)
    }
    
    public convenience init?(fromDateText date: String, inTimeZone timeZone: TimeZone) {
        guard let date = RealDateTime.stringToDate(date, timeZone: timeZone)
        else {
            return nil
        }
        self.init(fromDate: date, inTimeZone: timeZone)
    }
    
    public convenience init?(fromDateText date: String, inTimeZone timeZoneId: String) {
        guard let timeZone = TimeZone(identifier: timeZoneId)
        else {
            return nil
        }
        self.init(fromDateText: date, inTimeZone: timeZone)
    }
    
    public convenience init?(fromDateText textDate: String, defaultTimeZone timeZone: TimeZone?) {
        let matches = textDate.matchList("(\\d{4}-\\d{2}-\\d{2} \\d{2}:\\d{2}:\\d{2})( (\\S+))?")
        if !matches.isEmpty {
            if matches[0][2].isEmpty {
                self.init(
                    fromDateText: matches[0][1],
                    inTimeZone: timeZone ?? TimeZone.current)
            }
            else {
                let targetTimeZone:TimeZone =
                        TimeZone(identifier: matches[0][3]) ??
                        TimeZone.current
                self.init(
                    fromDateText: matches[0][1],
                    inTimeZone: targetTimeZone)
            }
        }
        else {
            return nil
        }
    }
    
    static func stringToDate(_ dateTime:String?, timeZone:TimeZone?) -> Date? {
        
        if(StringUtils.shared.isNullOrEmpty(dateTime)){ return nil }
        
        guard let safeDateTime:String = dateTime else { return nil }
        
        let dateFormatter = DateFormatter()
        dateFormatter.timeZone = timeZone ?? TimeZone.current
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"

        let date = dateFormatter.date(from: safeDateTime)
        return date
    }
    
    public func add(_ dateComponent:Calendar.Component, value:Int){
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = timeZone
        var tempDate = calendar.date(from: currentDateComponents)
        tempDate = calendar.date(byAdding: dateComponent, value: value, to: tempDate!)
        currentDateComponents = calendar.dateComponents(RealDateTime.units, from: tempDate!)
    }
    
    public var date:Date {
        get {
            var calendar:Calendar = Calendar.current
            calendar.timeZone = dateComponents.timeZone!
            return calendar.date(from: dateComponents)!
        }
    }
    
    public func shiftTimeZone(toTimeZone timeZone: TimeZone) -> RealDateTime {
        return RealDateTime.init(fromDate: self.date, inTimeZone: timeZone)
    }
    
    public static func ==(lhs: RealDateTime, rhs: RealDateTime) -> Bool {
        if lhs.currentDateComponents.timeZone == rhs.currentDateComponents.timeZone {
            return lhs.currentDateComponents == rhs.currentDateComponents
        }
        let shiftedLhs = lhs.shiftTimeZone(toTimeZone: rhs.dateComponents.timeZone!)
        return shiftedLhs.currentDateComponents == rhs.currentDateComponents
    }
    
    public static func < (lhs: RealDateTime, rhs: RealDateTime) -> Bool {
        if lhs.currentDateComponents.timeZone == rhs.currentDateComponents.timeZone {
            return lhs.date < rhs.date
        }
        let shiftedLhs = lhs.shiftTimeZone(toTimeZone: rhs.dateComponents.timeZone!)
        return shiftedLhs.date < rhs.date
    }
    
    public static func > (lhs: RealDateTime, rhs: RealDateTime) -> Bool {
        if lhs.currentDateComponents.timeZone == rhs.currentDateComponents.timeZone {
            return lhs.date > rhs.date
        }
        let shiftedLhs = lhs.shiftTimeZone(toTimeZone: rhs.dateComponents.timeZone!)
        return shiftedLhs.date > rhs.date
    }
    
    public static func <=(lhs: RealDateTime, rhs: RealDateTime) -> Bool {
        return lhs < rhs || lhs == rhs
    }
    
    public static func >=(lhs: RealDateTime, rhs: RealDateTime) -> Bool {
        return lhs > rhs || lhs == rhs
    }
    
    public func copy(with zone: NSZone? = nil) -> RealDateTime {
        return RealDateTime.init(
            fromDateComponents: self.currentDateComponents)
    }
    
    public var description: String {
        return String(
            format: "%04d-%02d-%02d %02d:%02d:%02d %@",
            currentDateComponents.year!,
            currentDateComponents.month!,
            currentDateComponents.day!,
            currentDateComponents.hour!,
            currentDateComponents.minute!,
            currentDateComponents.second!,
            currentDateComponents.timeZone!.identifier
        )
    }
    
}
