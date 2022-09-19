//
//  Formatter.swift
//  awesome_notifications
//
//  Created by Rafael Setragni on 05/10/20.
//

import Foundation
 
extension Formatter {
    
    // create static date formatters for your date representations
    static let preciseLocalTime: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = Definitions.DATE_FORMAT
        return formatter
    }()
    static let preciseGMTTime: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        formatter.dateFormat = Definitions.DATE_FORMAT
        return formatter
    }()
}
