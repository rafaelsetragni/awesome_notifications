//
//  NotificationScheduleModel.swift
//  awesome_notifications
//
//  Created by Rafael Setragni on 05/09/20.
//

import Foundation

public protocol NotificationScheduleModel : AbstractModel {
     
    func getUNNotificationTrigger() -> UNNotificationTrigger?
    
}
