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
        finalBundleName = finalBundleName.replacingOccurrences(of: ".AwesomeServiceExtension", with: "")
        finalBundleName = finalBundleName.replacingOccurrences(of: ".AwesomeContentExtension", with: "")
        return finalBundleName
    }
}
