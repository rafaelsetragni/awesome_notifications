//
//  NotificationBuilder.swift
//  awesome_notifications
//
//  Created by Rafael Setragni on 11/09/20.
//

import Foundation

@available(iOS 10.0, *)
class NotificationBuilder {
    
    private static let TAG = "NotificationBuilder"
    
    private static var badgeAmount:NSNumber = 0
        
    public static func incrementBadge(){
        NotificationBuilder.badgeAmount = NSNumber(value: NotificationBuilder.badgeAmount.intValue + 1)
    }
    
    public static func resetBadge(){
        NotificationBuilder.badgeAmount = 0
    }
    
    public static func getBadge() -> NSNumber {
        return NotificationBuilder.badgeAmount
    }
    
    public static func requestPermissions(completion: @escaping (Bool) -> ()){
        
        // iOS 10 support
        let notificationCenter = UNUserNotificationCenter.current()
        
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
    
    public static func preProcessNotification(){
        
    }
    
    public static func isNotificationAuthorized(completion: @escaping (Bool) -> ()) {
        
        let current = UNUserNotificationCenter.current()

        current.getNotificationSettings(completionHandler: { (settings) in
            
            if settings.authorizationStatus == .notDetermined {
                // Notification permission has not been asked yet, go for it!
                requestPermissions(completion: { enabled in
                    completion(enabled)
                })
                
            } else if settings.authorizationStatus == .denied {
                // Notification permission was previously denied, go to settings & privacy to re-enable
                completion(false)
                
            } else if settings.authorizationStatus == .authorized {
                // Notification permission was already granted
                completion(true)
            }
        })
        
        //return UIApplication.shared.isRegisteredForRemoteNotifications
    }
    
    public static func jsonToPushNotification(jsonData:String?) -> PushNotification? {
        if(StringUtils.isNullOrEmpty(jsonData)){ return nil }
        
        let data:[String:Any?]? = JsonUtils.fromJson(jsonData)
        if(data == nil){ return nil }
        
        let pushNotification:PushNotification? = PushNotification().fromMap(arguments: data!) as? PushNotification
        return pushNotification        
    }
    
    public static func buildNotificationActionFromJson(jsonData:String?, actionKey:String?, userText:String?) -> ActionReceived? {
        
        let pushNotification:PushNotification? = jsonToPushNotification(jsonData: jsonData)
        if(pushNotification == nil){ return nil }
        let actionReceived:ActionReceived = ActionReceived(pushNotification!.content)
        
        switch actionKey {
        
            case UNNotificationDismissActionIdentifier.description:
                actionReceived.actionKey = nil
                actionReceived.actionInput = nil
                actionReceived.dismissedLifeCycle = SwiftAwesomeNotificationsPlugin.getApplicationLifeCycle()
                actionReceived.dismissedDate = DateUtils.getUTCDate()
                
            default:
                actionReceived.actionKey = actionKey == UNNotificationDefaultActionIdentifier.description ? nil : actionKey
                actionReceived.actionInput = userText
                actionReceived.actionLifeCycle = SwiftAwesomeNotificationsPlugin.getApplicationLifeCycle()
                actionReceived.actionDate = DateUtils.getUTCDate()
        }
        
        if(StringUtils.isNullOrEmpty(actionReceived.displayedDate)){
            actionReceived.displayedDate = DateUtils.getUTCDate()
        }
        
        return actionReceived
    }
    
    public static func createNotification(_ pushNotification:PushNotification) throws -> PushNotification? {
        
        guard let channel = ChannelManager.getChannelByKey(channelKey: pushNotification.content!.channelKey!) else {
            return nil
        }
        
        let nextDate:Date? = getNextScheduleDate(pushNotification: pushNotification)
        
        if(pushNotification.schedule == nil || nextDate != nil){
            
            let content = buildNotificationContentFromModel(pushNotification: pushNotification)
            
            setTitle(pushNotification: pushNotification, channel: channel, content: content)
            setBody(pushNotification: pushNotification, content: content)
            setSummary(pushNotification: pushNotification, content: content)
            
            
            setVisibility(pushNotification: pushNotification, channel: channel, content: content)
            setShowWhen(pushNotification: pushNotification, content: content)
            
            setLayout(pushNotification: pushNotification, content: content)
            
            createActionButtons(pushNotification: pushNotification, content: content)
            
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
                    
            applyGrouping(channel: channel, content: content)
            
            pushNotification.content!.displayedDate = nextDate?.toString() ?? DateUtils.getUTCDate()
            
            setUserInfoContent(pushNotification: pushNotification, content: content)
            
            let trigger:UNCalendarNotificationTrigger? = dateToCalendarTrigger(targetDate: nextDate)
            let request = UNNotificationRequest(identifier: pushNotification.content!.id!.description, content: content, trigger: trigger)
            
            UNUserNotificationCenter.current().add(request)
            {
                error in // called when message has been sent

                if error != nil {
                    debugPrint("Error: \(error.debugDescription)")
                }
                else {
                    if(nextDate != nil){
                        ScheduleManager.saveSchedule(notification: pushNotification, nextDate: nextDate!)
                    } else {
                        _ = ScheduleManager.removeSchedule(id: pushNotification.content!.id!)
                    }
                }
            }
            return pushNotification
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
    
    private static func setUserInfoContent(pushNotification:PushNotification, content:UNMutableNotificationContent) {
        
        let pushData = pushNotification.toMap()
        let jsonData = JsonUtils.toJson(pushData)
        content.userInfo[Definitions.NOTIFICATION_JSON] = jsonData
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
    
    private static func setBadge(pushNotification:PushNotification, channel:NotificationChannelModel, content:UNMutableNotificationContent){
        if(channel.channelShowBadge!){ NotificationBuilder.incrementBadge() }
        content.badge = NotificationBuilder.getBadge()
    }
    
    private static func createActionButtons(pushNotification:PushNotification, content:UNMutableNotificationContent){
        
        if(pushNotification.actionButtons != nil){
            var actions:[UNNotificationAction] = []
            var category:String = ""
            
            for button in pushNotification.actionButtons! {
                
                let action:UNNotificationAction?
                
                switch button.buttonType {
                    
                    case .InputField:
                        action = UNTextInputNotificationAction(
                            identifier: button.key!,
                            title: button.label!
                        )
                        break
                    
                    default:
                        action = UNNotificationAction(
                            identifier: button.key!,
                            title: button.label!
                        )
                        break
                }
                
                category.append(button.key!)
                actions.append(action!)
            }
            
            let categoryIdentifier:String = category.md5
            let categoryObject = UNNotificationCategory(identifier: categoryIdentifier, actions: actions, intentIdentifiers: [], options: .customDismissAction)
            
            UNUserNotificationCenter.current().setNotificationCategories([categoryObject])
            
            content.categoryIdentifier = categoryIdentifier
        }
        else {
            
            let categoryIdentifier:String = "standard".md5
            let categoryObject = UNNotificationCategory(identifier: categoryIdentifier, actions: [], intentIdentifiers: [], options: .customDismissAction)
            
            UNUserNotificationCenter.current().setNotificationCategories([categoryObject])
            
            content.categoryIdentifier = categoryIdentifier
        }
        
    }
    
    private static func getNextScheduleDate(pushNotification:PushNotification?) -> Date? {
        
        if pushNotification?.schedule == nil { return nil }
        var nextValidDate:Date? = Date()
        
        do {

            if(pushNotification != nil){

                nextValidDate = CronUtils.getNextCalendar(
                    initialDateTime: pushNotification!.schedule!.initialDateTime,
                    crontabRule: pushNotification!.schedule!.crontabSchedule
                )

                if(nextValidDate != nil){

                    return nextValidDate
                }
                else {

                    if(!(ListUtils.isEmptyLists(pushNotification!.schedule!.preciseSchedules as [AnyObject]?))){

                        for nextDateTime in pushNotification!.schedule!.preciseSchedules! {

                            let closestDate:Date? = CronUtils.getNextCalendar(
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

                    NotificationSenderAndScheduler.cancelNotification(id: pushNotification!.content!.id!)
                    Log.d(TAG, "Date is not more valid. ("+DateUtils.getUTCDate()+")")
                }
            }

        } catch {
            debugPrint("\(error)")
        }
        return nil
    }
    
    private static func setVisibility(pushNotification:PushNotification, channel:NotificationChannelModel, content:UNMutableNotificationContent){
        
    }
    
    private static func setShowWhen(pushNotification:PushNotification, content:UNMutableNotificationContent){
    }

    private static func setAutoCancel(pushNotification:PushNotification, content:UNMutableNotificationContent){
        
    }
    
    private static func setTicker(pushNotification:PushNotification, content:UNMutableNotificationContent){
        
    }
    
    private static func setOnlyAlertOnce(pushNotification:PushNotification, channel:NotificationChannelModel, content:UNMutableNotificationContent){
        
    }

    private static func setLockedNotification(pushNotification:PushNotification, channel:NotificationChannelModel, content:UNMutableNotificationContent){
        
    }
    
    private static func setImportance(channel:NotificationChannelModel, content:UNMutableNotificationContent){
        
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
            
            content.sound = UNNotificationSound.default
        }
        else {
            content.sound = nil
        }
    }
    
    private static func setVibrationPattern(channel:NotificationChannelModel, content:UNMutableNotificationContent){
        
    }
    
    private static func setLights(channel:NotificationChannelModel, content:UNMutableNotificationContent){
        // iOS does not have any lights
    }

    private static func setSmallIcon(channel:NotificationChannelModel, content:UNMutableNotificationContent){
        
    }
    
    private static func setLargeIcon(pushNotification:PushNotification, content:UNMutableNotificationContent){
        
    }
    
    private static func setLayoutColor(pushNotification:PushNotification, channel:NotificationChannelModel, content:UNMutableNotificationContent){
        
    }

    private static func applyGrouping(channel:NotificationChannelModel, content:UNMutableNotificationContent){
        
        if((channel.setAsGroupSummary ?? false) && (!StringUtils.isNullOrEmpty(channel.groupKey))){
            content.threadIdentifier = channel.groupKey!
        }
    }

    private static func setLayout(pushNotification:PushNotification, content:UNMutableNotificationContent){
        
        switch pushNotification.content!.notificationLayout {
            
            case .BigPicture:
                setBigPictureLayout(pushNotification: pushNotification, content: content)
                return
                
            case .BigText:
                // In iOS, notifications are always a big text layout
                return
                
            case .Inbox:
                return
                    
            case .Messaging:
                return
                        
            case .ProgressBar:
                setProgressBarLayout(pushNotification: pushNotification, content: content)
                return
                            
            case .Default:
                return
            
            default:
                return
        }
    }
    
    private static func getAttatchmentFromBitmapSource(_ bitmapSource:String?) -> UNNotificationAttachment? {
        
        if !StringUtils.isNullOrEmpty(bitmapSource) {
            
            if let image:UIImage = BitmapUtils.getBitmapFromSource(bitmapPath: bitmapSource!) {
                
                let fileManager = FileManager.default
                let tmpSubFolderName = ProcessInfo.processInfo.globallyUniqueString
                let tmpSubFolderURL = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(tmpSubFolderName, isDirectory: true)
                do {
                    try fileManager.createDirectory(at: tmpSubFolderURL, withIntermediateDirectories: true, attributes: nil)
                    let imageFileIdentifier = bitmapSource!.md5 + ".png"
                    let fileURL = tmpSubFolderURL.appendingPathComponent(imageFileIdentifier)
                    
                    let imageData = UIImage.pngData(image)
                    try imageData()?.write(to: fileURL)
                    
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
        
        if(!StringUtils.isNullOrEmpty(pushNotification.content?.bigPicture)){
            
            if let attachment:UNNotificationAttachment = getAttatchmentFromBitmapSource(pushNotification.content?.bigPicture) {
                content.attachments.append(attachment)
                //	return
            }
        }
        
        if(!StringUtils.isNullOrEmpty(pushNotification.content?.largeIcon)){
            
            if let attachment:UNNotificationAttachment = getAttatchmentFromBitmapSource(pushNotification.content?.largeIcon) {
                content.attachments.append(attachment)
            }
        }
    }
    
    private static func setProgressBarLayout(pushNotification:PushNotification, content:UNMutableNotificationContent) {
        
        let categoryIdentifier:String = "AwesomeLayout"
        let categoryObject = UNNotificationCategory(identifier: categoryIdentifier, actions: [], intentIdentifiers: [], options: .customDismissAction)
        
        UNUserNotificationCenter.current().setNotificationCategories([categoryObject])
        
        content.categoryIdentifier = categoryIdentifier
    }
    
    
    public static func cancelNotification(id:Int){
        let referenceKey:String = String(id)
            
        let center = UNUserNotificationCenter.current()
        center.removeDeliveredNotifications(withIdentifiers: [referenceKey])
        center.removePendingNotificationRequests(withIdentifiers: [referenceKey])

    }
    
    public static func cancellAllNotifications(){
            
        let center = UNUserNotificationCenter.current()
        center.removeAllDeliveredNotifications()
        center.removeAllPendingNotificationRequests()
        
    }
    
}
