
import UIKit
import Flutter
import FirebaseCore
import FirebaseMessaging
import BackgroundTasks
import UserNotifications

public class SwiftAwesomeNotificationsPlugin: NSObject, FlutterPlugin, UNUserNotificationCenterDelegate, MessagingDelegate {
    
    private static var _instance:SwiftAwesomeNotificationsPlugin?
    
    static let TAG = "AwesomeNotificationsPlugin"
    static var registrar:FlutterPluginRegistrar?
    
    static var firebaseEnabled:Bool = false
    static var firebaseDeviceToken:String?
    
    static var appLifeCycle:NotificationLifeCycle {
        get { return LifeCycleManager.getLifeCycle(referenceKey: "currentlifeCycle") }
        set (newValue) { LifeCycleManager.setLifeCycle(referenceKey: "currentlifeCycle", lifeCycle: newValue) }
    }

    var flutterChannel:FlutterMethodChannel?
    
    public static var instance:SwiftAwesomeNotificationsPlugin? {
        get { return _instance }
    }
    
    private static func checkGooglePlayServices() -> Bool {
        return true
    }
    
    public func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable : Any], fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) -> Bool {
        
        do {
            if let contentJsonData:String = userInfo[Definitions.PUSH_NOTIFICATION_CONTENT] as? String {
                
                var mapData:[String:Any?] = [:]
                
                mapData[Definitions.PUSH_NOTIFICATION_CONTENT] = JsonUtils.fromJson(contentJsonData)
                
                if let scheduleJsonData:String = userInfo[Definitions.PUSH_NOTIFICATION_SCHEDULE] as? String {
                    mapData[Definitions.PUSH_NOTIFICATION_SCHEDULE] = JsonUtils.fromJson(contentJsonData)
                }
                
                if let buttonsJsonData:String = userInfo[Definitions.PUSH_NOTIFICATION_BUTTONS] as? String {
                    mapData[Definitions.PUSH_NOTIFICATION_BUTTONS] = JsonUtils.fromJson(buttonsJsonData)
                }
                
                var pushSource:NotificationSource?
                
                if userInfo["gcm.message_id"] != nil {
                    pushSource = NotificationSource.Firebase
                }
                
                if pushSource == nil {
                    completionHandler(UIBackgroundFetchResult.failed)
                    return false
                }
                
                if #available(iOS 10.0, *) {
                    
                    if let pushNotification = PushNotification().fromMap(arguments: mapData) as? PushNotification {
                    
                        try NotificationSenderAndScheduler().send(
                            createdSource: pushSource!,
                            pushNotification: pushNotification,
                            completion: { sent, content, error in
                                
                            }
                        )
                    }
                }
            }
            
        } catch {
            completionHandler(UIBackgroundFetchResult.failed)
            return false
        }
        
        completionHandler(UIBackgroundFetchResult.newData)
        
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
    
    public func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        Messaging.messaging().apnsToken = deviceToken
        if let token = requestFirebaseToken() {
            flutterChannel?.invokeMethod(Definitions.CHANNEL_METHOD_NEW_FCM_TOKEN, arguments: token)
        }
    }
    
    public func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String) {
        print("Firebase registration token: \(fcmToken)")

        let dataDict:[String: String] = ["token": fcmToken]
        NotificationCenter.default.post(name: Notification.Name("FCMToken"), object: nil, userInfo: dataDict)
        // TODO: If necessary send token to application server.
        // Note: This callback is fired at each app startup and whenever a new token is generated.
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
    
    @available(iOS 10.0, *)
    public func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        receiveNotification(content: notification.request.content, withCompletionHandler: completionHandler)
    }
    
    public func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [AnyHashable : Any] = [:]) -> Bool {
        enableFirebase(application)
        enableScheduler(application)
        
        return true
    }
    
    var backgroundSessionCompletionHandler: (() -> Void)?
    var backgroundSynchTask: UIBackgroundTaskIdentifier = .invalid
    public func application(_ application: UIApplication, handleEventsForBackgroundURLSession identifier: String, completionHandler: @escaping () -> Void) -> Bool {
        
        rescheduleLostNotifications()
        
        backgroundSessionCompletionHandler = completionHandler
        return true
    }
    
    private func requestFirebaseToken() -> String? {
        if let token = SwiftAwesomeNotificationsPlugin.firebaseDeviceToken ?? Messaging.messaging().fcmToken {
            SwiftAwesomeNotificationsPlugin.firebaseDeviceToken = token
            return token
        }
        return nil
    }
    
    private func enableScheduler(_ application: UIApplication){
        if !SwiftUtils.isRunningOnExtension() {
            if #available(iOS 13.0, *) {
                
                BGTaskScheduler.shared.register(
                    forTaskWithIdentifier: Definitions.IOS_BACKGROUND_SCHEDULER,
                    using: nil//DispatchQueue.global()//DispatchQueue.global(qos: .background).async
                ){ (task) in
                    Log.d("BG Schedule","My backgroundTask is executed NOW: \(Date().toString() ?? "")")
                    self.handleAppSchedules(task: task as! BGAppRefreshTask)
                }
                
            } else {
                
                Log.d("BG Schedule","iOS < 13  Registering for Background duty")
                UIApplication.shared.setMinimumBackgroundFetchInterval(UIApplication.backgroundFetchIntervalMinimum)
            }
        }
    }
    
    private func startBackgroundScheduler(){
        SwiftAwesomeNotificationsPlugin.rescheduleBackgroundTask()
    }
    
    private func stopBackgroundScheduler(){
        if #available(iOS 13.0, *) {
            BGTaskScheduler.shared.cancel(taskRequestWithIdentifier: Definitions.IOS_BACKGROUND_SCHEDULER)
        }
    }
    
    public static func rescheduleBackgroundTask(){
        if #available(iOS 13.0, *) {
            if SwiftAwesomeNotificationsPlugin.appLifeCycle != .Foreground {
                
                let earliestDate:Date? = ScheduleManager.getEarliestDate()
                
                if earliestDate != nil {
                    let request = BGAppRefreshTaskRequest(identifier: Definitions.IOS_BACKGROUND_SCHEDULER)
                    request.earliestBeginDate = earliestDate!
                         
                    do {
                        try BGTaskScheduler.shared.submit(request)
                        Log.d(TAG, "(\(Date().toString()!)) BG Scheduled created: "+earliestDate!.toString()!)
                    } catch {
                       print("Could not schedule next notification: \(error)")
                    }
                }
            }
        }
    }
    
    @available(iOS 13.0, *)
    private func handleAppSchedules(task: BGAppRefreshTask){
        
        let queue = OperationQueue()
        queue.maxConcurrentOperationCount = 1
        
        queue.addOperation(runScheduler)
        
        task.expirationHandler = {
            queue.cancelAllOperations()
        }

        let lastOperation = queue.operations.last
        lastOperation?.completionBlock = {
            task.setTaskCompleted(success: !(lastOperation?.isCancelled ?? false))
        }
    }
    
    @available(iOS 13.0, *)
    private func runScheduler(){
        
        rescheduleLostNotifications()
        SwiftAwesomeNotificationsPlugin.rescheduleBackgroundTask()
    }
    
    private func enableFirebase(_ application: UIApplication){
        guard let firebaseConfigPath = Bundle.main.path(forResource: "GoogleService-Info", ofType: "plist") else {
            return
        }
        
        let fileManager = FileManager.default
        
        if fileManager.fileExists(atPath: firebaseConfigPath) {
            if FirebaseApp.app() == nil {
                FirebaseApp.configure()
            }
            SwiftAwesomeNotificationsPlugin.firebaseEnabled = true
        }
    }
    
    @available(iOS 10.0, *)
    private func receiveNotification(content:UNNotificationContent, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void){
        
        let jsonData:String? = content.userInfo[Definitions.NOTIFICATION_JSON] as? String
        let pushNotification:PushNotification? = NotificationBuilder.jsonToPushNotification(jsonData: jsonData)
        
        if(pushNotification == nil){
            Log.d("receiveNotification","notification discarted")
            completionHandler([])
            return
        }
        
        if(content.userInfo["updated"] == nil){
            
            pushNotification!.content!.displayedLifeCycle = SwiftAwesomeNotificationsPlugin.appLifeCycle
            
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
                notificationReceived: notificationReceived!,
                completionHandler: completionHandler
            )
            
            if CreatedManager.getCreatedByKey(id: notificationReceived!.id!) != nil {
                SwiftAwesomeNotificationsPlugin.createEvent(notificationReceived: notificationReceived!)
            }
            
            DisplayedManager.reloadLostSchedulesDisplayed(referenceDate: Date())
            
            SwiftAwesomeNotificationsPlugin.displayEvent(notificationReceived: notificationReceived!)
            
            if(pushNotification?.schedule != nil){
                                
                do {
                    try NotificationSenderAndScheduler().send(
                        createdSource: pushNotification!.content!.createdSource!,
                        pushNotification: pushNotification,
                        completion: { sent, content, error in
                        
                        }
                    )
                } catch {
                    // Fallback on earlier versions
                }
            }
        }
    }
    
    @available(iOS 10.0, *)
    private func alertOnlyOnceNotification(_ alertOnce:Bool?, notificationReceived:NotificationReceived, completionHandler: @escaping (UNNotificationPresentationOptions) -> Void){
        
        if(alertOnce ?? false){
            
            UNUserNotificationCenter.current().getDeliveredNotifications { (notifications) in
                
                for notification in notifications {
                    if notification.request.identifier == String(notificationReceived.id!) {
                        
                        self.shouldDisplay(
                            notificationReceived: notificationReceived,
                            options: [.alert, .badge],
                            completionHandler: completionHandler
                        )
                        
                        return
                    }
                }
            }
            
        }
            
        self.shouldDisplay(
            notificationReceived: notificationReceived,
            options: [.alert, .badge, .sound],
            completionHandler: completionHandler
        )
    }
    
    @available(iOS 10.0, *)
    private func shouldDisplay(notificationReceived:NotificationReceived, options:UNNotificationPresentationOptions, completionHandler: @escaping (UNNotificationPresentationOptions) -> Void){
        
        let currentLifeCycle = SwiftAwesomeNotificationsPlugin.appLifeCycle
        if(
            (notificationReceived.displayOnForeground! && currentLifeCycle == .Foreground)
                ||
            (notificationReceived.displayOnBackground! && currentLifeCycle == .Background)
        ){
            completionHandler(options)
        }
        completionHandler([])
    }
    
    private func receiveAction(jsonData: String?, actionKey:String?, userText:String?){
        Log.d(SwiftAwesomeNotificationsPlugin.TAG, "NOTIFICATION RECEIVED")
        
        if(SwiftAwesomeNotificationsPlugin.appLifeCycle == .AppKilled){
            fireBackgroundLostEvents()
        }
        
        if #available(iOS 10.0, *) {
            let actionReceived:ActionReceived? = NotificationBuilder.buildNotificationActionFromJson(jsonData: jsonData, actionKey: actionKey, userText: userText)
            
            if actionReceived!.dismissedDate == nil {
                Log.d(SwiftAwesomeNotificationsPlugin.TAG, "NOTIFICATION RECEIVED")
                flutterChannel?.invokeMethod(Definitions.CHANNEL_METHOD_RECEIVED_ACTION, arguments: actionReceived?.toMap())
            }
            else {
                Log.d(SwiftAwesomeNotificationsPlugin.TAG, "NOTIFICATION DISMISSED")
                flutterChannel?.invokeMethod(Definitions.CHANNEL_METHOD_NOTIFICATION_DISMISSED, arguments: actionReceived?.toMap())
            }
        } else {
            // Fallback on earlier versions
        }
    }
    
    @available(iOS 10.0, *)
    public static func processNotificationContent(_ notification: UNNotification) -> UNNotification{
        print("processNotificationContent SwiftAwesomeNotificationsPlugin")
        return notification
    }
    
    public static func createEvent(notificationReceived:NotificationReceived){
        //Log.d(SwiftAwesomeNotificationsPlugin.TAG, "NOTIFICATION CREATED")
        
        let lifecycle = SwiftAwesomeNotificationsPlugin.appLifeCycle
        
        if(SwiftUtils.isRunningOnExtension() || lifecycle == .AppKilled){
            CreatedManager.saveCreated(received: notificationReceived)
        } else {
            _ = CreatedManager.removeCreated(id: notificationReceived.id!)
            
            SwiftAwesomeNotificationsPlugin.instance?.flutterChannel?.invokeMethod(Definitions.CHANNEL_METHOD_NOTIFICATION_CREATED, arguments: notificationReceived.toMap())
        }
    }
    
    public static func displayEvent(notificationReceived:NotificationReceived){
        //Log.d(SwiftAwesomeNotificationsPlugin.TAG, "NOTIFICATION DISPLAYED")

        let lifecycle = SwiftAwesomeNotificationsPlugin.appLifeCycle
        
        if(SwiftUtils.isRunningOnExtension() || lifecycle == .AppKilled){
            DisplayedManager.saveDisplayed(received: notificationReceived)
        } else {
            _ = DisplayedManager.removeDisplayed(id: notificationReceived.id!)
            
            SwiftAwesomeNotificationsPlugin.instance?.flutterChannel?.invokeMethod(Definitions.CHANNEL_METHOD_NOTIFICATION_DISPLAYED, arguments: notificationReceived.toMap())
        }
    }
    
    private static var didIRealyGoneBackground:Bool = true
    
    public func applicationDidBecomeActive(_ application: UIApplication) {
        //debugPrint("applicationDidBecomeActive")
        SwiftAwesomeNotificationsPlugin.appLifeCycle = NotificationLifeCycle.Foreground
        
        if(SwiftAwesomeNotificationsPlugin.didIRealyGoneBackground){
            fireBackgroundLostEvents()
        }
        SwiftAwesomeNotificationsPlugin.didIRealyGoneBackground = false
    }
    
    public func applicationWillResignActive(_ application: UIApplication) {
        //debugPrint("applicationWillResignActive")
        
        SwiftAwesomeNotificationsPlugin.didIRealyGoneBackground = false
        SwiftAwesomeNotificationsPlugin.appLifeCycle = NotificationLifeCycle.Background
    }
    
    public func applicationDidEnterBackground(_ application: UIApplication) {
        //debugPrint("applicationDidEnterBackground")
        
        SwiftAwesomeNotificationsPlugin.appLifeCycle = NotificationLifeCycle.AppKilled
        SwiftAwesomeNotificationsPlugin.didIRealyGoneBackground = true
        
        startBackgroundScheduler()
    }
    
    public func applicationWillEnterForeground(_ application: UIApplication) {
        //debugPrint("applicationWillEnterForeground")
        SwiftAwesomeNotificationsPlugin.appLifeCycle = NotificationLifeCycle.Background
        
        stopBackgroundScheduler()
        rescheduleLostNotifications()
    }
    
    public func applicationWillTerminate(_ application: UIApplication) {
        //debugPrint("applicationWillTerminate")
        
        SwiftAwesomeNotificationsPlugin.appLifeCycle = NotificationLifeCycle.AppKilled
        
        SwiftAwesomeNotificationsPlugin.rescheduleBackgroundTask()
    }

    private static func requestPermissions() -> Bool {
        if #available(iOS 10.0, *) {
            NotificationBuilder.requestPermissions(completion: { authorized in
                debugPrint( authorized ? "Notifications authorized" : "Notifications not authorized" )
            })
        }
        return true
    }
    
    public func rescheduleLostNotifications(){
        let referenceDate = Date()
        
        let lostSchedules = ScheduleManager.listPendingSchedules(referenceDate: referenceDate)
        for pushNotification in lostSchedules {
            
            do {
                if #available(iOS 10.0, *) {
                    try NotificationSenderAndScheduler().send(
                        createdSource: pushNotification.content!.createdSource!,
                        pushNotification: pushNotification,
                        completion: { sent, content, error in
                        }
                    )
                }
            } catch {
                // Fallback on earlier versions
            }
        }
    }

    public func fireBackgroundLostEvents(){
        
        let lostCreated = CreatedManager.listCreated()
        for createdNotification in lostCreated {
            SwiftAwesomeNotificationsPlugin.createEvent(notificationReceived: createdNotification)
        }
        
        DisplayedManager.reloadLostSchedulesDisplayed(referenceDate: Date())
        
        let lostDisplayed = DisplayedManager.listDisplayed()
        for displayedNotification in lostDisplayed {
            SwiftAwesomeNotificationsPlugin.displayEvent(notificationReceived: displayedNotification)
        }
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
        
        if #available(iOS 10.0, *) {
            UNUserNotificationCenter.current().delegate = self
            if(SwiftAwesomeNotificationsPlugin.firebaseEnabled){
                Messaging.messaging().delegate = self
            }
        }
        
        if !SwiftUtils.isRunningOnExtension() {
            UIApplication.shared.registerForRemoteNotifications()
        }
                
        if #available(iOS 10.0, *) {
        
            let categoryObject = UNNotificationCategory(
                identifier: Definitions.DEFAULT_CATEGORY_IDENTIFIER,
                actions: [],
                intentIdentifiers: [],
                options: .customDismissAction
            )
            UNUserNotificationCenter.current().setNotificationCategories([categoryObject])
        }
        
        SwiftAwesomeNotificationsPlugin.appLifeCycle = NotificationLifeCycle.AppKilled
        
        debugPrint("Awesome Notifications - App Group : "+Definitions.USER_DEFAULT_TAG)
        
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
                
            case Definitions.CHANNEL_METHOD_IS_NOTIFICATION_ALLOWED:
                channelMethodIsNotificationAllowed(call: call, result: result)
                return

            case Definitions.CHANNEL_METHOD_REQUEST_NOTIFICATIONS:
                channelMethodRequestNotification(call: call, result: result)
                return
                    
            case Definitions.CHANNEL_METHOD_CREATE_NOTIFICATION:
                channelMethodCreateNotification(call: call, result: result)
                return
                    
            case Definitions.CHANNEL_METHOD_SET_NOTIFICATION_CHANNEL:
                channelMethodSetChannel(call: call, result: result)
                return
                
            case Definitions.CHANNEL_METHOD_GET_BADGE_COUNT:
                channelMethodGetBadgeCounter(call: call, result: result)
                return
                
            case Definitions.CHANNEL_METHOD_SET_BADGE_COUNT:
                channelMethodSetBadgeCounter(call: call, result: result)
                return
                
            case Definitions.CHANNEL_METHOD_RESET_BADGE:
                channelMethodResetBadge(call: call, result: result)
                return
                
            case Definitions.CHANNEL_METHOD_CANCEL_NOTIFICATION:
                channelMethodCancelNotification(call: call, result: result)
                return
                        
            case Definitions.CHANNEL_METHOD_CANCEL_SCHEDULE:
                channelMethodCancelSchedule(call: call, result: result)
                return
                
            case Definitions.CHANNEL_METHOD_CANCEL_ALL_SCHEDULES:
                channelMethodCancelAllSchedules(call: call, result: result)
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
        
        //do {
            let schedules = ScheduleManager.listSchedules()
            var serializeds:[[String:Any?]]  = []

            if(!ListUtils.isEmptyLists(schedules)){
                for pushNotification in schedules {
                    let serialized:[String:Any?] = pushNotification.toMap()
                    serializeds.append(serialized)
                }
            }

            result(serializeds)
         /*
        } catch {
            
            result(
                FlutterError.init(
                    code: "\(error)",
                    message: "Could not list notifications",
                    details: error.localizedDescription
                )
            )
            
            result(nil)
        }*/
    }
    
    private func channelMethodSetChannel(call: FlutterMethodCall, result: @escaping FlutterResult) {
        
        //do {

            let channelData:[String:Any?] = call.arguments as! [String:Any?]
            let channel:NotificationChannelModel = NotificationChannelModel().fromMap(arguments: channelData) as! NotificationChannelModel
            
            ChannelManager.saveChannel(channel: channel)
            
            Log.d(SwiftAwesomeNotificationsPlugin.TAG, "Channel updated")
            result(true)
/*
        } catch {
            
            result(
                FlutterError.init(
                    code: "\(error)",
                    message: "Invalid channel",
                    details: error.localizedDescription
                )
            )
        }
        
        result(false)*/
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
            
            Log.d(SwiftAwesomeNotificationsPlugin.TAG, "Awesome Notification service initialized")
                        
            fireBackgroundLostEvents()
            
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
        
        //do {
            let bitmapReference:String = call.arguments as! String
                
            let image:UIImage = BitmapUtils.getBitmapFromSource(bitmapPath: bitmapReference)!
            let data:Data? = UIImage.pngData(image)()

            if(data == nil){
                result(nil)
            }
            else {
                let uInt8ListBytes:FlutterStandardTypedData = FlutterStandardTypedData.init(bytes: data!)
                result(uInt8ListBytes)
            }/*
        }
        catch {
            result(FlutterError.init(
                code: "\(error)",
                message: "Image couldnt be loaded",
                details: error.localizedDescription
            ))
        }*/
    }
    
    private func channelMethodGetFcmToken(call: FlutterMethodCall, result: @escaping FlutterResult) {
        let token = requestFirebaseToken()
        result(token)
    }
		
    private func channelMethodIsFcmAvailable(call: FlutterMethodCall, result: @escaping FlutterResult) {
        let token = requestFirebaseToken()
        result(!StringUtils.isNullOrEmpty(token))
    }
    
    private func channelMethodIsNotificationAllowed(call: FlutterMethodCall, result: @escaping FlutterResult) {
        if #available(iOS 10.0, *) {
            NotificationBuilder.isNotificationAllowed(completion: { (allowed) in
                result(allowed)
            })
        }
        else {
            result(nil)
        }
    }

    private func channelMethodRequestNotification(call: FlutterMethodCall, result: @escaping FlutterResult) {
        if #available(iOS 10.0, *) {
            NotificationBuilder.requestPermissions { (allowed) in
                result(allowed)
            }
        }
        else {
            result(nil)
        }
    }
    
    private func channelMethodGetBadgeCounter(call: FlutterMethodCall, result: @escaping FlutterResult) {
        if #available(iOS 10.0, *) {
            result(NotificationBuilder.getBadge().intValue)
        }
        else {
            result(0)
        }
    }
    
    private func channelMethodSetBadgeCounter(call: FlutterMethodCall, result: @escaping FlutterResult) {
        
        let platformParameters:[String:Any?] = call.arguments as? [String:Any?] ?? [:]
        let value:Int? = platformParameters[Definitions.NOTIFICATION_CHANNEL_SHOW_BADGE] as? Int
        //let channelKey:String? = platformParameters[Definitions.NOTIFICATION_CHANNEL_KEY] as? String
        
        if #available(iOS 10.0, *), value != nil {
            NotificationBuilder.setBadge(value!)
        }
        result(nil)
    }
    
    private func channelMethodResetBadge(call: FlutterMethodCall, result: @escaping FlutterResult) {
        if #available(iOS 10.0, *) {
            NotificationBuilder.resetBadge()
        }
        result(nil)
    }

    private func channelMethodCancelNotification(call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let notificationId:Int = call.arguments as? Int else {
            result(false); return
        }
        
        if #available(iOS 10.0, *) {
            result(NotificationSenderAndScheduler.cancelNotification(id: notificationId))
            return
        } else {
            // Fallback on earlier versions
        }
        
        result(false)
    }
    
    private func channelMethodCancelSchedule(call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let notificationId:Int = call.arguments as? Int else {
            result(false); return
        }
        
        if #available(iOS 10.0, *) {
            result(NotificationSenderAndScheduler.cancelSchedule(id: notificationId))
            return
        } else {
            // Fallback on earlier versions
        }
        
        result(false)
    }
    
    private func channelMethodCancelAllSchedules(call: FlutterMethodCall, result: @escaping FlutterResult) {
        
        if #available(iOS 10.0, *) {
            result(NotificationSenderAndScheduler.cancelAllSchedules())
            return
        } else {
            // Fallback on earlier versions
        }
        
        result(false)
    }

    private func channelMethodCancelAllNotifications(call: FlutterMethodCall, result: @escaping FlutterResult) {
        
        if #available(iOS 10.0, *) {
            result(NotificationSenderAndScheduler.cancelAllNotifications())
            return
        } else {
            // Fallback on earlier versions
        }
        
        result(false)
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
                        completion: { sent, content, error in
                        
                            if sent {
                                Log.d(SwiftAwesomeNotificationsPlugin.TAG, "Notification sent")
                            }
                            
                            if error != nil {
                                let flutterError:FlutterError?
                                if let notificationError = error as? PushNotificationError {
                                    switch notificationError {
                                        case PushNotificationError.notificationNotAuthorized:
                                            flutterError = FlutterError.init(
                                                code: "notificationNotAuthorized",
                                                message: "Notifications are disabled",
                                                details: nil
                                            )
                                        case PushNotificationError.cronException:
                                            flutterError = FlutterError.init(
                                                code: "cronException",
                                                message: notificationError.localizedDescription,
                                                details: nil
                                            )
                                        default:
                                            flutterError = FlutterError.init(
                                                code: "exception",
                                                message: "Unknow error",
                                                details: notificationError.localizedDescription
                                            )
                                    }
                                }
                                else {
                                    flutterError = FlutterError.init(
                                        code: error.debugDescription,
                                        message: error?.localizedDescription,
                                        details: nil
                                    )
                                }
                                result(flutterError)
                                return
                            }
                            else {
                                result(sent)
                                return
                            }
                            
                        }
                    )
                } else {
                    // Fallback on earlier versions
                    
                    Log.d(SwiftAwesomeNotificationsPlugin.TAG, "Notification sent");
                    result(true)
                    return
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
                return
            }

        } catch {
            
            result(
                FlutterError.init(
                    code: "\(error)",
                    message: "Awesome Notification service could not beeing initialized",
                    details: error.localizedDescription
                )
            )
            return
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
