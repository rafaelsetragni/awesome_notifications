//
//  SharedManager.swift
//  awesome_notifications
//
//  Created by Rafael Setragni on 11/09/20.
//

import Foundation

public class SharedManager {
    private let userDefaults: UserDefaults
    private let tag: String
    private var objectList: [String: Any?]

    private let queue = DispatchQueue(label: "awn.sharedManager.queue")

    public init(tag: String) {
        self.tag = tag
        self.userDefaults = UserDefaults(suiteName: Definitions.USER_DEFAULT_TAG) ?? .standard
        self.objectList = self.userDefaults.dictionary(forKey: tag) ?? [:]
    }

    private func refreshObjects() {
        queue.sync {
            objectList = userDefaults.dictionary(forKey: tag) ?? [:]
        }
    }

    private func updateObjects() {
        queue.sync {
            userDefaults.removeObject(forKey: tag)
            userDefaults.setValue(objectList, forKey: tag)
            userDefaults.synchronize()
            refreshObjects()
        }
    }

    public func get(referenceKey: String) -> [String: Any?]? {
        queue.sync {
            refreshObjects()
            return objectList[referenceKey] as? [String: Any?]
        }
    }

    public func set(_ data: [String: Any?]?, referenceKey: String) {
        guard !StringUtils.shared.isNullOrEmpty(referenceKey),
              let data = data else { return }

        queue.sync {
            refreshObjects()
            objectList[referenceKey] = data
            updateObjects()
        }
    }

    public func remove(referenceKey: String) -> Bool {
        guard !StringUtils.shared.isNullOrEmpty(referenceKey) else { return false }

        queue.sync {
            refreshObjects()
            objectList.removeValue(forKey: referenceKey)
            updateObjects()
            return true
        }
    }

    public func removeAll() {
        queue.sync {
            refreshObjects()
            objectList.removeAll()
            updateObjects()
        }
    }

    public func getAllObjectsStarting(with keyFragment: String) -> [[String: Any?]] {
        queue.sync {
            refreshObjects()
            return objectList.compactMap { key, data in
                guard key.starts(with: keyFragment),
                      let dictionary = data as? [String: Any?] else { return nil }
                return dictionary
            }
        }
    }

    public func getAllObjects() -> [[String: Any?]] {
        queue.sync {
            refreshObjects()
            return objectList.compactMap { _, data in
                data as? [String: Any?]
            }
        }
    }
}
