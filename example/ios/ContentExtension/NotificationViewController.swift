//
//  NotificationViewController.swift
//  ContentExtension
//
//  Created by Rafael Setragni on 28/09/20.
//

import UIKit
import UserNotifications
import UserNotificationsUI

@available(iOSApplicationExtension 10.0, *)
class NotificationViewController: UIViewController, UNNotificationContentExtension {
    
    @IBOutlet weak var referencename: UILabel!
    @IBOutlet weak var percentageIndicator: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any required interface initialization here.
    }
    
    func didReceive(_ notification: UNNotification) {
        self.referencename.text = notification.request.content.body
    }

}
