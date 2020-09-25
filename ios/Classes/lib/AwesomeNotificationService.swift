//
//  AwesomeNotificationService.swift
//  awesome_notifications
//
//  Created by Rafael Setragni on 25/09/20.
//

import Foundation

@available(iOS 10.0, *)
public class AwesomeNotificationService {

    var contentHandler: ((UNNotificationContent) -> Void)?
    var bestAttemptContent: UNMutableNotificationContent?

    public init(){
        
    }
    
    public func didReceive(_ request: UNNotificationRequest, withContentHandler contentHandler: @escaping (UNNotificationContent) -> Void) {
        self.contentHandler = contentHandler
        bestAttemptContent = (request.content.mutableCopy() as? UNMutableNotificationContent)
        
        if let bestAttemptContent = bestAttemptContent {
            bestAttemptContent.title = "\(bestAttemptContent.title) [modifiedssss]"
            
            contentHandler(bestAttemptContent)
        }
    }
    
    public func serviceExtensionTimeWillExpire() {
        // Called just before the extension will be terminated by the system.
        // Use this as an opportunity to deliver your "best attempt" at modified content, otherwise the original push payload will be used.
        if let contentHandler = contentHandler, let bestAttemptContent =  bestAttemptContent {
            contentHandler(bestAttemptContent)
        }
    }

}
