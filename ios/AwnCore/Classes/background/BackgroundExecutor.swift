//
//  DartBackgroundExecutor.swift
//  awesome_notifications
//
//  Created by CardaDev on 02/02/22.
//
import Foundation

public protocol BackgroundExecutor {
    
    init()
    
    var isRunning:Bool { get }
    var isNotRunning:Bool { get }
        
    func runBackgroundProcess(
        silentActionRequest: SilentActionRequest,
        dartCallbackHandle:Int64,
        silentCallbackHandle:Int64
    )
}
