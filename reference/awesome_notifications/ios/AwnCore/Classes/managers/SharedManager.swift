//
//  SharedManager.swift
//  awesome_notifications
//
//  Created by Rafael Setragni on 11/09/20.
//

import Foundation

public class SharedManager {
    
    let _userDefaults = UserDefaults(suiteName: Definitions.USER_DEFAULT_TAG)
    
    let tag:String
    var objectList:[String:Any?]    
    
    public init(tag:String){
        self.tag = tag
        objectList = [:]
    }
    
    private let TAG:String = "SharedManager"
    
    private func refreshObjects(){
        objectList = _userDefaults!.dictionary(forKey: tag) ?? [:]
    }
    
    private func updateObjects(){
        _userDefaults!.removeObject(forKey: tag)
        _userDefaults!.setValue(objectList, forKey: tag)
        refreshObjects()
    }
    
    public func get(referenceKey:String ) -> [String:Any?]? {
        refreshObjects()
        return objectList[referenceKey] as? [String:Any?]
    }
    
    public func set(_ data:[String:Any?]?, referenceKey:String) {
        refreshObjects()
        if(StringUtils.shared.isNullOrEmpty(referenceKey) || data == nil){ return }
        objectList[referenceKey] = data!
        updateObjects()
    }
    
    public func remove(referenceKey:String) -> Bool {
        refreshObjects()
        if(StringUtils.shared.isNullOrEmpty(referenceKey)){ return false }
        
        objectList.removeValue(forKey: referenceKey)
        updateObjects()
        return true
    }
    
    public func removeAll() {
        refreshObjects()
        objectList.removeAll()
        updateObjects()
    }
    
    public func getAllObjects() -> [[String:Any?]] {
        refreshObjects()
        var returnedList:[[String:Any?]] = []
        
        for (_, data) in objectList {
            if let dictionary:[String:Any?] = data as? [String:Any?] {
                returnedList.append( dictionary )
            }
        }
        
        return returnedList
    }
    
}
