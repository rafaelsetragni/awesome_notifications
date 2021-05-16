//
//  Log.swift
//  awesome_notifications
//
//  Created by Rafael Setragni on 10/09/20.
//

import Foundation


class Log {
    
    public static func d(_ tag:String, _ message:String){
        if(SwiftAwesomeNotificationsPlugin.debug){
            debugPrint(tag+": "+message)
        }
    }
    
}
