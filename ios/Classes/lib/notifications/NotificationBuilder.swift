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

    public static func jsonDataToNotificationModel(jsonData:[String : Any?]?) -> NotificationModel? {
        if(jsonData?.isEmpty ?? true){ return nil }

        let notificationModel:NotificationModel? = NotificationModel().fromMap(arguments: jsonData!) as? NotificationModel
        return notificationModel
    }
    
    public static func jsonToNotificationModel(jsonData:String?) -> NotificationModel? {
        if(StringUtils.isNullOrEmpty(jsonData)){ return nil }
        
        let data:[String:Any?]? = JsonUtils.fromJson(jsonData)
        if(data == nil){ return nil }
        
        let notificationModel:NotificationModel? = NotificationModel().fromMap(arguments: data!) as? NotificationModel
        return notificationModel
    }
    
    public static func buildNotificationFromJson(jsonData:String?) -> NotificationModel? {
        return  jsonToNotificationModel(jsonData: jsonData)
    }
    
    public static func buildNotificationActionFromJson(jsonData:String?, buttonKeyPressed:String?, userText:String?) -> ActionReceived? {
        
        let notificationModel:NotificationModel? = buildNotificationFromJson(jsonData: jsonData)
        if(notificationModel == nil){ return nil }
        let actionReceived:ActionReceived = ActionReceived(notificationModel!.content)
        
        switch buttonKeyPressed {
        
            case UNNotificationDismissActionIdentifier.description:
                actionReceived.buttonKeyPressed = nil
                actionReceived.buttonKeyInput = nil
                actionReceived.actionLifeCycle = nil
                actionReceived.actionDate = nil
                actionReceived.dismissedLifeCycle = SwiftAwesomeNotificationsPlugin.appLifeCycle
                actionReceived.dismissedDate = DateUtils.getUTCTextDate()
                
            default:
                let defaultIOSAction = UNNotificationDefaultActionIdentifier.description
                actionReceived.buttonKeyPressed = buttonKeyPressed == defaultIOSAction ? nil : buttonKeyPressed
                actionReceived.buttonKeyInput = userText
                actionReceived.actionLifeCycle = SwiftAwesomeNotificationsPlugin.appLifeCycle
                actionReceived.actionDate = DateUtils.getUTCTextDate()
                actionReceived.dismissedLifeCycle = nil
                actionReceived.dismissedDate = nil
                
                if(notificationModel!.actionButtons != nil) {
                    for button:NotificationButtonModel in notificationModel!.actionButtons! {
                        if button.key == buttonKeyPressed {
                            actionReceived.autoDismissible = button.autoDismissible
                            break
                        }
                    }
                }
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
    
    public static func createNotification(_ notificationModel:NotificationModel, content:UNMutableNotificationContent?) throws -> NotificationModel? {
        
        guard let channel = ChannelManager.getChannelByKey(channelKey: notificationModel.content!.channelKey!) else {
            throw AwesomeNotificationsException.invalidRequiredFields(msg: "Channel '\(notificationModel.content!.channelKey!)' does not exist or is disabled")
        }

        notificationModel.content!.groupKey = getGroupKey(notificationModel: notificationModel, channel: channel)

        let nextDate:Date? = getNextScheduleDate(notificationModel: notificationModel)
        
        if(notificationModel.schedule == nil || nextDate != nil){
            
            let content = content ?? buildNotificationContentFromModel(notificationModel: notificationModel)
            
            setTitle(notificationModel: notificationModel, channel: channel, content: content)
            setBody(notificationModel: notificationModel, content: content)
            setSummary(notificationModel: notificationModel, content: content)

            setGrouping(notificationModel: notificationModel, channel: channel, content: content)
            
            setVisibility(notificationModel: notificationModel, channel: channel, content: content)
            setShowWhen(notificationModel: notificationModel, content: content)
            setBadgeIndicator(notificationModel: notificationModel, channel: channel, content: content)
            
            setAutoCancel(notificationModel: notificationModel, content: content)
            setTicker(notificationModel: notificationModel, content: content)
            
            setOnlyAlertOnce(notificationModel: notificationModel, channel: channel, content: content)
            
            setLockedNotification(notificationModel: notificationModel, channel: channel, content: content)
            setImportance(channel: channel, content: content)
            
            setSound(notificationModel: notificationModel, channel: channel, content: content)
            setVibrationPattern(channel: channel, content: content)
            
            setLights(channel: channel, content: content)
            
            setSmallIcon(channel: channel, content: content)
            setLargeIcon(notificationModel: notificationModel, content: content)
            
            setLayoutColor(notificationModel: notificationModel, channel: channel, content: content)
            
            setLayout(notificationModel: notificationModel, content: content)
            
            createActionButtonsAndCategory(notificationModel: notificationModel, content: content)
            
            setUserInfoContent(notificationModel: notificationModel, content: content)
            
            if SwiftUtils.isRunningOnExtension() {                
                return notificationModel
            }
            
            //let trigger:UNCalendarNotificationTrigger? = dateToCalendarTrigger(targetDate: nextDate)
            
            notificationModel.content!.displayedDate = nextDate?.toString(toTimeZone: "UTC") ?? DateUtils.getUTCTextDate()
            
            let trigger:UNNotificationTrigger? = nextDate == nil ? nil : notificationModel.schedule?.getUNNotificationTrigger()
            let request = UNNotificationRequest(identifier: notificationModel.content!.id!.description, content: content, trigger: trigger)
            
            UNUserNotificationCenter.current().add(request)
            {
                error in // called when message has been sent

                if error != nil {
                    debugPrint("Error: \(error.debugDescription)")
                }
                else {
                    if(notificationModel.schedule != nil){
                        
                        notificationModel.schedule!.timeZone =
                            notificationModel.schedule!.timeZone ?? DateUtils.localTimeZone.identifier
                        notificationModel.schedule!.createdDate =
                            DateUtils.getLocalTextDate(fromTimeZone: notificationModel.schedule!.timeZone!)
                        
                        if (nextDate != nil){
                            ScheduleManager.saveSchedule(notification: notificationModel, nextDate: nextDate!)
                        } else {
                            _ = ScheduleManager.removeSchedule(id: notificationModel.content!.id!)
                        }
                    }
                }
            }
            return notificationModel
        }
        else {
            if(notificationModel.schedule != nil){
                _ = ScheduleManager.removeSchedule(id: notificationModel.content!.id!)
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
    
    private static func buildNotificationContentFromModel(notificationModel:NotificationModel) -> UNMutableNotificationContent {
        let content = UNMutableNotificationContent()
        return content
    }
    
    public static func setUserInfoContent(notificationModel:NotificationModel, content:UNMutableNotificationContent) {
        
        let pushData = notificationModel.toMap()
        let jsonData = JsonUtils.toJson(pushData)

        content.userInfo[Definitions.NOTIFICATION_JSON] = jsonData
        content.userInfo[Definitions.NOTIFICATION_ID] = notificationModel.content!.id!
        content.userInfo[Definitions.NOTIFICATION_CHANNEL_KEY] = notificationModel.content!.channelKey!
        content.userInfo[Definitions.NOTIFICATION_GROUP_KEY] = notificationModel.content!.groupKey
    }

    private static func setTitle(notificationModel:NotificationModel, channel:NotificationChannelModel, content:UNMutableNotificationContent){
        content.title = notificationModel.content!.title?.withoutHtmlTags() ?? ""
    }
    
    private static func setBody(notificationModel:NotificationModel, content:UNMutableNotificationContent){
        content.body = notificationModel.content!.body?.withoutHtmlTags() ?? ""
    }
    
    private static func setSummary(notificationModel:NotificationModel, content:UNMutableNotificationContent){
        if #available(iOS 12.0, *) {
            content.summaryArgument = notificationModel.content!.summary?.withoutHtmlTags() ?? ""
        }
    }
    
    private static func setBadgeIndicator(notificationModel:NotificationModel, channel:NotificationChannelModel, content:UNMutableNotificationContent){
        if(channel.channelShowBadge!){
            content.badge = NSNumber(value: BadgeManager.incrementGlobalBadgeCounter())
        }
    }
    
    private static func createActionButtonsAndCategory(notificationModel:NotificationModel, content:UNMutableNotificationContent){
        
        var categoryIdentifier:String = StringUtils.isNullOrEmpty(content.categoryIdentifier) ?
            Definitions.DEFAULT_CATEGORY_IDENTIFIER : content.categoryIdentifier
        
        var actions:[UNNotificationAction] = []
        var dynamicCategory:[String] = []
        var dynamicLabels:[String] = []
        
        if(notificationModel.actionButtons != nil){
            
            var temporaryCategory:[String] = []
            
            dynamicCategory.append(content.categoryIdentifier)
            
            for button in notificationModel.actionButtons! {
                
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
                            options: (button.isDangerousOption ?? false) ?
                                [.destructive, .foreground] : [.foreground]
                        )
                        
                    case .DisabledAction:
                        action = UNNotificationAction(
                            identifier: button.key!,
                            title: button.label!,
                            options: (button.isDangerousOption ?? false) ?
                                [.destructive] : []
                        )
                    
                    default:
                        action = UNNotificationAction(
                            identifier: button.key!,
                            title: button.label!,
                            options: (button.isDangerousOption ?? false) ?
                                [.destructive, .foreground] : [.foreground]
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
    
    private static func getNextScheduleDate(notificationModel:NotificationModel?) -> Date? {
        
        if notificationModel?.schedule == nil { return nil }
        
        switch true {
            
            case notificationModel!.schedule! is NotificationCalendarModel:
                
                let calendarModel:NotificationCalendarModel = notificationModel!.schedule! as! NotificationCalendarModel
                guard let trigger:UNCalendarNotificationTrigger = calendarModel.getUNNotificationTrigger() as? UNCalendarNotificationTrigger else { return nil }
                
                return trigger.nextTriggerDate()
                
            case notificationModel!.schedule! is NotificationIntervalModel:
                
                let intervalModel:NotificationIntervalModel = notificationModel!.schedule! as! NotificationIntervalModel
                guard let trigger:UNTimeIntervalNotificationTrigger = intervalModel.getUNNotificationTrigger() as? UNTimeIntervalNotificationTrigger else { return nil }
                
                return trigger.nextTriggerDate()
                
            default:
                return nil
        }
        /*
        let cron:CronUtils = CronUtils()
        
        do {

            if(notificationModel != nil){

                nextValidDate = cron.getNextCalendar(
                    initialDateTime: notificationModel!.schedule!.createdDateTime,
                    crontabRule: notificationModel!.schedule!.crontabExpression
                )

                if(nextValidDate != nil){

                    return nextValidDate
                }
                else {

                    if(!(ListUtils.isEmptyLists(notificationModel!.schedule!.preciseSchedules as [AnyObject]?))){

                        for nextDateTime in notificationModel!.schedule!.preciseSchedules! {

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

                    _ = NotificationSenderAndScheduler.cancelNotification(id: notificationModel!.content!.id!)
                    Log.d(TAG, "Date is not more valid. ("+DateUtils.getUTCDate()+")")
                }
            }
        } catch {
            debugPrint("\(error)")
        }
        return nil
        */
    }
    
    private static func setVisibility(notificationModel:NotificationModel, channel:NotificationChannelModel, content:UNMutableNotificationContent){
        // TODO
    }
    
    private static func setShowWhen(notificationModel:NotificationModel, content:UNMutableNotificationContent){
        // TODO
    }

    private static func setAutoCancel(notificationModel:NotificationModel, content:UNMutableNotificationContent){
        // TODO
    }
    
    private static func setTicker(notificationModel:NotificationModel, content:UNMutableNotificationContent){
        // TODO
    }
    
    private static func setOnlyAlertOnce(notificationModel:NotificationModel, channel:NotificationChannelModel, content:UNMutableNotificationContent){
        // TODO
    }

    private static func setLockedNotification(notificationModel:NotificationModel, channel:NotificationChannelModel, content:UNMutableNotificationContent){
        // TODO
    }
    
    private static func setImportance(channel:NotificationChannelModel, content:UNMutableNotificationContent){
        // TODO
    }

    private static func setSound(notificationModel:NotificationModel, channel:NotificationChannelModel, content:UNMutableNotificationContent){
        if (notificationModel.content!.playSound ?? false) && (channel.playSound ?? false) {
            
            if(!StringUtils.isNullOrEmpty(notificationModel.content!.customSound)){
                content.sound = AudioUtils.getSoundFromSource(SoundPath: notificationModel.content!.customSound!)
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
    
    private static func setLargeIcon(notificationModel:NotificationModel, content:UNMutableNotificationContent){
        // TODO
    }
    
    private static func setLayoutColor(notificationModel:NotificationModel, channel:NotificationChannelModel, content:UNMutableNotificationContent){
        // TODO
    }

    private static func setGrouping(notificationModel:NotificationModel, channel:NotificationChannelModel, content:UNMutableNotificationContent){

        let groupKey:String? = getGroupKey(notificationModel: notificationModel, channel: channel)
        if(!StringUtils.isNullOrEmpty(groupKey)){
            content.threadIdentifier = groupKey!
        }
    }

    private static func getGroupKey(notificationModel:NotificationModel, channel:NotificationChannelModel) -> String? {
        return notificationModel.content!.groupKey ?? channel.groupKey
    }

    private static func setLayout(notificationModel:NotificationModel, content:UNMutableNotificationContent){
        
        switch notificationModel.content!.notificationLayout {
            
            case .BigPicture:
                setBigPictureLayout(notificationModel: notificationModel, content: content)
                return
                
            case .BigText:
                setBigTextLayout(notificationModel: notificationModel, content: content)
                return
                
            case .Inbox:
                setInboxLayout(notificationModel: notificationModel, content: content)
                return
                
            case .MediaPlayer:
                setMediaPlayerLayout(notificationModel: notificationModel, content: content)
                return
                
            case .Messaging:
                setMessagingLayout(notificationModel: notificationModel, content: content, isGrouping: false)
                return
                
            case .MessagingGroup:
                setMessagingLayout(notificationModel: notificationModel, content: content, isGrouping: true)
                return
                        
            case .ProgressBar:
                setProgressBarLayout(notificationModel: notificationModel, content: content)
                return
                            
            case .Default:
                setDefaultLayout(notificationModel: notificationModel, content: content)
                return
            
            default:
                setDefaultLayout(notificationModel: notificationModel, content: content)
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
    
    private static func setBigPictureLayout(notificationModel:NotificationModel, content:UNMutableNotificationContent) {
        content.categoryIdentifier = "BigPicture"
        
        if(!StringUtils.isNullOrEmpty(notificationModel.content?.bigPicture)){
            
            if let attachment:UNNotificationAttachment = getAttatchmentFromBitmapSource(notificationModel.content?.bigPicture) {
                content.attachments.append(attachment)
                return
            }
        }
        
        if(!StringUtils.isNullOrEmpty(notificationModel.content?.largeIcon)){
            
            if let attachment:UNNotificationAttachment = getAttatchmentFromBitmapSource(notificationModel.content?.largeIcon) {
                content.attachments.append(attachment)
            }
        }
    }
    
    private static func setBigTextLayout(notificationModel:NotificationModel, content:UNMutableNotificationContent) {
        content.categoryIdentifier = "BigText"
    }
    
    private static func setProgressBarLayout(notificationModel:NotificationModel, content:UNMutableNotificationContent) {
        content.categoryIdentifier = "ProgressBar"
    }
    
    private static func setIndeterminateBarLayout(notificationModel:NotificationModel, content:UNMutableNotificationContent) {
        content.categoryIdentifier = "IndeterminateBar"
    }
    
    private static func setMediaPlayerLayout(notificationModel:NotificationModel, content:UNMutableNotificationContent) {
        content.categoryIdentifier = "MediaPlayer"
    }
    
    private static func setInboxLayout(notificationModel:NotificationModel, content:UNMutableNotificationContent) {
        content.categoryIdentifier = "Inbox"
    }
    
    private static func setMessagingLayout(notificationModel:NotificationModel, content:UNMutableNotificationContent, isGrouping:Bool) {
        content.categoryIdentifier = "Messaging"
        
        content.threadIdentifier = (isGrouping ? "MessagingGR." : "Messaging.")+notificationModel.content!.channelKey!
    }
    
    private static func setDefaultLayout(notificationModel:NotificationModel, content:UNMutableNotificationContent) {
        content.categoryIdentifier = "Default"
    }
    
}
