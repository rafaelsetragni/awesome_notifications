//
//  NotificationChannelModel.swift
//  awesome_notifications
//
//  Created by Rafael Setragni on 28/08/20.
//

import Foundation

class NotificationChannelModel : AbstractModel {
    
    var channelKey: String?
    var channelName: String?
    var channelDescription: String?
    var channelShowBadge: Bool?

    var importance: NotificationImportance?

    var playSound: Bool?
    var soundSource: String?

    var enableVibration: Bool?
    
    // TODO missing implementation
    // public long[] vibrationPattern;

    var enableLights: Bool?
    var ledColor: Int?
    var ledOnMs: Int?
    var ledOffMs: Int?

    var groupKey: String?
    var setAsGroupSummary: Bool?
    var groupAlertBehavior: GroupAlertBehaviour?
    
    func fromMap(arguments: [String : AnyObject?]) -> AbstractModel {
        
        self.channelKey         = MapUtils.getValueOrDefault(type: String.self , reference: "channelKey", arguments: arguments)
        self.channelName        = MapUtils.getValueOrDefault(type: String.self , reference: "channelName", arguments: arguments)
        self.channelDescription = MapUtils.getValueOrDefault(type: String.self , reference: "channelDescription", arguments: arguments)
        self.channelShowBadge   = MapUtils.getValueOrDefault(type: Bool.self , reference: "channelShowBadge", arguments: arguments)
        
        self.importance         = MapUtils.getEnumOrDefault(type: NotificationImportance.self, reference: "importance", arguments: arguments)
        
        self.playSound          = MapUtils.getValueOrDefault(type: Bool.self , reference: "playSound", arguments: arguments)
        self.soundSource        = MapUtils.getValueOrDefault(type: String.self , reference: "soundSource", arguments: arguments)
        
        self.enableVibration    = MapUtils.getValueOrDefault(type: Bool.self , reference: "enableVibration", arguments: arguments)
        
        self.enableLights       = MapUtils.getValueOrDefault(type: Bool.self , reference: "enableLights", arguments: arguments)
        self.ledColor           = MapUtils.getValueOrDefault(type: Int.self , reference: "ledColor", arguments: arguments)
        self.ledOnMs            = MapUtils.getValueOrDefault(type: Int.self , reference: "ledOnMs", arguments: arguments)
        self.ledOffMs           = MapUtils.getValueOrDefault(type: Int.self , reference: "ledOffMs", arguments: arguments)
        
        self.groupKey           = MapUtils.getValueOrDefault(type: String.self , reference: "groupKey", arguments: arguments)
        self.setAsGroupSummary  = MapUtils.getValueOrDefault(type: Bool.self , reference: "setAsGroupSummary", arguments: arguments)
        
        self.groupAlertBehavior = MapUtils.getEnumOrDefault(type: GroupAlertBehaviour.self, reference: "groupAlertBehavior", arguments: arguments)
        
        return self
    }
    
    func toMap() -> [String : AnyObject?] {
        var mapData:[String: AnyObject?] = [:]
        
        if(channelKey != nil) {mapData["channelKey"] = self.channelKey as AnyObject?}
        if(channelName != nil) {mapData["channelName"] = self.channelName as AnyObject?}
        if(channelDescription != nil) {mapData["channelDescription"] = self.channelDescription as AnyObject?}
        if(channelShowBadge != nil) {mapData["channelShowBadge"] = self.channelShowBadge as AnyObject?}
        
        if(importance != nil) {mapData["importance"] = self.importance as AnyObject?}
        
        if(playSound != nil) {mapData["playSound"] = self.playSound as AnyObject?}
        if(soundSource != nil) {mapData["soundSource"] = self.soundSource as AnyObject?}
        
        if(enableVibration != nil) {mapData["enableVibration"] = self.enableVibration as AnyObject?}
        
        if(enableLights != nil) {mapData["enableLights"] = self.enableLights as AnyObject?}
        if(ledColor != nil) {mapData["ledColor"] = self.ledColor as AnyObject?}
        if(ledOnMs != nil) {mapData["ledOnMs"] = self.ledOnMs as AnyObject?}
        if(ledOffMs != nil) {mapData["ledOffMs"] = self.ledOffMs as AnyObject?}
        
        if(groupKey != nil) {mapData["groupKey"] = self.groupKey as AnyObject?}
        if(setAsGroupSummary != nil) {mapData["setAsGroupSummary"] = self.setAsGroupSummary as AnyObject?}
        
        if(groupAlertBehavior != nil) {mapData["groupAlertBehavior"] = self.groupAlertBehavior as AnyObject?}
        
        return mapData
    }
    
    func validate() throws {
        
        if(StringUtils.isNullOrEmpty(value: channelKey)){
            throw PushNotificationError.invalidRequiredFields(
                msg: "channelKey cannot be null or empty")
        }

        if(StringUtils.isNullOrEmpty(value: channelName)){
            throw PushNotificationError.invalidRequiredFields(
                msg: "channelName cannot be null or empty")
        }

        if(StringUtils.isNullOrEmpty(value: channelDescription)){
            throw PushNotificationError.invalidRequiredFields(
                msg: "channelDescription cannot be null or empty")
        }
        
        if(BooleanUtils.getValue(value: playSound as AnyObject?, defaultValue: false) &&
            !StringUtils.isNullOrEmpty(value: soundSource)){
            if(!AudioUtils.isValidAudio(audioPath: soundSource)){
                throw PushNotificationError.invalidRequiredFields(msg: "Audio media is not valid")
            }
        }
    }
}
