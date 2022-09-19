//
//  ChannelManager.swift
//  awesome_notifications
//
//  Created by Rafael Setragni on 11/09/20.
//

import Foundation

public class ChannelManager {
    
    static let TAG = "ChannelManager"
    
    // ************** SINGLETON PATTERN ***********************
    
    static var instance:ChannelManager?
    public static var shared:ChannelManager {
        get {
            ChannelManager.instance =
                ChannelManager.instance ?? ChannelManager()
            return ChannelManager.instance!
        }
    }
    private init(){}
    
    // ********************************************************
    
    private let sharedManager:SharedManager = SharedManager(tag: "NotificationChannels")
    
    public func removeChannel( channelKey:String ) -> Bool {
        return sharedManager.remove(referenceKey: channelKey)
    }
    
    public func listChannels() -> [NotificationChannelModel] {
        var returnedList:[NotificationChannelModel] = []
        let dataList = sharedManager.getAllObjects()
        
        for data in dataList {
            let channel:NotificationChannelModel = NotificationChannelModel().fromMap(arguments: data) as! NotificationChannelModel
            returnedList.append(channel)
        }
        
        return returnedList
    }
    
    public func saveChannel(channel:NotificationChannelModel, setOnlyNew:Bool){
        if setOnlyNew {
            let oldChannel:NotificationChannelModel? = getChannelByKey(channelKey: channel.channelKey!)
            if oldChannel != nil && !channel.areAndroidLockedFieldsEqualsTo(channel: oldChannel!) {
                return
            }
        }
        sharedManager.set(channel.toMap(), referenceKey: channel.channelKey!)
    }
    
    public func getChannelByKey(channelKey:String) -> NotificationChannelModel? {
        guard let data:[String:Any?] = sharedManager.get(referenceKey: channelKey) else {
          return nil
        }
        return NotificationChannelModel().fromMap(arguments: data) as? NotificationChannelModel
    }
    
    public func isNotificationChannelActive(channel: NotificationChannelModel) -> Bool {
        return channel.importance != .None
    }
    
    public func isNotificationChannelActive(channelKey:String) -> Bool {
        guard let channel:NotificationChannelModel = getChannelByKey(channelKey: channelKey) else {
            return false
        }
        return isNotificationChannelActive(channel: channel)
    }
    
}
