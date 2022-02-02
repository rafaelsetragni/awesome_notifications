//
//  BackgroundService.swift
//  awesome_notifications
//
//  Created by CardaDev on 02/02/22.
//

import Foundation

class BackgroundService {
    
    private let TAG = "BackgroundService"
    
    // ************** SINGLETON PATTERN ***********************
    
    public static let shared = BackgroundService()
    private init(){}
    
    // ********************************************************
    
    
    public func enqueue(
        SilentBackgroundAction silentAction: ActionReceived,
        handler: @escaping () -> ()
    ){
        Log.d(TAG, "A new Dart background service has started")
        
        let silentActionRequest:SilentActionRequest =
                SilentActionRequest(
                    actionReceived: silentAction,
                    handler: handler)
        
        let dartCallbackHandle: Int64 = DefaultManager.shared.getDartBgCallback()
        let silentCallbackHandle: Int64 = DefaultManager.shared.getActionCallback()
        
        if dartCallbackHandle == 0 {
            Log.d(TAG,
                  "A background message could not be handled in Dart because there is no valid onActionReceivedMethod handler register")
            return
        }
        
        if silentCallbackHandle == 0 {
            Log.d(TAG,
                  "A background message could not be handled in Dart because there is no valid dart background handler register")
            return
        }
        
        DartBackgroundExecutor
            .shared
            .runBackgroundExecutor(
                silentActionRequest: silentActionRequest,
                dartCallbackHandle: dartCallbackHandle,
                silentCallbackHandle: silentCallbackHandle)
    }
    
}
