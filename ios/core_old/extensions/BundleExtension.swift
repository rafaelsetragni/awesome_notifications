//
//  NSBundleExtension.swift
//  Pods
//
//  Created by Rafael Setragni on 01/11/20.
//

import Foundation

extension Bundle {
    
    func getBundleName() -> String {
        var finalBundleName = Bundle.main.bundleIdentifier ?? "unknow"
        if(SwiftUtils.isRunningOnExtension()){
            _ = finalBundleName.replaceRegex(#"\.\w+$"#)
        }
        return finalBundleName
    }
}
