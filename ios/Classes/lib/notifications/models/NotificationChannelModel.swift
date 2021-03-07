//
//  NotificationChannelModel.swift
//  awesome_notifications
//
//  Created by Rafael Setragni on 05/09/20.
//

import Foundation

public class NotificationChannelModel : AbstractModel {
    
    var channelKey: String?
    var channelName: String?
    var channelDescription: String?
    var channelShowBadge: Bool?

    var importance: NotificationImportance?

    var playSound: Bool?
    var soundSource: String?
    var defaultRingtoneType: DefaultRingtoneType?

    var enableVibration: Bool?
    
    var vibrationPattern:[Int]?

    var enableLights: Bool?
    var ledColor: Int?
    var ledOnMs: Int?
    var ledOffMs: Int?

    var groupKey: String?
    var groupSort: GroupSort?
    var groupAlertBehavior: GroupAlertBehaviour?
    
    var locked: Bool?
    var onlyAlertOnce: Bool?
    
    public func fromMap(arguments: [String : Any?]?) -> AbstractModel? {
        
        self.channelKey         = MapUtils<String>.getValueOrDefault(reference: "channelKey", arguments: arguments)
        self.channelName        = MapUtils<String>.getValueOrDefault(reference: "channelName", arguments: arguments)
        self.channelDescription = MapUtils<String>.getValueOrDefault(reference: "channelDescription", arguments: arguments)
        self.channelShowBadge   = MapUtils<Bool>.getValueOrDefault(reference: "channelShowBadge", arguments: arguments)
        
        self.importance         = EnumUtils<NotificationImportance>.getEnumOrDefault(reference: "importance", arguments: arguments)
        
        self.playSound          = MapUtils<Bool>.getValueOrDefault(reference: "playSound", arguments: arguments)
        self.soundSource        = MapUtils<String>.getValueOrDefault(reference: "soundSource", arguments: arguments)
        
        self.enableVibration    = MapUtils<Bool>.getValueOrDefault(reference: "enableVibration", arguments: arguments)
        
        self.enableLights       = MapUtils<Bool>.getValueOrDefault(reference: "enableLights", arguments: arguments)
        self.ledColor           = MapUtils<Int>.getValueOrDefault(reference: "ledColor", arguments: arguments)
        self.ledOnMs            = MapUtils<Int>.getValueOrDefault(reference: "ledOnMs", arguments: arguments)
        self.ledOffMs           = MapUtils<Int>.getValueOrDefault(reference: "ledOffMs", arguments: arguments)
        
        self.groupKey           = MapUtils<String>.getValueOrDefault(reference: "groupKey", arguments: arguments)
        self.groupSort          = EnumUtils<GroupSort>.getEnumOrDefault(reference: "groupSort", arguments: arguments)
        
        self.locked         = MapUtils<Bool>.getValueOrDefault(reference: "locked", arguments: arguments)
        self.onlyAlertOnce  = MapUtils<Bool>.getValueOrDefault(reference: "onlyAlertOnce", arguments: arguments)
        
        self.groupAlertBehavior = EnumUtils<GroupAlertBehaviour>.getEnumOrDefault(reference: "groupAlertBehavior", arguments: arguments)
        
        self.defaultRingtoneType = EnumUtils<DefaultRingtoneType>.getEnumOrDefault(reference: "defaultRingtoneType", arguments: arguments)
        
        return self
    }
    
    public func toMap() -> [String : Any?] {
        var mapData:[String: Any?] = [:]
        
        if(channelKey != nil) {mapData["channelKey"] = self.channelKey}
        if(channelName != nil) {mapData["channelName"] = self.channelName}
        if(channelDescription != nil) {mapData["channelDescription"] = self.channelDescription}
        if(channelShowBadge != nil) {mapData["channelShowBadge"] = self.channelShowBadge}
        
        if(importance != nil) {mapData["importance"] = self.importance?.rawValue}
        
        if(playSound != nil) {mapData["playSound"] = self.playSound}
        if(soundSource != nil) {mapData["soundSource"] = self.soundSource}
        
        if(enableVibration != nil) {mapData["enableVibration"] = self.enableVibration}
        
        if(enableLights != nil) {mapData["enableLights"] = self.enableLights}
        if(ledColor != nil) {mapData["ledColor"] = self.ledColor}
        if(ledOnMs != nil) {mapData["ledOnMs"] = self.ledOnMs}
        if(ledOffMs != nil) {mapData["ledOffMs"] = self.ledOffMs}
        
        if(groupKey != nil) {mapData["groupKey"] = self.groupKey}
        if(groupSort != nil) {mapData["groupSort"] = self.groupSort?.rawValue}
        
        if(locked != nil) {mapData["locked"] = self.locked}
        if(onlyAlertOnce != nil) {mapData["onlyAlertOnce"] = self.onlyAlertOnce}
        
        if(groupAlertBehavior != nil) {mapData["groupAlertBehavior"] = self.groupAlertBehavior?.rawValue}
        
        if(defaultRingtoneType != nil) {mapData["defaultRingtoneType"] = self.defaultRingtoneType?.rawValue}
        
        return mapData
    }
    
    public func validate() throws {
        
        if(StringUtils.isNullOrEmpty(channelKey)){
            throw PushNotificationError.invalidRequiredFields(
                msg: "channelKey cannot be null or empty")
        }

        if(StringUtils.isNullOrEmpty(channelName)){
            throw PushNotificationError.invalidRequiredFields(
                msg: "channelName cannot be null or empty")
        }

        if(StringUtils.isNullOrEmpty(channelDescription)){
            throw PushNotificationError.invalidRequiredFields(
                msg: "channelDescription cannot be null or empty")
        }
        
        if(
            BooleanUtils.getValue(value: playSound, defaultValue: false) &&
            !StringUtils.isNullOrEmpty(soundSource)
        ){
            if #available(iOS 10.0, *) {
                if(!AudioUtils.isValidSound(soundSource)){
                    throw PushNotificationError.invalidRequiredFields(msg: "Audio media is not valid")
                }
            } else {
                // Fallback on earlier versions
            }
        }
    }
}
