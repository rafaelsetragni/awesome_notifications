//
//  NotificationContentModel.swift
//  awesome_notifications
//
//  Created by Rafael Setragni on 05/09/20.
//

import Foundation

public class NotificationContentModel : AbstractModel {
    
    static let TAG = "NotificationContentModel"

    public var id: Int?
    public var channelKey: String?
    public var groupKey: String?
    public var title: String?
    public var body: String?
    public var summary: String?
    public var showWhen: Bool?
    
    public var actionButtons:[NotificationButtonModel]?
    public var payload:[String:String?]?
    
    public var wakeUpScreen: Bool?
    public var playSound: Bool?
    public var customSound: String?
    public var locked: Bool?
    public var icon: String?
    public var largeIcon: String?
    public var bigPicture: String?
    public var hideLargeIconOnExpand: Bool?
    public var autoDismissible: Bool?
    public var displayOnForeground: Bool?
    public var displayOnBackground: Bool?
    public var color: Int64?
    public var backgroundColor: Int64?
    public var progress: Int?
    public var ticker: String?

    public var roundedLargeIcon: Bool?
    public var roundedBigPicture: Bool?
    
    public var actionType: ActionType?
    
    public var privacy: NotificationPrivacy?
    public var privateMessage: String?

    public var notificationLayout: NotificationLayout?

    public var createdSource: NotificationSource?
    public var createdLifeCycle: NotificationLifeCycle?
    public var displayedLifeCycle: NotificationLifeCycle?
    public var createdDate: RealDateTime?
    public var displayedDate: RealDateTime?
    
    public init(){}
    
    func registerCreateEvent(
        inLifeCycle lifeCycle: NotificationLifeCycle,
        fromSource createdSource: NotificationSource
    ) -> Bool {
        if(self.createdDate == nil){
            self.createdSource = createdSource
            self.createdLifeCycle = lifeCycle
            self.createdDate =
                    RealDateTime.init(
                        fromTimeZone: RealDateTime.utcTimeZone)
            
            return true
        }
        return false
    }
    
    public func registerDisplayedEvent(
        inLifeCycle lifeCycle: NotificationLifeCycle
    ){
        self.displayedLifeCycle = lifeCycle
        self.displayedDate =
                RealDateTime.init(
                    fromTimeZone: TimeZone(identifier: "UTC"))
    }
    
    public func registerLastDisplayedEvent(
        inLifeCycle lifeCycle: NotificationLifeCycle,
        fromNotificationResponse response: UNNotificationResponse,
        fromNotificationSchedule schedule: NotificationScheduleModel?
    ){
        if displayedDate == nil {
            displayedDate = RealDateTime.init(
                fromDate: response.notification.date,
                inTimeZone: DateUtils.shared.utcTimeZone)
            
            if schedule == nil {
                registerDisplayedEvent(
                    inLifeCycle: lifeCycle
                )
            }
            else {
                displayedLifeCycle = lifeCycle
//                    DateUtils
//                        .shared
//                        .getLastValidDate(
//                            scheduleModel: schedule!,
//                            fixedDateTime: RealDateTime.init(
//                                fromTimeZone: TimeZone(identifier: "UTC")))
            }
        }
    }
    
    public func fromMap(arguments: [String : Any?]?) -> AbstractModel? {
                
        self.id = MapUtils<Int>.getValueOrDefault(reference: Definitions.NOTIFICATION_ID, arguments: arguments)
        if((id ?? -1) < 0) {
            id = IntUtils.generateNextRandomId();
        }
        
        _processRetroCompatibility(fromArguments: arguments)
        
        self.channelKey     = MapUtils<String>.getValueOrDefault(reference: Definitions.NOTIFICATION_CHANNEL_KEY, arguments: arguments)
        self.groupKey       = MapUtils<String>.getValueOrDefault(reference: Definitions.NOTIFICATION_GROUP_KEY, arguments: arguments)
        self.title          = MapUtils<String>.getValueOrDefault(reference: Definitions.NOTIFICATION_TITLE, arguments: arguments)
        self.body           = MapUtils<String>.getValueOrDefault(reference: Definitions.NOTIFICATION_BODY, arguments: arguments)
        self.summary        = MapUtils<String>.getValueOrDefault(reference: Definitions.NOTIFICATION_SUMMARY, arguments: arguments)
        self.showWhen       = MapUtils<Bool>.getValueOrDefault(reference: Definitions.NOTIFICATION_SHOW_WHEN, arguments: arguments)
        
        self.playSound             = MapUtils<Bool>.getValueOrDefault(reference: Definitions.NOTIFICATION_PLAY_SOUND, arguments: arguments)
        self.customSound           = MapUtils<String>.getValueOrDefault(reference: Definitions.NOTIFICATION_CUSTOM_SOUND, arguments: arguments)
        
        self.wakeUpScreen          = MapUtils<Bool>.getValueOrDefault(reference: Definitions.NOTIFICATION_WAKE_UP_SCREEN, arguments: arguments)
        self.locked                = MapUtils<Bool>.getValueOrDefault(reference: Definitions.NOTIFICATION_LOCKED, arguments: arguments)
        self.icon                  = MapUtils<String>.getValueOrDefault(reference: Definitions.NOTIFICATION_ICON, arguments: arguments)
        self.largeIcon             = MapUtils<String>.getValueOrDefault(reference: Definitions.NOTIFICATION_LARGE_ICON, arguments: arguments)
        self.bigPicture            = MapUtils<String>.getValueOrDefault(reference: Definitions.NOTIFICATION_BIG_PICTURE, arguments: arguments)
        self.hideLargeIconOnExpand = MapUtils<Bool>.getValueOrDefault(reference: Definitions.NOTIFICATION_HIDE_LARGE_ICON_ON_EXPAND, arguments: arguments)
        self.autoDismissible       = MapUtils<Bool>.getValueOrDefault(reference: Definitions.NOTIFICATION_AUTO_DISMISSIBLE, arguments: arguments)
        self.displayOnForeground   = MapUtils<Bool>.getValueOrDefault(reference: Definitions.NOTIFICATION_DISPLAY_ON_FOREGROUND, arguments: arguments)
        self.displayOnBackground   = MapUtils<Bool>.getValueOrDefault(reference: Definitions.NOTIFICATION_DISPLAY_ON_BACKGROUND, arguments: arguments)
        self.color                 = MapUtils<Int64>.getValueOrDefault(reference: Definitions.NOTIFICATION_COLOR, arguments: arguments)
        self.backgroundColor       = MapUtils<Int64>.getValueOrDefault(reference: Definitions.NOTIFICATION_BACKGROUND_COLOR, arguments: arguments)
        self.progress              = MapUtils<Int>.getValueOrDefault(reference: Definitions.NOTIFICATION_PROGRESS, arguments: arguments)
        self.ticker                = MapUtils<String>.getValueOrDefault(reference: Definitions.NOTIFICATION_TICKER, arguments: arguments)
        
        self.roundedLargeIcon   = MapUtils<Bool>.getValueOrDefault(reference: Definitions.NOTIFICATION_ROUNDED_LARGE_ICON, arguments: arguments)
        self.roundedBigPicture  = MapUtils<Bool>.getValueOrDefault(reference: Definitions.NOTIFICATION_ROUNDED_BIG_PICTURE, arguments: arguments)
        
        self.actionType         = EnumUtils<ActionType>.getEnumOrDefault(reference: Definitions.NOTIFICATION_ACTION_TYPE, arguments: arguments)
        
        self.privacy            = EnumUtils<NotificationPrivacy>.getEnumOrDefault(reference: Definitions.NOTIFICATION_PRIVACY, arguments: arguments)
        self.privateMessage     = MapUtils<String>.getValueOrDefault(reference: Definitions.NOTIFICATION_PRIVATE_MESSAGE, arguments: arguments)
        
        self.notificationLayout = EnumUtils<NotificationLayout>.getEnumOrDefault(reference: Definitions.NOTIFICATION_LAYOUT, arguments: arguments)
        
        self.createdSource      = EnumUtils<NotificationSource>.getEnumOrDefault(reference: Definitions.NOTIFICATION_CREATED_SOURCE, arguments: arguments)
        self.createdLifeCycle   = EnumUtils<NotificationLifeCycle>.getEnumOrDefault(reference: Definitions.NOTIFICATION_CREATED_LIFECYCLE, arguments: arguments)
        self.displayedLifeCycle = EnumUtils<NotificationLifeCycle>.getEnumOrDefault(reference: Definitions.NOTIFICATION_DISPLAYED_LIFECYCLE, arguments: arguments)
        self.createdDate        = MapUtils<RealDateTime>.getRealDateOrDefault(reference: Definitions.NOTIFICATION_CREATED_DATE, arguments: arguments, defaultTimeZone: RealDateTime.utcTimeZone)
        self.displayedDate      = MapUtils<RealDateTime>.getRealDateOrDefault(reference: Definitions.NOTIFICATION_DISPLAYED_DATE, arguments: arguments, defaultTimeZone: RealDateTime.utcTimeZone)
        
        self.payload  = MapUtils<[String:String?]>.getValueOrDefault(reference: Definitions.NOTIFICATION_PAYLOAD, arguments: arguments)
        
        return self
    }
    
    public func toMap() -> [String : Any?] {
        var mapData:[String: Any?] = [:]
        
        if(self.id != nil) {mapData[Definitions.NOTIFICATION_ID] = self.id}
        if(self.channelKey != nil) {mapData[Definitions.NOTIFICATION_CHANNEL_KEY] = self.channelKey}
        if(self.groupKey != nil) {mapData[Definitions.NOTIFICATION_GROUP_KEY] = self.groupKey}
        if(self.title != nil){ mapData[Definitions.NOTIFICATION_TITLE] = self.title }
        if(self.body != nil){ mapData[Definitions.NOTIFICATION_BODY] = self.body }
        if(self.summary != nil){ mapData[Definitions.NOTIFICATION_SUMMARY] = self.summary }
        if(self.wakeUpScreen != nil){ mapData[Definitions.NOTIFICATION_WAKE_UP_SCREEN] = self.wakeUpScreen }
        if(self.showWhen != nil){ mapData[Definitions.NOTIFICATION_SHOW_WHEN] = self.showWhen }
        if(self.playSound != nil){ mapData[Definitions.NOTIFICATION_PLAY_SOUND] = self.playSound }
        if(self.customSound != nil){ mapData[Definitions.NOTIFICATION_CUSTOM_SOUND] = self.customSound }
        if(self.icon != nil){ mapData[Definitions.NOTIFICATION_ICON] = self.icon }
        if(self.largeIcon != nil){ mapData[Definitions.NOTIFICATION_LARGE_ICON] = self.largeIcon }
        if(self.locked != nil){ mapData[Definitions.NOTIFICATION_LOCKED] = self.locked }
        if(self.bigPicture != nil){ mapData[Definitions.NOTIFICATION_BIG_PICTURE] = self.bigPicture }
        if(self.hideLargeIconOnExpand != nil){ mapData[Definitions.NOTIFICATION_HIDE_LARGE_ICON_ON_EXPAND] = self.hideLargeIconOnExpand }
        if(self.autoDismissible != nil){ mapData[Definitions.NOTIFICATION_AUTO_DISMISSIBLE] = self.autoDismissible }
        if(self.roundedLargeIcon != nil){ mapData[Definitions.NOTIFICATION_ROUNDED_LARGE_ICON] = self.roundedLargeIcon }
        if(self.roundedBigPicture != nil){ mapData[Definitions.NOTIFICATION_ROUNDED_BIG_PICTURE] = self.roundedBigPicture }
        if(self.actionType != nil){ mapData[Definitions.NOTIFICATION_ACTION_TYPE] = self.actionType?.rawValue }
        if(self.displayOnForeground != nil){ mapData[Definitions.NOTIFICATION_DISPLAY_ON_FOREGROUND] = self.displayOnForeground }
        if(self.displayOnBackground != nil){ mapData[Definitions.NOTIFICATION_DISPLAY_ON_BACKGROUND] = self.displayOnBackground }
        if(self.color != nil){ mapData[Definitions.NOTIFICATION_COLOR] = self.color }
        if(self.backgroundColor != nil){ mapData[Definitions.NOTIFICATION_BACKGROUND_COLOR] = self.backgroundColor }
        if(self.progress != nil){ mapData[Definitions.NOTIFICATION_PROGRESS] = self.progress }
        if(self.ticker != nil){ mapData[Definitions.NOTIFICATION_TICKER] = self.ticker }
        if(self.privacy != nil){ mapData[Definitions.NOTIFICATION_PRIVACY] = self.privacy?.rawValue }
        if(self.privateMessage != nil){ mapData[Definitions.NOTIFICATION_PRIVATE_MESSAGE] = self.privateMessage }
        if(self.notificationLayout != nil){ mapData[Definitions.NOTIFICATION_LAYOUT] = self.notificationLayout?.rawValue }
        if(self.createdSource != nil){ mapData[Definitions.NOTIFICATION_CREATED_SOURCE] = self.createdSource?.rawValue }
        if(self.createdLifeCycle != nil){ mapData[Definitions.NOTIFICATION_CREATED_LIFECYCLE] = self.createdLifeCycle?.rawValue }
        if(self.displayedLifeCycle != nil){ mapData[Definitions.NOTIFICATION_DISPLAYED_LIFECYCLE] = self.displayedLifeCycle?.rawValue }
        if(self.createdDate != nil){ mapData[Definitions.NOTIFICATION_CREATED_DATE] = self.createdDate!.description }
        if(self.displayedDate != nil){ mapData[Definitions.NOTIFICATION_DISPLAYED_DATE] = self.displayedDate!.description  }
        if(self.payload != nil){ mapData[Definitions.NOTIFICATION_PAYLOAD] = self.payload }

        return mapData
    }
    
    func _processRetroCompatibility(fromArguments arguments: [String : Any?]?){
        if arguments?["autoCancel"] != nil {
            Logger.w(NotificationButtonModel.TAG, "autoCancel is deprecated. Please use autoDismissible instead.")
            autoDismissible = MapUtils<Bool>.getValueOrDefault(reference: "autoCancel", arguments: arguments)
        }
    }
    
    public func validate() throws {

        if(IntUtils.isNullOrEmpty(id)){
            throw ExceptionFactory
                    .shared
                    .createNewAwesomeException(
                        className: NotificationContentModel.TAG,
                        code: ExceptionCode.CODE_MISSING_ARGUMENTS,
                        message: "Notification id is required",
                        detailedCode: ExceptionCode.DETAILED_REQUIRED_ARGUMENTS+".notificationContent.id")
        }
        
        guard let channelKey:String = channelKey else {
            throw ExceptionFactory
                    .shared
                    .createNewAwesomeException(
                        className: NotificationContentModel.TAG,
                        code: ExceptionCode.CODE_INVALID_ARGUMENTS,
                        message: "channelKey cannot be null or empty",
                        detailedCode: ExceptionCode.DETAILED_INVALID_ARGUMENTS+".notificationContent.channelKey")
        }
        
        if(ChannelManager.shared.getChannelByKey(channelKey: channelKey) == nil){
            throw ExceptionFactory
                    .shared
                    .createNewAwesomeException(
                        className: NotificationContentModel.TAG,
                        code: ExceptionCode.CODE_INVALID_ARGUMENTS,
                        message: "Notification channel '\(channelKey)' does not exist.",
                        detailedCode: ExceptionCode.DETAILED_INVALID_ARGUMENTS+".notificationContent.\(channelKey)")
        }

        try validateIcon(icon)
        
        if notificationLayout == nil {
            notificationLayout = .Default
        } else {
            if notificationLayout == .BigPicture {
                try validateRequiredImages()
            }
        }

        try validateBigPicture()
        try validateLargeIcon()
    }
    
    private func validateRequiredImages() throws {
        if bigPicture == nil && largeIcon == nil {
            throw ExceptionFactory
                    .shared
                    .createNewAwesomeException(
                        className: NotificationContentModel.TAG,
                        code: ExceptionCode.CODE_MISSING_ARGUMENTS,
                        message: "bigPicture or largeIcon is required",
                        detailedCode: ExceptionCode.DETAILED_REQUIRED_ARGUMENTS+".image.required")
        }
    }
    
    private func validateIcon(_ icon:String?) throws {
        if StringUtils.shared.isNullOrEmpty(icon) {
            return
        }
        
        let mediaType:MediaSource = BitmapUtils.shared.getMediaSourceType(mediaPath: icon)
        if mediaType != MediaSource.Resource {
            throw ExceptionFactory
                    .shared
                    .createNewAwesomeException(
                        className: NotificationContentModel.TAG,
                        code: ExceptionCode.CODE_INVALID_ARGUMENTS,
                        message: "Small icon +\(icon ?? "[invalid icon]")+ must be a valid media native resource type.",
                        detailedCode: ExceptionCode.DETAILED_INVALID_ARGUMENTS+".smallIcon.invalid")
        }
    }
    
    private func validateBigPicture() throws {
        if(bigPicture != nil && !BitmapUtils.shared.isValidBitmap(bigPicture)){
            throw ExceptionFactory
                    .shared
                    .createNewAwesomeException(
                        className: NotificationContentModel.TAG,
                        code: ExceptionCode.CODE_INVALID_ARGUMENTS,
                        message: "bigPicture is invalid",
                        detailedCode: ExceptionCode.DETAILED_INVALID_ARGUMENTS+".invalid.bigPicture")
        }
    }
    
    private func validateLargeIcon() throws {
        if(largeIcon != nil && !BitmapUtils.shared.isValidBitmap(largeIcon)){
            throw ExceptionFactory
                    .shared
                    .createNewAwesomeException(
                        className: NotificationContentModel.TAG,
                        code: ExceptionCode.CODE_INVALID_ARGUMENTS,
                        message: "largeIcon is invalid",
                        detailedCode: ExceptionCode.DETAILED_INVALID_ARGUMENTS+".invalid.largeIcon")
        }
    }
}
