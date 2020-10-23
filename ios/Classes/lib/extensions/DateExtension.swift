//
//  DateExtension.swift
//  awesome_notifications
//
//  Created by Rafael Setragni on 31/08/20.
//

import Foundation

extension Date {
    
    public func getTime() -> Int64 {
        return Int64((self.timeIntervalSince1970 * 1000.0).rounded())
    }

    init(fromMilliseconds:Int64) {
        self = Date(timeIntervalSince1970: TimeInterval(fromMilliseconds) / 1000)
    }
    
    var millisecondsSince1970:Int64 {
        return Int64((self.timeIntervalSince1970 * 1000.0).rounded())
    }

    init(milliseconds:Int64) {
        self = Date(timeIntervalSince1970: TimeInterval(milliseconds) / 1000)
    }
    
    var secondsSince1970:Int64 {
        return Int64((self.timeIntervalSince1970).rounded(.up))
    }

    init(seconds:Int64) {
        self = Date(timeIntervalSince1970: TimeInterval(seconds))
    }
    
    var nanosecond: Int { return Calendar.current.component(.nanosecond,  from: self)   }
    
    // the same for your local time
    var preciseLocalTime: String {
        return Formatter.preciseLocalTime.string(for: self) ?? ""
    }
    
    // or GMT time
    var preciseGMTTime: String {
        return Formatter.preciseGMTTime.string(for: self) ?? ""
    }
    
    var dateComponents: DateComponents {
        let calendar = Calendar.current
        var components:DateComponents = DateComponents()
        components.second = calendar.component(.second, from: self)
        components.minute = calendar.component(.minute, from: self)
        components.hour = calendar.component(.hour, from: self)
        components.day = calendar.component(.day, from: self)
        components.month = calendar.component(.month, from: self)
        components.year = calendar.component(.year, from: self)
        return components
    }
    
    public func toString() -> String? {
        return DateUtils.dateToString(self)
    }
}
