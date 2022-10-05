//
//  TimeZoneUtils.swift
//  awesome_notifications
//
//  Created by CardaDev on 09/03/22.
//

import Foundation

public class TimeZoneUtils {

    // *****************************  SINGLETON PATTERN  *****************************
    
    static var instance:TimeZoneUtils?
    public static var shared:TimeZoneUtils {
        get {
            TimeZoneUtils.instance = TimeZoneUtils.instance ?? TimeZoneUtils()
            return TimeZoneUtils.instance!
        }
    }
    private init(){}

    // *******************************************************************************

    public func getValidTimeZone(fromTimeZoneId timeZoneId:String?) -> TimeZone? {
        guard let timeZoneId:String = timeZoneId
        else {
            return nil
        }
            
        let pattern = #"^((\-|\+)?(\d{2}(:\d{2})?))|(\S+)$"#
        let matcher = timeZoneId.matchList(pattern)
        
        var finalTimeZone:TimeZone?
        if !matcher.isEmpty {
            let matches:[String] = matcher[0]
            if !matches[1].isEmpty {
                let finalTimeZoneId:String =
                "GMT"+(
                    (matches[2].isEmpty ? "+" : matches[2]) +
                    matches[3] +
                    (matches[4].isEmpty ? ":00" : "")
                )
                finalTimeZone = TimeZone.init(identifier:finalTimeZoneId)
            }
            else {
              finalTimeZone = TimeZone.init(identifier: matches[5])
            }
        }
        
        if finalTimeZone?.identifier.contains(timeZoneId) ?? false {
            return finalTimeZone
        }
        
        return nil
    }

    public func timeZoneToString(timeZone:TimeZone?) -> String? {
        if timeZone == nil {
            return nil
        }
        else {
            return timeZone!.identifier
        }
    }
}
