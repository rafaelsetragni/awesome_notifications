//
//  FCMService.swift
//  awesome_notifications-iOS10.0
//
//  Created by Rafael Setragni on 16/10/20.
//

import Foundation

//@available(iOS 10.0, *)
class FCMService {

    public func didReceive(_ content: UNMutableNotificationContent, withContentHandler contentHandler: @escaping (UNNotificationContent) -> Void) {
        
        // Modify the notification content here...
        content.title = "\(content.title) [modified 3]"
        
        if(!StringUtils.isNullOrEmpty(content.userInfo["gcm.message_id"] as? String)){
            
        }
        
        contentHandler(content)
    }
    
    public func serviceExtensionTimeWillExpire(_ content: UNMutableNotificationContent) -> UNMutableNotificationContent? {
        
        return nil
    }
    
}
