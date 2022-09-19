//
//  AwesomeExceptionListener.swift
//  awesome_notifications
//
//  Created by CardaDev on 08/04/22.
//

import Foundation

public protocol AwesomeExceptionListener: AnyObject {
    func onNewAwesomeException(
        fromClassName className:String,
        withAwesomeException awesomeException:AwesomeNotificationsException)
}
