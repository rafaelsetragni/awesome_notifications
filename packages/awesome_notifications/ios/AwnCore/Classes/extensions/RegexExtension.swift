//
//  RegexExtension.swift
//  awesome_notifications
//
//  Created by Rafael Setragni on 18/09/20.
//

import Foundation

extension NSRegularExpression {
    convenience init(_ pattern: String) {
        do {
            try self.init(pattern: pattern)
        } catch {
            preconditionFailure("Illegal regular expression: \(pattern).")
        }
    }
}
