//
//  NotificationViewController.swift
//  AwesomeContentExtension
//
//  Created by Rafael Setragni on 28/09/20.
//

import UIKit
import UserNotifications
import UserNotificationsUI
import awesome_notifications

@available(iOS 10.0, *)
class NotificationViewController: UIViewController, UNNotificationContentExtension {

    @IBOutlet weak var filename: UILabel!
    
    var awesomeContentExtension:AwesomeContentExtension?
    
    override func viewDidLoad() {
        self.awesomeContentExtension = AwesomeContentExtension()
        awesomeContentExtension?.viewDidLoad()
    }
    
    func didReceive(_ notification: UNNotification) {
        awesomeContentExtension?.didReceive(notification)
    }

}
