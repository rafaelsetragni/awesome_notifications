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
        
        let backgroundCallback:Int64 = DefaultsManager.shared.backgroundCallback ?? 0
        let actionCallback:Int64 = DefaultsManager.shared.actionCallback ?? 0
        
        if backgroundCallback == 0 {
            Log.d(TAG,
                  "A background message could not be handled in Dart because there is no valid background handler register")
            return
        }
        
        if actionCallback == 0 {
            Log.d(TAG,
                  "A background message could not be handled in Dart because there is no valid action callback handler register")
            return
        }
        
        DartBackgroundExecutor
            .shared
            .runBackgroundProcess(
                silentActionRequest: silentActionRequest,
                dartCallbackHandle: backgroundCallback,
                silentCallbackHandle: actionCallback)
    }
    
}
