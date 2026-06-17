//
//  NotificationLocalization.swift
//  IosAwnCore
//
//  Created by Rafael Setragni on 19/02/23.
//

import Foundation

public class NotificationLocalizationModel : AbstractModel {
    
    private static let TAG = "NotificationLocalization"
    
    public var content:NotificationContentModel?
    public var actionButtons:[NotificationButtonModel]?
    public var schedule:NotificationScheduleModel?
    public var importance:NotificationImportance?
    
    var title:String?
    var body:String?
    var summary:String?
    var largeIcon:String?
    var bigPicture:String?
    var buttonLabels:[String:String]?
    
    public init(){}
    
    public func fromMap(arguments: [String : Any?]?) -> AbstractModel? {
        
        self.title      = MapUtils<String>.getValueOrDefault(reference: Definitions.NOTIFICATION_TITLE, arguments: arguments)
        self.body       = MapUtils<String>.getValueOrDefault(reference: Definitions.NOTIFICATION_BODY, arguments: arguments)
        self.summary    = MapUtils<String>.getValueOrDefault(reference: Definitions.NOTIFICATION_SUMMARY, arguments: arguments)
        self.largeIcon  = MapUtils<String>.getValueOrDefault(reference: Definitions.NOTIFICATION_LARGE_ICON, arguments: arguments)
        self.bigPicture = MapUtils<String>.getValueOrDefault(reference: Definitions.NOTIFICATION_BIG_PICTURE, arguments: arguments)
        self.buttonLabels = MapUtils<[String:String]>.getValueOrDefault(reference: Definitions.NOTIFICATION_BUTTON_LABELS, arguments: arguments)
        
        return self
    }
    
    public func toMap() -> [String : Any?] {
        var mapData:[String: Any?] = [:]
        
        if(title != nil) {mapData[Definitions.NOTIFICATION_TITLE] = title}
        if(body != nil) {mapData[Definitions.NOTIFICATION_BODY] = body}
        if(summary != nil) {mapData[Definitions.NOTIFICATION_SUMMARY] = summary}
        if(largeIcon != nil) {mapData[Definitions.NOTIFICATION_LARGE_ICON] = largeIcon}
        if(bigPicture != nil) {mapData[Definitions.NOTIFICATION_BIG_PICTURE] = bigPicture}
        if(buttonLabels != nil) {mapData[Definitions.NOTIFICATION_BUTTON_LABELS] = buttonLabels}
        
        return mapData
    }
    
    public func validate() throws {
    }
}
