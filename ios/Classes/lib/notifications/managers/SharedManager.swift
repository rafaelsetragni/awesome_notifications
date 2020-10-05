//
//  SharedManager.swift
//  awesome_notifications
//
//  Created by Rafael Setragni on 11/09/20.
//

import Foundation

public class SharedManager {
    
    let _sharedInstance = UserDefaults.standard
    
    let tag:String
    var objectList:[String:Any?]
    
    
    public init(tag:String){
        self.tag = tag
        objectList = _sharedInstance.dictionary(forKey: tag) ?? [:]
    }
    
    private let TAG:String = "SharedManager"
    
    public func updateObjects(){
        //_sharedInstance.setValue(objectList, forKey: tag)
    }
    
    public func get(referenceKey:String ) -> [String:Any?]? {
        return objectList[referenceKey] as? [String:Any?]
    }
    
    public func set(_ data:[String:Any?]?, referenceKey:String) {
        if(StringUtils.isNullOrEmpty(referenceKey) || data == nil){ return }
        objectList[referenceKey] = data!
        updateObjects()
    }
    
    public func remove(referenceKey:String) -> Bool {
        if(StringUtils.isNullOrEmpty(referenceKey)){ return false }
        
        if(objectList[referenceKey] != nil){
            objectList.removeValue(forKey: referenceKey)
            updateObjects()
            return true
        }
        return false
    }
    
    public func getAllObjects() -> [[String:Any?]] {
        var returnedList:[[String:Any?]] = []
        
        for (_, data) in objectList {
            if let dictionary:[String:Any?] = data as? [String:Any?] {
                returnedList.append( dictionary )
            }
        }
        
        return returnedList
    }
    
}
