//
//  DateUtils.swift
//  awesome_notifications
//
//  Created by Rafael Setragni on 05/09/20.
//

import Foundation

class DateUtils {

    public static let utcTimeZone :TimeZone = TimeZone(secondsFromGMT: 0)!;

    public static func parseDate(_ dateTime:String?) -> Date? {
        
        if(StringUtils.isNullOrEmpty(dateTime)){ return nil }
        
        guard let safeDateTime:String = dateTime else { return nil }
        let dateFormatter = DateFormatter()

        dateFormatter.timeZone = self.utcTimeZone
        dateFormatter.dateFormat = Definitions.DATE_FORMAT

        let date = dateFormatter.date(from: safeDateTime)!
        return date
    }
    
    public static func dateToString(_ dateTime:Date?) -> String? {
        
        if(dateTime == nil){ return nil }
        
        let dateFormatter = DateFormatter()

        dateFormatter.timeZone = self.utcTimeZone
        dateFormatter.dateFormat = Definitions.DATE_FORMAT

        let date = dateFormatter.string(from: dateTime!)
        return date
    }

    public static func getUTCDate() -> String {
        let dateUtc = getUTCDateTime()        
        return dateUtc.preciseGMTTime
    }

    public static func getUTCDateTime() -> Date {
        return Date()
    }
    
    public static func getNowUTC() -> Date {
        return Date()
    }
}
