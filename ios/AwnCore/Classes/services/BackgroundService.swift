//
//  BackgroundService.swift
//  awesome_notifications
//
//  Created by CardaDev on 02/02/22.
//

import Foundation

class BackgroundService {
    
    static let TAG = "BackgroundService"
    
    // ************** SINGLETON PATTERN ***********************
    
    static var instance:BackgroundService?
    public static var shared:BackgroundService {
        get {
            BackgroundService.instance =
                BackgroundService.instance ?? BackgroundService()
            return BackgroundService.instance!
        }
    }
    private init(){}
    
    // ********************************************************
    
    public func enqueue(
        SilentBackgroundAction silentAction: ActionReceived,
        withCompletionHandler completionHandler: @escaping (Bool, Error?) -> ()
    ){
        let start = DispatchTime.now()
        Logger.d(BackgroundService.TAG, "A new Dart background service has started")
        
        let completionWithTimer:(Bool, Error?) -> () = { (success, error) in
            let end = DispatchTime.now()
            let nanoTime = end.uptimeNanoseconds - start.uptimeNanoseconds
            let timeInterval:Double = Double(nanoTime) / 1_000_000
            Logger.d(BackgroundService.TAG, "Background action finished in \(timeInterval.rounded())ms")
            
            completionHandler(success, error)
        }
        
        do {
            let backgroundCallback:Int64 = DefaultsManager.shared.backgroundCallback
            let actionCallback:Int64 = DefaultsManager.shared.actionCallback
            
            if backgroundCallback == 0 {
                throw ExceptionFactory
                        .shared
                        .createNewAwesomeException(
                            className: BackgroundService.TAG,
                            code: ExceptionCode.CODE_INVALID_ARGUMENTS,
                            message: "A background message could not be handled in Dart because there is no valid background handler register",
                            detailedCode: ExceptionCode.DETAILED_INVALID_ARGUMENTS + ".enqueue.backgroundCallback")
            }
            
            if actionCallback == 0 {
                throw ExceptionFactory
                        .shared
                        .createNewAwesomeException(
                            className: BackgroundService.TAG,
                            code: ExceptionCode.CODE_INVALID_ARGUMENTS,
                            message: "A background message could not be handled in Dart because there is no valid action callback handler register",
                            detailedCode: ExceptionCode.DETAILED_INVALID_ARGUMENTS + ".enqueue.backgroundCallback")
            }
            
            if Thread.isMainThread {
                mainThreadServiceExecution(
                    SilentBackgroundAction: silentAction,
                    backgroundCallback: backgroundCallback,
                    actionCallback: actionCallback,
                    withCompletionHandler: completionWithTimer)
            }
            else {
                try backgroundThreadServiceExecution(
                    SilentBackgroundAction: silentAction,
                    backgroundCallback: backgroundCallback,
                    actionCallback: actionCallback,
                    withCompletionHandler: completionWithTimer)
            }
            
        } catch {
            if error is AwesomeNotificationsException {
                completionWithTimer(false, error)
            } else {
                completionWithTimer(
                    false,
                    ExceptionFactory
                        .shared
                        .createNewAwesomeException(
                            className: BackgroundService.TAG,
                            code: ExceptionCode.CODE_INVALID_ARGUMENTS,
                            message: "A background message could not be handled in Dart because there is no valid background handler register",
                            detailedCode: ExceptionCode.DETAILED_INVALID_ARGUMENTS + ".enqueue.backgroundCallback"))
            }
        }
    }
    
    func mainThreadServiceExecution(
        SilentBackgroundAction silentAction: ActionReceived,
        backgroundCallback:Int64,
        actionCallback:Int64,
        withCompletionHandler completionHandler: @escaping (Bool, Error?) -> ()
    ){
        let silentActionRequest:SilentActionRequest =
                SilentActionRequest(
                    actionReceived: silentAction,
                    handler: { success in
                        completionHandler(success, nil)
                    })
        
        let backgroundExecutor:BackgroundExecutor =
                AwesomeNotifications
                    .backgroundClassType!
                    .init()
        
        backgroundExecutor
            .runBackgroundProcess(
                silentActionRequest: silentActionRequest,
                dartCallbackHandle: backgroundCallback,
                silentCallbackHandle: actionCallback)
    }
    
    func backgroundThreadServiceExecution(
        SilentBackgroundAction silentAction: ActionReceived,
        backgroundCallback:Int64,
        actionCallback:Int64,
        withCompletionHandler completionHandler: @escaping (Bool, Error?) -> ()
    ) throws {
        let group = DispatchGroup()
        group.enter()
        
        let silentActionRequest:SilentActionRequest =
                SilentActionRequest(
                    actionReceived: silentAction,
                    handler: { success in
                        group.leave()
                    })
        
        let workItem:DispatchWorkItem = DispatchWorkItem {
            DispatchQueue.global(qos: .background).async {
                
                let backgroundExecutor:BackgroundExecutor =
                        AwesomeNotifications
                            .backgroundClassType!
                            .init()
                
                backgroundExecutor
                    .runBackgroundProcess(
                        silentActionRequest: silentActionRequest,
                        dartCallbackHandle: backgroundCallback,
                        silentCallbackHandle: actionCallback)
            }
            
        }
        
        workItem.perform()
        if group.wait(timeout: DispatchTime.now() + .seconds(10)) == .timedOut {
            workItem.cancel()
            throw ExceptionFactory
                    .shared
                    .createNewAwesomeException(
                        className: BackgroundService.TAG,
                        code: ExceptionCode.CODE_INVALID_ARGUMENTS,
                        message: "Background silent push service reached timeout limit",
                        detailedCode: ExceptionCode.DETAILED_INVALID_ARGUMENTS + ".mainThreadServiceExecution.timeout")
        }
    }
    
}
