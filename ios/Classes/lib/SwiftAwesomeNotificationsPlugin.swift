
import UIKit
import Flutter
//import FirebaseCore
//import FirebaseMessaging
import BackgroundTasks
import UserNotifications

public class SwiftAwesomeNotificationsPlugin: NSObject, FlutterPlugin, UNUserNotificationCenterDelegate/*, MessagingDelegate*/ {
    
    private static var _instance:SwiftAwesomeNotificationsPlugin?
    
    static var debug = false
    static let TAG = "AwesomeNotificationsPlugin"
    static var registrar:FlutterPluginRegistrar?
    
    static var firebaseEnabled:Bool = false
    static var firebaseDeviceToken:String?
    
    static var appLifeCycle:NotificationLifeCycle {
        get { return LifeCycleManager.getLifeCycle(referenceKey: "currentlifeCycle") }
        set (newValue) { LifeCycleManager.setLifeCycle(referenceKey: "currentlifeCycle", lifeCycle: newValue) }
    }

    var flutterChannel:FlutterMethodChannel?
    
    // If somebody already layed claim to UNNotificationCenterDelegate, rather than clobbering
    // them, we forward on any delegate calls that we receive.
    private var _originalNotificationCenterDelegate: UNUserNotificationCenterDelegate?
    
    public static var instance:SwiftAwesomeNotificationsPlugin? {
        get { return _instance }
    }
    
    private static func checkGooglePlayServices() -> Bool {
        return true
    }
    
    /*
    public func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable : Any], fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) -> Bool {
        
        do {
            
            if let contentJsonData:String = userInfo[Definitions.PUSH_NOTIFICATION_CONTENT] as? String {
                
                var mapData:[String:Any?] = [:]
                
                mapData[Definitions.PUSH_NOTIFICATION_CONTENT] = JsonUtils.fromJson(contentJsonData)
                
                if let scheduleJsonData:String = userInfo[Definitions.PUSH_NOTIFICATION_SCHEDULE] as? String {
                    mapData[Definitions.PUSH_NOTIFICATION_SCHEDULE] = JsonUtils.fromJson(scheduleJsonData)
                }
                
                if let buttonsJsonData:String = userInfo[Definitions.PUSH_NOTIFICATION_BUTTONS] as? String {
                    mapData[Definitions.PUSH_NOTIFICATION_BUTTONS] = JsonUtils.fromJsonArr(buttonsJsonData)
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
    */
    
    public func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        /*
        Messaging.messaging().apnsToken = deviceToken
        if let token = requestFirebaseToken() {
            flutterChannel?.invokeMethod(Definitions.CHANNEL_METHOD_NEW_FCM_TOKEN, arguments: token)
        }
        */
    }
    /*
    // For Firebase Messaging versions older than 7.0
    // https://github.com/rafaelsetragni/awesome_notifications/issues/39
    public func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String) {
        
        didReceiveRegistrationToken(messaging, fcmToken: fcmToken)
    }
    
    public func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
        
        if let unwrapped = fcmToken {
            didReceiveRegistrationToken(messaging, fcmToken: unwrapped)
        }
        
    }
    
    private func didReceiveRegistrationToken(_ messaging: Messaging, fcmToken: String){
        
        print("Firebase registration token: \(fcmToken)")
        let dataDict:[String: String] = ["token": fcmToken]
        NotificationCenter.default.post(name: Notification.Name("FCMToken"), object: nil, userInfo: dataDict)
        
        flutterChannel?.invokeMethod(Definitions.CHANNEL_METHOD_NEW_FCM_TOKEN, arguments: fcmToken)
    }
    */

    @available(iOS 10.0, *)
    public func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        
        var userText:String?
        if let textResponse =  response as? UNTextInputNotificationResponse {
            userText =  textResponse.userText
        }

        if let jsonData:String = response.notification.request.content.userInfo[Definitions.NOTIFICATION_JSON] as? String {
            receiveAction(
                  jsonData: jsonData,
                  actionKey: response.actionIdentifier,
                  userText: userText
              )
        } else {
            print("Received an invalid notification content")
        }

        if _originalNotificationCenterDelegate?.userNotificationCenter?(center, didReceive: response, withCompletionHandler: completionHandler) == nil {
            completionHandler()
        }
    }

    @available(iOS 10.0, *)
    public func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        if !receiveNotification(content: notification.request.content, withCompletionHandler: completionHandler) {
            // completionHandler was *not* called, so maybe this notification is for another plugin:

            if _originalNotificationCenterDelegate?.userNotificationCenter?(center, willPresent: notification, withCompletionHandler: completionHandler) == nil {
                // TODO(tek08): Absorb notifications like this?  Or present them by default?
                print("Was going to present a notification, but no plugin wanted to handle it.")
                completionHandler([])
            }
        }
    }
    
    public func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [AnyHashable : Any] = [:]) -> Bool {
        
        // Set ourselves as the UNUserNotificationCenter delegate, but also preserve any existing delegate...
        let notificationCenter = UNUserNotificationCenter.current()
        _originalNotificationCenterDelegate = notificationCenter.delegate
        notificationCenter.delegate = self
        
        //enableFirebase(application)
        //enableScheduler(application)
        rescheduleLostNotifications()
		
        if(SwiftAwesomeNotificationsPlugin.debug){
			Log.d(SwiftAwesomeNotificationsPlugin.TAG, "Awesome Notifications attached for iOS")
        }
		
        return true
    }
    
    var backgroundSessionCompletionHandler: (() -> Void)?
    var backgroundSynchTask: UIBackgroundTaskIdentifier = .invalid
    public func application(_ application: UIApplication, handleEventsForBackgroundURLSession identifier: String, completionHandler: @escaping () -> Void) -> Bool {
        
        rescheduleLostNotifications()
        
        backgroundSessionCompletionHandler = completionHandler
        return true
    }
    
    /*
    private func requestFirebaseToken() -> String? {
        if let token = SwiftAwesomeNotificationsPlugin.firebaseDeviceToken ?? Messaging.messaging().fcmToken {
            SwiftAwesomeNotificationsPlugin.firebaseDeviceToken = token
            return token
        }
        return nil
    }
    */
    /*
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
    */

    /// - Returns: True if completionHandler was called (aka if correct notificationJson was present and processed)
    @available(iOS 10.0, *)
    private func receiveNotification(content:UNNotificationContent, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) -> Bool {
        
        var arguments:[String : Any?]
        if(content.userInfo[Definitions.NOTIFICATION_JSON] != nil){
            let jsonData:String = content.userInfo[Definitions.NOTIFICATION_JSON] as! String
            arguments = JsonUtils.fromJson(jsonData) ?? [:]
        }
        else {
            arguments = content.userInfo as! [String : Any?]
            
            if(arguments[Definitions.PUSH_NOTIFICATION_CONTENT] is String){
                arguments[Definitions.PUSH_NOTIFICATION_CONTENT] = JsonUtils.fromJson(arguments[Definitions.PUSH_NOTIFICATION_CONTENT] as? String)
            }
            
            if(arguments[Definitions.PUSH_NOTIFICATION_BUTTONS] is String){
                arguments[Definitions.PUSH_NOTIFICATION_BUTTONS] = JsonUtils.fromJson(arguments[Definitions.PUSH_NOTIFICATION_BUTTONS] as? String)
            }
            
            if(arguments[Definitions.PUSH_NOTIFICATION_SCHEDULE] is String){
                arguments[Definitions.PUSH_NOTIFICATION_SCHEDULE] = JsonUtils.fromJson(arguments[Definitions.PUSH_NOTIFICATION_SCHEDULE] as? String)
            }
        }
        
        guard let pushNotification:PushNotification = NotificationBuilder.jsonDataToPushNotification(jsonData: arguments)
        else {
            Log.d("receiveNotification","notification data invalid")
            return false
        }
        
        /*
        if(content.userInfo["updated"] == nil){
            
            let pushData = pushNotification.toMap()
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
        */
    
        let notificationReceived:NotificationReceived? = NotificationReceived(pushNotification.content)
        if(notificationReceived != nil){
            
            pushNotification.content!.displayedLifeCycle = SwiftAwesomeNotificationsPlugin.appLifeCycle
                        
            let channel:NotificationChannelModel? = ChannelManager.getChannelByKey(channelKey: pushNotification.content!.channelKey!)
            
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

            /*
            if(pushNotification.schedule != nil){
                                
                do {
                    try NotificationSenderAndScheduler().send(
                        createdSource: pushNotification.content!.createdSource!,
                        pushNotification: pushNotification,
                        completion: { sent, content, error in
                        
                        }
                    )
                } catch {
                    // Fallback on earlier versions
                }
            }
            */

            // Completion handler was called in alertOnlyOnceNotification(...) / its subcalls.
            return true;
        }
        return false;
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
		
        if(SwiftAwesomeNotificationsPlugin.appLifeCycle == .AppKilled){
            fireBackgroundLostEvents()
        }
        
        if #available(iOS 10.0, *) {
            let actionReceived:ActionReceived? = NotificationBuilder.buildNotificationActionFromJson(jsonData: jsonData, actionKey: actionKey, userText: userText)
            
            if actionReceived?.dismissedDate == nil {

                if(SwiftAwesomeNotificationsPlugin.debug){
					Log.d(SwiftAwesomeNotificationsPlugin.TAG, "Notification action received");
				}
                flutterChannel?.invokeMethod(Definitions.CHANNEL_METHOD_RECEIVED_ACTION, arguments: actionReceived?.toMap())
            }
            else {

                if(SwiftAwesomeNotificationsPlugin.debug){
					Log.d(SwiftAwesomeNotificationsPlugin.TAG, "Notification dismissed");
				}
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
		if(debug){
			Log.d(SwiftAwesomeNotificationsPlugin.TAG, "Notification created")
		}
        
        let lifecycle = SwiftAwesomeNotificationsPlugin.appLifeCycle
        
        if(SwiftUtils.isRunningOnExtension() || lifecycle == .AppKilled){
            CreatedManager.saveCreated(received: notificationReceived)
        } else {
            _ = CreatedManager.removeCreated(id: notificationReceived.id!)
            
            SwiftAwesomeNotificationsPlugin.instance?.flutterChannel?.invokeMethod(Definitions.CHANNEL_METHOD_NOTIFICATION_CREATED, arguments: notificationReceived.toMap())
        }
    }
    
    public static func displayEvent(notificationReceived:NotificationReceived){
		if(debug){
			Log.d(SwiftAwesomeNotificationsPlugin.TAG, "Notification displayed")
		}

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
	
        SwiftAwesomeNotificationsPlugin.appLifeCycle = NotificationLifeCycle.Foreground
        
        if(SwiftAwesomeNotificationsPlugin.didIRealyGoneBackground){
            fireBackgroundLostEvents()
        }
        SwiftAwesomeNotificationsPlugin.didIRealyGoneBackground = false
		
        if(SwiftAwesomeNotificationsPlugin.debug){
			Log.d(
				SwiftAwesomeNotificationsPlugin.TAG,
				"Notification lifeCycle: (DidBecomeActive) " 
					+ SwiftAwesomeNotificationsPlugin.appLifeCycle.rawValue
			)
		}
    }
    
    public func applicationWillResignActive(_ application: UIApplication) {
        
        // applicationWillTerminate is not always get called, so the Background state is not correct defined in this cases
        //SwiftAwesomeNotificationsPlugin.appLifeCycle = NotificationLifeCycle.Foreground
        
        SwiftAwesomeNotificationsPlugin.appLifeCycle = NotificationLifeCycle.Background
        SwiftAwesomeNotificationsPlugin.didIRealyGoneBackground = false
		
        if(SwiftAwesomeNotificationsPlugin.debug){
			Log.d(
				SwiftAwesomeNotificationsPlugin.TAG,
				"Notification lifeCycle: (WillResignActive) " 
					+ SwiftAwesomeNotificationsPlugin.appLifeCycle.rawValue
			)
		}
    }
    
    public func applicationDidEnterBackground(_ application: UIApplication) {
        
        // applicationWillTerminate is not always get called, so the AppKilled state is not correct defined in this cases
        //SwiftAwesomeNotificationsPlugin.appLifeCycle = NotificationLifeCycle.Background
        
        SwiftAwesomeNotificationsPlugin.appLifeCycle = NotificationLifeCycle.AppKilled
        SwiftAwesomeNotificationsPlugin.didIRealyGoneBackground = true
		
        if(SwiftAwesomeNotificationsPlugin.debug){
			Log.d(
				SwiftAwesomeNotificationsPlugin.TAG,
				"Notification lifeCycle: (DidEnterBackground) " 
					+ SwiftAwesomeNotificationsPlugin.appLifeCycle.rawValue
			)
		}
        
        //startBackgroundScheduler()
    }
    
    public func applicationWillEnterForeground(_ application: UIApplication) {
	
        SwiftAwesomeNotificationsPlugin.appLifeCycle = NotificationLifeCycle.Background
        
        //stopBackgroundScheduler()
        rescheduleLostNotifications()
		
        if(SwiftAwesomeNotificationsPlugin.debug){
			Log.d(
				SwiftAwesomeNotificationsPlugin.TAG,
				"Notification lifeCycle: (WillEnterForeground) " 
					+ SwiftAwesomeNotificationsPlugin.appLifeCycle.rawValue
			)
		}
    }
    
    public func applicationWillTerminate(_ application: UIApplication) {
        
        SwiftAwesomeNotificationsPlugin.appLifeCycle = NotificationLifeCycle.AppKilled
        
        //SwiftAwesomeNotificationsPlugin.rescheduleBackgroundTask()
		
        if(SwiftAwesomeNotificationsPlugin.debug){
			Log.d(
				SwiftAwesomeNotificationsPlugin.TAG,
				"Notification lifeCycle: (WillTerminate) " 
					+ SwiftAwesomeNotificationsPlugin.appLifeCycle.rawValue
			)
		}
    }

    private static func requestPermissions() -> Bool {
        if #available(iOS 10.0, *) {
            NotificationBuilder.requestPermissions(completion: { authorized in
				if(debug){
					Log.d(SwiftAwesomeNotificationsPlugin.TAG, 
					authorized ? "Notifications authorized" : "Notifications not authorized")
				}
            })
        }
        return true
    }
    
    public func clearDeactivatedSchedules(){
        
        UNUserNotificationCenter.current().getPendingNotificationRequests(completionHandler: { activeSchedules in
            
            if activeSchedules.count > 0 {
                let schedules = ScheduleManager.listSchedules()
                
                if(!ListUtils.isEmptyLists(schedules)){
                    for pushNotification in schedules {
                        var founded = false
                        for activeSchedule in activeSchedules {
                            if activeSchedule.identifier != String(pushNotification.content!.id!) {
                                founded = true
                                break;
                            }
                        }
                        if(!founded){
                            ScheduleManager.cancelScheduled(id: pushNotification.content!.id!)
                        }
                    }
                }
            } else {
                ScheduleManager.cancelAllSchedules();
            }
        })
    }
    
    public func rescheduleLostNotifications(){
        let referenceDate = Date()
        
        let lostSchedules = ScheduleManager.listPendingSchedules(referenceDate: referenceDate)
        for pushNotification in lostSchedules {
            
            do {
                let hasNextValidDate:Bool = (pushNotification.schedule?.hasNextValidDate() ?? false)
                if  pushNotification.schedule?.createdDate == nil || !hasNextValidDate {
                    throw AwesomeNotificationsException.notificationExpired
                }
                
                if #available(iOS 10.0, *) {
                    try NotificationSenderAndScheduler().send(
                        createdSource: pushNotification.content!.createdSource!,
                        pushNotification: pushNotification,
                        completion: { sent, content, error in
                        }
                    )
                }
            } catch {
                let _ = ScheduleManager.removeSchedule(id: pushNotification.content!.id!)
            }
        }
        
        clearDeactivatedSchedules();
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
        
        /*
        // TODO(?): If this is ever uncommented, remember delegate forwarding (_originalNotificationCenterDelegate)!
        if #available(iOS 10.0, *) {
            UNUserNotificationCenter.current().delegate = self
            if(SwiftAwesomeNotificationsPlugin.firebaseEnabled){
                Messaging.messaging().delegate = self
            }
        }
        */
        
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

            UNUserNotificationCenter.current().getNotificationCategories(completionHandler: { results in
                UNUserNotificationCenter.current().setNotificationCategories(results.union([categoryObject]))
            })
        }
        
        SwiftAwesomeNotificationsPlugin.appLifeCycle = NotificationLifeCycle.AppKilled
        
        if(SwiftAwesomeNotificationsPlugin.debug){
			Log.d(SwiftAwesomeNotificationsPlugin.TAG, 
			"Awesome Notifications - App Group : "+Definitions.USER_DEFAULT_TAG)
		}
        
    }
    
    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
		
		do {
		
			switch call.method {
				
				case Definitions.CHANNEL_METHOD_INITIALIZE:
                    try channelMethodInitialize(call: call, result: result)
					return
				
				case Definitions.CHANNEL_METHOD_GET_DRAWABLE_DATA:
                    try channelMethodGetDrawableData(call: call, result: result)
					return;
				/*
				case Definitions.CHANNEL_METHOD_IS_FCM_AVAILABLE:
                    try channelMethodIsFcmAvailable(call: call, result: result)
					return
			  
				case Definitions.CHANNEL_METHOD_GET_FCM_TOKEN:
                    try channelMethodGetFcmToken(call: call, result: result)
					return
				*/
				case Definitions.CHANNEL_METHOD_IS_NOTIFICATION_ALLOWED:
                    try channelMethodIsNotificationAllowed(call: call, result: result)
					return

				case Definitions.CHANNEL_METHOD_REQUEST_NOTIFICATIONS:
                    try channelMethodRequestNotification(call: call, result: result)
					return
						
				case Definitions.CHANNEL_METHOD_CREATE_NOTIFICATION:
                    try channelMethodCreateNotification(call: call, result: result)
					return
					
				case Definitions.CHANNEL_METHOD_SET_NOTIFICATION_CHANNEL:
                    try channelMethodSetChannel(call: call, result: result)
					return
					
				case Definitions.CHANNEL_METHOD_REMOVE_NOTIFICATION_CHANNEL:
                    try channelMethodRemoveChannel(call: call, result: result)
					return
					
				case Definitions.CHANNEL_METHOD_GET_BADGE_COUNT:
                    try channelMethodGetBadgeCounter(call: call, result: result)
					return
					
				case Definitions.CHANNEL_METHOD_SET_BADGE_COUNT:
                    try channelMethodSetBadgeCounter(call: call, result: result)
					return

				case Definitions.CHANNEL_METHOD_INCREMENT_BADGE_COUNT:
                    try channelMethodIncrementBadgeCounter(call: call, result: result)
					return

				case Definitions.CHANNEL_METHOD_DECREMENT_BADGE_COUNT:
                    try channelMethodDecrementBadgeCounter(call: call, result: result)
					return
					
				case Definitions.CHANNEL_METHOD_RESET_BADGE:
                    try channelMethodResetBadge(call: call, result: result)
					return
                    
                case Definitions.CHANNEL_METHOD_DISMISS_NOTIFICATION:
                    try channelMethodDismissNotification(call: call, result: result)
                    return
                    
                case Definitions.CHANNEL_METHOD_CANCEL_SCHEDULE:
                    try channelMethodCancelSchedule(call: call, result: result)
                    return
                    
                case Definitions.CHANNEL_METHOD_CANCEL_NOTIFICATION:
                    try channelMethodCancelNotification(call: call, result: result)
                    return
                    
                case Definitions.CHANNEL_METHOD_DISMISS_ALL_NOTIFICATIONS:
                    try channelMethodDismissAllNotifications(call: call, result: result)
                    return
					
				case Definitions.CHANNEL_METHOD_CANCEL_ALL_SCHEDULES:
                    try channelMethodCancelAllSchedules(call: call, result: result)
					return
                    
                case Definitions.CHANNEL_METHOD_CANCEL_ALL_NOTIFICATIONS:
                    try channelMethodCancelAllNotifications(call: call, result: result)
                    return
                    
                case Definitions.CHANNEL_METHOD_GET_NEXT_DATE:
                    try channelMethodGetNextDate(call: call, result: result)
                    return
                    
                case Definitions.CHANNEL_METHOD_GET_UTC_TIMEZONE_IDENTIFIER:
                    try channelMethodGetUTCTimeZoneIdentifier(call: call, result: result)
                    return
                    
                case Definitions.CHANNEL_METHOD_GET_LOCAL_TIMEZONE_IDENTIFIER:
                    try channelMethodGetLocalTimeZoneIdentifier(call: call, result: result)
                    return
					
				case Definitions.CHANNEL_METHOD_LIST_ALL_SCHEDULES:
					try channelMethodListAllSchedules(call: call, result: result)
					return

				default:
					result(FlutterError.init(code: "methodNotFound", message: "method not found", details: call.method));
					return
			}

        } catch {

            result(
                FlutterError.init(
                    code: SwiftAwesomeNotificationsPlugin.TAG,
                    message: "\(error)",
                    details: error.localizedDescription
                )
            )

            result(false)
        }
    }
    
    private func channelMethodGetNextDate(call: FlutterMethodCall, result: @escaping FlutterResult) throws {

		let platformParameters:[String:Any?] = call.arguments as? [String:Any?] ?? [:]
		let fixedDate:String? = platformParameters[Definitions.NOTIFICATION_INITIAL_FIXED_DATE] as? String
        
        let timezone:String =
            (platformParameters[Definitions.NOTIFICATION_SCHEDULE_TIMEZONE] as? String) ?? DateUtils.utcTimeZone.identifier
        
		guard let scheduleData:[String : Any?] = platformParameters[Definitions.PUSH_NOTIFICATION_SCHEDULE] as? [String : Any?]
		else { result(nil); return }
        
        var scheduleModel:NotificationScheduleModel?
        if(scheduleData[Definitions.NOTIFICATION_SCHEDULE_INTERVAL] != nil){
            scheduleModel = NotificationIntervalModel().fromMap(arguments: scheduleData) as? NotificationScheduleModel
        } else {
            scheduleModel = NotificationCalendarModel().fromMap(arguments: scheduleData) as? NotificationScheduleModel
        }
        if(scheduleModel == nil){ result(nil); return }
        
        let nextValidDate:Date? = DateUtils.getNextValidDate(scheduleModel: scheduleModel!, fixedDate: fixedDate, timeZone: timezone)

		if(nextValidDate == nil){ result(nil); return }
        let convertedDate:String? = DateUtils.dateToString(nextValidDate, timeZone: timezone)

		result(convertedDate)
    }
    
    private func channelMethodGetUTCTimeZoneIdentifier(call: FlutterMethodCall, result: @escaping FlutterResult) throws {
        result(DateUtils.utcTimeZone.identifier)
    }
    
    private func channelMethodGetLocalTimeZoneIdentifier(call: FlutterMethodCall, result: @escaping FlutterResult) throws {
        result(DateUtils.localTimeZone.identifier)
    }
    
    private func channelMethodListAllSchedules(call: FlutterMethodCall, result: @escaping FlutterResult) throws {
        
        UNUserNotificationCenter.current().getPendingNotificationRequests(completionHandler: { activeSchedules in
            
            var serializeds:[[String:Any?]]  = []
            if activeSchedules.count > 0 {
                let schedules = ScheduleManager.listSchedules()
                
                if(!ListUtils.isEmptyLists(schedules)){
                    for pushNotification in schedules {
                        var founded = false
                        for activeSchedule in activeSchedules {
                            if activeSchedule.identifier == String(pushNotification.content!.id!) {
                                founded = true
                                let serialized:[String:Any?] = pushNotification.toMap()
                                serializeds.append(serialized)
                                break;
                            }
                        }
                        if(!founded){
                            ScheduleManager.cancelScheduled(id: pushNotification.content!.id!)
                        }
                    }
                }
            } else {
                ScheduleManager.cancelAllSchedules();
            }

            result(serializeds)
        })
    }
    
    private func channelMethodSetChannel(call: FlutterMethodCall, result: @escaping FlutterResult) throws {
	
		let channelData:[String:Any?] = call.arguments as! [String:Any?]
		let channel:NotificationChannelModel = NotificationChannelModel().fromMap(arguments: channelData) as! NotificationChannelModel
		
		ChannelManager.saveChannel(channel: channel)
		
		Log.d(SwiftAwesomeNotificationsPlugin.TAG, "Channel updated")
		result(true)
    }
    
    private func channelMethodRemoveChannel(call: FlutterMethodCall, result: @escaping FlutterResult) throws {
	
		let channelKey:String? = call.arguments as? String
				
		if (channelKey == nil){
			
			result(
				FlutterError.init(
					code: "Empty channel key",
					message: "Empty channel key",
					details: channelKey
				)
			)
		}
		else {
			
			let removed:Bool = ChannelManager.removeChannel(channelKey: channelKey!)
		 
			if removed {
				
				Log.d(SwiftAwesomeNotificationsPlugin.TAG, "Channel removed")
				result(removed)
			}
			else {
				
				Log.d(SwiftAwesomeNotificationsPlugin.TAG, "Channel '\(channelKey!)' not found")
				result(removed)
			}
		}
    }
    
    private func channelMethodInitialize(call: FlutterMethodCall, result: @escaping FlutterResult) throws {
	
		let platformParameters:[String:Any?] = call.arguments as? [String:Any?] ?? [:]
		let defaultIconPath:String? = platformParameters[Definitions.DEFAULT_ICON] as? String
		let channelsData:[Any] = platformParameters[Definitions.INITIALIZE_CHANNELS] as? [Any] ?? []

		try setDefaultConfigurations(
			defaultIconPath,
			channelsData
		)
		
		Log.d(SwiftAwesomeNotificationsPlugin.TAG, "Awesome Notifications service initialized")
					
		fireBackgroundLostEvents()
		
		result(true)
    }

    private func channelMethodGetDrawableData(call: FlutterMethodCall, result: @escaping FlutterResult) throws {
        
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
    
    /*private func channelMethodGetFcmToken(call: FlutterMethodCall, result: @escaping FlutterResult) throws {
        
        result(FlutterError.init(
            code: "Method deprecated",
            message: "Method deprecated",
            details: "channelMethodGetFcmToken"
        ))
         
        let token = requestFirebaseToken()
        result(token)
        
        result(nil)
    }
		
    private func channelMethodIsFcmAvailable(call: FlutterMethodCall, result: @escaping FlutterResult) throws {
        result(FlutterError.init(
            code: "Method deprecated",
            message: "Method deprecated",
            details: "channelMethodGetFcmToken"
        ))
        
        let token = requestFirebaseToken()
        result(!StringUtils.isNullOrEmpty(token))
         
    }*/
    
    private func channelMethodIsNotificationAllowed(call: FlutterMethodCall, result: @escaping FlutterResult) throws {
        if #available(iOS 10.0, *) {
            NotificationBuilder.isNotificationAllowed(completion: { (allowed) in
                result(allowed)
            })
        }
        else {
            result(nil)
        }
    }

    private func channelMethodRequestNotification(call: FlutterMethodCall, result: @escaping FlutterResult) throws {
        if #available(iOS 10.0, *) {
            NotificationBuilder.requestPermissions { (allowed) in
                result(allowed)
            }
        }
        else {
            result(nil)
        }
    }
    
    private func channelMethodGetBadgeCounter(call: FlutterMethodCall, result: @escaping FlutterResult) throws {
        if #available(iOS 10.0, *) {
            result(NotificationBuilder.getBadge().intValue)
        }
        else {
            result(0)
        }
    }
    
    private func channelMethodSetBadgeCounter(call: FlutterMethodCall, result: @escaping FlutterResult) throws {

		let count:Int = call.arguments as? Int ?? -1

        if (count < 0) {
            throw AwesomeNotificationsException.invalidRequiredFields(msg: "Invalid Badge value")
        }
        
        if #available(iOS 10.0, *) {
            NotificationBuilder.setBadge(count)
        }
        result(nil)
    }

    private func channelMethodIncrementBadgeCounter(call: FlutterMethodCall, result: @escaping FlutterResult) throws {
        if #available(iOS 10.0, *) {
            let actualValue:NSNumber = NotificationBuilder.incrementBadge()
            result(actualValue.intValue)
            return
        }
        result(nil)
    }

    private func channelMethodDecrementBadgeCounter(call: FlutterMethodCall, result: @escaping FlutterResult) throws {
        if #available(iOS 10.0, *) {
            let actualValue:NSNumber = NotificationBuilder.decrementBadge()
            result(actualValue.intValue)
            return
        }
        result(nil)
    }
    
    private func channelMethodResetBadge(call: FlutterMethodCall, result: @escaping FlutterResult) throws {
        if #available(iOS 10.0, *) {
            NotificationBuilder.resetBadge()
        }
        result(nil)
    }
    
    private func channelMethodDismissNotification(call: FlutterMethodCall, result: @escaping FlutterResult) throws {
        guard let notificationId:Int = call.arguments as? Int else {
            result(false); return
        }
        
        if #available(iOS 10.0, *) {
            result(NotificationSenderAndScheduler.dismissNotification(id: notificationId))
            return
        } else {
            // Fallback on earlier versions
        }
        
        result(false)
    }
    
    private func channelMethodCancelSchedule(call: FlutterMethodCall, result: @escaping FlutterResult) throws {
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
    
    private func channelMethodCancelNotification(call: FlutterMethodCall, result: @escaping FlutterResult) throws {
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
    
    private func channelMethodDismissAllNotifications(call: FlutterMethodCall, result: @escaping FlutterResult) throws {
        
        if #available(iOS 10.0, *) {
            result(NotificationSenderAndScheduler.dismissAllNotifications())
            return
        } else {
            // Fallback on earlier versions
        }
        
        result(false)
    }
    
    private func channelMethodCancelAllSchedules(call: FlutterMethodCall, result: @escaping FlutterResult) throws {
        
        if #available(iOS 10.0, *) {
            result(NotificationSenderAndScheduler.cancelAllSchedules())
            return
        } else {
            // Fallback on earlier versions
        }
        
        result(false)
    }

    private func channelMethodCancelAllNotifications(call: FlutterMethodCall, result: @escaping FlutterResult) throws {
        
        if #available(iOS 10.0, *) {
            result(NotificationSenderAndScheduler.cancelAllNotifications())
            return
        } else {
            // Fallback on earlier versions
        }
        
        result(false)
    }

    private func channelMethodCreateNotification(call: FlutterMethodCall, result: @escaping FlutterResult) throws {
        
		let pushData:[String:Any?] = call.arguments as? [String:Any?] ?? [:]
		let pushNotification:PushNotification? = PushNotification().fromMap(arguments: pushData) as? PushNotification
		
		if(pushNotification != nil){
				
			if #available(iOS 10.0, *) {
				try NotificationSenderAndScheduler().send(
					createdSource: NotificationSource.Local,
					pushNotification: pushNotification,
					completion: { sent, content, error in
					
						if error != nil {
							let flutterError:FlutterError?
							if let notificationError = error as? AwesomeNotificationsException {
								switch notificationError {
									case AwesomeNotificationsException.notificationNotAuthorized:
										flutterError = FlutterError.init(
											code: "notificationNotAuthorized",
											message: "Notifications are disabled",
											details: nil
										)
									case AwesomeNotificationsException.cronException:
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
				
				result(true)
				return
			}
		}
		else {
            throw AwesomeNotificationsException.invalidRequiredFields(msg: "Notification content is invalid")
		}
        
        result(false)
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
