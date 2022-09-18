//
//  DartAwesomeServiceExtension.swift
//  awesome_notifications
//
//  Created by CardaDev on 29/08/22.
//

import Foundation

open class DartAwesomeServiceExtension: AwesomeServiceExtension {
    
    public override func didReceive(
        _ request: UNNotificationRequest,
        withContentHandler contentHandler: @escaping (UNNotificationContent) -> Void
    ){
        DartAwesomeNotificationsExtension.setRegistrar()
        DartAwesomeNotificationsExtension.initialize()
        
        super.didReceive(request, withContentHandler: contentHandler)
    }
}
