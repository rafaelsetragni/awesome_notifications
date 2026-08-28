import Foundation
import IosAwnCore

/// A silent (data-only) push, serialized to/from the map delivered to the Dart
/// `FcmSilentData`. Envelope fields are pulled out; everything else is [data].
final class SilentDataModel {
    var id: Int?
    var data: [String: Any] = [:]
    var createdDate: String?
    var createdSource: NotificationSource = .firebase
    var createdLifeCycle: NotificationLifeCycle = .terminated

    @discardableResult
    func fromData(_ remoteData: [String: Any]) -> SilentDataModel {
        for (key, value) in remoteData {
            switch key {
            case Definitions.NOTIFICATION_ID:
                id = (value as? Int) ?? Int("\(value)")
            case Definitions.NOTIFICATION_CREATED_DATE:
                createdDate = "\(value)"
            case Definitions.NOTIFICATION_CREATED_SOURCE:
                createdSource = NotificationSource(rawValue: "\(value)") ?? .firebase
            case Definitions.NOTIFICATION_CREATED_LIFECYCLE:
                createdLifeCycle = NotificationLifeCycle(rawValue: "\(value)") ?? .terminated
            case FcmDefinitions.SILENT_HANDLE, FcmDefinitions.APS:
                break
            default:
                data[key] = value
            }
        }
        if createdDate == nil { createdDate = FcmDateUtils.nowUtc() }
        return self
    }

    func toMap() -> [String: Any] {
        var map: [String: Any] = data
        map[Definitions.NOTIFICATION_ID] = id.map { String($0) }
        map[Definitions.NOTIFICATION_CREATED_DATE] = createdDate
        map[Definitions.NOTIFICATION_CREATED_SOURCE] = createdSource.rawValue
        map[Definitions.NOTIFICATION_CREATED_LIFECYCLE] = createdLifeCycle.rawValue
        return map
    }
}
