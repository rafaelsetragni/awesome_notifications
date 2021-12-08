
import UIKit
import Flutter
//import BackgroundTasks
import UserNotifications

public class SwiftAwesomeNotificationsPlugin: NSObject, FlutterPlugin, UNUserNotificationCenterDelegate {
    
    private static var _instance:SwiftAwesomeNotificationsPlugin?
    
    static var debug = false
    static let TAG = "AwesomeNotificationsPlugin"
        
    public static var appLifeCycle:NotificationLifeCycle {
        get { return LifeCycleManager.getLifeCycle(referenceKey: "currentlifeCycle") }
        set (newValue) { LifeCycleManager.setLifeCycle(referenceKey: "currentlifeCycle", lifeCycle: newValue) }
    }

#if !ACTION_EXTENSION
    static var registrar:FlutterPluginRegistrar?
    var flutterChannel:FlutterMethodChannel?
#endif
    // them, we forward on any delegate calls that we receive.
    private var _originalNotificationCenterDelegate: UNUserNotificationCenterDelegate?
    
    public static var instance:SwiftAwesomeNotificationsPlugin? {
        get { return _instance }
    }
    
    private static func checkGooglePlayServices() -> Bool {
        return true
    }

    @available(iOS 10.0, *)
    public func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        
        var userText:String?
        if let textResponse =  response as? UNTextInputNotificationResponse {
            userText =  textResponse.userText
        }

        if let jsonData:String = response.notification.request.content.userInfo[Definitions.NOTIFICATION_JSON] as? String {
            receiveAction(
                  jsonData: jsonData,
                  buttonKeyPressed: response.actionIdentifier,
                  userText: userText,
                  withCompletionHandler: completionHandler
              )
        } else {
            print("Received an invalid notification content")
            
            if _originalNotificationCenterDelegate != nil {
                _originalNotificationCenterDelegate?.userNotificationCenter?(center, didReceive: response, withCompletionHandler: completionHandler)
            }
            else {
                completionHandler()
            }
        }
    }

    @available(iOS 10.0, *)
    public func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        if !receiveNotification(content: notification.request.content, withCompletionHandler: completionHandler) {
            // completionHandler was *not* called, so maybe this notification is for another plugin:

            if _originalNotificationCenterDelegate != nil {
                _originalNotificationCenterDelegate?.userNotificationCenter?(center, willPresent: notification, withCompletionHandler: completionHandler)
            }
            else {
                completionHandler([.alert, .badge, .sound])
            }
        }
    }
    
    public func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [AnyHashable : Any] = [:]) -> Bool {
        
        // Set ourselves as the UNUserNotificationCenter delegate, but also preserve any existing delegate...
        let notificationCenter = UNUserNotificationCenter.current()
        _originalNotificationCenterDelegate = notificationCenter.delegate
        notificationCenter.delegate = self
        
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
            
            if(arguments[Definitions.NOTIFICATION_MODEL_CONTENT] is String){
                arguments[Definitions.NOTIFICATION_MODEL_CONTENT] = JsonUtils.fromJson(arguments[Definitions.NOTIFICATION_MODEL_CONTENT] as? String)
            }
            
            if(arguments[Definitions.NOTIFICATION_MODEL_BUTTONS] is String){
                arguments[Definitions.NOTIFICATION_MODEL_BUTTONS] = JsonUtils.fromJson(arguments[Definitions.NOTIFICATION_MODEL_BUTTONS] as? String)
            }
            
            if(arguments[Definitions.NOTIFICATION_MODEL_SCHEDULE] is String){
                arguments[Definitions.NOTIFICATION_MODEL_SCHEDULE] = JsonUtils.fromJson(arguments[Definitions.NOTIFICATION_MODEL_SCHEDULE] as? String)
            }
        }
        
        guard let notificationModel:NotificationModel = NotificationBuilder.jsonDataToNotificationModel(jsonData: arguments)
        else {
            Log.d("receiveNotification","notification data invalid")
            return false
        }
        
        /*
        if(content.userInfo["updated"] == nil){
            
            let pushData = notificationModel.toMap()
            let updatedJsonData = JsonUtils.toJson(pushData)
            
            let content:UNMutableNotificationContent =
                UNMutableNotificationContent().copyContent(from: content)
            
            content.userInfo[Definitions.NOTIFICATION_JSON] = updatedJsonData
            content.userInfo["updated"] = true
            
            let request = UNNotificationRequest(identifier: notificationModel!.content!.id!.description, content: content, trigger: nil)
            
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
    
        let notificationReceived:NotificationReceived? = NotificationReceived(notificationModel.content)
        if(notificationReceived != nil){
            
            notificationModel.content!.displayedLifeCycle = SwiftAwesomeNotificationsPlugin.appLifeCycle
                        
            let channel:NotificationChannelModel? = ChannelManager.getChannelByKey(channelKey: notificationModel.content!.channelKey!)
            
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
            if(notificationModel.schedule != nil){
                                
                do {
                    try NotificationSenderAndScheduler().send(
                        createdSource: notificationModel.content!.createdSource!,
                        notificationModel: notificationModel,
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
    
#if !ACTION_EXTENSION
    private func receiveAction(jsonData: String?, buttonKeyPressed:String?, userText:String?, withCompletionHandler completionHandler: @escaping () -> Void){
		
        if(SwiftAwesomeNotificationsPlugin.appLifeCycle == .AppKilled){
            fireBackgroundLostEvents()
        }
        
        if #available(iOS 10.0, *) {
            let actionReceived:ActionReceived? = NotificationBuilder.buildNotificationActionFromJson(jsonData: jsonData, buttonKeyPressed: buttonKeyPressed, userText: userText)
            
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
        } 
        completionHandler()
    }
#endif
    
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
		
        PermissionManager.handlePermissionResult()
        
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

        PermissionManager.handlePermissionResult()
		
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
    
    public func clearDeactivatedSchedules(){
        
        UNUserNotificationCenter.current().getPendingNotificationRequests(completionHandler: { activeSchedules in
            
            if activeSchedules.count > 0 {
                let schedules = ScheduleManager.listSchedules()
                
                if(!ListUtils.isEmptyLists(schedules)){
                    for notificationModel in schedules {
                        var founded = false
                        for activeSchedule in activeSchedules {
                            if activeSchedule.identifier != String(notificationModel.content!.id!) {
                                founded = true
                                break;
                            }
                        }
                        if(!founded){
                            _ = ScheduleManager.cancelScheduled(id: notificationModel.content!.id!)
                        }
                    }
                }
            } else {
                _ = ScheduleManager.cancelAllSchedules();
            }
        })
    }
    
    public func rescheduleLostNotifications(){
        let referenceDate = Date()
        
        let lostSchedules = ScheduleManager.listPendingSchedules(referenceDate: referenceDate)
        for notificationModel in lostSchedules {
            
            do {
                let hasNextValidDate:Bool = (notificationModel.schedule?.hasNextValidDate() ?? false)
                if  notificationModel.schedule?.createdDate == nil || !hasNextValidDate {
                    throw AwesomeNotificationsException.notificationExpired
                }
                
                try NotificationSenderAndScheduler().send(
                    createdSource: notificationModel.content!.createdSource!,
                    notificationModel: notificationModel,
                    completion: { sent, content, error in
                    }
                )
            } catch {
                let _ = ScheduleManager.removeSchedule(id: notificationModel.content!.id!)
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
        
        if !SwiftUtils.isRunningOnExtension() {
            UIApplication.shared.registerForRemoteNotifications()
        }
        
        let categoryObject = UNNotificationCategory(
            identifier: Definitions.DEFAULT_CATEGORY_IDENTIFIER,
            actions: [],
            intentIdentifiers: [],
            options: .customDismissAction
        )

        UNUserNotificationCenter.current().getNotificationCategories(completionHandler: { results in
            UNUserNotificationCenter.current().setNotificationCategories(results.union([categoryObject]))
        })
        
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

				case Definitions.CHANNEL_METHOD_IS_NOTIFICATION_ALLOWED:
                    try channelMethodIsNotificationAllowed(call: call, result: result)
					return
                
                case Definitions.CHANNEL_METHOD_SHOULD_SHOW_RATIONALE:
                    try channelMethodShouldShowRationale(call: call, result: result)
                    return
                
                case Definitions.CHANNEL_METHOD_SHOW_NOTIFICATION_PAGE:
                    try channelMethodShowNotificationConfigPage(call: call, result: result)
                    return
                    
                case Definitions.CHANNEL_METHOD_SHOW_ALARM_PAGE:
                    try channelMethodShowPreciseAlarmsPage(call: call, result: result)
                    return
                
                case Definitions.CHANNEL_METHOD_SHOW_GLOBAL_DND_PAGE:
                    try channelMethodShowGlobalDndPage(call: call, result: result)
                    return
                    
                case Definitions.CHANNEL_METHOD_CHECK_PERMISSIONS:
                    try channelMethodCheckPermissions(call: call, result: result)
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
                    
                case Definitions.CHANNEL_METHOD_DISMISS_NOTIFICATIONS_BY_CHANNEL_KEY:
                    try channelMethodDismissNotificationsByChannelKey(call: call, result: result)
                    return
                    
                case Definitions.CHANNEL_METHOD_CANCEL_SCHEDULES_BY_CHANNEL_KEY:
                    try channelMethodCancelSchedulesByChannelKey(call: call, result: result)
                    return
                    
                case Definitions.CHANNEL_METHOD_CANCEL_NOTIFICATIONS_BY_CHANNEL_KEY:
                    try channelMethodCancelNotificationsByChannelKey(call: call, result: result)
                    return

                case Definitions.CHANNEL_METHOD_DISMISS_NOTIFICATIONS_BY_GROUP_KEY:
                    try channelMethodDismissNotificationsByGroupKey(call: call, result: result)
                    return

                case Definitions.CHANNEL_METHOD_CANCEL_SCHEDULES_BY_GROUP_KEY:
                    try channelMethodCancelSchedulesByGroupKey(call: call, result: result)
                    return

                case Definitions.CHANNEL_METHOD_CANCEL_NOTIFICATIONS_BY_GROUP_KEY:
                    try channelMethodCancelNotificationsByGroupKey(call: call, result: result)
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
        
		guard let scheduleData:[String : Any?] = platformParameters[Definitions.NOTIFICATION_MODEL_SCHEDULE] as? [String : Any?]
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
                    for notificationModel in schedules {
                        var founded = false
                        for activeSchedule in activeSchedules {
                            if activeSchedule.identifier == String(notificationModel.content!.id!) {
                                founded = true
                                let serialized:[String:Any?] = notificationModel.toMap()
                                serializeds.append(serialized)
                                break;
                            }
                        }
                        if(!founded){
                            _ = ScheduleManager.cancelScheduled(id: notificationModel.content!.id!)
                        }
                    }
                }
            } else {
                _ = ScheduleManager.cancelAllSchedules();
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
    
    private func isChannelEnabled(channelKey:String) -> Bool {
        let channel:NotificationChannelModel? = ChannelManager.getChannelByKey(channelKey: channelKey)
        return
            channel?.importance == nil ?
                false :
                channel?.importance != NotificationImportance.None
    }
    
    private func channelMethodIsNotificationAllowed(call: FlutterMethodCall, result: @escaping FlutterResult) throws {
        PermissionManager.areNotificationsGloballyAllowed(permissionCompletion: { (allowed) in
            result(allowed)
        })
    }
    
    private func channelMethodShowPreciseAlarmsPage(call: FlutterMethodCall, result: @escaping FlutterResult) throws {
        // There is no precise alarms page on iOS. This mode is always enabled
        result(false)
    }
    
    private func channelMethodShowGlobalDndPage(call: FlutterMethodCall, result: @escaping FlutterResult) throws {
        // There is no override DnD on iOS. This mode is always enabled with critical alerts
        result(false)
    }
    
    private func channelMethodShowNotificationConfigPage(call: FlutterMethodCall, result: @escaping FlutterResult) throws {
        PermissionManager.showNotificationConfigPage(completionHandler: {
            result(true)
        })
    }
    
    private func channelMethodShouldShowRationale(call: FlutterMethodCall, result: @escaping FlutterResult) throws {
        
        let platformParameters:[String:Any?] = call.arguments as? [String:Any?] ?? [:]
        
        let channelKey:String? = platformParameters[Definitions.NOTIFICATION_CHANNEL_KEY] as? String
        
        guard let permissions:[String] = platformParameters[Definitions.NOTIFICATION_PERMISSIONS] as? [String] else {
            throw AwesomeNotificationsException.invalidRequiredFields(msg: "Permission list is required")
        }

        if(permissions.isEmpty){
            throw AwesomeNotificationsException.invalidRequiredFields(msg: "Permission list cannot be empty")
        }

        PermissionManager.shouldShowRationale(permissions, channelKey: channelKey, completion: { (permissionsAllowed) in
            result(permissionsAllowed)
        })
    }

    private func channelMethodCheckPermissions(call: FlutterMethodCall, result: @escaping FlutterResult) throws {
        
        let platformParameters:[String:Any?] = call.arguments as? [String:Any?] ?? [:]
        
        let channelKey:String? = platformParameters[Definitions.NOTIFICATION_CHANNEL_KEY] as? String
        
        guard let permissions:[String] = platformParameters[Definitions.NOTIFICATION_PERMISSIONS] as? [String] else {
            throw AwesomeNotificationsException.invalidRequiredFields(msg: "Permission list is required")
        }

        if(permissions.isEmpty){
            throw AwesomeNotificationsException.invalidRequiredFields(msg: "Permission list cannot be empty")
        }

        PermissionManager.arePermissionsAllowed(permissions, channelKey: channelKey, completion: { (permissionsAllowed) in
            result(permissionsAllowed)
        })
    }

    private func channelMethodRequestNotification(call: FlutterMethodCall, result: @escaping FlutterResult) throws {
        
        let platformParameters:[String:Any?] = call.arguments as? [String:Any?] ?? [:]
        
        let channelKey:String? = platformParameters[Definitions.NOTIFICATION_CHANNEL_KEY] as? String
        
        guard let permissions:[String] = platformParameters[Definitions.NOTIFICATION_PERMISSIONS] as? [String] else {
            throw AwesomeNotificationsException.invalidRequiredFields(msg: "Permission list is required")
        }

        if(permissions.isEmpty){
            throw AwesomeNotificationsException.invalidRequiredFields(msg: "Permission list cannot be empty")
        }
        
        try PermissionManager.requestUserPermissions(permissions: permissions, channelKey: channelKey, permissionCompletion: { (deniedPermissions) in
            result(deniedPermissions)
        })
    }
    
    private func channelMethodGetBadgeCounter(call: FlutterMethodCall, result: @escaping FlutterResult) throws {
        result(BadgeManager.getGlobalBadgeCounter())
    }
    
    private func channelMethodSetBadgeCounter(call: FlutterMethodCall, result: @escaping FlutterResult) throws {

		let count:Int = call.arguments as? Int ?? -1

        if (count < 0) {
            throw AwesomeNotificationsException.invalidRequiredFields(msg: "Invalid Badge value")
        }
        
        BadgeManager.setGlobalBadgeCounter(count)
        result(nil)
    }

    private func channelMethodIncrementBadgeCounter(call: FlutterMethodCall, result: @escaping FlutterResult) throws {
        let actualValue:Int = BadgeManager.incrementGlobalBadgeCounter()
        result(actualValue)
        return
    }

    private func channelMethodDecrementBadgeCounter(call: FlutterMethodCall, result: @escaping FlutterResult) throws {
        
        let actualValue:Int = BadgeManager.decrementGlobalBadgeCounter()
        result(actualValue)
        return
    }
    
    private func channelMethodResetBadge(call: FlutterMethodCall, result: @escaping FlutterResult) throws {
        BadgeManager.resetGlobalBadgeCounter()
        result(nil)
    }
    
    private func channelMethodDismissNotification(call: FlutterMethodCall, result: @escaping FlutterResult) throws {
        guard let notificationId:Int = call.arguments as? Int else {
            result(false); return
        }
        
        let success:Bool = CancellationManager.dismissNotification(id: notificationId)
        
        if(SwiftAwesomeNotificationsPlugin.debug){
            Log.d(SwiftAwesomeNotificationsPlugin.TAG, "Notification id "+String(notificationId)+" dismissed")
        }
        
        result(success)
    }
    
    private func channelMethodCancelSchedule(call: FlutterMethodCall, result: @escaping FlutterResult) throws {
        guard let notificationId:Int = call.arguments as? Int else {
            result(false); return
        }
        
        let success:Bool = CancellationManager.cancelSchedule(id: notificationId)
        
        if(SwiftAwesomeNotificationsPlugin.debug){
            Log.d(SwiftAwesomeNotificationsPlugin.TAG, "Schedule id "+String(notificationId)+" cancelled")
        }
        
        result(success)
    }
    
    private func channelMethodCancelNotification(call: FlutterMethodCall, result: @escaping FlutterResult) throws {
        guard let notificationId:Int = call.arguments as? Int else {
            result(false); return
        }
        
        let success:Bool = CancellationManager.cancelNotification(id: notificationId)
        
        if(SwiftAwesomeNotificationsPlugin.debug){
            Log.d(SwiftAwesomeNotificationsPlugin.TAG, "Notification id "+String(notificationId)+" cancelled")
        }
        
        result(success)
    }

    private func channelMethodDismissNotificationsByChannelKey(call: FlutterMethodCall, result: @escaping FlutterResult) throws {
        guard let channelKey:String = call.arguments as? String else {
            result(false); return
        }
        
        let success:Bool = CancellationManager.dismissNotificationsByChannelKey(channelKey: channelKey)
        
        if(SwiftAwesomeNotificationsPlugin.debug){
            Log.d(SwiftAwesomeNotificationsPlugin.TAG, "Notifications from channel "+channelKey+" dismissed")
        }
        
        result(success)
    }

    private func channelMethodCancelSchedulesByChannelKey(call: FlutterMethodCall, result: @escaping FlutterResult) throws {
        guard let channelKey:String = call.arguments as? String else {
            result(false); return
        }
        
        let success:Bool = CancellationManager.cancelSchedulesByChannelKey(channelKey: channelKey)
        
        if(SwiftAwesomeNotificationsPlugin.debug){
            Log.d(SwiftAwesomeNotificationsPlugin.TAG, "Schedules from channel "+channelKey+" cancelled")
        }
        
        result(success)
    }

    private func channelMethodCancelNotificationsByChannelKey(call: FlutterMethodCall, result: @escaping FlutterResult) throws {
        guard let channelKey:String = call.arguments as? String else {
            result(false); return
        }
        
        let success:Bool = CancellationManager.cancelNotificationsByChannelKey(channelKey: channelKey)
        
        if(SwiftAwesomeNotificationsPlugin.debug){
            Log.d(SwiftAwesomeNotificationsPlugin.TAG, "Notifications from channel "+channelKey+" cancelled")
        }
        
        result(success)
    }

    private func channelMethodDismissNotificationsByGroupKey(call: FlutterMethodCall, result: @escaping FlutterResult) throws {
        guard let groupKey:String = call.arguments as? String else {
            result(false); return
        }
        
        let success:Bool = CancellationManager.dismissNotificationsByGroupKey(groupKey: groupKey)
        
        if(SwiftAwesomeNotificationsPlugin.debug){
            Log.d(SwiftAwesomeNotificationsPlugin.TAG, "Notifications from group "+groupKey+" cancelled")
        }

        result(success)
    }

    private func channelMethodCancelSchedulesByGroupKey(call: FlutterMethodCall, result: @escaping FlutterResult) throws {
        guard let groupKey:String = call.arguments as? String else {
            result(false); return
        }
        
        let success:Bool = CancellationManager.cancelSchedulesByGroupKey(groupKey: groupKey)

        if(SwiftAwesomeNotificationsPlugin.debug){
            Log.d(SwiftAwesomeNotificationsPlugin.TAG, "Schedules from group "+groupKey+" cancelled")
        }
        
        result(success)
    }

    private func channelMethodCancelNotificationsByGroupKey(call: FlutterMethodCall, result: @escaping FlutterResult) throws {
        guard let groupKey:String = call.arguments as? String else {
            result(false); return
        }
        
        let success:Bool = CancellationManager.cancelNotificationsByGroupKey(groupKey: groupKey)
        
        if(SwiftAwesomeNotificationsPlugin.debug){
            Log.d(SwiftAwesomeNotificationsPlugin.TAG, "Notifications from group "+groupKey+" cancelled")
        }
        
        result(success)
    }
    
    private func channelMethodDismissAllNotifications(call: FlutterMethodCall, result: @escaping FlutterResult) throws {
        
        let success:Bool = CancellationManager.dismissAllNotifications()
        
        if(SwiftAwesomeNotificationsPlugin.debug){
            Log.d(SwiftAwesomeNotificationsPlugin.TAG, "All notifications was dismissed")
        }
        
        result(success)
    }
    
    private func channelMethodCancelAllSchedules(call: FlutterMethodCall, result: @escaping FlutterResult) throws {
        
        let success:Bool = CancellationManager.cancelAllSchedules()
        
        if(SwiftAwesomeNotificationsPlugin.debug){
            Log.d(SwiftAwesomeNotificationsPlugin.TAG, "All schedules was cancelled")
        }
        
        result(success)
    }

    private func channelMethodCancelAllNotifications(call: FlutterMethodCall, result: @escaping FlutterResult) throws {
        
        let success:Bool = CancellationManager.cancelAllNotifications()
        
        if(SwiftAwesomeNotificationsPlugin.debug){
            Log.d(SwiftAwesomeNotificationsPlugin.TAG, "All notifications was cancelled")
        }
        
        result(success)
    }

    private func channelMethodCreateNotification(call: FlutterMethodCall, result: @escaping FlutterResult) throws {
        
		let pushData:[String:Any?] = call.arguments as? [String:Any?] ?? [:]
		let notificationModel:NotificationModel? = NotificationModel().fromMap(arguments: pushData) as? NotificationModel
		
		if(notificationModel != nil){
				
            try NotificationSenderAndScheduler().send(
                createdSource: NotificationSource.Local,
                notificationModel: notificationModel,
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
		}
		else {
            result(false)
            throw AwesomeNotificationsException.invalidRequiredFields(msg: "Notification content is invalid")
		}
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
