//
//  DartBackgroundService.swift
//  awesome_notifications
//
//  Created by Rafael Setragni on 04/06/21.
//
import UIKit
import Foundation
import Flutter

public class DartBackgroundExecutor: BackgroundExecutor {
    
    private let TAG = "DartBackgroundExecutor"
    
    public let silentDataQueue:SynchronizedArray = SynchronizedArray<SilentActionRequest>()
        
    private var backgroundEngine: FlutterEngine?
    private var backgroundChannel: FlutterMethodChannel?
    
    static var registrar: FlutterPluginRegistrar?
    
    private var _isRunning = false
    public var isRunning:Bool {
        get { return _isRunning }
    }
    public var isNotRunning: Bool {
        get { return !_isRunning }
    }
    
    private var actionReceived:ActionReceived?
    
    // ************** SINGLETON PATTERN ***********************
    
    static var instance:DartBackgroundExecutor?
    public static var shared:DartBackgroundExecutor {
        get {
            DartBackgroundExecutor.instance =
                DartBackgroundExecutor.instance ?? DartBackgroundExecutor()
            return DartBackgroundExecutor.instance!
        }
    }
    
    public static func extendCapabilities(usingFlutterRegistrar registrar:FlutterPluginRegistrar){
        BitmapUtils.instance = FlutterBitmapUtils(registrar: registrar)
    }
    
    // ************** IOS EVENTS LISTENERS ************************
        
    var dartCallbackHandle:Int64 = 0
    var silentCallbackHandle:Int64 = 0
    
    public func runBackgroundProcess(
        silentActionRequest: SilentActionRequest,
        dartCallbackHandle:Int64,
        silentCallbackHandle:Int64
    ){
        addSilentActionRequest(silentActionRequest)
       
        if(!self._isRunning){
            
            self._isRunning = true
            
            self.silentCallbackHandle = silentCallbackHandle
            self.dartCallbackHandle = dartCallbackHandle
            
            runBackgroundThread(
                silentCallbackHandle: silentCallbackHandle,
                dartCallbackHandle: dartCallbackHandle)
        }
    }
    
    public func addSilentActionRequest(_ silentActionRequest:SilentActionRequest){
        silentDataQueue.append(silentActionRequest)
    }
    
    public func onMethodCall(_ call: FlutterMethodCall, result: @escaping FlutterResult){
        
        if(call.method == Definitions.CHANNEL_METHOD_INITIALIZE){
            
            dischargeNextSilentExecution()
            result(true)
            
        } else {
            
            result(
                FlutterError.init(
                    code: TAG,
                    message: "\(call.method) not implemented",
                    details: call.method
                )
            )

            result(false)
        }
    }
    
    func runBackgroundThread(
        silentCallbackHandle:Int64,
        dartCallbackHandle:Int64
    ) {
        
        guard let dartCallbackInfo = FlutterCallbackCache.lookupCallbackInformation(dartCallbackHandle) else {
            Log.d(TAG, "There is no valid callback info to handle dart channels.")
            self.closeBackgroundIsolate()
            return
        }
        
        guard FlutterCallbackCache.lookupCallbackInformation(silentCallbackHandle) != nil else {
            Log.d(TAG, "There is no valid callback info to handle silent data.")
            self.closeBackgroundIsolate()
            return
        }
        
        if(self.backgroundEngine != nil){
            Log.d(TAG, "Background isolate already started.")
            self.closeBackgroundIsolate()
            return
        }
        
        DispatchQueue.main.async {
            
            self.backgroundEngine = FlutterEngine(
                name: "AwesomeNotificationsBgEngine",
                project: nil,
                allowHeadlessExecution: true
            )
            
            if self.backgroundEngine == nil {
                Log.d(self.TAG, "Flutter background engine is not available.")
                self.closeBackgroundIsolate()
            }
            else {
                
                self.backgroundEngine!.run(
                    withEntrypoint: dartCallbackInfo.callbackName,
                    libraryURI: dartCallbackInfo.callbackLibraryPath)
                
                SwiftAwesomeNotificationsPlugin.flutterRegistrantCallback?(
                    self.backgroundEngine!)
                
                self.initializeReverseMethodChannel(
                    backgroundEngine: self.backgroundEngine!)
            }
        }
    }
    
    func initializeReverseMethodChannel(backgroundEngine: FlutterEngine){
        
        self.backgroundChannel = FlutterMethodChannel(
            name: Definitions.DART_REVERSE_CHANNEL,
            binaryMessenger: backgroundEngine.binaryMessenger
        )
        
        self.backgroundChannel!.setMethodCallHandler(onMethodCall)
    }
    
    func closeBackgroundIsolate() {
        _isRunning = false
        
        self.backgroundEngine?.destroyContext()
        self.backgroundEngine = nil
        
        self.backgroundChannel = nil
    }
    
    func dischargeNextSilentExecution(){
        if let silentDataRequest:SilentActionRequest = silentDataQueue.first {
            silentDataQueue.remove(at: 0)
            self.executeDartCallbackInBackgroundIsolate(silentDataRequest)
        }
        else {
            closeBackgroundIsolate()
        }
    }

    func finishDartBackgroundExecution(){
        if (silentDataQueue.count == 0) {
            Log.i(TAG, "All silent data fetched.")
            self.closeBackgroundIsolate()
        }
        else {
            Log.i(TAG, "Remaining " + String(silentDataQueue.count) + " silents to finish")
            self.dischargeNextSilentExecution()
        }
    }
    
    func executeDartCallbackInBackgroundIsolate(_ silentDataRequest:SilentActionRequest){
        
        if self.backgroundEngine == nil {
            Log.i(TAG, "A background message could not be handle since" +
                    "dart callback handler has not been registered")
        }
        
        var silentData:[String : Any?] = silentDataRequest.actionReceived.toMap()
        silentData[Definitions.ACTION_HANDLE] = self.silentCallbackHandle
        
        backgroundChannel?.invokeMethod(
            Definitions.CHANNEL_METHOD_SILENCED_CALLBACK,
            arguments: silentData,
            result: { flutterResult in
                silentDataRequest.handler(true)
                self.finishDartBackgroundExecution()
            }
        )
    }
}

