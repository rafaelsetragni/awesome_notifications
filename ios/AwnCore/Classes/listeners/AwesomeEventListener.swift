//
//  AwesomeEventListener.swift
//  awesome_notifications
//
//  Created by CardaDev on 30/01/22.
//

import Foundation

public protocol AwesomeEventListener: AnyObject {
    func onNewAwesomeEvent(eventType:String, content:[String: Any?]);
}
