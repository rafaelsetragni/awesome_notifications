//
//  AwesomeNotificationEventListener.swift
//  awesome_notifications
//
//  Created by CardaDev on 30/01/22.
//

import Foundation

public protocol AwesomeNotificationEventListener: AnyObject {
    func onNewNotificationReceived(eventName:String, notificationReceived:NotificationReceived);
}
