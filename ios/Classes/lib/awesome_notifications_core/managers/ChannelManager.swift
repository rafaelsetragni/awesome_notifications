//
//  ChannelManager.swift
//  awesome_notifications
//
//  Created by Rafael Setragni on 11/09/20.
//

import Foundation

public class ChannelManager {
    
    public static String TAG = "ChannelManager"
    
    // ************** SINGLETON PATTERN ***********************
    
    public static let shared: ChannelManager = ChannelManager()
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
    
    public func saveChannel(channel:NotificationChannelModel){
        sharedManager.set(channel.toMap(), referenceKey: channel.channelKey!)
    }
    
    public func getChannelByKey( channelKey:String ) -> NotificationChannelModel? {
        guard let data:[String:Any?] = sharedManager.get(referenceKey: channelKey) else {
          return nil
        }
        return NotificationChannelModel().fromMap(arguments: data) as? NotificationChannelModel
    }
    
    public func isNotificationChannelActive( channelKey:String ) -> Bool {
        return sharedManager.get(referenceKey: channelKey) != nil
    }
    
}
