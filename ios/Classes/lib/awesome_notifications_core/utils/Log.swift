//
//  Log.swift
//  awesome_notifications
//
//  Created by Rafael Setragni on 10/09/20.
//

import Foundation
import os.log

class Log {
    
    public static func i(_ tag:String, _ message:String, file:String = #file, function:String = #function, line:Int = #line){
        os_log("%@ %@:%d %@", type: .error, tag, function, line, message)
    }
    
    public static func e(_ tag:String, _ message:String, file:String = #file, function:String = #function, line:Int = #line){
        os_log("%@ %@:%d %@", type: .error, tag, function, line, message)
    }
    
    public static func d(_ tag:String, _ message:String, file:String = #file, function:String = #function, line:Int = #line){
        if(SwiftAwesomeNotificationsPlugin.debug){
            os_log("%@ %@:%d %@", type: .error, tag, function, line, message)
        }
    }
    
}
