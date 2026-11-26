//
//  NotificationScheduleModel.swift
//  awesome_notifications
//
//  Created by Rafael Setragni on 05/09/20.
//

import Foundation

public protocol NotificationScheduleModel : AbstractModel {
    
    /// Initial reference date from schedule
    var createdDate:RealDateTime? { get set }
    /// Initial reference date from schedule
    var timeZone:TimeZone? { get set }
    
    func getUNNotificationTrigger() -> UNNotificationTrigger?
    
    func hasNextValidDate() -> Bool
    func getNextValidDate() -> RealDateTime?
}
