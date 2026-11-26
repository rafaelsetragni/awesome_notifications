//
//  SwiftUtils.swift
//  Pods
//
//  Created by Rafael Setragni on 16/10/20.
//

import Foundation
public class SwiftUtils{
    
    private static var _isExtension:Bool?
    
    public static func isRunningOnExtension() -> Bool {
        if _isExtension == nil {
            _isExtension = Bundle.main.bundlePath.hasSuffix(".appex")
        }
        return _isExtension!
    }
}
