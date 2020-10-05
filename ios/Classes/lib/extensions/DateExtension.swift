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
    
    var nanosecond: Int { return Calendar.current.component(.nanosecond,  from: self)   }
    
    // the same for your local time
    var preciseLocalTime: String {
        return Formatter.preciseLocalTime.string(for: self) ?? ""
    }
    
    // or GMT time
    var preciseGMTTime: String {
        return Formatter.preciseGMTTime.string(for: self) ?? ""
    }
}
