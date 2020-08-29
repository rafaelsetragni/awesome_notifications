//
//  NotificationContentModel.swift
//  awesome_notifications
//
//  Created by Rafael Setragni on 28/08/20.
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
    var color: UIColor?
    var backgroundColor: UIColor?
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
    
    func fromMap(arguments: [String : Any?]?) -> AbstractModel {
                
        self.id             = MapUtils.getValueOrDefault(type: Int.self , reference: "id", arguments: arguments)
        self.channelKey     = MapUtils.getValueOrDefault(type: String.self , reference: "channelKey", arguments: arguments)
        self.title          = MapUtils.getValueOrDefault(type: String.self , reference: "title", arguments: arguments)
        self.body           = MapUtils.getValueOrDefault(type: String.self , reference: "body", arguments: arguments)
        self.summary        = MapUtils.getValueOrDefault(type: String.self , reference: "summary", arguments: arguments)
        self.showWhen       = MapUtils.getValueOrDefault(type: Bool.self , reference: "showWhen", arguments: arguments)
        
        self.playSound             = MapUtils.getValueOrDefault(type: Bool.self , reference: "playSound", arguments: arguments)
        self.customSound           = MapUtils.getValueOrDefault(type: String.self , reference: "customSound", arguments: arguments)
        self.largeIcon             = MapUtils.getValueOrDefault(type: String.self , reference: "largeIcon", arguments: arguments)
        self.locked                = MapUtils.getValueOrDefault(type: Bool.self , reference: "locked", arguments: arguments)
        self.bigPicture            = MapUtils.getValueOrDefault(type: String.self , reference: "bigPicture", arguments: arguments)
        self.hideLargeIconOnExpand = MapUtils.getValueOrDefault(type: Bool.self , reference: "hideLargeIconOnExpand", arguments: arguments)
        self.autoCancel            = MapUtils.getValueOrDefault(type: Bool.self , reference: "autoCancel", arguments: arguments)
        self.color                 = MapUtils.getValueOrDefault(type: UIColor.self , reference: "color", arguments: arguments)
        self.backgroundColor       = MapUtils.getValueOrDefault(type: UIColor.self , reference: "backgroundColor", arguments: arguments)
        self.progress              = MapUtils.getValueOrDefault(type: Int.self , reference: "progress", arguments: arguments)
        self.ticker                = MapUtils.getValueOrDefault(type: String.self , reference: "ticker", arguments: arguments)

        self.privacy            = MapUtils.getEnumOrDefault(type: NotificationPrivacy.self, reference: "privacy", arguments: arguments)
        self.privateMessage     = MapUtils.getValueOrDefault(type: String.self , reference: "privateMessage", arguments: arguments)
        
        self.notificationLayout = MapUtils.getEnumOrDefault(type: NotificationLayout.self, reference: "notificationLayout", arguments: arguments)
        
        self.createdSource      = MapUtils.getEnumOrDefault(type: NotificationSource.self, reference: "createdSource", arguments: arguments)
        self.createdLifeCycle   = MapUtils.getEnumOrDefault(type: NotificationLifeCycle.self, reference: "createdLifeCycle", arguments: arguments)
        self.displayedLifeCycle = MapUtils.getEnumOrDefault(type: NotificationLifeCycle.self, reference: "displayedLifeCycle", arguments: arguments)
        self.createdDate        = MapUtils.getValueOrDefault(type: String.self , reference: "createdDate", arguments: arguments)
        self.displayedDate      = MapUtils.getValueOrDefault(type: String.self , reference: "displayedDate", arguments: arguments)
        
        self.payload  = MapUtils.getValueOrDefault(type: [String:String?].self, reference: "payload", arguments: arguments)
        
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
    
    func toMap() -> [String : Any?] {
        var mapData:[String: Any?] = [:]
        
        if(id != nil) {mapData["id"] = self.id}
        if(channelKey != nil) {mapData["channelKey"] = self.channelKey}
        
        return mapData
    }
    
    func validate() throws {

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
