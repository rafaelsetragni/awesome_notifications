//
//  ActionReceived.swift
//  awesome_notifications
//
//  Created by Rafael Setragni on 05/09/20.
//

import Foundation

public class ActionReceived : NotificationReceived {
    
    public var buttonKeyPressed: String?
    public var buttonKeyInput: String?

    public var actionLifeCycle: NotificationLifeCycle?
    public var dismissedLifeCycle: NotificationLifeCycle?
    public var actionDate: RealDateTime?
    public var dismissedDate: RealDateTime?
    
    override init(_ contentModel:NotificationContentModel?){
        super.init(contentModel)
        
        if(contentModel == nil){ return }
    }
    
    convenience init(
        _ contentModel:NotificationContentModel?,
        buttonKeyPressed: String?,
        buttonKeyInput: String?
    ){
        self.init(contentModel)
        if(contentModel == nil){ return }
        
        self.buttonKeyPressed = buttonKeyPressed
        self.buttonKeyInput = buttonKeyInput
    }
    
    override public func fromMap(arguments: [String : Any?]?) -> AbstractModel {
        _ = super.fromMap(arguments: arguments)
        
        self.buttonKeyPressed = MapUtils<String>.getValueOrDefault(reference: Definitions.NOTIFICATION_BUTTON_KEY_PRESSED, arguments: arguments)
        self.buttonKeyInput   = MapUtils<String>.getValueOrDefault(reference: Definitions.NOTIFICATION_BUTTON_KEY_INPUT, arguments: arguments)
        
        self.actionDate       = MapUtils<RealDateTime>.getRealDateOrDefault(reference: Definitions.NOTIFICATION_ACTION_DATE, arguments: arguments, defaultTimeZone: RealDateTime.utcTimeZone)
        self.dismissedDate    = MapUtils<RealDateTime>.getRealDateOrDefault(reference: Definitions.NOTIFICATION_DISMISSED_DATE, arguments: arguments, defaultTimeZone: RealDateTime.utcTimeZone)
        
        self.actionLifeCycle  = EnumUtils<NotificationLifeCycle>.getEnumOrDefault(reference: Definitions.NOTIFICATION_ACTION_LIFECYCLE, arguments: arguments)
        self.dismissedLifeCycle = EnumUtils<NotificationLifeCycle>.getEnumOrDefault(reference: Definitions.NOTIFICATION_DISMISSED_LIFECYCLE, arguments: arguments)
        
        return self
    }
    
    override public func toMap() -> [String : Any?] {
        var dataMap:[String : Any?] = super.toMap()
                
        if(buttonKeyPressed != nil) {dataMap[Definitions.NOTIFICATION_BUTTON_KEY_PRESSED] = self.buttonKeyPressed}
        if(buttonKeyInput != nil) {dataMap[Definitions.NOTIFICATION_BUTTON_KEY_INPUT] = self.buttonKeyInput}
        
        if(actionLifeCycle != nil) {dataMap[Definitions.NOTIFICATION_ACTION_LIFECYCLE] = self.actionLifeCycle?.rawValue}
        if(dismissedLifeCycle != nil) {dataMap[Definitions.NOTIFICATION_DISMISSED_LIFECYCLE] = self.dismissedLifeCycle?.rawValue}
        if(actionDate != nil) {dataMap[Definitions.NOTIFICATION_ACTION_DATE] = self.actionDate!.description}
        if(dismissedDate != nil) {dataMap[Definitions.NOTIFICATION_DISMISSED_DATE] = self.dismissedDate!.description}
        
        return dataMap
    }
    
    override public func validate() throws {
        
    }
    
    public func registerActionEvent(withLifeCycle lifeCycle: NotificationLifeCycle){
        actionDate = RealDateTime.init(fromTimeZone: RealDateTime.utcTimeZone)
        actionLifeCycle = lifeCycle
    }
    
    public func registerDismissedEvent(withLifeCycle lifeCycle: NotificationLifeCycle){
        dismissedDate = RealDateTime.init(fromTimeZone: RealDateTime.utcTimeZone)
        dismissedLifeCycle = lifeCycle
    }
    
}
