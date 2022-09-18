//
//  AwesomeContentExtension.swift
//  awesome_notifications
//
//  Created by Rafael Setragni on 22/10/20.
//

import UIKit
import UserNotifications
import UserNotificationsUI
import Foundation

// https://stackoverflow.com/questions/39882188/how-do-you-create-a-notification-content-extension-without-using-a-storyboard

@available(iOS 10.0, *)
open class AwesomeContentExtension: UIViewController, UNNotificationContentExtension {
    
    open override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .red
    }
    
    public func didReceive(_ notification: UNNotification) {
    }
}
