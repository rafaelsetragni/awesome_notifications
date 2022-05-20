//
//  AwesomeActionEventListener.swift
//  awesome_notifications
//
//  Created by CardaDev on 30/01/22.
//

import Foundation

public protocol AwesomeActionEventListener: AnyObject {
    func onNewActionReceived(fromEventNamed eventName:String, withActionReceived actionReceived:ActionReceived)
    func onNewActionReceivedWithInterruption(fromEventNamed eventName:String, withActionReceived actionReceived:ActionReceived) -> Bool
}
