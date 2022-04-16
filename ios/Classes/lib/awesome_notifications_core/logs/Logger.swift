//
//  Logger.swift
//  awesome_notifications
//
//  Created by CardaDev on 01/04/22.
//

import Foundation
import os.log

public class Logger {
    
    static let redColor = "\u{001B}[0;31m"
    static let greenColor = "\u{001B}[0;32m"
    static let blueColor = "\u{001B}[0;34m"
    static let yellowColor = "\u{001B}[0;33m"
    static let resetColor = "\u{001B}[0;0m"
    
    static public func d(_ className:String, _ message:String, line: Int = #line){
        os_log("%@Swift: [AWESOME NOTIFICATIONS - DEBUG] %@ (%@:%d)%@", type: .debug, greenColor, message, className, line, resetColor)
    }
    
    static public func e(_ className:String, _ message:String, line: Int = #line){
        os_log("%@Swift: [AWESOME NOTIFICATIONS - ERROR] %@ (%@:%d)%@", type: .error, redColor, message, className, line, resetColor)
    }
    
    static public func i(_ className:String, _ message:String, line: Int = #line){
        os_log("%@Swift: [AWESOME NOTIFICATIONS - INFO] %@ (%@:%d)%@", type: .info, blueColor, message, className, line, resetColor)
    }
    
    static public func w(_ className:String, _ message:String, line: Int = #line){
        os_log("%@Swift: [AWESOME NOTIFICATIONS - WARNING] %@ (%@:%d)%@", type: .fault, yellowColor, message, className, line, resetColor)
    }
}
