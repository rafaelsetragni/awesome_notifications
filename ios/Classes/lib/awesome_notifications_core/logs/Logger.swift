//
//  Logger.swift
//  awesome_notifications
//
//  Created by CardaDev on 01/04/22.
//

import Foundation
import os.log

public class Logger {
    
    static func d(_ className:String, _ message:String, line: Int = #line){
        os_log("Swift: [AWESOME NOTIFICATIONS - DEBUG] %@ (%@:%d)", type: .debug, message, className, line)
    }
    
    static func e(_ className:String, _ message:String, line: Int = #line){
        os_log("Swift: [AWESOME NOTIFICATIONS - ERROR] %@ (%@:%d)", type: .error, message, className, line)
    }
    
    static func i(_ className:String, _ message:String, line: Int = #line){
        os_log("Swift: [AWESOME NOTIFICATIONS - INFO] %@ (%@:%d)", type: .info, message, className, line)
    }
    
    static func w(_ className:String, _ message:String, line: Int = #line){
        os_log("Swift: [AWESOME NOTIFICATIONS - WARNING] %@ (%@:%d)", type: .fault, message, className, line)
    }
}
