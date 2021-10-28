//
//  NotificationBuilder.swift
//  awesome_notifications
//
//  Created by Rafael Setragni on 11/09/20.
//

import Foundation

@available(iOS 10.0, *)
public class NotificationBuilder {
    
    private static let TAG = "NotificationBuilder"
    
    private static var badgeAmount:NSNumber = 0
        
    public static func incrementBadge() -> NSNumber {
        let count:Int = NotificationBuilder.getBadge().intValue + 1
        NotificationBuilder.setBadge(count)
        return NSNumber(value: count)
    }

    public static func decrementBadge() -> NSNumber {
        let count:Int = max(NotificationBuilder.getBadge().intValue - 1, 0)
        NotificationBuilder.setBadge(count)
        return NSNumber(value: count)
    }
    
    public static func resetBadge(){
        setBadge(0)
    }
    
    public static func getBadge() -> NSNumber {
        if !SwiftUtils.isRunningOnExtension() && Thread.isMainThread {
            NotificationBuilder.badgeAmount = NSNumber(value: UIApplication.shared.applicationIconBadgeNumber)
        }
        else{
            let userDefaults = UserDefaults(suiteName: Definitions.USER_DEFAULT_TAG)
            let badgeCount:Int = userDefaults!.integer(forKey: Definitions.BADGE_COUNT)
            NotificationBuilder.badgeAmount = NSNumber(value: badgeCount)
        }
        return NotificationBuilder.badgeAmount
    }
    
    public static func setBadge(_ count:Int) {
        NotificationBuilder.badgeAmount = NSNumber(value: count)
        
        if !SwiftUtils.isRunningOnExtension() && Thread.isMainThread {
            UIApplication.shared.applicationIconBadgeNumber = count
        }
        else{
            NotificationBuilder.badgeAmount = NSNumber(value: count)
        }
        
        let userDefaults = UserDefaults(suiteName: Definitions.USER_DEFAULT_TAG)
        userDefaults!.set(count, forKey: Definitions.BADGE_COUNT)
    }
    
    public static func requestPermissions(completion: @escaping (Bool) -> ()){
        
        if !SwiftUtils.isRunningOnExtension() {
            
            let notificationCenter = UNUserNotificationCenter.current()
            notificationCenter.getNotificationSettings { settings in
                
                var isAllowed:Bool = false
                if #available(iOS 12.0, *) {
                    isAllowed =
                        (settings.authorizationStatus == .authorized) ||
                        (settings.authorizationStatus == .provisional)
                } else {
                    isAllowed =
                        (settings.authorizationStatus == .authorized)
                }

                if !isAllowed && settings.authorizationStatus == .notDetermined {
                    
                    notificationCenter.requestAuthorization(options: [.sound,.alert,.badge]) { (granted, error) in
                        if granted {
                            DispatchQueue.main.async {
                                UIApplication.shared.registerForRemoteNotifications()
                            }
                            print("Notification Enable Successfully")
                            completion(true)
                        }
                        else {
                            completion(false)
                        }
                    }
                }
                else {
                    DispatchQueue.main.async {
                        UIApplication.shared.open(URL(string: UIApplication.openSettingsURLString)!)
                    }
                    completion(isAllowed)
                }
            }
            
        } else {
            // For Extensions, the notification is always enabled
            completion(true)
        }
    }
    
    public static func isNotificationAllowed(completion: @escaping (Bool) -> ()) {
             
        // Extension targets are always authorized
        if SwiftUtils.isRunningOnExtension() {
            completion(true)
            return
        }
        
        let current = UNUserNotificationCenter.current()
        current.getNotificationSettings(completionHandler: { (settings) in
            
            if settings.authorizationStatus == .notDetermined {
                // The user hasnt decided yet if he authorizes or not
                completion(false)
                return
                
            } else if settings.authorizationStatus == .denied {
                // Notification permission was previously denied, go to settings & privacy to re-enable
                completion(false)
                return
                
            } else if settings.authorizationStatus == .authorized {
                // Notification permission was already granted
                completion(true)
                return
            }
        })
        
        //return UIApplication.shared.isRegisteredForRemoteNotifications
    }

    public static func jsonDataToPushNotification(jsonData:[String : Any?]?) -> PushNotification? {
        if(jsonData?.isEmpty ?? true){ return nil }

        let pushNotification:PushNotification? = PushNotification().fromMap(arguments: jsonData!) as? PushNotification
        return pushNotification
    }
    
    public static func jsonToPushNotification(jsonData:String?) -> PushNotification? {
        if(StringUtils.isNullOrEmpty(jsonData)){ return nil }
        
        let data:[String:Any?]? = JsonUtils.fromJson(jsonData)
        if(data == nil){ return nil }
        
        let pushNotification:PushNotification? = PushNotification().fromMap(arguments: data!) as? PushNotification
        return pushNotification        
    }
    
    public static func buildNotificationFromJson(jsonData:String?) -> PushNotification? {
        return  jsonToPushNotification(jsonData: jsonData)
    }
    
    public static func buildNotificationActionFromJson(jsonData:String?, buttonKeyPressed:String?, userText:String?) -> ActionReceived? {
        
        let pushNotification:PushNotification? = buildNotificationFromJson(jsonData: jsonData)
        if(pushNotification == nil){ return nil }
        let actionReceived:ActionReceived = ActionReceived(pushNotification!.content)
        
        switch buttonKeyPressed {
        
            case UNNotificationDismissActionIdentifier.description:
                actionReceived.buttonKeyPressed = nil
                actionReceived.buttonKeyInput = nil
                actionReceived.dismissedLifeCycle = SwiftAwesomeNotificationsPlugin.appLifeCycle
                actionReceived.dismissedDate = DateUtils.getUTCTextDate()
                
            default:
                let defaultIOSAction = UNNotificationDefaultActionIdentifier.description
                actionReceived.buttonKeyPressed = buttonKeyPressed == defaultIOSAction ? nil : buttonKeyPressed
                actionReceived.buttonKeyInput = userText
                actionReceived.actionLifeCycle = SwiftAwesomeNotificationsPlugin.appLifeCycle
                actionReceived.actionDate = DateUtils.getUTCTextDate()
        }
        
        if(StringUtils.isNullOrEmpty(actionReceived.displayedDate)){
            actionReceived.displayedDate = DateUtils.getUTCTextDate()
            actionReceived.displayedLifeCycle = SwiftAwesomeNotificationsPlugin.appLifeCycle
        }
        else {
            if actionReceived.createdDate == actionReceived.displayedDate {
                actionReceived.displayedLifeCycle = actionReceived.createdLifeCycle
            }
        }
        
        return actionReceived
    }
    
    public static func createNotification(_ pushNotification:PushNotification, content:UNMutableNotificationContent?) throws -> PushNotification? {
        
        guard let channel = ChannelManager.getChannelByKey(channelKey: pushNotification.content!.channelKey!) else {
            throw AwesomeNotificationsException.invalidRequiredFields(msg: "Channel '\(pushNotification.content!.channelKey!)' does not exist or is disabled")
        }
        
        let nextDate:Date? = getNextScheduleDate(pushNotification: pushNotification)
        
        if(pushNotification.schedule == nil || nextDate != nil){
            
            let content = content ?? buildNotificationContentFromModel(pushNotification: pushNotification)
            
            setTitle(pushNotification: pushNotification, channel: channel, content: content)
            setBody(pushNotification: pushNotification, content: content)
            setSummary(pushNotification: pushNotification, content: content)
            
            
            setVisibility(pushNotification: pushNotification, channel: channel, content: content)
            setShowWhen(pushNotification: pushNotification, content: content)
            setBadgeIndicator(pushNotification: pushNotification, channel: channel, content: content)
            
            setAutoCancel(pushNotification: pushNotification, content: content)
            setTicker(pushNotification: pushNotification, content: content)
            
            setOnlyAlertOnce(pushNotification: pushNotification, channel: channel, content: content)
            
            setLockedNotification(pushNotification: pushNotification, channel: channel, content: content)
            setImportance(channel: channel, content: content)
            
            setSound(pushNotification: pushNotification, channel: channel, content: content)
            setVibrationPattern(channel: channel, content: content)
            
            setLights(channel: channel, content: content)
            
            setSmallIcon(channel: channel, content: content)
            setLargeIcon(pushNotification: pushNotification, content: content)
            
            setLayoutColor(pushNotification: pushNotification, channel: channel, content: content)
            
            setLayout(pushNotification: pushNotification, content: content)
            
            createActionButtonsAndCategory(pushNotification: pushNotification, content: content)
                    
            setGrouping(channel: channel, content: content)
            
            setUserInfoContent(pushNotification: pushNotification, content: content)
            
            if SwiftUtils.isRunningOnExtension() {                
                return pushNotification
            }
            
            //let trigger:UNCalendarNotificationTrigger? = dateToCalendarTrigger(targetDate: nextDate)
            
            pushNotification.content!.displayedDate = nextDate?.toString(toTimeZone: "UTC") ?? DateUtils.getUTCTextDate()
            
            let trigger:UNNotificationTrigger? = nextDate == nil ? nil : pushNotification.schedule?.getUNNotificationTrigger()
            let request = UNNotificationRequest(identifier: pushNotification.content!.id!.description, content: content, trigger: trigger)
            
            UNUserNotificationCenter.current().add(request)
            {
                error in // called when message has been sent

                if error != nil {
                    debugPrint("Error: \(error.debugDescription)")
                }
                else {
                    if(pushNotification.schedule != nil){
                        
                        pushNotification.schedule!.timeZone =
                            pushNotification.schedule!.timeZone ?? DateUtils.localTimeZone.identifier
                        pushNotification.schedule!.createdDate =
                            DateUtils.getLocalTextDate(fromTimeZone: pushNotification.schedule!.timeZone!)
                        
                        if (nextDate != nil){
                            ScheduleManager.saveSchedule(notification: pushNotification, nextDate: nextDate!)
                        } else {
                            _ = ScheduleManager.removeSchedule(id: pushNotification.content!.id!)
                        }
                    }
                }
            }
            return pushNotification
        }
        else {
            if(pushNotification.schedule != nil){
                _ = ScheduleManager.removeSchedule(id: pushNotification.content!.id!)
            }
        }
        
        return nil
    }
    
    private static func dateToCalendarTrigger(targetDate:Date?) -> UNCalendarNotificationTrigger? {
        if(targetDate == nil){ return nil}
        
        let dateComponents = Calendar.current.dateComponents([.day, .month, .year, .hour, .minute, .second], from: targetDate!)
        let trigger = UNCalendarNotificationTrigger( dateMatching: dateComponents, repeats: false )
        return trigger
    }
    
    private static func buildNotificationContentFromModel(pushNotification:PushNotification) -> UNMutableNotificationContent {
        let content = UNMutableNotificationContent()
        return content
    }
    
    public static func setUserInfoContent(pushNotification:PushNotification, content:UNMutableNotificationContent) {
        
        let pushData = pushNotification.toMap()
        let jsonData = JsonUtils.toJson(pushData)
        content.userInfo[Definitions.NOTIFICATION_JSON] = jsonData
        content.userInfo[Definitions.NOTIFICATION_ID] = pushNotification.content!.id!
    }

    private static func setTitle(pushNotification:PushNotification, channel:NotificationChannelModel, content:UNMutableNotificationContent){
        content.title = pushNotification.content!.title?.withoutHtmlTags() ?? ""
    }
    
    private static func setBody(pushNotification:PushNotification, content:UNMutableNotificationContent){
        content.body = pushNotification.content!.body?.withoutHtmlTags() ?? ""
    }
    
    private static func setSummary(pushNotification:PushNotification, content:UNMutableNotificationContent){
        if #available(iOS 12.0, *) {
            content.summaryArgument = pushNotification.content!.summary?.withoutHtmlTags() ?? ""
        }
    }
    
    private static func setBadgeIndicator(pushNotification:PushNotification, channel:NotificationChannelModel, content:UNMutableNotificationContent){
        if(channel.channelShowBadge!){
            content.badge = NotificationBuilder.incrementBadge()
        }
    }
    
    private static func createActionButtonsAndCategory(pushNotification:PushNotification, content:UNMutableNotificationContent){
        
        var categoryIdentifier:String = StringUtils.isNullOrEmpty(content.categoryIdentifier) ?
            Definitions.DEFAULT_CATEGORY_IDENTIFIER : content.categoryIdentifier
        
        var actions:[UNNotificationAction] = []
        var dynamicCategory:[String] = []
        var dynamicLabels:[String] = []
        
        if(pushNotification.actionButtons != nil){
            
            var temporaryCategory:[String] = []
            
            dynamicCategory.append(content.categoryIdentifier)
            
            for button in pushNotification.actionButtons! {
                
                let action:UNNotificationAction?
                                
                switch button.buttonType {
                
                    case .InputField:
                        action = UNTextInputNotificationAction(
                            identifier: button.key!,
                            title: button.label!,
                            options: [.foreground]
                        )
                        break
                        
                    case .Default:
                        action = UNNotificationAction(
                            identifier: button.key!,
                            title: button.label!,
                            options: [.foreground]
                        )
                        
                    case .DisabledAction:
                        action = UNNotificationAction(
                            identifier: button.key!,
                            title: button.label!,
                            options: []
                        )
                    
                    default:
                        action = UNNotificationAction(
                            identifier: button.key!,
                            title: button.label!,
                            options: [.foreground]
                        )
                        break
                }
                
                temporaryCategory.append(button.key!)
                dynamicLabels.append(button.label! + (button.buttonType?.rawValue ?? "default"))
                actions.append(action!)
            }
            
            dynamicCategory.append(contentsOf: temporaryCategory)
            
            categoryIdentifier = dynamicCategory.joined(separator: ",")
        }
        
        categoryIdentifier = categoryIdentifier.uppercased()

        if(SwiftAwesomeNotificationsPlugin.debug){
            print("Notification category identifier: " + categoryIdentifier)
        }
        content.categoryIdentifier = categoryIdentifier
        
        dynamicLabels.append(contentsOf: dynamicCategory)
        let categoryHashIdentifier = dynamicLabels.joined(separator: ",").md5
                
        let userDefaults = UserDefaults(suiteName: Definitions.USER_DEFAULT_TAG)
        let lastHash = userDefaults!.string(forKey: categoryHashIdentifier)
        
        
        // Only calls setNotificationCategories when its necessary to update or create it
        if(StringUtils.isNullOrEmpty(lastHash)){
            
            userDefaults!.set(categoryHashIdentifier, forKey: "registered")
            
            let categoryObject = UNNotificationCategory(
                identifier: categoryIdentifier,
                actions: actions,
                intentIdentifiers: [],
                options: .customDismissAction
            )
            
            UNUserNotificationCenter.current().getNotificationCategories(completionHandler: { results in
                UNUserNotificationCenter.current().setNotificationCategories(results.union([categoryObject]))
            })
        }
    }
    
    private static func getNextScheduleDate(pushNotification:PushNotification?) -> Date? {
        
        if pushNotification?.schedule == nil { return nil }
        
        switch true {
            
            case pushNotification!.schedule! is NotificationCalendarModel:
                
                let calendarModel:NotificationCalendarModel = pushNotification!.schedule! as! NotificationCalendarModel
                guard let trigger:UNCalendarNotificationTrigger = calendarModel.getUNNotificationTrigger() as? UNCalendarNotificationTrigger else { return nil }
                
                return trigger.nextTriggerDate()
                
            case pushNotification!.schedule! is NotificationIntervalModel:
                
                let intervalModel:NotificationIntervalModel = pushNotification!.schedule! as! NotificationIntervalModel
                guard let trigger:UNTimeIntervalNotificationTrigger = intervalModel.getUNNotificationTrigger() as? UNTimeIntervalNotificationTrigger else { return nil }
                
                return trigger.nextTriggerDate()
                
            default:
                return nil
        }
        /*
        let cron:CronUtils = CronUtils()
        
        do {

            if(pushNotification != nil){

                nextValidDate = cron.getNextCalendar(
                    initialDateTime: pushNotification!.schedule!.createdDateTime,
                    crontabRule: pushNotification!.schedule!.crontabSchedule
                )

                if(nextValidDate != nil){

                    return nextValidDate
                }
                else {

                    if(!(ListUtils.isEmptyLists(pushNotification!.schedule!.preciseSchedules as [AnyObject]?))){

                        for nextDateTime in pushNotification!.schedule!.preciseSchedules! {

                            let closestDate:Date? = cron.getNextCalendar(
                                initialDateTime: nextDateTime,
                                crontabRule: nil
                            )

                            if closestDate != nil {
                                if nextValidDate == nil {
                                    nextValidDate = closestDate
                                }
                                else {
                                    if closestDate!.compare(nextValidDate!) == ComparisonResult.orderedAscending {
                                        nextValidDate = closestDate
                                    }
                                }
                            }
                        }

                        if nextValidDate != nil {
                            return nextValidDate
                        }
                    }

                    _ = NotificationSenderAndScheduler.cancelNotification(id: pushNotification!.content!.id!)
                    Log.d(TAG, "Date is not more valid. ("+DateUtils.getUTCDate()+")")
                }
            }
        } catch {
            debugPrint("\(error)")
        }
        return nil
        */
    }
    
    private static func setVisibility(pushNotification:PushNotification, channel:NotificationChannelModel, content:UNMutableNotificationContent){
        // TODO
    }
    
    private static func setShowWhen(pushNotification:PushNotification, content:UNMutableNotificationContent){
        // TODO
    }

    private static func setAutoCancel(pushNotification:PushNotification, content:UNMutableNotificationContent){
        // TODO
    }
    
    private static func setTicker(pushNotification:PushNotification, content:UNMutableNotificationContent){
        // TODO
    }
    
    private static func setOnlyAlertOnce(pushNotification:PushNotification, channel:NotificationChannelModel, content:UNMutableNotificationContent){
        // TODO
    }

    private static func setLockedNotification(pushNotification:PushNotification, channel:NotificationChannelModel, content:UNMutableNotificationContent){
        // TODO
    }
    
    private static func setImportance(channel:NotificationChannelModel, content:UNMutableNotificationContent){
        // TODO
    }

    private static func setSound(pushNotification:PushNotification, channel:NotificationChannelModel, content:UNMutableNotificationContent){
        if (pushNotification.content!.playSound ?? false) && (channel.playSound ?? false) {
            
            if(!StringUtils.isNullOrEmpty(pushNotification.content!.customSound)){
                content.sound = AudioUtils.getSoundFromSource(SoundPath: pushNotification.content!.customSound!)
                return
            }
            
            if(!StringUtils.isNullOrEmpty(channel.soundSource)){
                content.sound = AudioUtils.getSoundFromSource(SoundPath: channel.soundSource!)
                return
            }
            
            // TODO Get default iOS path sounds
            switch channel.defaultRingtoneType {
                
                case .Ringtone:
                    content.sound = UNNotificationSound.default
                    return
                    
                case .Alarm:
                    content.sound = UNNotificationSound.default
                    return
                
                case .Notification:
                    content.sound = UNNotificationSound.default
                    return
                    
                case .none:
                    content.sound = UNNotificationSound.default
                    return
            }
        }
        else {
            content.sound = nil
        }
    }
    
    private static func setVibrationPattern(channel:NotificationChannelModel, content:UNMutableNotificationContent){
        // TODO
    }
    
    private static func setLights(channel:NotificationChannelModel, content:UNMutableNotificationContent){
        // iOS does not have any lights
    }

    private static func setSmallIcon(channel:NotificationChannelModel, content:UNMutableNotificationContent){
        // TODO
    }
    
    private static func setLargeIcon(pushNotification:PushNotification, content:UNMutableNotificationContent){
        // TODO
    }
    
    private static func setLayoutColor(pushNotification:PushNotification, channel:NotificationChannelModel, content:UNMutableNotificationContent){
        // TODO
    }

    private static func setGrouping(channel:NotificationChannelModel, content:UNMutableNotificationContent){
        
        if(!StringUtils.isNullOrEmpty(channel.groupKey)){
            content.threadIdentifier = channel.groupKey!
        }
    }

    private static func setLayout(pushNotification:PushNotification, content:UNMutableNotificationContent){
        
        switch pushNotification.content!.notificationLayout {
            
            case .BigPicture:
                setBigPictureLayout(pushNotification: pushNotification, content: content)
                return
                
            case .BigText:
                setBigTextLayout(pushNotification: pushNotification, content: content)
                return
                
            case .Inbox:
                setInboxLayout(pushNotification: pushNotification, content: content)
                return
                
            case .MediaPlayer:
                setMediaPlayerLayout(pushNotification: pushNotification, content: content)
                return
                
            case .Messaging:
                setMessagingLayout(pushNotification: pushNotification, content: content)
                return
                        
            case .ProgressBar:
                setProgressBarLayout(pushNotification: pushNotification, content: content)
                return
                            
            case .Default:
                setDefaultLayout(pushNotification: pushNotification, content: content)
                return
            
            default:
                setDefaultLayout(pushNotification: pushNotification, content: content)
                return
        }
    }
    
    private static func getAttatchmentFromBitmapSource(_ bitmapSource:String?) -> UNNotificationAttachment? {
        
        //let dimensionLimit:CGFloat = 1038.0
        		
        if !StringUtils.isNullOrEmpty(bitmapSource) {
            
            if let image:UIImage = BitmapUtils.getBitmapFromSource(bitmapPath: bitmapSource!) {
                
                let fileManager = FileManager.default
                let tmpSubFolderName = ProcessInfo.processInfo.globallyUniqueString
                let tmpSubFolderURL = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(tmpSubFolderName, isDirectory: true)
                
                do {
                    try fileManager.createDirectory(at: tmpSubFolderURL, withIntermediateDirectories: true, attributes: nil)
                    let imageFileIdentifier = bitmapSource!.md5 + ".png"
                    let fileURL = tmpSubFolderURL.appendingPathComponent(imageFileIdentifier)
                    
                    // JPEG is more memory efficient, but switches trasparency by white color
                    let imageData = image.pngData()//.jpegData(compressionQuality: 0.9)//
                    try imageData?.write(to: fileURL)
                                        
                    let imageAttachment = try UNNotificationAttachment.init(identifier: imageFileIdentifier, url: fileURL, options: nil)
                    return imageAttachment
                    
                } catch {
                    print("error " + error.localizedDescription)
                }
            }
        }
        return nil
    }
    
    private static func setBigPictureLayout(pushNotification:PushNotification, content:UNMutableNotificationContent) {
        content.categoryIdentifier = "BigPicture"
        
        if(!StringUtils.isNullOrEmpty(pushNotification.content?.bigPicture)){
            
            if let attachment:UNNotificationAttachment = getAttatchmentFromBitmapSource(pushNotification.content?.bigPicture) {
                content.attachments.append(attachment)
                return
            }
        }
        
        if(!StringUtils.isNullOrEmpty(pushNotification.content?.largeIcon)){
            
            if let attachment:UNNotificationAttachment = getAttatchmentFromBitmapSource(pushNotification.content?.largeIcon) {
                content.attachments.append(attachment)
            }
        }
    }
    
    private static func setBigTextLayout(pushNotification:PushNotification, content:UNMutableNotificationContent) {
        content.categoryIdentifier = "BigText"
    }
    
    private static func setProgressBarLayout(pushNotification:PushNotification, content:UNMutableNotificationContent) {
        content.categoryIdentifier = "ProgressBar"
    }
    
    private static func setIndeterminateBarLayout(pushNotification:PushNotification, content:UNMutableNotificationContent) {
        content.categoryIdentifier = "IndeterminateBar"
    }
    
    private static func setMediaPlayerLayout(pushNotification:PushNotification, content:UNMutableNotificationContent) {
        content.categoryIdentifier = "MediaPlayer"
    }
    
    private static func setInboxLayout(pushNotification:PushNotification, content:UNMutableNotificationContent) {
        content.categoryIdentifier = "Inbox"
    }
    
    private static func setMessagingLayout(pushNotification:PushNotification, content:UNMutableNotificationContent) {
        content.categoryIdentifier = "Messaging"
    }
    
    private static func setDefaultLayout(pushNotification:PushNotification, content:UNMutableNotificationContent) {
        content.categoryIdentifier = "Default"
    }
    
    public static func dismissNotification(id:Int){
        let referenceKey:String = String(id)
            
        let center = UNUserNotificationCenter.current()
        center.removeDeliveredNotifications(withIdentifiers: [referenceKey])
    }
    
    public static func cancelScheduledNotification(id:Int){
        let referenceKey:String = String(id)
            
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: [referenceKey])
    }
    
    public static func cancelNotification(id:Int){
        let referenceKey:String = String(id)
            
        let center = UNUserNotificationCenter.current()
        center.removeDeliveredNotifications(withIdentifiers: [referenceKey])
        center.removePendingNotificationRequests(withIdentifiers: [referenceKey])
    }
    
    public static func cancellAllScheduledNotifications(){
            
        let center = UNUserNotificationCenter.current()
        center.removeAllPendingNotificationRequests()        
    }
    
    public static func dismissAllNotifications(){
            
        let center = UNUserNotificationCenter.current()
        center.removeAllDeliveredNotifications()
    }
    
    public static func cancellAllNotifications(){
            
        let center = UNUserNotificationCenter.current()
        center.removeAllDeliveredNotifications()
        center.removeAllPendingNotificationRequests()
    }
    
}
