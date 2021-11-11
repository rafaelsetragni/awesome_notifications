//
//  NotificationButtonModel.swift
//  awesome_notifications
//
//  Created by Rafael Setragni on 05/09/20.
//

import Foundation

public class NotificationButtonModel : AbstractModel {
    
    var key:String?
    var icon:String?
    var label:String?
    var enabled:Bool?
    var color: Int64?
    var autoDismissible:Bool?
    var showInCompactView:Bool?
    var isDangerousOption:Bool?
    var buttonType:ActionButtonType?
    
    public func fromMap(arguments: [String : Any?]?) -> AbstractModel? {
        if(arguments == nil){ return self }
       
        self.key        = MapUtils<String>.getValueOrDefault(reference: Definitions.NOTIFICATION_BUTTON_KEY, arguments: arguments)
        self.icon       = MapUtils<String>.getValueOrDefault(reference: Definitions.NOTIFICATION_BUTTON_ICON, arguments: arguments)
        self.label      = MapUtils<String>.getValueOrDefault(reference: Definitions.NOTIFICATION_BUTTON_LABEL, arguments: arguments)
        self.color      = MapUtils<Int64>.getValueOrDefault(reference: Definitions.NOTIFICATION_COLOR, arguments: arguments)
        
        self.buttonType = EnumUtils<ActionButtonType>.getEnumOrDefault(reference: Definitions.NOTIFICATION_BUTTON_TYPE, arguments: arguments)
        
        self.enabled    = MapUtils<Bool>.getValueOrDefault(reference: Definitions.NOTIFICATION_ENABLED, arguments: arguments)
        self.autoDismissible = MapUtils<Bool>.getValueOrDefault(reference: Definitions.NOTIFICATION_AUTO_DISMISSIBLE, arguments: arguments)
        self.showInCompactView = MapUtils<Bool>.getValueOrDefault(reference: Definitions.NOTIFICATION_SHOW_IN_COMPACT_VIEW, arguments: arguments)
        self.isDangerousOption = MapUtils<Bool>.getValueOrDefault(reference: Definitions.NOTIFICATION_IS_DANGEROUS_OPTION, arguments: arguments)

        return self
    }
    
    public func toMap() -> [String : Any?] {
        var mapData:[String: Any?] = [:]
        
        if(key != nil) {mapData[Definitions.NOTIFICATION_BUTTON_KEY] = self.key}
        if(icon != nil) {mapData[Definitions.NOTIFICATION_BUTTON_ICON] = self.icon}
        if(label != nil) {mapData[Definitions.NOTIFICATION_BUTTON_LABEL] = self.label}
        if(color != nil){ mapData[Definitions.NOTIFICATION_COLOR] = self.color }
        
        if(buttonType != nil) {mapData[Definitions.NOTIFICATION_BUTTON_TYPE] = self.buttonType?.rawValue}

        if(enabled != nil) {mapData[Definitions.NOTIFICATION_ENABLED] = self.enabled}
        if(autoDismissible != nil) {mapData[Definitions.NOTIFICATION_AUTO_DISMISSIBLE] = self.autoDismissible}
        if(showInCompactView != nil) {mapData[Definitions.NOTIFICATION_SHOW_IN_COMPACT_VIEW] = self.showInCompactView}
        if(isDangerousOption != nil) {mapData[Definitions.NOTIFICATION_IS_DANGEROUS_OPTION] = self.isDangerousOption}
        
        return mapData
    }
    
    public func validate() throws {
        
        if(StringUtils.isNullOrEmpty(key)){
            throw AwesomeNotificationsException.invalidRequiredFields(
                msg: "Button action key cannot be null or empty")
        }

        if(StringUtils.isNullOrEmpty(label)){
            throw AwesomeNotificationsException.invalidRequiredFields(
                msg: "Button label cannot be null or empty")
        }
    }
}
