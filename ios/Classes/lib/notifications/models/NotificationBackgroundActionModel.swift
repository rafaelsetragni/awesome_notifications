//
//  NotificationBackgroundActionModel.swift
//  awesome_notifications
//
//  Created by Sahar Vanunu on 09/08/2021.
//

import Foundation

public class NotificationBackgroundActionModel:AbstractModel {
    
    var identifier:String?
    var positive:NotificationButtonModel?
    var negative:NotificationButtonModel?
    
    public func fromMap(arguments: [String : Any?]?) -> AbstractModel? {
        if(arguments == nil){ return self }
        self.identifier = MapUtils<String>.getValueOrDefault(reference: "identifier", arguments: arguments)
        self.positive = NotificationButtonModel().fromMap(arguments:MapUtils<[String : Any?]>.getValueOrDefault(reference: "positive", arguments: arguments)) as? NotificationButtonModel
        
        self.negative = NotificationButtonModel().fromMap(arguments:MapUtils<[String : Any?]>.getValueOrDefault(reference: "negative", arguments: arguments)) as? NotificationButtonModel
        return self;
    }
    
    public func toMap() -> [String : Any?] {
        var mapData:[String: Any?] = [:]
        if(identifier != nil) {mapData["identifier"] = self.identifier}
        if(positive != nil) {mapData["positive"] = self.positive?.toMap()}
        if(negative != nil) {mapData["negative"] = self.negative?.toMap()}
        return mapData
    }
    
    public func validate() throws {
        if(StringUtils.isNullOrEmpty(identifier)){
            throw AwesomeNotificationsException.invalidRequiredFields(
                msg: "Button action key cannot be null or empty")
        }

        if(positive == nil){
            throw AwesomeNotificationsException.invalidRequiredFields(
                msg: "Positive Button cannot be null or empty")
        }
        
        try positive?.validate()
        
        if(negative == nil){
            throw AwesomeNotificationsException.invalidRequiredFields(
                msg: "Negative Button cannot be null or empty")
        }
        
        try negative?.validate()
    }
    
    
}
