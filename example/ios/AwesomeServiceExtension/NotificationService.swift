//
//  NotificationService.swift
//  AwesomeServiceExtension
//
//  Created by Rafael Setragni on 16/10/20.
//

import UserNotifications
import awesome_notifications

@available(iOS 10.0, *)
class NotificationService: UNNotificationServiceExtension {
    
    var awesomeServiceExtension:AwesomeServiceExtension?
    
    override func didReceive(
        _ request: UNNotificationRequest,
        withContentHandler contentHandler: @escaping (UNNotificationContent) -> Void
    ){
        self.awesomeServiceExtension = AwesomeServiceExtension()
        awesomeServiceExtension?.didReceive(request, withContentHandler: contentHandler)
    }
    
    override func serviceExtensionTimeWillExpire() {
        if let awesomeServiceExtension = awesomeServiceExtension {
            awesomeServiceExtension.serviceExtensionTimeWillExpire()
        }
    }

}
