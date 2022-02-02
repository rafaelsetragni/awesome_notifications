//
//  DartBackgroundService.swift
//  awesome_notifications
//
//  Created by Rafael Setragni on 04/06/21.
//
import Flutter
import Foundation

public class DartBackgroundExecutor: BackgroundExecutor {
    
    
    private let TAG = "DartBackgroundExecutor"
    
    public let silentDataQueue:SynchronizedArray = SynchronizedArray<SilentActionRequest>()
        
    private var backgroundEngine: FlutterEngine?
    private var backgroundChannel: FlutterMethodChannel?
    private var flutterPluginRegistrantCallback: FlutterPluginRegistrantCallback?
    
    static var registrar: FlutterPluginRegistrar?
    
    private var _isRunning = false
    public var isRunning:Bool {
        get { return _isRunning }
    }
    public var isNotRunning: Bool {
        get { return !_isRunning }
    }
    
    private var actionReceived:ActionReceived?
    
    private static var instance:DartBackgroundExecutor?
    public static var shared: DartBackgroundExecutor = {
        instance = instance ?? DartBackgroundExecutor()
        return instance!
    }()
    
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
                    code: SwiftAwesomeNotificationsPlugin.TAG,
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
        
        guard let silentCallbackInfo = FlutterCallbackCache.lookupCallbackInformation(silentCallbackHandle) else {
            Log.d(TAG, "There is no valid callback info to handle silent data.")
            self.closeBackgroundIsolate()
            return
        }
        
        if(self.backgroundEngine != nil){
            Log.d(TAG, "Background isolate already started.")
            self.closeBackgroundIsolate()
            return
        }
        
        DispatchQueue.global(qos: .background).async {
            
            self.backgroundEngine = FlutterEngine(
                name: "AwesomeNotificationsBgEngine",
                project: nil,
                allowHeadlessExecution: true
            )
            
            if self.backgroundEngine == nil {
                Log.d(TAG, "Flutter background engine is not available.")
                self.closeBackgroundIsolate()
                return
            }
            
            self.flutterPluginRegistrantCallback?(self.backgroundEngine!)
            self.initializeReverseMethodChannel(backgroundEngine: self.backgroundEngine!)
            
            self.backgroundEngine!.run(
                withEntrypoint: dartCallbackInfo.callbackName,
                libraryURI: dartCallbackInfo.callbackLibraryPath)
            
            self.backgroundEngine!.viewController = nil
        }
    }
    
    func initializeReverseMethodChannel(backgroundEngine: FlutterEngine){
        
        self.backgroundChannel = FlutterMethodChannel(
            name: Definitions.CHANNEL_METHOD_DART_CALLBACK,
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
        
        let silentData = silentDataRequest.actionReceived.toMap()
        
        backgroundChannel?.invokeMethod(
            Definitions.CHANNEL_METHOD_SILENCED_CALLBACK,
            arguments: [
                Definitions.ACTION_HANDLE: self.silentCallbackHandle,
                Definitions.CHANNEL_METHOD_RECEIVED_ACTION: silentData
            ],
            result: { flutterResult in
                silentDataRequest.handler()
                self.finishDartBackgroundExecution()
            }
        )
    }
}

