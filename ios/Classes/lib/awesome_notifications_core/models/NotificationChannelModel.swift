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

    var icon: String?
    var defaultColor: Int?
    
    var locked: Bool?
    var onlyAlertOnce: Bool?

    var criticalAlerts: Bool?

    var defaultPrivacy: NotificationPrivacy?
    
    public func fromMap(arguments: [String : Any?]?) -> AbstractModel? {
        
        self.channelKey         = MapUtils<String>.getValueOrDefault(reference: Definitions.NOTIFICATION_CHANNEL_KEY, arguments: arguments)
        self.channelName        = MapUtils<String>.getValueOrDefault(reference: Definitions.NOTIFICATION_CHANNEL_NAME, arguments: arguments)
        self.channelDescription = MapUtils<String>.getValueOrDefault(reference: Definitions.NOTIFICATION_CHANNEL_DESCRIPTION, arguments: arguments)
        self.channelShowBadge   = MapUtils<Bool>.getValueOrDefault(reference: Definitions.NOTIFICATION_CHANNEL_SHOW_BADGE, arguments: arguments)
        
        self.playSound          = MapUtils<Bool>.getValueOrDefault(reference: Definitions.NOTIFICATION_PLAY_SOUND, arguments: arguments)
        self.soundSource        = MapUtils<String>.getValueOrDefault(reference: Definitions.NOTIFICATION_SOUND_SOURCE, arguments: arguments)
        
        self.enableVibration    = MapUtils<Bool>.getValueOrDefault(reference: Definitions.NOTIFICATION_ENABLE_VIBRATION, arguments: arguments)
        self.vibrationPattern   = MapUtils<[Int]>.getValueOrDefault(reference: Definitions.NOTIFICATION_VIBRATION_PATTERN, arguments: arguments)
        
        self.enableLights       = MapUtils<Bool>.getValueOrDefault(reference: Definitions.NOTIFICATION_ENABLE_LIGHTS, arguments: arguments)
        self.ledColor           = MapUtils<Int>.getValueOrDefault(reference: Definitions.NOTIFICATION_LED_COLOR, arguments: arguments)
        self.ledOnMs            = MapUtils<Int>.getValueOrDefault(reference: Definitions.NOTIFICATION_LED_ON_MS, arguments: arguments)
        self.ledOffMs           = MapUtils<Int>.getValueOrDefault(reference: Definitions.NOTIFICATION_LED_OFF_MS, arguments: arguments)
        
        self.icon               = MapUtils<String>.getValueOrDefault(reference: Definitions.NOTIFICATION_ICON, arguments: arguments)
        self.defaultColor       = MapUtils<Int>.getValueOrDefault(reference: Definitions.NOTIFICATION_DEFAULT_COLOR, arguments: arguments)
        
        self.importance         = EnumUtils<NotificationImportance>.getEnumOrDefault(reference: Definitions.NOTIFICATION_IMPORTANCE, arguments: arguments)
        
        self.groupSort          = EnumUtils<GroupSort>.getEnumOrDefault(reference: Definitions.NOTIFICATION_GROUP_SORT, arguments: arguments)
        self.groupKey           = MapUtils<String>.getValueOrDefault(reference: Definitions.NOTIFICATION_GROUP_KEY, arguments: arguments)
        
        self.locked             = MapUtils<Bool>.getValueOrDefault(reference: Definitions.NOTIFICATION_LOCKED, arguments: arguments)
        self.onlyAlertOnce      = MapUtils<Bool>.getValueOrDefault(reference: Definitions.NOTIFICATION_ONLY_ALERT_ONCE, arguments: arguments)

        self.criticalAlerts     = MapUtils<Bool>.getValueOrDefault(reference: Definitions.NOTIFICATION_CHANNEL_CRITICAL_ALERTS, arguments: arguments)

        self.defaultPrivacy     = EnumUtils<NotificationPrivacy>.getEnumOrDefault(reference: Definitions.NOTIFICATION_DEFAULT_PRIVACY, arguments: arguments)

        self.groupAlertBehavior = EnumUtils<GroupAlertBehaviour>.getEnumOrDefault(reference: Definitions.NOTIFICATION_GROUP_ALERT_BEHAVIOR, arguments: arguments)
        
        self.defaultRingtoneType = EnumUtils<DefaultRingtoneType>.getEnumOrDefault(reference: Definitions.NOTIFICATION_DEFAULT_RINGTONE_TYPE, arguments: arguments)
        
        return self
    }
    
    public func toMap() -> [String : Any?] {
        var mapData:[String: Any?] = [:]
        
        if(channelKey != nil) {mapData[Definitions.NOTIFICATION_CHANNEL_KEY] = self.channelKey}
        if(channelName != nil) {mapData[Definitions.NOTIFICATION_CHANNEL_NAME] = self.channelName}
        if(channelDescription != nil) {mapData[Definitions.NOTIFICATION_CHANNEL_DESCRIPTION] = self.channelDescription}
        if(channelShowBadge != nil) {mapData[Definitions.NOTIFICATION_CHANNEL_SHOW_BADGE] = self.channelShowBadge}
        
        if(importance != nil) {mapData[Definitions.NOTIFICATION_IMPORTANCE] = self.importance?.rawValue}
        
        if(playSound != nil) {mapData[Definitions.NOTIFICATION_PLAY_SOUND] = self.playSound}
        if(soundSource != nil) {mapData[Definitions.NOTIFICATION_SOUND_SOURCE] = self.soundSource}
        
        if(enableVibration != nil) {mapData[Definitions.NOTIFICATION_ENABLE_VIBRATION] = self.enableVibration}
        if(vibrationPattern != nil) {mapData[Definitions.NOTIFICATION_VIBRATION_PATTERN] = self.vibrationPattern}
        
        if(enableLights != nil) {mapData[Definitions.NOTIFICATION_ENABLE_LIGHTS] = self.enableLights}
        if(ledColor != nil) {mapData[Definitions.NOTIFICATION_LED_COLOR] = self.ledColor}
        if(ledOnMs != nil) {mapData[Definitions.NOTIFICATION_LED_ON_MS] = self.ledOnMs}
        if(ledOffMs != nil) {mapData[Definitions.NOTIFICATION_LED_OFF_MS] = self.ledOffMs}
        
        if(groupKey != nil) {mapData[Definitions.NOTIFICATION_GROUP_KEY] = self.groupKey}
        if(groupSort != nil) {mapData[Definitions.NOTIFICATION_GROUP_SORT] = self.groupSort?.rawValue}

        if(icon != nil) {mapData[Definitions.NOTIFICATION_ICON] = self.icon}
        if(defaultColor != nil) {mapData[Definitions.NOTIFICATION_DEFAULT_COLOR] = self.defaultColor}
        
        if(locked != nil) {mapData[Definitions.NOTIFICATION_LOCKED] = self.locked}
        if(onlyAlertOnce != nil) {mapData[Definitions.NOTIFICATION_ONLY_ALERT_ONCE] = self.onlyAlertOnce}
        
        if(criticalAlerts != nil) {mapData[Definitions.NOTIFICATION_CHANNEL_CRITICAL_ALERTS] = self.locked}

        if(defaultPrivacy != nil) {mapData[Definitions.NOTIFICATION_DEFAULT_PRIVACY] = self.defaultPrivacy?.rawValue}
        
        if(groupAlertBehavior != nil) {mapData[Definitions.NOTIFICATION_GROUP_ALERT_BEHAVIOR] = self.groupAlertBehavior?.rawValue}
        
        if(defaultRingtoneType != nil) {mapData[Definitions.NOTIFICATION_DEFAULT_RINGTONE_TYPE] = self.defaultRingtoneType?.rawValue}
        
        return mapData
    }
    
    public func validate() throws {
        
        if(StringUtils.isNullOrEmpty(channelKey)){
            throw AwesomeNotificationsException.invalidRequiredFields(
                msg: "channelKey cannot be null or empty")
        }

        if(StringUtils.isNullOrEmpty(channelName)){
            throw AwesomeNotificationsException.invalidRequiredFields(
                msg: "channelName cannot be null or empty")
        }

        if(StringUtils.isNullOrEmpty(channelDescription)){
            throw AwesomeNotificationsException.invalidRequiredFields(
                msg: "channelDescription cannot be null or empty")
        }
        
        if(
            BooleanUtils.getValue(value: playSound, defaultValue: false) &&
            !StringUtils.isNullOrEmpty(soundSource)
        ){
            if #available(iOS 10.0, *) {
                if(!AudioUtils.isValidSound(soundSource)){
                    throw AwesomeNotificationsException.invalidRequiredFields(msg: "Audio media is not valid")
                }
            } else {
                // Fallback on earlier versions
            }
        }
    }
}
