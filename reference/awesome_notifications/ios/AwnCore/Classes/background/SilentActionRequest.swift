//
//  SilentDataRequest.swift
//  awesome_notifications
//
//  Created by Rafael Setragni on 12/09/21.
//
import Foundation

public class SilentActionRequest {
    public let actionReceived: ActionReceived
    public let handler: (Bool) -> ()
    
    init(actionReceived:ActionReceived, handler: @escaping (Bool) -> ()){
        self.actionReceived = actionReceived
        self.handler = handler
    }
}
