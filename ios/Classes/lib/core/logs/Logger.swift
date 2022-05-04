//
//  Logger.swift
//  awesome_notifications
//
//  Created by CardaDev on 01/04/22.
//

import Foundation
import os.log

public class Logger {
    
    static let redColor = "\u{1b}[31m"
    static let greenColor = "\u{1b}[32m"
    static let blueColor = "\u{1b}[34m"
    static let yellowColor = "\u{1b}[33m"
    static let resetColor = "\u{1b}[0m"
    
    static public func d(_ className:String, _ message:String, line: Int = #line){
        os_log("%@ [AWESOME NOTIFICATIONS] Swift: %@ (%@:%d) %@", type: .debug, greenColor, message, className, line, resetColor)
    }
    
    static public func e(_ className:String, _ message:String, line: Int = #line){
        os_log("%@ [AWESOME NOTIFICATIONS] Swift: %@ (%@:%d) %@", type: .error, redColor, message, className, line, resetColor)
    }
    
    static public func i(_ className:String, _ message:String, line: Int = #line){
        os_log("%@ [AWESOME NOTIFICATIONS] Swift: %@ (%@:%d) %@", type: .info, blueColor, message, className, line, resetColor)
    }
    
    static public func w(_ className:String, _ message:String, line: Int = #line){
        os_log("%@ [AWESOME NOTIFICATIONS] Swift: %@ (%@:%d) %@", type: .fault, yellowColor, message, className, line, resetColor)
    }
}
