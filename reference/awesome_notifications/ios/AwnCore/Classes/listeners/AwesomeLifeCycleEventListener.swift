//
//  AwesomeLifeCycleEventListener.swift
//  awesome_notifications
//
//  Created by CardaDev on 30/01/22.
//

import Foundation

public protocol AwesomeLifeCycleEventListener: AnyObject {
    func onNewLifeCycleEvent(lifeCycle:NotificationLifeCycle)
}
