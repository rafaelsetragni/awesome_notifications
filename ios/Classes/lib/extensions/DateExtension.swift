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
}
