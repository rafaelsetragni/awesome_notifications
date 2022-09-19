//
//  NotificationBuilder.swift
//  awesome_notifications
//
//  Created by Rafael Setragni on 11/09/20.
//

import Foundation

@available(iOS 10.0, *)
public class NotificationBuilder {
    
    private let TAG = "NotificationBuilder"
    
    // ************** FACTORY PATTERN ***********************

    public static func newInstance() -> NotificationBuilder {
        return NotificationBuilder()
    }
    private init(){}
    
    // ********************************************************
    
    public func jsonDataToNotificationModel(jsonData:[String : Any?]?) -> NotificationModel? {
        if jsonData?.isEmpty ?? true { return nil }

        let notificationModel:NotificationModel? = NotificationModel().fromMap(arguments: jsonData!) as? NotificationModel
        return notificationModel
    }
    
    public func jsonToNotificationModel(jsonData:String?) -> NotificationModel? {
        if StringUtils.shared.isNullOrEmpty(jsonData) { return nil }
        
        let data:[String:Any?]? = JsonUtils.fromJson(jsonData)
        if data == nil { return nil }
        
        let notificationModel:NotificationModel? = NotificationModel().fromMap(arguments: data!) as? NotificationModel
        return notificationModel
    }
    
    public func buildNotificationFromJson(jsonData:String?) -> NotificationModel? {
        return  jsonToNotificationModel(jsonData: jsonData)
    }
    
    public func buildNotificationActionFromModel(
        notificationModel:NotificationModel?,
        buttonKeyPressed:String?,
        userText:String?
    ) -> ActionReceived? {
        if notificationModel == nil { return nil }
        
        let actionReceived:ActionReceived = ActionReceived(
            notificationModel!.content,
            buttonKeyPressed: buttonKeyPressed,
            buttonKeyInput: userText)
        
        if notificationModel!.actionButtons != nil && !StringUtils.shared.isNullOrEmpty(buttonKeyPressed) {
            for button:NotificationButtonModel in notificationModel!.actionButtons! {
                if button.key == buttonKeyPressed {
                    actionReceived.autoDismissible = button.autoDismissible
                    actionReceived.actionType = button.actionType
                    break
                }
            }
        }
        
        if notificationModel!.schedule == nil {
            actionReceived.displayedDate = actionReceived.createdDate
            actionReceived.displayedLifeCycle = actionReceived.createdLifeCycle
        }
        
        if actionReceived.actionType == nil {
            actionReceived.actionType = .Default
        }
        
        return actionReceived
    }
    
    public func createNotification(
        _ notificationModel:NotificationModel,
        content:UNMutableNotificationContent?,
        completion: @escaping (NotificationModel?) -> ()
    ) throws {
        
        guard let channelkey:String = notificationModel.content!.channelKey else {
            throw ExceptionFactory
                    .shared
                    .createNewAwesomeException(
                        className: NotificationIntervalModel.TAG,
                        code: ExceptionCode.CODE_INVALID_ARGUMENTS,
                        message: "Channel key is required",
                        detailedCode: ExceptionCode.DETAILED_INVALID_ARGUMENTS+".channel.key")
        }
        
        guard let channel = ChannelManager.shared.getChannelByKey(channelKey: channelkey) else {
            throw ExceptionFactory
                    .shared
                    .createNewAwesomeException(
                        className: NotificationIntervalModel.TAG,
                        code: ExceptionCode.CODE_INSUFFICIENT_PERMISSIONS,
                        message: "Channel '\(channelkey)' does not exist",
                        detailedCode: ExceptionCode.DETAILED_INSUFFICIENT_PERMISSIONS+".channel.notFound.\(channelkey)")
        }
        
        if !ChannelManager.shared.isNotificationChannelActive(channel: channel) {
            throw ExceptionFactory
                    .shared
                    .createNewAwesomeException(
                        className: NotificationIntervalModel.TAG,
                        code: ExceptionCode.CODE_INSUFFICIENT_PERMISSIONS,
                        message: "Channel '\(channelkey)' is disabled",
                        detailedCode: ExceptionCode.DETAILED_INSUFFICIENT_PERMISSIONS+".channel.disabled.\(channelkey)")
        }

        notificationModel.content!.groupKey = getGroupKey(notificationModel: notificationModel, channel: channel)

        let nextDate:RealDateTime? = getNextScheduleDate(notificationModel: notificationModel)
        if notificationModel.schedule != nil && nextDate == nil {
            _ = ScheduleManager.removeSchedule(id: notificationModel.content!.id!)
            completion(nil)
            return
        }
            
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
        setImportance(channel: channel, notificationModel: notificationModel,content: content)
        
        setSound(notificationModel: notificationModel, channel: channel, content: content)
        setVibrationPattern(channel: channel, content: content)
        
        setLights(channel: channel, content: content)
        
        setSmallIcon(channel: channel, content: content)
        setLargeIcon(notificationModel: notificationModel, content: content)
        
        setLayoutColor(notificationModel: notificationModel, channel: channel, content: content)
        
        setLayout(notificationModel: notificationModel, content: content)
        
        let category:UNNotificationCategory =
            createActionButtonsAndCategory(
                notificationModel: notificationModel,
                content: content)
        
        setWakeUpScreen(notificationModel: notificationModel, content: content)
        setCriticalAlert(channel: channel, content: content)
        
        setUserInfoContent(notificationModel: notificationModel, content: content)
        
        notificationModel.nextValidDate = nextDate
        
        let trigger:UNNotificationTrigger? = nextDate == nil ? nil : notificationModel.schedule?.getUNNotificationTrigger()
        let request = UNNotificationRequest(identifier: notificationModel.content!.id!.description, content: content, trigger: trigger)
                
        var previousCategories:[UNNotificationCategory] = []
        previousCategories.append(contentsOf: [category])
        UNUserNotificationCenter.current().setNotificationCategories(Set(previousCategories))            
        Logger.d(TAG, "Notification Category Identifier: \(category.identifier)")
        
        if(notificationModel.schedule != nil){
            
            notificationModel.schedule!.timeZone =
                notificationModel.schedule!.timeZone ?? TimeZone.current
            notificationModel.schedule!.createdDate = RealDateTime(
                fromTimeZone: notificationModel.schedule!.timeZone!)
            
            if (nextDate != nil){
                ScheduleManager.saveSchedule(notification: notificationModel, nextDate: nextDate!.date)
            } else {
                _ = ScheduleManager.removeSchedule(id: notificationModel.content!.id!)
            }
        }
        
        if SwiftUtils.isRunningOnExtension() {
            completion(notificationModel)
            return
        }
        
        UNUserNotificationCenter.current().add(request) { error in
            if error != nil {
                ExceptionFactory
                        .shared
                        .registerNewAwesomeException(
                            className: NotificationIntervalModel.TAG,
                            code: ExceptionCode.CODE_UNKNOWN_EXCEPTION,
                            message: "Notification could not be created",
                            detailedCode: ExceptionCode.DETAILED_UNEXPECTED_ERROR+".createNotification",
                            originalException: error!)
                completion(nil)
            }
            completion(notificationModel)
        }
    }
    
    private func dateToCalendarTrigger(targetDate:Date?) -> UNCalendarNotificationTrigger? {
        if(targetDate == nil){ return nil}
        
        let dateComponents = Calendar.current.dateComponents([.day, .month, .year, .hour, .minute, .second], from: targetDate!)
        let trigger = UNCalendarNotificationTrigger( dateMatching: dateComponents, repeats: false )
        return trigger
    }
    
    private func buildNotificationContentFromModel(notificationModel:NotificationModel) -> UNMutableNotificationContent {
        let content = UNMutableNotificationContent()
        return content
    }
    
    public func setUserInfoContent(notificationModel:NotificationModel, content:UNMutableNotificationContent) {
        
        let pushData = notificationModel.toMap()
        let jsonData = JsonUtils.toJson(pushData)
        
        content.userInfo[Definitions.NOTIFICATION_JSON] = jsonData
        content.userInfo[Definitions.NOTIFICATION_ID] = notificationModel.content!.id!
        content.userInfo[Definitions.NOTIFICATION_CHANNEL_KEY] = notificationModel.content!.channelKey!
        content.userInfo[Definitions.NOTIFICATION_GROUP_KEY] = notificationModel.content!.groupKey
    }

    private func setTitle(notificationModel:NotificationModel, channel:NotificationChannelModel, content:UNMutableNotificationContent){
        content.title = notificationModel.content!.title?.withoutHtmlTags() ?? ""
    }
    
    private func setBody(notificationModel:NotificationModel, content:UNMutableNotificationContent){
        content.body = notificationModel.content!.body?.withoutHtmlTags() ?? ""
    }
    
    private func setSummary(notificationModel:NotificationModel, content:UNMutableNotificationContent){
        if #available(iOS 12.0, *) {
            content.summaryArgument = notificationModel.content!.summary?.withoutHtmlTags() ?? ""
        }
    }
    
    private func setBadgeIndicator(notificationModel:NotificationModel, channel:NotificationChannelModel, content:UNMutableNotificationContent){
        if(channel.channelShowBadge!){
            content.badge = NSNumber(value: BadgeManager.shared.incrementGlobalBadgeCounter())
        }
    }
    
    private func createActionButtonsAndCategory(notificationModel:NotificationModel, content:UNMutableNotificationContent) -> UNNotificationCategory{
        
        var categoryIdentifier:String = StringUtils.shared.isNullOrEmpty(content.categoryIdentifier) ?
            Definitions.DEFAULT_CATEGORY_IDENTIFIER : content.categoryIdentifier
        
        var actions:[UNNotificationAction] = []
        var dynamicCategory:[String] = [categoryIdentifier]
        
        if(notificationModel.actionButtons != nil){
            for button in notificationModel.actionButtons! {
                
                let action:UNNotificationAction?
                var options:UNNotificationActionOptions = []
                
                if button.actionType == .Default {
                    options.update(with: .foreground)
                }
                
                if button.isDangerousOption ?? false {
                    options.update(with: .destructive)
                }
                
                if button.requireInputText ?? false {
                    action = UNTextInputNotificationAction(
                        identifier:
                            button.actionType == .DismissAction
                                    ? UNNotificationDismissActionIdentifier.description
                                    : button.key!,
                        title: button.label!,
                        options: options
                    )
                }
                else {
                    action = UNNotificationAction(
                        identifier:
                            button.actionType == .DismissAction
                                    ? UNNotificationDismissActionIdentifier.description
                                    : button.key!,
                        title: button.label!,
                        options: options
                    )
                }
                
                dynamicCategory.append("\(button.key ?? "")(\(button.label ?? ""))")
                actions.append(action!)
            }
        }
        
        categoryIdentifier = dynamicCategory.joined(separator: ",").uppercased()
        
        content.categoryIdentifier = categoryIdentifier
        return UNNotificationCategory(
            identifier: categoryIdentifier,
            actions: actions,
            intentIdentifiers: [],
            options: .customDismissAction
        )
    }
    
    private func getNextScheduleDate(notificationModel:NotificationModel?) -> RealDateTime? {
        
        if notificationModel?.schedule == nil { return nil }
        var nextDate:Date?
        switch true {
            
            case notificationModel!.schedule! is NotificationCalendarModel:
                
                let calendarModel:NotificationCalendarModel = notificationModel!.schedule! as! NotificationCalendarModel
                guard let trigger:UNCalendarNotificationTrigger = calendarModel.getUNNotificationTrigger() as? UNCalendarNotificationTrigger else { return nil }
                
                nextDate = trigger.nextTriggerDate()
                
            case notificationModel!.schedule! is NotificationIntervalModel:
                
                let intervalModel:NotificationIntervalModel = notificationModel!.schedule! as! NotificationIntervalModel
                guard let trigger:UNTimeIntervalNotificationTrigger = intervalModel.getUNNotificationTrigger() as? UNTimeIntervalNotificationTrigger else { return nil }
                
                nextDate = trigger.nextTriggerDate()
                
            default:
                break
        }
        
        if nextDate == nil {
            return nil
        }
        
        return RealDateTime.init(fromDate: nextDate!, inTimeZone: notificationModel!.schedule!.timeZone!)
    }
    
    private func setVisibility(notificationModel:NotificationModel, channel:NotificationChannelModel, content:UNMutableNotificationContent){
        // TODO
    }
    
    private func setShowWhen(notificationModel:NotificationModel, content:UNMutableNotificationContent){
        // TODO
    }

    private func setAutoCancel(notificationModel:NotificationModel, content:UNMutableNotificationContent){
        // TODO
    }
    
    private func setTicker(notificationModel:NotificationModel, content:UNMutableNotificationContent){
        // TODO
    }
    
    private func setOnlyAlertOnce(notificationModel:NotificationModel, channel:NotificationChannelModel, content:UNMutableNotificationContent){
        // TODO
    }

    private func setLockedNotification(notificationModel:NotificationModel, channel:NotificationChannelModel, content:UNMutableNotificationContent){
        // TODO
    }
    
    private func setImportance(channel:NotificationChannelModel, notificationModel:NotificationModel, content:UNMutableNotificationContent){
        notificationModel.importance = notificationModel.importance ?? channel.importance ?? .Default
        if #available(iOS 15.0, *) {
            switch notificationModel.importance! {
                
            case .None, .Min, .Low:
                content.interruptionLevel = .passive
                break
                
            case .Default:
                content.interruptionLevel = .active
                break
                
            case .High, .Max:
                content.interruptionLevel = .timeSensitive
                break
            }
        }
    }

    private func setSound(notificationModel:NotificationModel, channel:NotificationChannelModel, content:UNMutableNotificationContent){
        
        switch notificationModel.importance ?? .Default {
            
            case .Default, .High, .Max:
            if (notificationModel.content!.playSound ?? false) && (channel.playSound ?? false) {
                
                if(!StringUtils.shared.isNullOrEmpty(notificationModel.content!.customSound)){
                    content.sound = AudioUtils.shared.getSoundFromSource(SoundPath: notificationModel.content!.customSound!)
                    return
                }
                
                if(!StringUtils.shared.isNullOrEmpty(channel.soundSource)){
                    content.sound = AudioUtils.shared.getSoundFromSource(SoundPath: channel.soundSource!)
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
            break
            
            default:
            break
        }
    }
    
    private func setVibrationPattern(channel:NotificationChannelModel, content:UNMutableNotificationContent){
        // TODO
    }
    
    private func setLights(channel:NotificationChannelModel, content:UNMutableNotificationContent){
        // iOS does not have any lights
    }
    
    private func setWakeUpScreen(notificationModel:NotificationModel, content:UNMutableNotificationContent){
        if notificationModel.content?.wakeUpScreen ?? false {
            if #available(iOS 15.0, *) {
                content.interruptionLevel = .timeSensitive
            }
        }
    }
    
    private func setCriticalAlert(channel:NotificationChannelModel, content:UNMutableNotificationContent){
        if channel.criticalAlerts ?? false {
            if #available(iOS 15.0, *) {
                content.interruptionLevel = .critical
            }
        }
    }

    private func setSmallIcon(channel:NotificationChannelModel, content:UNMutableNotificationContent){
        // TODO
    }
    
    private func setLargeIcon(notificationModel:NotificationModel, content:UNMutableNotificationContent){
        // TODO
    }
    
    private func setLayoutColor(notificationModel:NotificationModel, channel:NotificationChannelModel, content:UNMutableNotificationContent){
        // TODO
    }

    private func setGrouping(notificationModel:NotificationModel, channel:NotificationChannelModel, content:UNMutableNotificationContent){

        let groupKey:String? = getGroupKey(notificationModel: notificationModel, channel: channel)
        if(!StringUtils.shared.isNullOrEmpty(groupKey)){
            content.threadIdentifier = groupKey!
        }
    }

    private func getGroupKey(notificationModel:NotificationModel, channel:NotificationChannelModel) -> String? {
        return notificationModel.content!.groupKey ?? channel.groupKey
    }

    private func setLayout(notificationModel:NotificationModel, content:UNMutableNotificationContent){
        
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
    
    private func getBitmapAttatchment(from bitmapSource:String?, rounding roundedBitmap: Bool) -> UNNotificationAttachment? {
        
        //let dimensionLimit:CGFloat = 1038.0
        		
        if !StringUtils.shared.isNullOrEmpty(bitmapSource) {
            
            if let image:UIImage =
                BitmapUtils
                    .shared
                    .getBitmapFromSource(
                        bitmapPath: bitmapSource!,
                        roundedBitpmap: roundedBitmap
            ){
                
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
                    Logger.e(TAG, error.localizedDescription)
                }
            }
        }
        return nil
    }
    
    private func setBigPictureLayout(notificationModel:NotificationModel, content:UNMutableNotificationContent) {
        content.categoryIdentifier = "BigPicture"
        
        if(!StringUtils.shared.isNullOrEmpty(notificationModel.content?.bigPicture)){
            
            if let attachment:UNNotificationAttachment =
                getBitmapAttatchment(
                    from: notificationModel.content?.bigPicture,
                    rounding: notificationModel.content?.roundedBigPicture ?? false
            ){
                content.attachments.append(attachment)
                return
            }
        }
        
        if(!StringUtils.shared.isNullOrEmpty(notificationModel.content?.largeIcon)){
            
            if let attachment:UNNotificationAttachment =
                    getBitmapAttatchment(
                        from: notificationModel.content?.largeIcon,
                        rounding: notificationModel.content?.roundedLargeIcon ?? false
            ){
                content.attachments.append(attachment)
            }
        }
    }
    
    private func setBigTextLayout(notificationModel:NotificationModel, content:UNMutableNotificationContent) {
        content.categoryIdentifier = "BigText"
    }
    
    private func setProgressBarLayout(notificationModel:NotificationModel, content:UNMutableNotificationContent) {
        content.categoryIdentifier = "ProgressBar"
        Logger.w(TAG, "ProgressBar layout are not available yet for iOS")
    }
    
    private func setIndeterminateBarLayout(notificationModel:NotificationModel, content:UNMutableNotificationContent) {
        content.categoryIdentifier = "IndeterminateBar"
        Logger.w(TAG, "IndeterminateBar layout are not available yet for iOS")
    }
    
    private func setMediaPlayerLayout(notificationModel:NotificationModel, content:UNMutableNotificationContent) {
        content.categoryIdentifier = "MediaPlayer"
        Logger.w(TAG, "MediaPlayer layout are not available yet for iOS")
    }
    
    private func setInboxLayout(notificationModel:NotificationModel, content:UNMutableNotificationContent) {
        content.categoryIdentifier = "Inbox"
        Logger.w(TAG, "Imbox layout are not available yet for iOS")
    }
    
    private func setMessagingLayout(notificationModel:NotificationModel, content:UNMutableNotificationContent, isGrouping:Bool) {
        content.categoryIdentifier = "Messaging"
        
        content.threadIdentifier = (isGrouping ? "MessagingGR." : "Messaging.")+notificationModel.content!.channelKey!
    }
    
    private func setDefaultLayout(notificationModel:NotificationModel, content:UNMutableNotificationContent) {
        content.categoryIdentifier = "Default"
    }
    
}

//func awaitExectution(timeoutInSeconds: Int = 0, completion: @escaping ( DispatchGroup ) -> Void){
//    let group = DispatchGroup()
//    group.enter()
//
//    let workItem:DispatchWorkItem = DispatchWorkItem {
//        DispatchQueue(label: UUID().uuidString).async {
//            completion(group)
//        }
//    }
//
//    workItem.perform()
//    if timeoutInSeconds == 0 {
//        group.wait()
//    }
//    else {
//        _ = group.wait(timeout: DispatchTime.now() + .seconds(timeoutInSeconds))
//    }
//}
