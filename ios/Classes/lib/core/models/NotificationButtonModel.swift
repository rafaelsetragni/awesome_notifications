//
//  NotificationButtonModel.swift
//  awesome_notifications
//
//  Created by Rafael Setragni on 05/09/20.
//

import Foundation

public class NotificationButtonModel : AbstractModel {
    
    public static let TAG = "NotificationButtonModel"
    
    var key:String?
    var icon:String?
    var label:String?
    var enabled:Bool?
    var color: Int64?
    var requireInputText:Bool?
    var autoDismissible:Bool?
    var showInCompactView:Bool?
    var isDangerousOption:Bool?
    var actionType:ActionType?
    
    public init(){}
    
    public func fromMap(arguments: [String : Any?]?) -> AbstractModel? {
        if(arguments == nil){ return self }
       
        _processRetroCompatibility(fromArguments: arguments)
        
        self.key        = MapUtils<String>.getValueOrDefault(reference: Definitions.NOTIFICATION_BUTTON_KEY, arguments: arguments)
        self.icon       = MapUtils<String>.getValueOrDefault(reference: Definitions.NOTIFICATION_BUTTON_ICON, arguments: arguments)
        self.label      = MapUtils<String>.getValueOrDefault(reference: Definitions.NOTIFICATION_BUTTON_LABEL, arguments: arguments)
        self.color      = MapUtils<Int64>.getValueOrDefault(reference: Definitions.NOTIFICATION_COLOR, arguments: arguments)
        
        self.actionType = EnumUtils<ActionType>.getEnumOrDefault(reference: Definitions.NOTIFICATION_ACTION_TYPE, arguments: arguments)
        
        self.enabled    = MapUtils<Bool>.getValueOrDefault(reference: Definitions.NOTIFICATION_ENABLED, arguments: arguments)
        self.autoDismissible   = MapUtils<Bool>.getValueOrDefault(reference: Definitions.NOTIFICATION_AUTO_DISMISSIBLE, arguments: arguments)
        self.requireInputText  = MapUtils<Bool>.getValueOrDefault(reference: Definitions.NOTIFICATION_REQUIRE_INPUT_TEXT, arguments: arguments)
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
        
        if(actionType != nil) {mapData[Definitions.NOTIFICATION_ACTION_TYPE] = self.actionType?.rawValue}

        if(enabled != nil) {mapData[Definitions.NOTIFICATION_ENABLED] = self.enabled}
        if(autoDismissible != nil) {mapData[Definitions.NOTIFICATION_AUTO_DISMISSIBLE] = self.autoDismissible}
        if(requireInputText != nil) {mapData[Definitions.NOTIFICATION_REQUIRE_INPUT_TEXT] = self.requireInputText}
        if(showInCompactView != nil) {mapData[Definitions.NOTIFICATION_SHOW_IN_COMPACT_VIEW] = self.showInCompactView}
        if(isDangerousOption != nil) {mapData[Definitions.NOTIFICATION_IS_DANGEROUS_OPTION] = self.isDangerousOption}
        
        return mapData
    }
    
    func _processRetroCompatibility(fromArguments arguments: [String : Any?]?){
        
        if arguments?["autoCancel"] != nil {
            Logger.w(NotificationButtonModel.TAG, "autoCancel is deprecated. Please use autoDismissible instead.")
            autoDismissible = MapUtils<Bool>.getValueOrDefault(reference: "autoCancel", arguments: arguments)
        }

        if arguments?["buttonType"] != nil {
            Logger.w(NotificationButtonModel.TAG, "buttonType is deprecated. Please use actionType instead.")            
            actionType = EnumUtils<ActionType>.getEnumOrDefault(reference: "buttonType", arguments: arguments)
        }
        
        _adaptInputFieldToRequireText()
    }
    
    func _adaptInputFieldToRequireText(){
        if actionType == ActionType.InputField {
            Logger.d(NotificationButtonModel.TAG,
                  "InputField is deprecated. Please use requireInputText instead.")
            requireInputText = true
            actionType = ActionType.SilentAction
        }
    }
    
    public func validate() throws {
        
        if(StringUtils.shared.isNullOrEmpty(key)){
            throw ExceptionFactory
                    .shared
                    .createNewAwesomeException(
                        className: NotificationButtonModel.TAG,
                        code: ExceptionCode.CODE_INVALID_ARGUMENTS,
                        message: "Button key is required",
                        detailedCode: ExceptionCode.DETAILED_INVALID_ARGUMENTS+".button.actionKey")
        }

        if(StringUtils.shared.isNullOrEmpty(label)){
            throw ExceptionFactory
                    .shared
                    .createNewAwesomeException(
                        className: NotificationButtonModel.TAG,
                        code: ExceptionCode.CODE_INVALID_ARGUMENTS,
                        message: "Button label is required",
                        detailedCode: ExceptionCode.DETAILED_INVALID_ARGUMENTS+".button.label")
        }
    }
}
