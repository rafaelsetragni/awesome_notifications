//
//  AbstractModel.swift
//  awesome_notifications
//
//  Created by Rafael Setragni on 28/08/20.
//

import Foundation

protocol AbstractEnum {
    static func fromString(_ value: String?) -> AbstractEnum?
}
