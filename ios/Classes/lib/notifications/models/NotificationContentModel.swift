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
    var title: String?
    var body: String?
    var summary: String?
    var showWhen: Bool?
    
    var actionButtons:[NotificationButtonModel]?
    var payload:[String:String?]?
    
    var playSound: Bool?
    var customSound: String?
    var largeIcon: String?
    var locked: Bool?
    var bigPicture: String?
    var hideLargeIconOnExpand: Bool?
    var autoCancel: Bool?
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
                
        self.id             = MapUtils<Int>.getValueOrDefault(reference: "id", arguments: arguments)
        self.channelKey     = MapUtils<String>.getValueOrDefault(reference: "channelKey", arguments: arguments)
        self.title          = MapUtils<String>.getValueOrDefault(reference: "title", arguments: arguments)
        self.body           = MapUtils<String>.getValueOrDefault(reference: "body", arguments: arguments)
        self.summary        = MapUtils<String>.getValueOrDefault(reference: "summary", arguments: arguments)
        self.showWhen       = MapUtils<Bool>.getValueOrDefault(reference: "showWhen", arguments: arguments)
        
        self.playSound             = MapUtils<Bool>.getValueOrDefault(reference: "playSound", arguments: arguments)
        self.customSound           = MapUtils<String>.getValueOrDefault(reference: "customSound", arguments: arguments)
        self.largeIcon             = MapUtils<String>.getValueOrDefault(reference: "largeIcon", arguments: arguments)
        self.locked                = MapUtils<Bool>.getValueOrDefault(reference: "locked", arguments: arguments)
        self.bigPicture            = MapUtils<String>.getValueOrDefault(reference: "bigPicture", arguments: arguments)
        self.hideLargeIconOnExpand = MapUtils<Bool>.getValueOrDefault(reference: "hideLargeIconOnExpand", arguments: arguments)
        self.autoCancel            = MapUtils<Bool>.getValueOrDefault(reference: "autoCancel", arguments: arguments)
        self.displayOnForeground   = MapUtils<Bool>.getValueOrDefault(reference: "displayOnForeground", arguments: arguments)
        self.displayOnBackground   = MapUtils<Bool>.getValueOrDefault(reference: "displayOnBackground", arguments: arguments) 
        self.color                 = MapUtils<Int64>.getValueOrDefault(reference: "color", arguments: arguments)
        self.backgroundColor       = MapUtils<Int64>.getValueOrDefault(reference: "backgroundColor", arguments: arguments)
        self.progress              = MapUtils<Int>.getValueOrDefault(reference: "progress", arguments: arguments)
        self.ticker                = MapUtils<String>.getValueOrDefault(reference: "ticker", arguments: arguments)

        self.privacy            = EnumUtils<NotificationPrivacy>.getEnumOrDefault(reference: "privacy", arguments: arguments)
        self.privateMessage     = MapUtils<String>.getValueOrDefault(reference: "privateMessage", arguments: arguments)
        
        self.notificationLayout = EnumUtils<NotificationLayout>.getEnumOrDefault(reference: "notificationLayout", arguments: arguments)
        
        self.createdSource      = EnumUtils<NotificationSource>.getEnumOrDefault(reference: "createdSource", arguments: arguments)
        self.createdLifeCycle   = EnumUtils<NotificationLifeCycle>.getEnumOrDefault(reference: "createdLifeCycle", arguments: arguments)
        self.displayedLifeCycle = EnumUtils<NotificationLifeCycle>.getEnumOrDefault(reference: "displayedLifeCycle", arguments: arguments)
        self.createdDate        = MapUtils<String>.getValueOrDefault(reference: "createdDate", arguments: arguments)
        self.displayedDate      = MapUtils<String>.getValueOrDefault(reference: "displayedDate", arguments: arguments)
        
        self.payload  = MapUtils<[String:String?]>.getValueOrDefault(reference: "payload", arguments: arguments)
        
        if(arguments?["actionButtons"] != nil){
            
            do {
                
                self.actionButtons = [NotificationButtonModel]()
                let listData = arguments?["actionButtons"] as? [Any] ?? []
                
                for data in listData {
                    
                    let buttonData:[String:Any?]? = data as? [String:Any?]
                    if(buttonData == nil){
                        throw PushNotificationError.invalidRequiredFields(msg: "actionButtons are invalid")
                    }
                    
                    self.actionButtons?.append(NotificationButtonModel().fromMap(arguments: buttonData) as! NotificationButtonModel)
                }
                
            } catch {
                self.actionButtons = nil
            }
            
            if(self.actionButtons?.isEmpty ?? true){
                self.actionButtons = nil
            }
        }
        
        return self
    }
    
    public func toMap() -> [String : Any?] {
        var mapData:[String: Any?] = [:]
        
        if(self.id != nil) {mapData["id"] = self.id}
        if(self.channelKey != nil) {mapData["channelKey"] = self.channelKey}
        if(self.title != nil){ mapData["title"] = self.title }
        if(self.body != nil){ mapData["body"] = self.body }
        if(self.summary != nil){ mapData["summary"] = self.summary }
        if(self.showWhen != nil){ mapData["showWhen"] = self.showWhen }
        if(self.playSound != nil){ mapData["playSound"] = self.playSound }
        if(self.customSound != nil){ mapData["customSound"] = self.customSound }
        if(self.largeIcon != nil){ mapData["largeIcon"] = self.largeIcon }
        if(self.locked != nil){ mapData["locked"] = self.locked }
        if(self.bigPicture != nil){ mapData["bigPicture"] = self.bigPicture }
        if(self.hideLargeIconOnExpand != nil){ mapData["hideLargeIconOnExpand"] = self.hideLargeIconOnExpand }
        if(self.autoCancel != nil){ mapData["autoCancel"] = self.autoCancel }
        if(self.displayOnForeground != nil){ mapData["displayOnForeground"] = self.displayOnForeground }
        if(self.displayOnBackground != nil){ mapData["displayOnBackground"] = self.displayOnBackground }
        if(self.color != nil){ mapData["color"] = self.color }
        if(self.backgroundColor != nil){ mapData["backgroundColor"] = self.backgroundColor }
        if(self.progress != nil){ mapData["progress"] = self.progress }
        if(self.ticker != nil){ mapData["ticker"] = self.ticker }
        if(self.privacy != nil){ mapData["privacy"] = self.privacy?.rawValue }
        if(self.privateMessage != nil){ mapData["privateMessage"] = self.privateMessage }
        if(self.notificationLayout != nil){ mapData["notificationLayout"] = self.notificationLayout?.rawValue }
        if(self.createdSource != nil){ mapData["createdSource"] = self.createdSource?.rawValue }
        if(self.createdLifeCycle != nil){ mapData["createdLifeCycle"] = self.createdLifeCycle?.rawValue }
        if(self.displayedLifeCycle != nil){ mapData["displayedLifeCycle"] = self.displayedLifeCycle?.rawValue }
        if(self.createdDate != nil){ mapData["createdDate"] = self.createdDate }
        if(self.displayedDate != nil){ mapData["displayedDate"] = self.displayedDate }
        if(self.payload != nil){ mapData["payload"] = self.payload }

        return mapData
    }
    
    public func validate() throws {

        if(IntUtils.isNullOrEmpty(id)){
            throw PushNotificationError.invalidRequiredFields(
                msg: "id cannot be null or empty")
        }
        
        if(StringUtils.isNullOrEmpty(channelKey)){
            throw PushNotificationError.invalidRequiredFields(
                msg: "channelKey cannot be null or empty")
        }
        
        if(notificationLayout == nil){
            throw PushNotificationError.invalidRequiredFields(
                msg: "notificationLayout cannot be null or empty")
        }
        
        switch notificationLayout {
            
            case .Default:
                break
                
            case .BigPicture:
            
                if(bigPicture == nil && largeIcon == nil){
                    throw PushNotificationError.invalidRequiredFields(
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
            throw PushNotificationError.invalidRequiredFields(msg: "invalid bigPicture")
        }
    }
    
    private func validateLargeIcon() throws {
        if(largeIcon != nil && !BitmapUtils.isValidBitmap(largeIcon)){
            throw PushNotificationError.invalidRequiredFields(msg: "invalid largeIcon")
        }
    }
}
