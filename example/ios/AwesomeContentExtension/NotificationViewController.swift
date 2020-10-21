//
//  NotificationViewController.swift
//  AwesomeContentExtension
//
//  Created by Rafael Setragni on 28/09/20.
//

import UIKit
import UserNotifications
import UserNotificationsUI

@available(iOS 10.0, *)
class NotificationViewController: UIViewController, UNNotificationContentExtension {

    @IBOutlet weak var filename: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any required interface initialization here.
    }
    
    func didReceive(_ notification: UNNotification) {
        self.filename?.text = notification.request.content.body
    }

}
