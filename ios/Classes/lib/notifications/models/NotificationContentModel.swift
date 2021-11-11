//
//  NotificationContentModel.swift
//  awesome_notifications
//
//  Created by Rafael Setragni on 05/09/20.
//

import Foundation

public class NotificationContentModel : AbstractModel {

    var id: Int?
    var channelKey: String?
    var groupKey: String?
    var title: String?
    var body: String?
    var summary: String?
    var showWhen: Bool?
    
    var actionButtons:[NotificationButtonModel]?
    var payload:[String:String?]?
    
    var wakeUpScreen: Bool?
    var playSound: Bool?
    var customSound: String?
    var locked: Bool?
    var icon: String?
    var largeIcon: String?
    var bigPicture: String?
    var hideLargeIconOnExpand: Bool?
    var autoDismissible: Bool?
    var displayOnForeground: Bool?
    var displayOnBackground: Bool?
    var color: Int64?
    var backgroundColor: Int64?
    var progress: Int?
    var ticker: String?

    var privacy: NotificationPrivacy?
    var privateMessage: String?

    var notificationLayout: NotificationLayout?

    var createdSource: NotificationSource?
    var createdLifeCycle: NotificationLifeCycle?
    var displayedLifeCycle: NotificationLifeCycle?
    var createdDate: String?
    var displayedDate: String?
    
    public func fromMap(arguments: [String : Any?]?) -> AbstractModel? {
                
        self.id = MapUtils<Int>.getValueOrDefault(reference: Definitions.NOTIFICATION_ID, arguments: arguments)
        if((id ?? -1) < 0) {
            id = IntUtils.generateNextRandomId();
        }
        
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

        self.privacy            = EnumUtils<NotificationPrivacy>.getEnumOrDefault(reference: Definitions.NOTIFICATION_PRIVACY, arguments: arguments)
        self.privateMessage     = MapUtils<String>.getValueOrDefault(reference: Definitions.NOTIFICATION_PRIVATE_MESSAGE, arguments: arguments)
        
        self.notificationLayout = EnumUtils<NotificationLayout>.getEnumOrDefault(reference: Definitions.NOTIFICATION_LAYOUT, arguments: arguments)
        
        self.createdSource      = EnumUtils<NotificationSource>.getEnumOrDefault(reference: Definitions.NOTIFICATION_CREATED_SOURCE, arguments: arguments)
        self.createdLifeCycle   = EnumUtils<NotificationLifeCycle>.getEnumOrDefault(reference: Definitions.NOTIFICATION_CREATED_LIFECYCLE, arguments: arguments)
        self.displayedLifeCycle = EnumUtils<NotificationLifeCycle>.getEnumOrDefault(reference: Definitions.NOTIFICATION_DISPLAYED_LIFECYCLE, arguments: arguments)
        self.createdDate        = MapUtils<String>.getValueOrDefault(reference: Definitions.NOTIFICATION_CREATED_DATE, arguments: arguments)
        self.displayedDate      = MapUtils<String>.getValueOrDefault(reference: Definitions.NOTIFICATION_DISPLAYED_DATE, arguments: arguments)
        
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
        if(self.createdDate != nil){ mapData[Definitions.NOTIFICATION_CREATED_DATE] = self.createdDate }
        if(self.displayedDate != nil){ mapData[Definitions.NOTIFICATION_DISPLAYED_DATE] = self.displayedDate }
        if(self.payload != nil){ mapData[Definitions.NOTIFICATION_PAYLOAD] = self.payload }

        return mapData
    }
    
    public func validate() throws {

        if(IntUtils.isNullOrEmpty(id)){
            throw AwesomeNotificationsException.invalidRequiredFields(
                msg: "id cannot be null or empty")
        }
        
        if(StringUtils.isNullOrEmpty(channelKey)){
            throw AwesomeNotificationsException.invalidRequiredFields(
                msg: "channelKey cannot be null or empty")
        }

        if(!StringUtils.isNullOrEmpty(icon)){
            if(
                BitmapUtils.getMediaSourceType(mediaPath: icon) != MediaSource.Resource
            ){
                let iconError = icon ?? "[invalid icon]"
                throw AwesomeNotificationsException.invalidRequiredFields(
                    msg: "Small icon +\(iconError)+ must be a valid media native resource type.")
            }
        }
        
        if(notificationLayout == nil){
            throw AwesomeNotificationsException.invalidRequiredFields(
                msg: "notificationLayout cannot be null or empty")
        }
        
        switch notificationLayout {
            
            case .Default:
                break
                
            case .BigPicture:
            
                if(bigPicture == nil && largeIcon == nil){
                    throw AwesomeNotificationsException.invalidRequiredFields(
                        msg: "bigPicture or largeIcon needs to be not empty")
                }
                try validateBigPicture()
                try validateLargeIcon()
                break
                
            case .BigText:
                break
                
            case .ProgressBar:
                break
            
            case .MediaPlayer:
                break
                    
            case .Inbox:
                break
                
            case .Messaging:
                break
                
            default:
                notificationLayout = NotificationLayout.Default
                break
        }
    }
    
    private func validateBigPicture() throws {
        if(bigPicture != nil && !BitmapUtils.isValidBitmap(bigPicture)){
            throw AwesomeNotificationsException.invalidRequiredFields(msg: "invalid bigPicture")
        }
    }
    
    private func validateLargeIcon() throws {
        if(largeIcon != nil && !BitmapUtils.isValidBitmap(largeIcon)){
            throw AwesomeNotificationsException.invalidRequiredFields(msg: "invalid largeIcon")
        }
    }
}
