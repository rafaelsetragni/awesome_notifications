
import Flutter
import UIKit
import UserNotifications
import FirebaseCore
import FirebaseMessaging

public class SwiftAwesomeNotificationsPlugin: NSObject, FlutterPlugin, UNUserNotificationCenterDelegate {
    
    private static var _instance:SwiftAwesomeNotificationsPlugin?
    
    static let TAG = "AwesomeNotificationsPlugin"
    static var registrar:FlutterPluginRegistrar?
    
    static var appLifeCycle:NotificationLifeCycle = NotificationLifeCycle.AppKilled

    var flutterChannel:FlutterMethodChannel?
    
    public static var instance:SwiftAwesomeNotificationsPlugin? {
        get { return _instance }
    }
    
    private static func checkGooglePlayServices() -> Bool {
        return true
    }
    
    public func application(_ application: UIApplication, didReceive notification: UILocalNotification) {
        let jsonData:String? = notification.userInfo?[Definitions.NOTIFICATION_JSON] as? String
        receiveAction(
            jsonData: jsonData,
            actionKey: nil,
            userText: nil
        )
    }
    
    @available(iOS 10.0, *)
    public func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        
        var userText:String?
        if let textResponse =  response as? UNTextInputNotificationResponse {
            userText =  textResponse.userText
        }
        
        receiveAction(
            jsonData: response.notification.request.content.userInfo[Definitions.NOTIFICATION_JSON] as? String,
            actionKey: response.actionIdentifier,
            userText: userText
        )
        
        completionHandler()
    }
    
    public func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable : Any], fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) -> Bool {
        print("test")
        return true
    }
    
    @available(iOS 10.0, *)
    public func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        receiveNotification(content: notification.request.content, withCompletionHandler: completionHandler)
    }
    
    public func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [AnyHashable : Any] = [:]) -> Bool {
        enableFirebase()
        return true
    }
    
    private func enableFirebase(){
        let firebaseConfigPath = Bundle.main.path(forResource: "GoogleService-Info", ofType: "plist")!
        let fileManager = FileManager.default
        
        if fileManager.fileExists(atPath: firebaseConfigPath) {
            if FirebaseApp.app() == nil {
                FirebaseApp.configure()
            }
        }
    }
    
    @available(iOS 10.0, *)
    private func receiveNotification(content:UNNotificationContent, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void){
        
        let jsonData:String? = content.userInfo[Definitions.NOTIFICATION_JSON] as? String
        let pushNotification:PushNotification? = NotificationBuilder.jsonToPushNotification(jsonData: jsonData)
        
        if(pushNotification == nil){ return }
        
        if(content.userInfo["updated"] == nil){
            
            let lifecycle = SwiftAwesomeNotificationsPlugin.getApplicationLifeCycle()
            pushNotification!.content!.displayedLifeCycle = lifecycle
            
            let pushData = pushNotification!.toMap()
            let updatedJsonData = JsonUtils.toJson(pushData)
            
            let content:UNMutableNotificationContent =
                UNMutableNotificationContent().copyContent(from: content)
            
            content.userInfo[Definitions.NOTIFICATION_JSON] = updatedJsonData
            content.userInfo["updated"] = true
            
            let request = UNNotificationRequest(identifier: pushNotification!.content!.id!.description, content: content, trigger: nil)
            
            UNUserNotificationCenter.current().add(request)
            {
                error in // called when message has been sent

                if error != nil {
                    debugPrint("Error: \(error.debugDescription)")
                }
            }
            
            completionHandler([])
            return
        }
    
        let notificationReceived:NotificationReceived? = NotificationReceived(pushNotification?.content)
        if(notificationReceived != nil){
                        
            let channel:NotificationChannelModel? = ChannelManager.getChannelByKey(channelKey: pushNotification!.content!.channelKey!)
            
            alertOnlyOnceNotification(
                channel?.onlyAlertOnce,
                id: String(pushNotification!.content!.id!),
                completionHandler: completionHandler
            )
            
            displayEvent(notificationReceived: notificationReceived!)
            
            if(pushNotification?.schedule != nil){
                                
                do {
                    try NotificationSenderAndScheduler().send(
                        createdSource: pushNotification!.content!.createdSource!,
                        pushNotification: pushNotification,
                        completion: { sent, error in
                        
                        }
                    )
                } catch {
                    // Fallback on earlier versions
                }
            }
        }
    }
    
    @available(iOS 10.0, *)
    private func alertOnlyOnceNotification(_ alertOnce:Bool?, id:String, completionHandler: @escaping (UNNotificationPresentationOptions) -> Void){
        if(alertOnce ?? false){
            
            UNUserNotificationCenter.current().getDeliveredNotifications { (notifications) in
                
                for notification in notifications {
                    if notification.request.identifier == id {
                        completionHandler([.alert])
                        return
                    }
                }
                completionHandler([.alert, .badge, .sound])
            }
            
        } else {
            completionHandler([.alert, .badge, .sound])
        }
    }
    
    private func receiveAction(jsonData: String?, actionKey:String?, userText:String?){
        Log.d(SwiftAwesomeNotificationsPlugin.TAG, "NOTIFICATION RECEIVED")
        
        if #available(iOS 10.0, *) {
            let actionReceived:ActionReceived? = NotificationBuilder.buildNotificationActionFromJson(jsonData: jsonData, actionKey: actionKey, userText: userText)
            flutterChannel?.invokeMethod(Definitions.CHANNEL_METHOD_RECEIVED_ACTION, arguments: actionReceived?.toMap())
        } else {
            // Fallback on earlier versions
        }
    }
    
    @available(iOS 10.0, *)
    public static func processNotificationContent(_ notification: UNNotification) -> UNNotification{
        print("processNotificationContent SwiftAwesomeNotificationsPlugin")
        return notification
    }
    
    public func createEvent(notificationReceived:NotificationReceived){
        Log.d(SwiftAwesomeNotificationsPlugin.TAG, "NOTIFICATION CREATED")
        flutterChannel?.invokeMethod(Definitions.CHANNEL_METHOD_NOTIFICATION_CREATED, arguments: notificationReceived.toMap())
    }
    
    public func displayEvent(notificationReceived:NotificationReceived){
        Log.d(SwiftAwesomeNotificationsPlugin.TAG, "NOTIFICATION DISPLAYED")

        let lifecycle = SwiftAwesomeNotificationsPlugin.getApplicationLifeCycle()
        
        if(lifecycle == .AppKilled){
            DisplayedManager.saveDisplayed(received: notificationReceived)
        }
        
        flutterChannel?.invokeMethod(Definitions.CHANNEL_METHOD_NOTIFICATION_DISPLAYED, arguments: notificationReceived.toMap())
    }
    
    
    public func applicationDidBecomeActive(_ application: UIApplication) {
        SwiftAwesomeNotificationsPlugin.appLifeCycle = NotificationLifeCycle.Foreground
        debugPrint("applicationDidBecomeActive")
    }
    
    public func applicationWillTerminate(_ application: UIApplication) {
        SwiftAwesomeNotificationsPlugin.appLifeCycle = NotificationLifeCycle.AppKilled
        debugPrint("applicationWillTerminate")
    }
    
    public func applicationWillResignActive(_ application: UIApplication) {
        //SwiftAwesomeNotificationsPlugin.appLifeCycle = NotificationLifeCycle.Background
        debugPrint("applicationWillResignActive")
    }
    
    public func applicationDidEnterBackground(_ application: UIApplication) {
        SwiftAwesomeNotificationsPlugin.appLifeCycle = NotificationLifeCycle.Background
        debugPrint("applicationDidEnterBackground")
    }
    
    public func applicationWillEnterForeground(_ application: UIApplication) {
        SwiftAwesomeNotificationsPlugin.appLifeCycle = NotificationLifeCycle.Foreground
        debugPrint("applicationWillEnterForeground")
    }
    
    public static func getApplicationLifeCycle() -> NotificationLifeCycle {
        return SwiftAwesomeNotificationsPlugin.appLifeCycle  // getApplicationLifeCycle(UIApplicationDelegate.)
    }

    private static func requestPermissions() -> Bool {
        if #available(iOS 10.0, *) {
            NotificationBuilder.requestPermissions(completion: { authorized in
                if authorized { debugPrint("Notifications authorized") }
                else { debugPrint("Notifications not authorized") }
            })
        } else {
            // Fallback on earlier versions
        }
        return true
    }

    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(name: Definitions.CHANNEL_FLUTTER_PLUGIN, binaryMessenger: registrar.messenger())
        let instance = SwiftAwesomeNotificationsPlugin()

        instance.initializeFlutterPlugin(registrar: registrar, channel: channel)
        SwiftAwesomeNotificationsPlugin._instance = instance
    }

    private func initializeFlutterPlugin(registrar: FlutterPluginRegistrar, channel: FlutterMethodChannel) {
        self.flutterChannel = channel
        
        registrar.addMethodCallDelegate(self, channel: self.flutterChannel!)
        registrar.addApplicationDelegate(self)
                
        SwiftAwesomeNotificationsPlugin.registrar = registrar
                
        UIApplication.shared.applicationIconBadgeNumber = 0
        UIApplication.shared.registerForRemoteNotifications()
        
        if #available(iOS 10.0, *) {
            UNUserNotificationCenter.current().delegate = self
        }
    }
    
    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {

        switch call.method {
            
            case Definitions.CHANNEL_METHOD_INITIALIZE:
                channelMethodInitialize(call: call, result: result)
                return
            
            case Definitions.CHANNEL_METHOD_GET_DRAWABLE_DATA:
                channelMethodGetDrawableData(call: call, result: result)
                return;
                
            case Definitions.CHANNEL_METHOD_IS_FCM_AVAILABLE:
                channelMethodIsFcmAvailable(call: call, result: result)
                return
          
            case Definitions.CHANNEL_METHOD_GET_FCM_TOKEN:
                channelMethodGetFcmToken(call: call, result: result)
                return
                    
            case Definitions.CHANNEL_METHOD_CREATE_NOTIFICATION:
                channelMethodCreateNotification(call: call, result: result)
                return
                    
            case Definitions.CHANNEL_METHOD_SET_NOTIFICATION_CHANNEL:
                channelMethodSetChannel(call: call, result: result)
                return
                
            case Definitions.CHANNEL_METHOD_CANCEL_NOTIFICATION:
                channelMethodCancelNotification(call: call, result: result)
                return
                
            case Definitions.CHANNEL_METHOD_CANCEL_ALL_NOTIFICATIONS:
                channelMethodCancelAllNotifications(call: call, result: result)
                return
                
            case Definitions.CHANNEL_METHOD_LIST_ALL_SCHEDULES:
                channelMethodListAllSchedules(call: call, result: result)
                return

            default:
                result(FlutterError.init(code: "methodNotFound", message: "method not found", details: call.method));
                return
        }
    }
    
    
    
    private func channelMethodListAllSchedules(call: FlutterMethodCall, result: @escaping FlutterResult) {
        
        do {
            ScheduleManager.listScheduled(completion: { schedules in
                  var serializeds:[[String:Any?]]  = []
                  
                  if(!ListUtils.isEmptyLists(schedules)){
                      for pushNotification in schedules {
                          let serialized:[String:Any?] = pushNotification.toMap()
                          serializeds.append(serialized)
                      }
                  }
                  
                  result(serializeds)
            })

        } catch {
            
            result(
                FlutterError.init(
                    code: "\(error)",
                    message: "Could not list notifications",
                    details: error.localizedDescription
                )
            )
            
            result(nil)
        }
    }
    
    private func channelMethodSetChannel(call: FlutterMethodCall, result: @escaping FlutterResult) {
        
        do {

            let channelData:[String:Any?] = call.arguments as! [String:Any?]
            let channel:NotificationChannelModel = NotificationChannelModel().fromMap(arguments: channelData) as! NotificationChannelModel
            
            ChannelManager.saveChannel(channel: channel)
            
            Log.d(SwiftAwesomeNotificationsPlugin.TAG, "Channel updated")
            result(true)

        } catch {
            
            result(
                FlutterError.init(
                    code: "\(error)",
                    message: "Invalid channel",
                    details: error.localizedDescription
                )
            )
        }
        
        result(false)
    }
    
    private func channelMethodInitialize(call: FlutterMethodCall, result: @escaping FlutterResult) {
        
        do {

            let platformParameters:[String:Any?] = call.arguments as? [String:Any?] ?? [:]
            let defaultIconPath:String? = platformParameters[Definitions.DEFAULT_ICON] as? String
            let channelsData:[Any] = platformParameters[Definitions.INITIALIZE_CHANNELS] as? [Any] ?? []

            try setDefaultConfigurations(
                defaultIconPath,
                channelsData
            )

            if #available(iOS 10.0, *) {
                NotificationBuilder.requestPermissions(completion: { authorized in
                    debugPrint("Notifications authorized")
                })
            } else {
                // Fallback on earlier versions
            }
            
            Log.d(SwiftAwesomeNotificationsPlugin.TAG, "Awesome Notification service initialized")
            result(true)

        } catch {
            
            result(result(
                FlutterError.init(
                    code: "\(error)",
                    message: "Awesome Notification service could not beeing initialized",
                    details: error.localizedDescription
                )
            ))
        }
    }

    private func channelMethodGetDrawableData(call: FlutterMethodCall, result: @escaping FlutterResult) {
        
        do {
            let bitmapReference:String = call.arguments as! String
                
            let image:UIImage = BitmapUtils.getBitmapFromSource(bitmapPath: bitmapReference)!
            let data:Data? = UIImage.pngData(image)()

            if(data == nil){
                result(nil)
            }
            else {
                let uInt8ListBytes:FlutterStandardTypedData = FlutterStandardTypedData.init(bytes: data!)
                result(uInt8ListBytes)
            }
        }
        catch {
            result(FlutterError.init(
                code: "\(error)",
                message: "Image couldnt be loaded",
                details: error.localizedDescription
            ))
        }
    }
    
    private func channelMethodGetFcmToken(call: FlutterMethodCall, result: @escaping FlutterResult) {
        result(false)
    }
		
    private func channelMethodIsFcmAvailable(call: FlutterMethodCall, result: @escaping FlutterResult) {
        result(false)
    }

    private func channelMethodCancelNotification(call: FlutterMethodCall, result: @escaping FlutterResult) {
        let notificationId:Int? = call.arguments as? Int
        if(notificationId == nil){ result(false); return }
        
        if #available(iOS 10.0, *) {
            NotificationSenderAndScheduler.cancelNotification(id: notificationId!)
        } else {
            // Fallback on earlier versions
        }
        
        result(true)
    }

    private func channelMethodCancelAllNotifications(call: FlutterMethodCall, result: @escaping FlutterResult) {
        
        if #available(iOS 10.0, *) {
            result(NotificationSenderAndScheduler.cancelAllNotifications())
        } else {
            // Fallback on earlier versions
        }
        result(true)
    }

    private func channelMethodCreateNotification(call: FlutterMethodCall, result: @escaping FlutterResult) {
        
        do {

            let pushData:[String:Any?] = call.arguments as? [String:Any?] ?? [:]
            let pushNotification:PushNotification? = PushNotification().fromMap(arguments: pushData) as? PushNotification
            
            if(pushNotification != nil){
                    
                if #available(iOS 10.0, *) {
                    try NotificationSenderAndScheduler().send(
                        createdSource: NotificationSource.Local,
                        pushNotification: pushNotification,
                        completion: { sent, error in
                        
                            if sent {
                                Log.d(SwiftAwesomeNotificationsPlugin.TAG, "Notification sent")
                            }
                            
                            result(sent)
                        }
                    )
                } else {
                    // Fallback on earlier versions
                    
                    Log.d(SwiftAwesomeNotificationsPlugin.TAG, "Notification sent");
                    result(true)
                }
            }
            else {
                result(
                    FlutterError.init(
                        code: "Invalid parameters",
                        message: "Notification content is invalid",
                        details: nil
                    )
                )
            }

        } catch {
            
            result(
                FlutterError.init(
                    code: "\(error)",
                    message: "Awesome Notification service could not beeing initialized",
                    details: error.localizedDescription
                )
            )
        }
        
        result(nil)
    }

    private func setDefaultConfigurations(_ defaultIconPath:String?, _ channelsData:[Any]) throws {
        
        for anyData in channelsData {
            if let channelData = anyData as? [String : Any?] {
                let channel:NotificationChannelModel? = (NotificationChannelModel().fromMap(arguments: channelData) as? NotificationChannelModel)
                
                if(channel != nil){
                    ChannelManager.saveChannel(channel: channel!)
                }
            }
        }
    }
}
