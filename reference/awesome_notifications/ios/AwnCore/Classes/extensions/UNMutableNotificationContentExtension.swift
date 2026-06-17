//
//  UNMutableNotificationContentExtension.swift
//  awesome_notifications
//
//  Created by Rafael Setragni on 24/09/20.
//

import Foundation

@available(iOS 10.0, *)
extension UNMutableNotificationContent {
    
    func copyContent(from: UNNotificationContent) -> UNMutableNotificationContent {
        
        self.attachments = from.attachments
        self.badge = from.badge
        self.body = from.body
        self.categoryIdentifier = from.categoryIdentifier
        self.launchImageName = from.launchImageName
        self.sound = from.sound
        self.subtitle = from.subtitle
        self.title = from.title
        self.userInfo = from.userInfo

        if #available(iOS 12.0, *) {
            self.summaryArgument = from.summaryArgument
            self.summaryArgumentCount = from.summaryArgumentCount
        }
        
        // An identifier for the content of the notification used by the system to customize the scene to be activated when tapping on a notification.
        if #available(iOS 13.0, *) {
            self.targetContentIdentifier = from.targetContentIdentifier
        }
        
        return self
    }
}
