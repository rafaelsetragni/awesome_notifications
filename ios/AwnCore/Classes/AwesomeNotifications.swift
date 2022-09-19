//
//  AwesomeNotifications.swift
//  awesome_notifications
//
//  Created by CardaDev on 30/01/22.
//

import Foundation

public class AwesomeNotifications:
        NSObject,
        AwesomeActionEventListener,
        AwesomeNotificationEventListener,
        AwesomeLifeCycleEventListener,
        UIApplicationDelegate,
        UNUserNotificationCenterDelegate
{
    let TAG = "AwesomeNotifications"
    
    static var _debug:Bool? = nil
    public static var debug:Bool {
        get {
            if _debug == nil {
                _debug = DefaultsManager.shared.debug
            }
            return _debug!
        }
        set {
            _debug = newValue
            DefaultsManager.shared.debug = newValue
        }
    }
    
    static var initialValues:[String : Any?] = [:]
    
    public static var awesomeExtensions:AwesomeNotificationsExtension?
    public static var backgroundClassType:BackgroundExecutor.Type?
    
    // ************************** CONSTRUCTOR ***********************************
        
    public override init() {
        super.init()
        
        AwesomeNotifications.debug = isApplicationInDebug()
        
        if !SwiftUtils.isRunningOnExtension() {
            LifeCycleManager
                .shared
                .subscribe(listener: self)
                .startListeners()
        }
        
        activateiOSNotifications()
    }
    
    static var areDefaultsLoaded = false
    public static func loadExtensions() throws {
        if areDefaultsLoaded {
            return
        }
        
        if AwesomeNotifications.awesomeExtensions == nil {
            throw ExceptionFactory
                    .shared
                    .createNewAwesomeException(
                        className: "SwiftLoadDefaults",
                        code: ExceptionCode.CODE_INITIALIZATION_EXCEPTION,
                        message: "Awesome's plugin extension reference was not found.",
                        detailedCode: ExceptionCode.DETAILED_INITIALIZATION_FAILED+".awesomeNotifications.extensions")
        }
        
        AwesomeNotifications.awesomeExtensions!.loadExternalExtensions()
        
        areDefaultsLoaded = true
    }
    
    private var isTheMainInstance = false
    public func attachAsMainInstance(usingAwesomeEventListener listener: AwesomeEventListener){
        if self.isTheMainInstance {
            return
        }
        
        self.isTheMainInstance = true
        
        subscribeOnAwesomeNotificationEvents(listener: listener)
        
        AwesomeEventsReceiver
            .shared
            .subscribeOnNotificationEvents(listener: self)
            .subscribeOnActionEvents(listener: self)
        
        Logger.d(TAG, "Awesome notifications \(self.hash) attached to app instance");
    }
    
    public func detachAsMainInstance(listener: AwesomeEventListener){
        if !self.isTheMainInstance {
            return
        }
        
        self.isTheMainInstance = false
        
        unsubscribeOnAwesomeNotificationEvents(listener: listener)
        
        AwesomeEventsReceiver
            .shared
            .unsubscribeOnNotificationEvents(listener: self)
            .unsubscribeOnActionEvents(listener: self)
        
        Logger.d(TAG, "Awesome notifications \(self.hash) detached from app instance");
    }
    
    public func dispose(){
        if !SwiftUtils.isRunningOnExtension() {
            LifeCycleManager
                .shared
                .unsubscribe(listener: self)
        }
    }
    
    public func initialize() {
        AwesomeNotifications.initialValues.removeAll()
        AwesomeNotifications.initialValues.merge(
                Definitions.initialValues,
                uniquingKeysWith: { (current, _) in current })
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    func activateiOSNotifications(){
        
        let categoryObject = UNNotificationCategory(
            identifier: Definitions.DEFAULT_CATEGORY_IDENTIFIER.uppercased(),
            actions: [],
            intentIdentifiers: [],
            options: .customDismissAction
        )

        UNUserNotificationCenter.current().getNotificationCategories(completionHandler: { results in
            UNUserNotificationCenter.current().setNotificationCategories(results.union([categoryObject]))
        })
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(self.didFinishLaunch),
            name: UIApplication.didFinishLaunchingNotification, object: nil)
    }
    
    // ***********************  EVENT INTERFACES  *******************************
    
    public func onNewNotificationReceived(eventName: String, notificationReceived: NotificationReceived) {
        notifyNotificationEvent(eventName: eventName, notificationReceived: notificationReceived)
    }
    
    public func onNewActionReceived(fromEventNamed eventName: String, withActionReceived actionReceived: ActionReceived) {
        notifyActionEvent(fromEventNamed: eventName, withActionReceived: actionReceived)
    }
    
    public func onNewActionReceivedWithInterruption(fromEventNamed eventName: String, withActionReceived actionReceived: ActionReceived) -> Bool {
        return false
    }
    
    public func onNewLifeCycleEvent(lifeCycle: NotificationLifeCycle) {
        
        if !isTheMainInstance {
            return
        }
        
        switch lifeCycle {
            
            case .Foreground:
                PermissionManager
                    .shared
                    .handlePermissionResult()
                do {
                    if (
                        DefaultsManager
                            .shared
                            .actionCallback != 0){
                        try recoverNotificationsDisplayed(
                            withReferenceLifeCycle: .Background
                        )
                    }
                } catch {
                    
                }
                break
            
            case .Background:
                break
                
            
            case .AppKilled:
                break
        }
    }
    
    // **************************** OBSERVER PATTERN **************************************
    
    private lazy var notificationEventListeners = [AwesomeNotificationEventListener]()
    
    public func subscribeOnNotificationEvents(listener:AwesomeNotificationEventListener) {
        notificationEventListeners.append(listener)
    }
    
    public func unsubscribeOnNotificationEvents(listener:AwesomeNotificationEventListener) {
        if let index = notificationEventListeners.firstIndex(where: {$0 === listener}) {
            notificationEventListeners.remove(at: index)
        }
    }
    
    private func notifyNotificationEvent(eventName:String, notificationReceived:NotificationReceived){
        notifyAwesomeEvent(eventType: eventName, content: notificationReceived.toMap())
        for listener in notificationEventListeners {
            listener.onNewNotificationReceived(
                eventName: eventName,
                notificationReceived: notificationReceived)
        }
    }
    
    // **************************** OBSERVER PATTERN **************************************
    
    private lazy var notificationActionListeners = [AwesomeActionEventListener]()
    
    public func subscribeOnActionEvents(listener:AwesomeActionEventListener) {
        notificationActionListeners.append(listener)
    }
    
    public func unsubscribeOnActionEvents(listener:AwesomeActionEventListener) {
        if let index = notificationActionListeners.firstIndex(where: {$0 === listener}) {
            notificationActionListeners.remove(at: index)
        }
    }
    
    private func notifyActionEvent(fromEventNamed eventName:String, withActionReceived actionReceived:ActionReceived){
        notifyAwesomeEvent(eventType: eventName, content: actionReceived.toMap())
        for listener in notificationActionListeners {
            listener
                .onNewActionReceived(
                    fromEventNamed: eventName,
                    withActionReceived: actionReceived)
        }
    }
    
    // ***************************************************************************************
    
    private lazy var awesomeEventListeners = [AwesomeEventListener]()
    
    public func subscribeOnAwesomeNotificationEvents(listener:AwesomeEventListener) {
        awesomeEventListeners.append(listener)
    }
    
    public func unsubscribeOnAwesomeNotificationEvents(listener:AwesomeEventListener) {
        if let index = awesomeEventListeners.firstIndex(where: {$0 === listener}) {
            awesomeEventListeners.remove(at: index)
        }
    }
    
    private func notifyAwesomeEvent(eventType: String, content: [String : Any?]){
        for listener in awesomeEventListeners {
            listener.onNewAwesomeEvent(eventType: eventType, content: content)
        }
    }
    
    // *****************************  LIFECYCLE FUNCTIONS  **********************************
    
    public var currentLifeCycle: NotificationLifeCycle {
        get { return LifeCycleManager.shared.currentLifeCycle }
        set { LifeCycleManager.shared.currentLifeCycle = newValue }
    }
    
    // *****************************  DRAWABLE FUNCTIONS  **********************************
    
    public func getDrawableData(bitmapReference:String) -> Data? {
        guard let image:UIImage =
            BitmapUtils
                .shared
                .getBitmapFromSource(
                    bitmapPath: bitmapReference,
                    roundedBitpmap: false)
        else {
            return nil
        }
        
        return UIImage.pngData(image)()
    }
    
    // ***************************************************************************************
    
    public func setActionHandle(actionHandle:Int64, recoveringLostDisplayed recoverDisplayed: Bool) throws {
        
        DefaultsManager
            .shared
            .actionCallback = actionHandle
        
        if actionHandle != 0 {
            try recoverLostEvents()
        }
    }
    
    public func recoverLostEvents() throws {
        try recoverNotificationsCreated()
        try recoverNotificationsDisplayed(withReferenceLifeCycle: .AppKilled)
        try recoverNotificationsDismissed()
        try recoverNotificationActions()
    }
    
    public func getActionHandle() -> Int64 {
        return DefaultsManager
                    .shared
                    .actionCallback
    }
    
    public func listAllPendingSchedules(
        whenGotResults completionHandler: @escaping ([NotificationModel]) -> Void
    ){
        
        UNUserNotificationCenter.current().getPendingNotificationRequests(completionHandler: { activeSchedules in
            
            var serializeds:[[String:Any?]]  = []
            
            if activeSchedules.count > 0 {
                let schedules = ScheduleManager.listSchedules()
                
                if(!ListUtils.isNullOrEmpty(schedules)){
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
                            _ = CancellationManager
                                    .shared
                                    .cancelSchedule(byId: notificationModel.content!.id!)
                        }
                    }
                }
                
                completionHandler(schedules)
                
            } else {
                _ = CancellationManager
                        .shared
                        .cancelAllSchedules()
                
                completionHandler([])
            }
        })
    }
    
    public func isApplicationInDebug() -> Bool {
#if DEBUG
        return true
#else
        return false
#endif
    }
    
    // *****************************  INITIALIZATION FUNCTIONS  **********************************
    
    public func initialize(
        defaultIconPath:String?,
        channels:[NotificationChannelModel],
        backgroundHandle:Int64,
        debug:Bool
    ) throws {
        
        setDefaultConfigurations (
            defaultIconPath: defaultIconPath,
            backgroundHandle: backgroundHandle)
        
        if ListUtils.isNullOrEmpty(channels) {
            throw ExceptionFactory
                    .shared
                    .createNewAwesomeException(
                        className: TAG,
                        code: ExceptionCode.CODE_INITIALIZATION_EXCEPTION,
                        message: "At least one channel is required",
                        detailedCode: ExceptionCode.DETAILED_REQUIRED_ARGUMENTS+".channelList")
        }
        
        for channel in channels {
            ChannelManager
                .shared
                .saveChannel(channel: channel, setOnlyNew: true)
        }
        
        AwesomeNotifications.debug = debug
        
        if(AwesomeNotifications.debug){
            Logger.d(TAG, "Awesome Notifications initialized")
        }
    }
    
    private func setDefaultConfigurations(defaultIconPath:String?, backgroundHandle:Int64?) {
        DefaultsManager.shared.defaultIcon = defaultIconPath
        DefaultsManager.shared.backgroundCallback = backgroundHandle ?? 0
    }
    
    // *****************************  RECOVER FUNCTIONS  **********************************
    
    private func recoverNotificationsCreated() throws {
        let lostCreated = CreatedManager.listCreated()
        for createdNotification in lostCreated {
            
            try createdNotification.validate()
            
            notifyNotificationEvent(
                eventName: Definitions.EVENT_NOTIFICATION_CREATED,
                notificationReceived: createdNotification)
            
            if !CreatedManager.removeCreated(id: createdNotification.id!) {
                Logger.e(TAG, "Created event \(createdNotification.id!) could not be cleaned")
            }
        }
    }
    
    private func recoverNotificationsDisplayed(
        withReferenceLifeCycle lifeCycle:NotificationLifeCycle
    ) throws {
        
        let lastRecoveredDate:RealDateTime =
                        DefaultsManager
                            .shared
                            .lastDisplayedDate
        
        DisplayedManager.reloadLostSchedulesDisplayed(referenceDate: Date())
        
        let lostDisplayed = DisplayedManager.listDisplayed()
        for displayedNotification in lostDisplayed {
            
            guard let displayedDate:RealDateTime = displayedNotification.displayedDate ?? displayedNotification.createdDate
            else {
                continue
            }
            
            if(lastRecoveredDate < displayedDate){
                try displayedNotification.validate()
                displayedNotification.displayedLifeCycle = lifeCycle
                
                notifyNotificationEvent(
                    eventName: Definitions.EVENT_NOTIFICATION_DISPLAYED,
                    notificationReceived: displayedNotification)
            }
            
            if !DisplayedManager.removeDisplayed(id: displayedNotification.id!) {
                Logger.e(TAG, "Displayed event \(displayedNotification.id!) could not be cleaned")
            }
        }
    }
    
    private func recoverNotificationsDismissed() throws {
        let lostDismissed = DismissedManager.listDismissed()
        for dismissedNotification in lostDismissed {
            
            try dismissedNotification.validate()
            
            notifyActionEvent(
                fromEventNamed: Definitions.EVENT_NOTIFICATION_DISMISSED,
                withActionReceived: dismissedNotification)
            
            if !DismissedManager.removeDismissed(id: dismissedNotification.id!) {
                Logger.e(TAG, "Dismissed event \(dismissedNotification.id!) could not be cleaned")
            }
        }
    }
    
    private func recoverNotificationActions() throws {
        let lostActions = ActionManager.recoverActions()
        for notificationAction in lostActions {
            
            try notificationAction.validate()
            
            notifyActionEvent(
                fromEventNamed: Definitions.EVENT_DEFAULT_ACTION,
                withActionReceived: notificationAction)
            
            if !ActionManager.removeAction(id: notificationAction.id!) {
                Logger.e(TAG, "Action event \(notificationAction.id!) could not be cleaned")
            }
        }
    }
    
    
    // *****************************  IOS NOTIFICATION CENTER METHODS  **********************************
#if !ACTION_EXTENSION
    
    private var _originalNotificationCenterDelegate: UNUserNotificationCenterDelegate?
    
    @objc public func didFinishLaunch(_ application: UIApplication) {
        
        UNUserNotificationCenter.current().delegate = self
        UIApplication.shared.registerForRemoteNotifications()
        
        RefreshSchedulesReceiver()
                .refreshSchedules()
        
        if AwesomeNotifications.debug {
            Logger.d(TAG, "Awesome Notifications attached for iOS")
        }
    }
    
    @available(iOS 10.0, *)
    public func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ){
        Logger.d(TAG, "Notification Category Identifier (action): \(response.notification.request.content.categoryIdentifier)")
        do {
            switch response.actionIdentifier {
            
                case UNNotificationDismissActionIdentifier.description:
                    try DismissedNotificationReceiver
                        .shared
                        .addNewDismissEvent(
                            fromResponse: response,
                            whenFinished: { (success:Bool, error:Error?) in
                                
                                if !success && self._originalNotificationCenterDelegate != nil {
                                    self._originalNotificationCenterDelegate!
                                        .userNotificationCenter?(
                                            center,
                                            didReceive: response,
                                            withCompletionHandler: completionHandler)
                                }
                                else {
                                    completionHandler()
                                }
                            })
                    
                default:
                    try NotificationActionReceiver
                        .shared
                        .addNewActionEvent(
                            fromResponse: response,
                            whenFinished: { (success:Bool, error:Error?) in
                                
                                if !success && self._originalNotificationCenterDelegate != nil {
                                    self._originalNotificationCenterDelegate!
                                        .userNotificationCenter?(
                                            center,
                                            didReceive: response,
                                            withCompletionHandler: completionHandler)
                                }
                                else {
                                    completionHandler()
                                }
                            })
            }
        } catch {
            if !(error is AwesomeNotificationsException) {
                ExceptionFactory
                    .shared
                    .registerNewAwesomeException(
                        className: TAG,
                        code: ExceptionCode.CODE_UNKNOWN_EXCEPTION,
                        message: "An unknow exception was found while receiving a notification action",
                        detailedCode: ExceptionCode.DETAILED_UNEXPECTED_ERROR,
                        originalException: error)
            }
            
            if self._originalNotificationCenterDelegate != nil {
                self._originalNotificationCenterDelegate!
                    .userNotificationCenter?(
                        center,
                        didReceive: response,
                        withCompletionHandler: completionHandler)
            }
            else {
                completionHandler()
            }
        }
    }
    
    @available(iOS 10.0, *)
    public func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ){
        let jsonData:[String : Any?] =
                extractNotificationJsonMap(
                    fromContent: notification.request.content)
        
        if let notificationModel:NotificationModel =
            NotificationBuilder
                .newInstance()
                .jsonDataToNotificationModel(
                    jsonData: jsonData)
        {
            StatusBarManager
                .shared
                .showNotificationOnStatusBar(
                    withNotificationModel: notificationModel,
                    whenFinished: { (notificationDisplayed:Bool, mustPlaySound:Bool) in
                        
                        if !notificationDisplayed && self._originalNotificationCenterDelegate != nil {
                            self._originalNotificationCenterDelegate?
                                .userNotificationCenter?(
                                    center,
                                    willPresent: notification,
                                    withCompletionHandler: completionHandler)
                        }
                        else {
                            if notificationDisplayed {
                                if mustPlaySound {
                                    completionHandler([.alert, .badge, .sound])
                                }
                                else {
                                    completionHandler([.alert, .badge])
                                }
                            }
                            else {
                                completionHandler([])
                            }
                        }
                    })
            
        }
        else {
            if _originalNotificationCenterDelegate != nil {
                _originalNotificationCenterDelegate?
                    .userNotificationCenter?(
                        center,
                        willPresent: notification,
                        withCompletionHandler: completionHandler)
            }
            else {
                completionHandler([.alert, .badge, .sound])
            }
        }
        
        do {
            try recoverLostEvents()
        } catch {
            if !(error is AwesomeNotificationsException) {
                ExceptionFactory
                    .shared
                    .registerNewAwesomeException(
                        className: TAG,
                        code: ExceptionCode.CODE_UNKNOWN_EXCEPTION,
                        message: "An unknow exception was found while displaying a notification in foreground",
                        detailedCode: ExceptionCode.DETAILED_UNEXPECTED_ERROR,
                        originalException: error)
            }
        }
    }
    
    // *****************************  EXTRACT NOTIFICATION METHODS  **********************************
    
    private func extractNotificationJsonMap(fromContent content: UNNotificationContent) -> [String : Any?]{
        
        var jsonMap:[String : Any?]
        
        if(content.userInfo[Definitions.NOTIFICATION_JSON] != nil){
            let jsonData:String = content.userInfo[Definitions.NOTIFICATION_JSON] as! String
            jsonMap = JsonUtils.fromJson(jsonData) ?? [:]
        }
        else {
            jsonMap = content.userInfo as! [String : Any?]
            
            if(jsonMap[Definitions.NOTIFICATION_MODEL_CONTENT] is String){
                jsonMap[Definitions.NOTIFICATION_MODEL_CONTENT] = JsonUtils.fromJson(jsonMap[Definitions.NOTIFICATION_MODEL_CONTENT] as? String)
            }
            
            if(jsonMap[Definitions.NOTIFICATION_MODEL_BUTTONS] is String){
                jsonMap[Definitions.NOTIFICATION_MODEL_BUTTONS] = JsonUtils.fromJson(jsonMap[Definitions.NOTIFICATION_MODEL_BUTTONS] as? String)
            }
            
            if(jsonMap[Definitions.NOTIFICATION_MODEL_SCHEDULE] is String){
                jsonMap[Definitions.NOTIFICATION_MODEL_SCHEDULE] = JsonUtils.fromJson(jsonMap[Definitions.NOTIFICATION_MODEL_SCHEDULE] as? String)
            }
        }
        return jsonMap
    }
    
#endif
    
    
    // *****************************  NOTIFICATION METHODS  **********************************
    
    public func createNotification(
        fromNotificationModel notificationModel: NotificationModel,
        afterCreated completionHandler: @escaping (Bool, UNMutableNotificationContent?, Error?) -> ()
    ) throws {
        try NotificationSenderAndScheduler
                .send(
                    createdSource: NotificationSource.Local,
                    notificationModel: notificationModel,
                    completion: completionHandler,
                    appLifeCycle: LifeCycleManager
                                        .shared
                                        .currentLifeCycle)
    }
    
    // *****************************  CHANNEL METHODS  **********************************
    
    public func setChannel(channel:NotificationChannelModel) -> Bool {
        ChannelManager
            .shared
            .saveChannel(channel: channel, setOnlyNew: false)
        return true
    }
    
    public func removeChannel(channelKey:String) -> Bool {
        return ChannelManager
                    .shared
                    .removeChannel(channelKey: channelKey)
    }
    
    public func getAllChannels() -> [NotificationChannelModel] {
        return ChannelManager
                    .shared
                    .listChannels()
    }
    
    // *****************************  SCHEDULE METHODS  **********************************
    
    public func getNextValidDate(
        scheduleModel: NotificationScheduleModel,
        fixedDate: String,
        timeZoneName: String
    ) -> RealDateTime? {
        
        let fixedDateTime:RealDateTime = RealDateTime.init(
            fromDateText: fixedDate, inTimeZone: timeZoneName) ?? RealDateTime()
        
        guard let nextValidDate:Date =
            DateUtils
                .shared
                .getNextValidDate(
                    fromScheduleModel: scheduleModel,
                    withReferenceDate: fixedDateTime)
        else {
            return nil
        }
        
        return RealDateTime.init(fromDate: nextValidDate, inTimeZone: fixedDateTime.timeZone)
    }
    
    public func getLocalTimeZone() -> TimeZone {
        return DateUtils.shared.localTimeZone
    }
    
    public func getUtcTimeZone() -> TimeZone {
        return DateUtils.shared.utcTimeZone
    }
    
    // ****************************  BADGE COUNTER METHODS  **********************************
    
    public func getGlobalBadgeCounter() -> Int {
        return BadgeManager
                    .shared
                    .globalBadgeCounter
    }
    
    public func setGlobalBadgeCounter(withAmmount ammount:Int) {
        BadgeManager
            .shared
            .globalBadgeCounter = ammount
    }
    
    public func resetGlobalBadgeCounter() {
        BadgeManager
            .shared
            .resetGlobalBadgeCounter()
    }
    
    public func incrementGlobalBadgeCounter() -> Int {
        return BadgeManager
                    .shared
                    .incrementGlobalBadgeCounter()
    }
    
    public func decrementGlobalBadgeCounter() -> Int {
        return BadgeManager
                    .shared
                    .decrementGlobalBadgeCounter()
    }
    
    // *****************************  CANCELATION METHODS  **********************************
    
    public func dismissNotification(byId id: Int) -> Bool {
        let success:Bool =
                CancellationManager
                    .shared
                    .dismissNotification(byId: id)
        
        if AwesomeNotifications.debug {
            Logger.d(TAG, "Notification id \(id) dismissed")
        }
        
        return success
    }
    
    public func cancelSchedule(byId id: Int) -> Bool {
        let success:Bool =
                CancellationManager
                    .shared
                    .cancelSchedule(byId: id)
        
        return success
    }
    
    public func cancelNotification(byId id: Int) -> Bool {
        let success:Bool =
                CancellationManager
                    .shared
                    .cancelNotification(byId: id)
        
        return success
    }
    
    public func dismissNotifications(byChannelKey channelKey: String) -> Bool {
        let success:Bool =
                CancellationManager
                    .shared
                    .dismissNotifications(
                        byChannelKey: channelKey)
        
        return success
    }
    
    public func cancelSchedules(byChannelKey channelKey: String) -> Bool {
        let success:Bool =
                CancellationManager
                    .shared
                    .cancelSchedules(
                        byChannelKey: channelKey)
        
        return success
    }
    
    public func cancelNotifications(byChannelKey channelKey: String) -> Bool {
        let success:Bool =
                CancellationManager
                    .shared
                    .cancelNotifications(
                        byChannelKey: channelKey)
        
        return success
    }
    
    public func dismissNotifications(byGroupKey groupKey: String) -> Bool {
        let success:Bool =
                CancellationManager
                    .shared
                    .dismissNotifications(
                        byGroupKey: groupKey)
        
        return success
    }
    
    public func cancelSchedules(byGroupKey groupKey: String) -> Bool {
        let success:Bool =
                CancellationManager
                    .shared
                    .cancelSchedules(
                        byGroupKey: groupKey)
        
        return success
    }
    
    public func cancelNotifications(byGroupKey groupKey: String) -> Bool {
        let success:Bool =
                CancellationManager
                    .shared
                    .cancelNotifications(
                        byGroupKey: groupKey)
        
        return success
    }
    
    public func dismissAllNotifications() -> Bool {
        let success:Bool =
                CancellationManager
                    .shared
                    .dismissAllNotifications()
        
        return success
    }
    
    public func cancelAllSchedules() -> Bool {
        let success:Bool =
                CancellationManager
                    .shared
                    .cancelAllSchedules()
        
        return success
        
    }
    
    public func cancelAllNotifications() -> Bool {
        let success:Bool =
                CancellationManager
                    .shared
                    .cancelAllNotifications()
        
        return success
    }
    
    // *****************************  PERMISSION METHODS  **********************************
    
    public func areNotificationsGloballyAllowed(whenCompleted completionHandler: @escaping (Bool) -> ()) {
        PermissionManager
            .shared
            .areNotificationsGloballyAllowed(
                whenGotResults: completionHandler)
    }
    
    public func showNotificationPage(whenUserReturns completionHandler: @escaping () -> ()){
        PermissionManager
            .shared
            .showNotificationConfigPage(
                whenUserReturns: completionHandler)
    }
    
    public func showPreciseAlarmPage(whenUserReturns completionHandler: @escaping () -> ()){
        PermissionManager
            .shared
            .showNotificationConfigPage(
                whenUserReturns: completionHandler)
    }
    
    public func showDnDGlobalOverridingPage(whenUserReturns completionHandler: @escaping () -> ()){
        PermissionManager
            .shared
            .showNotificationConfigPage(
                whenUserReturns: completionHandler)
    }
    
    public func arePermissionsAllowed(
        _ permissions:[String],
        filteringByChannelKey channelKey:String?,
        whenGotResults completion: @escaping ([String]) -> ()
    ){
        PermissionManager
            .shared
            .arePermissionsAllowed(
                permissions,
                filteringByChannelKey: channelKey,
                whenGotResults: completion)
    }
    
    public func shouldShowRationale(
        _ permissions:[String],
        filteringByChannelKey channelKey:String?,
        whenGotResults completion: @escaping ([String]) -> ()
    ){
        PermissionManager
            .shared
            .shouldShowRationale(
                permissions,
                filteringByChannelKey: channelKey,
                whenGotResults: completion)
    }
    
    public func requestUserPermissions(
        _ permissions:[String],
        filteringByChannelKey channelKey:String?,
        whenUserReturns completionHandler: @escaping ([String]) -> ()
    ) throws {
        try PermissionManager
            .shared
            .requestUserPermissions(
                permissions,
                filteringByChannelKey: channelKey,
                whenUserReturns: completionHandler)
        
    }
}
