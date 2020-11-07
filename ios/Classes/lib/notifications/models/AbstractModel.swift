//
//  AbstractModel.swift
//  awesome_notifications
//
//  Created by Rafael Setragni on 05/09/20.
//

import Foundation

public protocol AbstractModel {
    
    func fromMap(arguments: [String : Any?]?) -> AbstractModel?
    func toMap() -> [String : Any?]

    func validate() throws
}
